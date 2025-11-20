from fastapi import FastAPI, HTTPException, Query, Depends, status
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from datetime import timedelta

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
from .auth import (
    get_current_user,
    get_password_hash,
    verify_password,
    create_access_token,
    get_db,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)
import secrets

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="FinDuo Backend",
    version="0.1.0",
)


@app.get("/health")
def health():
    return {"status": "ok"}


# ==================== AUTENTICACIÓN ====================

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: dict


@app.post("/auth/register", response_model=TokenResponse)
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    """Registra un nuevo usuario"""
    # Verificar si el usuario ya existe
    existing_user = db.query(User).filter(User.email == request.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo electrónico ya está registrado"
        )
    
    # Crear nuevo usuario
    hashed_password = get_password_hash(request.password)
    user = User(
        email=request.email,
        name=request.name,
        password_hash=hashed_password
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Crear token de acceso
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name
        }
    }


@app.post("/auth/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Inicia sesión con email y contraseña"""
    # Buscar usuario
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )
    
    # Verificar contraseña
    if not user.password_hash or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )
    
    # Crear token de acceso
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name
        }
    }


@app.get("/auth/me")
def get_me(current_user: User = Depends(get_current_user)):
    """Obtiene la información del usuario actual"""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "name": current_user.name
    }


@app.post("/sync-email")
def sync_email(current_user: User = Depends(get_current_user)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Iniciando sincronización de correo para: {current_user.email}")
    try:
        count = sync_emails_to_db(current_user.email)
        logger.info(f"Sincronización completada: {count} correos importados")
        return {"imported": count}
    except Exception as e:
        logger.error(f"Error en sincronización: {e}", exc_info=True)
        return {"imported": 0, "error": str(e)}


@app.get("/transactions")
def list_transactions(
    mode: str = Query("individual"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if mode == "duo":
        membership = (
            db.query(DuoMembership)
            .filter(
                DuoMembership.user_id == current_user.id,
                DuoMembership.status == DuoStatus.active,
            )
            .first()
        )
        if not membership:
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
            .filter(Transaction.user_id == current_user.id)
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
    return result


@app.put("/transactions/{transaction_id}")
def update_transaction(
    transaction_id: int,
    tx: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Buscar la transacción
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not transaction:
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
    
    return result


@app.delete("/transactions/{transaction_id}")
def delete_transaction(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Buscar la transacción
        transaction = db.query(Transaction).filter(
            Transaction.id == transaction_id,
            Transaction.user_id == current_user.id
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


class JoinRequest(BaseModel):
    invite_code: str


@app.post("/duo/invite")
def create_duo_invite(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    membership = (
        db.query(DuoMembership).filter(DuoMembership.user_id == current_user.id).first()
    )
    if membership:
        room = db.query(DuoRoom).filter(DuoRoom.id == membership.room_id).first()
        return {"invite_code": room.invite_code}

    code = secrets.token_urlsafe(8)
    room = DuoRoom(invite_code=code)
    db.add(room)
    db.commit()
    db.refresh(room)

    owner = DuoMembership(
        user_id=current_user.id,
        room_id=room.id,
        role=DuoRole.owner,
        status=DuoStatus.active,
    )
    db.add(owner)
    db.commit()
    return {"invite_code": code}


@app.post("/duo/join")
def join_duo(
    req: JoinRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    room = db.query(DuoRoom).filter(DuoRoom.invite_code == req.invite_code).first()
    if not room:
        raise HTTPException(status_code=404, detail="Código no válido")

    count_members = (
        db.query(DuoMembership).filter(DuoMembership.room_id == room.id).count()
    )
    if count_members >= 2:
        raise HTTPException(status_code=400, detail="Este FinDuo ya está completo")

    membership = DuoMembership(
        user_id=current_user.id,
        room_id=room.id,
        role=DuoRole.partner,
        status=DuoStatus.active,
    )
    db.add(membership)
    db.commit()
    return {"status": "joined"}


@app.get("/me")
def me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    membership = (
        db.query(DuoMembership)
        .filter(DuoMembership.user_id == current_user.id, DuoMembership.status == DuoStatus.active)
        .first()
    )
    duo = None
    if membership:
        room = db.query(DuoRoom).filter(DuoRoom.id == membership.room_id).first()
        duo = {
            "room_id": room.id,
            "invite_code": room.invite_code,
            "role": membership.role.value,
        }
    return {
        "name": current_user.name,
        "email": current_user.email,
        "duo": duo,
    }
