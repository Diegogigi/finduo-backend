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
        status, data = mail.search(None, 'FROM "enviodigital@bancochile.cl"')
        if status == "OK" and data and data[0]:
            email_ids_str = data[0].strip()
            if email_ids_str:
                all_email_ids.update(email_ids_str.split())
    except Exception:
        pass
    
    # Buscar correos de serviciodetransferencias@bancochile.cl
    try:
        status, data = mail.search(None, 'FROM "serviciodetransferencias@bancochile.cl"')
        if status == "OK" and data and data[0]:
            email_ids_str = data[0].strip()
            if email_ids_str:
                all_email_ids.update(email_ids_str.split())
    except Exception:
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
    pattern = re.compile(
        r"compra por \$([\d\.]+)\s+con cargo a Cuenta \*+(\d+)\s+en (.+?) el (\d{2}/\d{2}/\d{4}) (\d{2}:\d{2})",
        re.IGNORECASE | re.DOTALL,
    )
    m = pattern.search(body)
    if not m:
        return None

    amount_str, last_digits, merchant, date_str, time_str = m.groups()
    amount = int(amount_str.replace(".", "").replace(",", ""))
    dt = datetime.strptime(f"{date_str} {time_str}", "%d/%m/%Y %H:%M")

    return dict(
        type="purchase",
        amount=amount,
        description=merchant.strip(),
        date_time=dt,
    )


def parse_transfer(body: str):
    monto_match = re.search(r"Monto\s+\$([\d\.]+)", body)
    if not monto_match:
        return None

    amount = int(monto_match.group(1).replace(".", "").replace(",", ""))
    # TODO: parsear fecha exacta desde el correo
    dt = datetime.utcnow()

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
    count = 0
    for body in bodies:
        info = parse_purchase(body) or parse_transfer(body)
        if info:
            tx = Transaction(
                user_id=user.id,
                type=info["type"],
                description=info["description"],
                amount=info["amount"],
                date_time=info["date_time"],
            )
            db.add(tx)
            count += 1

    db.commit()
    db.close()
    return count
