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
    
    # Probar con INBOX primero
    try:
        status = mail.select("INBOX")
        print(f"[DEBUG] Seleccionando INBOX: {status}")
    except Exception as e:
        print(f"[ERROR] Error seleccionando INBOX: {e}")
        mail.logout()
        return []

    # Buscar correos de ambas direcciones por separado y combinar resultados
    all_email_ids = set()

    # Buscar correos de enviodigital@bancochile.cl
    try:
        status, data = mail.search(None, "FROM", "enviodigital@bancochile.cl")
        print(f"[DEBUG] Búsqueda enviodigital: status={status}, data={data}")
        if status == "OK" and data and data[0]:
            email_ids_str = data[0].decode() if isinstance(data[0], bytes) else str(data[0])
            email_ids_str = email_ids_str.strip()
            if email_ids_str:
                found_ids = email_ids_str.split()
                print(f"[DEBUG] Encontrados {len(found_ids)} correos de enviodigital@bancochile.cl")
                all_email_ids.update(found_ids)
            else:
                print("[DEBUG] No se encontraron correos de enviodigital@bancochile.cl")
        else:
            print("[DEBUG] Búsqueda de enviodigital falló o no devolvió datos")
    except Exception as e:
        print(f"[ERROR] Error buscando enviodigital: {e}")
        import traceback
        traceback.print_exc()

    # Buscar correos de serviciodetransferencias@bancochile.cl
    try:
        status, data = mail.search(None, "FROM", "serviciodetransferencias@bancochile.cl")
        print(f"[DEBUG] Búsqueda serviciodetransferencias: status={status}, data={data}")
        if status == "OK" and data and data[0]:
            email_ids_str = data[0].decode() if isinstance(data[0], bytes) else str(data[0])
            email_ids_str = email_ids_str.strip()
            if email_ids_str:
                found_ids = email_ids_str.split()
                print(f"[DEBUG] Encontrados {len(found_ids)} correos de serviciodetransferencias@bancochile.cl")
                all_email_ids.update(found_ids)
            else:
                print("[DEBUG] No se encontraron correos de serviciodetransferencias@bancochile.cl")
        else:
            print("[DEBUG] Búsqueda de serviciodetransferencias falló o no devolvió datos")
    except Exception as e:
        print(f"[ERROR] Error buscando serviciodetransferencias: {e}")
        import traceback
        traceback.print_exc()

    print(f"[DEBUG] Total de IDs de correos encontrados: {len(all_email_ids)}")

    if not all_email_ids:
        print("[DEBUG] No se encontraron correos. Verificando si hay correos en el INBOX...")
        try:
            # Intentar buscar todos los correos recientes para debug
            status, data = mail.search(None, "ALL")
            if status == "OK" and data and data[0]:
                all_ids = data[0].decode() if isinstance(data[0], bytes) else str(data[0])
                all_ids = all_ids.strip()
                total = len(all_ids.split()) if all_ids else 0
                print(f"[DEBUG] Total de correos en INBOX: {total}")
        except Exception as e:
            print(f"[ERROR] Error contando correos: {e}")
        
        mail.logout()
        return []

    # Ordenar y tomar los últimos 30
    try:
        email_ids = sorted(list(all_email_ids), key=lambda x: int(x.decode() if isinstance(x, bytes) else x))[-30:]
    except Exception as e:
        print(f"[ERROR] Error ordenando IDs: {e}")
        email_ids = list(all_email_ids)[-30:]
    
    print(f"[DEBUG] Procesando {len(email_ids)} correos (últimos 30 de {len(all_email_ids)} encontrados)")
    messages = []
    for i, eid in enumerate(email_ids):
        try:
            eid_str = eid.decode() if isinstance(eid, bytes) else str(eid)
            status, msg_data = mail.fetch(eid_str.encode() if isinstance(eid_str, str) else eid_str, "(RFC822)")
            if status != "OK":
                print(f"[DEBUG] Error fetch correo {i+1} (ID: {eid_str}): status={status}")
                continue
            msg = email.message_from_bytes(msg_data[0][1])
            
            # Log del asunto para debugging
            subject = msg.get("Subject", "Sin asunto")
            from_addr = msg.get("From", "Sin remitente")
            print(f"[DEBUG] Correo {i+1}: From={from_addr[:50]}, Subject={subject[:50]}")
            
        except Exception as e:
            print(f"[ERROR] Error procesando correo {i+1} (ID: {eid}): {e}")
            import traceback
            traceback.print_exc()
            continue

        if msg.is_multipart():
            body = ""
            html_body = ""
            for part in msg.walk():
                content_type = part.get_content_type()
                if content_type == "text/plain":
                    try:
                        payload = part.get_payload(decode=True)
                        if payload:
                            body += payload.decode("utf-8", errors="ignore")
                    except Exception as e:
                        print(f"[DEBUG] Error decodificando text/plain: {e}")
                elif content_type == "text/html":
                    try:
                        payload = part.get_payload(decode=True)
                        if payload:
                            html_body += payload.decode("utf-8", errors="ignore")
                    except Exception as e:
                        print(f"[DEBUG] Error decodificando text/html: {e}")
            
            # Si no hay texto plano, usar HTML
            if not body and html_body:
                # Intentar extraer texto del HTML (básico)
                import re as re_module
                body = re_module.sub(r'<[^>]+>', ' ', html_body)
                body = re_module.sub(r'\s+', ' ', body)
            
            if body:
                messages.append(body)
            else:
                print(f"[DEBUG] Correo {i+1}: No se pudo extraer contenido")
        else:
            try:
                body = msg.get_payload(decode=True)
                if body:
                    body = body.decode("utf-8", errors="ignore")
                    messages.append(body)
                else:
                    print(f"[DEBUG] Correo {i+1}: Payload vacío")
            except Exception as e:
                print(f"[DEBUG] Error decodificando correo simple: {e}")

    mail.logout()
    return messages


