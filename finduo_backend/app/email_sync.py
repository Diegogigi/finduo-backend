import imaplib
import email
import os
import re
from datetime import datetime

from .database import SessionLocal
from .models import Transaction, User


IMAP_HOST = "imap.gmail.com"  # Cambia según tu proveedor de correo


def get_imap_conn():
    user = os.getenv("EMAIL_USER")
    password = os.getenv("EMAIL_PASSWORD")
    if not user or not password:
        raise RuntimeError("EMAIL_USER y EMAIL_PASSWORD deben estar configuradas")

    mail = imaplib.IMAP4_SSL(IMAP_HOST)
    mail.login(user, password)
    return mail


def fetch_bank_emails():
    """Obtiene los últimos correos del Banco de Chile."""
    mail = get_imap_conn()
    mail.select("INBOX")

    # Buscar correos de ambas direcciones por separado y combinar resultados
    all_email_ids = set()

    # Buscar correos de enviodigital@bancochile.cl
    try:
        status, data = mail.search(None, "FROM", "enviodigital@bancochile.cl")
        if status == "OK" and data and data[0]:
            email_ids_str = data[0].strip()
            if email_ids_str:
                all_email_ids.update(email_ids_str.split())
    except Exception as e:
        print(f"Error buscando enviodigital: {e}")
        pass

    # Buscar correos de serviciodetransferencias@bancochile.cl
    try:
        status, data = mail.search(
            None, "FROM", "serviciodetransferencias@bancochile.cl"
        )
        if status == "OK" and data and data[0]:
            email_ids_str = data[0].strip()
            if email_ids_str:
                all_email_ids.update(email_ids_str.split())
    except Exception as e:
        print(f"Error buscando serviciodetransferencias: {e}")
        pass

    if not all_email_ids:
        mail.logout()
        return []

    # Ordenar y tomar los últimos 30
    email_ids = sorted(list(all_email_ids), key=lambda x: int(x))[-30:]
    messages = []
    for eid in email_ids:
        status, msg_data = mail.fetch(eid, "(RFC822)")
        if status != "OK":
            continue
        msg = email.message_from_bytes(msg_data[0][1])

        if msg.is_multipart():
            body = ""
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body += part.get_payload(decode=True).decode(
                        "utf-8", errors="ignore"
                    )
        else:
            body = msg.get_payload(decode=True).decode("utf-8", errors="ignore")

        messages.append(body)

    mail.logout()
    return messages


def parse_purchase(body: str):
    # Patrón más flexible para compras
    patterns = [
        # Patrón original
        re.compile(
            r"compra por \$([\d\.]+)\s+con cargo a Cuenta \*+(\d+)\s+en (.+?) el (\d{2}/\d{2}/\d{4}) (\d{2}:\d{2})",
            re.IGNORECASE | re.DOTALL,
        ),
        # Variación sin asteriscos en cuenta
        re.compile(
            r"compra por \$([\d\.]+)\s+con cargo a Cuenta\s+(\d+)\s+en (.+?) el (\d{2}/\d{2}/\d{4}) (\d{2}:\d{2})",
            re.IGNORECASE | re.DOTALL,
        ),
        # Variación más flexible
        re.compile(
            r"compra.*?\$([\d\.]+).*?en (.+?) el (\d{2}/\d{2}/\d{4}) (\d{2}:\d{2})",
            re.IGNORECASE | re.DOTALL,
        ),
    ]

    for pattern in patterns:
        m = pattern.search(body)
        if m:
            try:
                groups = m.groups()
                if len(groups) == 5:
                    amount_str, last_digits, merchant, date_str, time_str = groups
                elif len(groups) == 4:
                    amount_str, merchant, date_str, time_str = groups
                else:
                    continue

                # Limpiar y convertir monto
                amount_str = amount_str.replace(".", "").replace(",", "").strip()
                amount = int(amount_str)

                # Parsear fecha y hora
                dt = datetime.strptime(f"{date_str} {time_str}", "%d/%m/%Y %H:%M")

                return dict(
                    type="purchase",
                    amount=amount,
                    description=merchant.strip(),
                    date_time=dt,
                )
            except (ValueError, IndexError) as e:
                print(f"[DEBUG] Error parseando compra: {e}")
                continue

    return None


