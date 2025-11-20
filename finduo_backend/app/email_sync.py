import imaplib
import email
import os
import re
import logging
import sys
from datetime import datetime

from .database import SessionLocal
from .models import Transaction, User

# Configurar logging para que se vea en Railway
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),  # Asegurar que va a stdout
        logging.StreamHandler(sys.stderr),  # También a stderr por si acaso
    ],
)
logger = logging.getLogger(__name__)


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
    """Obtiene los últimos correos del Banco de Chile desde INBOX y etiquetas."""
    mail = get_imap_conn()

    # Lista de ubicaciones donde buscar (INBOX + etiquetas de Gmail)
    locations = ["INBOX", "INBOX/Compras", "INBOX/Bancos"]
    
    # Buscar correos de ambas direcciones en todas las ubicaciones
    all_email_ids = set()

    # Buscar en cada ubicación
    for location in locations:
        try:
            # Intentar seleccionar la ubicación
            try:
                status = mail.select(location)
                logger.info(f"Seleccionando {location}: {status}")
            except Exception as e:
                # Si falla, intentar con formato alternativo
                try:
                    alt_location = location.replace("INBOX/", "")
                    status = mail.select(f'"[Gmail]/{alt_location}"')
                    logger.info(f"Seleccionando [Gmail]/{alt_location}: {status}")
                except Exception:
                    logger.warning(f"No se pudo acceder a {location}, saltando...")
                    continue

            # Buscar correos de enviodigital@bancochile.cl
            try:
                status, data = mail.search(None, "FROM", "enviodigital@bancochile.cl")
                logger.info(f"Búsqueda enviodigital en {location}: status={status}")
                if status == "OK" and data and data[0]:
                    email_ids_str = (
                        data[0].decode() if isinstance(data[0], bytes) else str(data[0])
                    )
                    email_ids_str = email_ids_str.strip()
                    if email_ids_str:
                        found_ids = email_ids_str.split()
                        logger.info(
                            f"Encontrados {len(found_ids)} correos de enviodigital@bancochile.cl en {location}"
                        )
                        all_email_ids.update(found_ids)
                else:
                    logger.debug(f"No se encontraron correos de enviodigital en {location}")
            except Exception as e:
                logger.warning(f"Error buscando enviodigital en {location}: {e}")

            # Buscar correos de serviciodetransferencias@bancochile.cl
            try:
                status, data = mail.search(
                    None, "FROM", "serviciodetransferencias@bancochile.cl"
                )
                logger.info(f"Búsqueda serviciodetransferencias en {location}: status={status}")
                if status == "OK" and data and data[0]:
                    email_ids_str = (
                        data[0].decode() if isinstance(data[0], bytes) else str(data[0])
                    )
                    email_ids_str = email_ids_str.strip()
                    if email_ids_str:
                        found_ids = email_ids_str.split()
                        logger.info(
                            f"Encontrados {len(found_ids)} correos de serviciodetransferencias@bancochile.cl en {location}"
                        )
                        all_email_ids.update(found_ids)
                else:
                    logger.debug(f"No se encontraron correos de serviciodetransferencias en {location}")
            except Exception as e:
                logger.warning(f"Error buscando serviciodetransferencias en {location}: {e}")

        except Exception as e:
            logger.warning(f"Error procesando ubicación {location}: {e}")
            continue

    logger.info(f"Total de IDs de correos encontrados: {len(all_email_ids)}")

    if not all_email_ids:
        logger.warning(
            "No se encontraron correos. Verificando si hay correos en el INBOX..."
        )
        try:
            # Intentar buscar todos los correos recientes para debug
            status, data = mail.search(None, "ALL")
            if status == "OK" and data and data[0]:
                all_ids = (
                    data[0].decode() if isinstance(data[0], bytes) else str(data[0])
                )
                all_ids = all_ids.strip()
                total = len(all_ids.split()) if all_ids else 0
                logger.info(f"Total de correos en INBOX: {total}")
        except Exception as e:
            logger.error(f"Error contando correos: {e}", exc_info=True)

        mail.logout()
        return []

    # Cerrar conexión actual y abrir una nueva para leer los correos desde INBOX
    mail.logout()
    mail = get_imap_conn()
    mail.select("INBOX")  # Seleccionar INBOX para leer los correos

    # Ordenar y tomar los últimos 30
    try:
        email_ids = sorted(
            list(all_email_ids),
            key=lambda x: int(x.decode() if isinstance(x, bytes) else x),
        )[-30:]
    except Exception as e:
        logger.error(f"Error ordenando IDs: {e}", exc_info=True)
        email_ids = list(all_email_ids)[-30:]

    logger.info(
        f"Procesando {len(email_ids)} correos (últimos 30 de {len(all_email_ids)} encontrados)"
    )
    messages = []
    for i, eid in enumerate(email_ids):
        try:
            eid_str = eid.decode() if isinstance(eid, bytes) else str(eid)
            status, msg_data = mail.fetch(eid_str, "(RFC822)")
            if status != "OK":
                logger.warning(
                    f"Error fetch correo {i+1} (ID: {eid_str}): status={status}"
                )
                continue
            msg = email.message_from_bytes(msg_data[0][1])

            # Log del asunto para debugging
            subject = msg.get("Subject", "Sin asunto")
            from_addr = msg.get("From", "Sin remitente")
            logger.info(f"Correo {i+1}: From={from_addr[:50]}, Subject={subject[:50]}")

        except Exception as e:
            logger.error(
                f"Error procesando correo {i+1} (ID: {eid}): {e}", exc_info=True
            )
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
                        logger.debug(f"Error decodificando text/plain: {e}")
                elif content_type == "text/html":
                    try:
                        payload = part.get_payload(decode=True)
                        if payload:
                            html_body += payload.decode("utf-8", errors="ignore")
                    except Exception as e:
                        logger.debug(f"Error decodificando text/html: {e}")

            # Si no hay texto plano, usar HTML
            if not body and html_body:
                # Intentar extraer texto del HTML (básico)
                import re as re_module

                body = re_module.sub(r"<[^>]+>", " ", html_body)
                body = re_module.sub(r"\s+", " ", body)

            if body:
                messages.append(body)
            else:
                logger.warning(f"Correo {i+1}: No se pudo extraer contenido")
        else:
            try:
                body = msg.get_payload(decode=True)
                if body:
                    body = body.decode("utf-8", errors="ignore")
                    messages.append(body)
                else:
                    logger.warning(f"Correo {i+1}: Payload vacío")
            except Exception as e:
                logger.error(f"Error decodificando correo simple: {e}", exc_info=True)

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
                logger.debug(
                    f"Patrón {pattern_num + 1} coincidió, grupos: {len(groups)}"
                )

                if len(groups) >= 3:
                    # Extraer monto
                    amount_str = groups[0].replace(".", "").replace(",", "").strip()
                    amount = int(amount_str)

                    # Extraer descripción
                    if len(groups) >= 4:
                        merchant = groups[1].strip()
                        date_str = groups[2]
                        time_str = (
                            groups[3] if len(groups) > 3 and groups[3] else "00:00"
                        )
                    elif len(groups) == 3:
                        # Formato: monto, fecha, hora opcional
                        merchant = "Compra"  # Descripción por defecto
                        date_str = groups[1] if "/" in groups[1] else groups[2]
                        time_str = groups[2] if ":" in str(groups[2]) else "00:00"
                    else:
                        continue

                    # Limpiar descripción (tomar primeros 100 caracteres)
                    merchant = merchant[:100].strip() if merchant else "Compra"

                    # Parsear fecha y hora
                    if time_str and ":" in str(time_str):
                        dt = datetime.strptime(
                            f"{date_str} {time_str}", "%d/%m/%Y %H:%M"
                        )
                    else:
                        dt = datetime.strptime(f"{date_str}", "%d/%m/%Y")

                    logger.info(f"Compra parseada: ${amount} CLP en {merchant} el {dt}")
                    return dict(
                        type="purchase",
                        amount=amount,
                        description=merchant,
                        date_time=dt,
                    )
            except (ValueError, IndexError, AttributeError) as e:
                logger.debug(
                    f"Error parseando compra con patrón {pattern_num + 1}: {e}"
                )
                continue

    return None