def parse_purchase(body: str):
    # Patrones más flexibles para compras/cargos
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
        # Cargo en Cuenta - formato común
        re.compile(
            r"cargo.*?cuenta.*?\$([\d\.]+).*?en (.+?)(?: el| fecha|,)\s*(\d{2}/\d{2}/\d{4})(?:\s+(\d{2}:\d{2}))?",
            re.IGNORECASE | re.DOTALL,
        ),
        # Variación con "Cargo en Cuenta" en el título
        re.compile(
            r"(?:cargo|compra).*?\$([\d\.]+).*?(?:en|en|de)\s+(.+?)(?:\s+el|\s+fecha|,)\s*(\d{2}/\d{2}/\d{4})(?:\s+(\d{2}:\d{2}))?",
            re.IGNORECASE | re.DOTALL,
        ),
        # Variación más flexible
        re.compile(
            r"compra.*?\$([\d\.]+).*?en (.+?) el (\d{2}/\d{2}/\d{4}) (\d{2}:\d{2})",
            re.IGNORECASE | re.DOTALL,
        ),
        # Buscar cualquier monto seguido de fecha
        re.compile(
            r"\$([\d\.]+).*?(?:cargo|compra|pago).*?(\d{2}/\d{2}/\d{4})(?:\s+(\d{2}:\d{2}))?",
            re.IGNORECASE | re.DOTALL,
        ),
    ]

    for pattern_num, pattern in enumerate(patterns):
        m = pattern.search(body)
        if m:
            try:
                groups = m.groups()
                print(f"[DEBUG] Patrón {pattern_num + 1} coincidió, grupos: {len(groups)}")
                
                if len(groups) >= 3:
                    # Extraer monto
                    amount_str = groups[0].replace(".", "").replace(",", "").strip()
                    amount = int(amount_str)
                    
                    # Extraer descripción
                    if len(groups) >= 4:
                        merchant = groups[1].strip()
                        date_str = groups[2]
                        time_str = groups[3] if len(groups) > 3 and groups[3] else "00:00"
                    elif len(groups) == 3:
                        # Formato: monto, fecha, hora opcional
                        merchant = "Compra"  # Descripción por defecto
                        date_str = groups[1] if '/' in groups[1] else groups[2]
                        time_str = groups[2] if ':' in str(groups[2]) else "00:00"
                    else:
                        continue
                    
                    # Limpiar descripción (tomar primeros 100 caracteres)
                    merchant = merchant[:100].strip() if merchant else "Compra"
                    
                    # Parsear fecha y hora
                    if time_str and ':' in str(time_str):
                        dt = datetime.strptime(f"{date_str} {time_str}", "%d/%m/%Y %H:%M")
                    else:
                        dt = datetime.strptime(f"{date_str}", "%d/%m/%Y")

                    print(f"[DEBUG] Compra parseada: ${amount} CLP en {merchant} el {dt}")
                    return dict(
                        type="purchase",
                        amount=amount,
                        description=merchant,
                        date_time=dt,
                    )
            except (ValueError, IndexError, AttributeError) as e:
                print(f"[DEBUG] Error parseando compra con patrón {pattern_num + 1}: {e}")
                continue

    return None


def parse_transfer(body: str):
    # Patrones más flexibles para transferencias
    patterns = [
        re.compile(r"monto\s+\$([\d\.]+)", re.IGNORECASE),
        re.compile(r"transferencia.*?a\s+terceros.*?\$([\d\.]+)", re.IGNORECASE | re.DOTALL),
        re.compile(r"transferencia.*?\$([\d\.]+)", re.IGNORECASE | re.DOTALL),
        re.compile(r"\$([\d\.]+).*?transferencia", re.IGNORECASE | re.DOTALL),
        re.compile(r"monto.*?(\d+[\.\d]*)", re.IGNORECASE),
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