def parse_transfer(body: str):
    # Patrones más flexibles para transferencias
    patterns = [
        re.compile(r"Monto\s+\$([\d\.]+)", re.IGNORECASE),
        re.compile(r"transferencia.*?\$([\d\.]+)", re.IGNORECASE | re.DOTALL),
        re.compile(r"monto.*?(\d+\.?\d*)", re.IGNORECASE),
    ]

    amount = None
    for pattern in patterns:
        m = pattern.search(body)
        if m:
            try:
                amount_str = m.group(1).replace(".", "").replace(",", "").strip()
                amount = int(amount_str)
                break
            except (ValueError, IndexError):
                continue

    if not amount:
        return None

    # Intentar parsear fecha del correo
    date_patterns = [
        re.compile(r"(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2})", re.IGNORECASE),
        re.compile(r"(\d{2}-\d{2}-\d{4})\s+(\d{2}:\d{2})", re.IGNORECASE),
    ]

    dt = datetime.utcnow()  # Por defecto usar fecha actual
    for pattern in date_patterns:
        m = pattern.search(body)
        if m:
            try:
                date_str, time_str = m.groups()
                if "/" in date_str:
                    dt = datetime.strptime(f"{date_str} {time_str}", "%d/%m/%Y %H:%M")
                else:
                    dt = datetime.strptime(f"{date_str} {time_str}", "%d-%m-%Y %H:%M")
                break
            except ValueError:
                continue

    return dict(
        type="transfer_out",
        amount=amount,
        description="Transferencia a terceros",
        date_time=dt,
    )


def sync_emails_to_db(user_email: str):
    """Lee correos y crea transacciones para un usuario."""
    db = SessionLocal()
    user = db.query(User).filter(User.email == user_email).first()
    if not user:
        user = User(email=user_email, name="Usuario FinDuo")
        db.add(user)
        db.commit()
        db.refresh(user)

    bodies = fetch_bank_emails()
    print(f"[DEBUG] Se encontraron {len(bodies)} correos para procesar")

    count = 0
    skipped = 0
    errors = 0

    for i, body in enumerate(bodies):
        try:
            info = parse_purchase(body) or parse_transfer(body)
            if not info:
                # Mostrar un preview del correo para debugging
                preview = body[:200].replace("\n", " ").strip()
                print(
                    f"[DEBUG] Correo {i+1}: No se pudo parsear (no coincide con patrones)"
                )
                print(f"[DEBUG] Preview: {preview}...")
                continue

            # Verificar si la transacción ya existe (evitar duplicados)
            existing = (
                db.query(Transaction)
                .filter(
                    Transaction.user_id == user.id,
                    Transaction.type == info["type"],
                    Transaction.amount == info["amount"],
                    Transaction.description == info["description"],
                    Transaction.date_time == info["date_time"],
                )
                .first()
            )

            if existing:
                print(
                    f"[DEBUG] Correo {i+1}: Transacción duplicada - {info['type']} ${info['amount']} CLP en {info['date_time']}"
                )
                skipped += 1
                continue

            tx = Transaction(
                user_id=user.id,
                type=info["type"],
                description=info["description"],
                amount=info["amount"],
                date_time=info["date_time"],
            )
            db.add(tx)
            count += 1
            print(
                f"[DEBUG] Correo {i+1}: Transacción creada - {info['type']} ${info['amount']} CLP en {info['date_time']}"
            )
        except Exception as e:
            print(f"[ERROR] Correo {i+1}: Error al procesar - {str(e)}")
            errors += 1
            continue

    db.commit()
    print(
        f"[DEBUG] Resumen: {count} importadas, {skipped} duplicadas, {errors} errores"
    )
    db.close()
    return count
