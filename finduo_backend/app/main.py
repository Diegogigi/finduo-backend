from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel

from .database import Base, engine, SessionLocal
from .models import (
    Transaction,
    User,
    DuoRoom,
    DuoMembership,
    DuoStatus,
    DuoRole,
)
from .email_sync import sync_emails_to_db
import secrets

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="FinDuo Backend",
    version="0.1.0",
)

# Para el MVP usamos un usuario fijo (luego se reemplaza por autenticación real)
CURRENT_USER_EMAIL = "diego.castro.lagos@gmail.com"


def get_current_user(db):
    user = db.query(User).filter(User.email == CURRENT_USER_EMAIL).first()
    if not user:
        user = User(email=CURRENT_USER_EMAIL, name="Diego")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/sync-email")
def sync_email():
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Iniciando sincronización de correo para: {CURRENT_USER_EMAIL}")
    try:
        count = sync_emails_to_db(CURRENT_USER_EMAIL)
        logger.info(f"Sincronización completada: {count} correos importados")
        return {"imported": count}
    except Exception as e:
        logger.error(f"Error en sincronización: {e}", exc_info=True)
        return {"imported": 0, "error": str(e)}


@app.get("/transactions")
def list_transactions(mode: str = Query("individual")):
    db = SessionLocal()
    user = get_current_user(db)

    if mode == "duo":
        membership = (
            db.query(DuoMembership)
            .filter(
                DuoMembership.user_id == user.id,
                DuoMembership.status == DuoStatus.active,
            )
            .first()
        )
        if not membership:
            db.close()
            return []
        room_id = membership.room_id
        txs = (
            db.query(Transaction)
            .filter(Transaction.duo_room_id == room_id)
            .order_by(Transaction.date_time.desc())
            .all()
        )
    else:
        txs = (
            db.query(Transaction)
            .filter(Transaction.user_id == user.id)
            .order_by(Transaction.date_time.desc())
            .all()
        )

    result = [
        {
            "id": t.id,
            "type": t.type,
            "description": t.description,
            "amount": t.amount,
            "currency": t.currency,
            "date_time": t.date_time.isoformat(),
        }
        for t in txs
    ]
    db.close()
    return result


@app.put("/transactions/{transaction_id}")
def update_transaction(transaction_id: int, tx: TransactionUpdate):
    db = SessionLocal()
    user = get_current_user(db)
    
    # Buscar la transacción
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == user.id
    ).first()
    
    if not transaction:
        db.close()
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    # Actualizar campos
    from datetime import datetime
    date_time = datetime.fromisoformat(tx.date_time.replace('Z', '+00:00'))
    
    transaction.type = tx.type
    transaction.description = tx.description
    transaction.amount = tx.amount
    transaction.date_time = date_time
    
    db.commit()
    db.refresh(transaction)
    
    result = {
        "id": transaction.id,
        "type": transaction.type,
        "description": transaction.description,
        "amount": transaction.amount,
        "currency": transaction.currency,
        "date_time": transaction.date_time.isoformat(),
    }
    
    db.close()
    return result


@app.delete("/transactions/{transaction_id}")
def delete_transaction(transaction_id: int):
    db = SessionLocal()
    try:
        user = get_current_user(db)
        
        # Buscar la transacción
        transaction = db.query(Transaction).filter(
            Transaction.id == transaction_id,
            Transaction.user_id == user.id
        ).first()
        
        if not transaction:
            raise HTTPException(status_code=404, detail="Transacción no encontrada")
        
        # Guardar ID antes de eliminar
        transaction_id_backup = transaction.id
        
        # Eliminar usando el método correcto de SQLAlchemy
        db.delete(transaction)
        db.commit()
        
        return {"status": "deleted", "id": transaction_id_backup}
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al eliminar transacción: {str(e)}")
    finally:
        db.close()


class JoinRequest(BaseModel):
    invite_code: str


@app.post("/duo/invite")
def create_duo_invite():
    db = SessionLocal()
    user = get_current_user(db)

    membership = (
        db.query(DuoMembership).filter(DuoMembership.user_id == user.id).first()
    )
    if membership:
        room = db.query(DuoRoom).get(membership.room_id)
        db.close()
        return {"invite_code": room.invite_code}

    code = secrets.token_urlsafe(8)
    room = DuoRoom(invite_code=code)
    db.add(room)
    db.commit()
    db.refresh(room)

    owner = DuoMembership(
        user_id=user.id,
        room_id=room.id,
        role=DuoRole.owner,
        status=DuoStatus.active,
    )
    db.add(owner)
    db.commit()
    db.close()
    return {"invite_code": code}


@app.post("/duo/join")
def join_duo(req: JoinRequest):
    db = SessionLocal()
    user = get_current_user(db)

    room = db.query(DuoRoom).filter(DuoRoom.invite_code == req.invite_code).first()
    if not room:
        db.close()
        raise HTTPException(status_code=404, detail="Código no válido")

    count_members = (
        db.query(DuoMembership).filter(DuoMembership.room_id == room.id).count()
    )
    if count_members >= 2:
        db.close()
        raise HTTPException(status_code=400, detail="Este FinDuo ya está completo")

    membership = DuoMembership(
        user_id=user.id,
        room_id=room.id,
        role=DuoRole.partner,
        status=DuoStatus.active,
    )
    db.add(membership)
    db.commit()
    db.close()
    return {"status": "joined"}


@app.get("/me")
def me():
    db = SessionLocal()
    user = get_current_user(db)
    membership = (
        db.query(DuoMembership)
        .filter(DuoMembership.user_id == user.id, DuoMembership.status == DuoStatus.active)
        .first()
    )
    duo = None
    if membership:
        room = db.query(DuoRoom).get(membership.room_id)
        duo = {
            "room_id": room.id,
            "invite_code": room.invite_code,
            "role": membership.role.value,
        }
    db.close()
    return {
        "name": user.name,
        "email": user.email,
        "duo": duo,
    }