def parse_transfer(body: str):
    # Patrones más flexibles para transferencias
    patterns = [
        re.compile(r"monto\s+\$([\d\.]+)", re.IGNORECASE),
        re.compile(
            r"transferencia.*?a\s+terceros.*?\$([\d\.]+)", re.IGNORECASE | re.DOTALL
        ),
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

    logger.info("Iniciando sincronización de correos...")
    try:
        bodies = fetch_bank_emails()
        logger.info(f"Se encontraron {len(bodies)} correos para procesar")
    except Exception as e:
        logger.error(f"Error al obtener correos: {e}", exc_info=True)
        db.close()
        return 0

    count = 0
    skipped = 0
    errors = 0

    for i, body in enumerate(bodies):
        try:
            info = parse_purchase(body) or parse_transfer(body)
            if not info:
                # Mostrar un preview del correo para debugging
                preview = body[:200].replace("\n", " ").strip()
                logger.warning(
                    f"Correo {i+1}: No se pudo parsear (no coincide con patrones)"
                )
                logger.debug(f"Preview: {preview}...")
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
                logger.info(
                    f"Correo {i+1}: Transacción duplicada - {info['type']} ${info['amount']} CLP en {info['date_time']}"
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
            logger.info(
                f"Correo {i+1}: Transacción creada - {info['type']} ${info['amount']} CLP en {info['date_time']}"
            )
        except Exception as e:
            logger.error(f"Correo {i+1}: Error al procesar - {str(e)}", exc_info=True)
            errors += 1
            continue

    db.commit()
    logger.info(f"Resumen: {count} importadas, {skipped} duplicadas, {errors} errores")
    db.close()
    return count
