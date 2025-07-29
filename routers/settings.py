

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Annotated
from database import SessionLocal
from models import User
from schemas import UserUpdate, UserPublicResponse, PasswordReset, PasswordResetRequest, PasswordChangeRequest
from routers.auth import get_current_user
from starlette import status
import bcrypt
from datetime import datetime, timezone
import logging


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


router = APIRouter(prefix='/settings', tags=['Settings'])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


db_dependency = Annotated[Session, Depends(get_db)]


@router.put('/profile', response_model=UserPublicResponse) # ayarlar panelinden profil güncelleme kısmı
async def update_profile(db: db_dependency, user_update: UserUpdate, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar profil güncelleyemez.")

    user = db.query(User).filter(User.id == current_user.id).first()
    if not user:
        logger.error(f"Kullanıcı ID {current_user.id} bulunamadı.")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user_update.username and user_update.username != user.username:
        existing_user = db.query(User).filter(User.username == user_update.username).first()
        if existing_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu kullanıcı adı zaten kayıtlı.")
        user.username = user_update.username

    if user_update.email and user_update.email != user.email:
        existing_user = db.query(User).filter(User.email == user_update.email).first()
        if existing_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu e-posta zaten kayıtlı.")
        user.email = user_update.email

    if user_update.notification_preferences:
        user.notification_preferences = user_update.notification_preferences.dict()

    if user_update.theme and user_update.theme not in ["light", "dark"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz tema seçimi: light veya dark olmalı.")

    if user_update.theme:
        user.theme = user_update.theme

    if user_update.language and user_update.language not in ["tr", "en"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz dil seçimi: tr veya en olmalı.")

    if user_update.language:
        user.language = user_update.language

    try:
        db.commit()
        logger.debug(f'Kullanıcı {user.id} için commit başarılı.')
        db.refresh(user)

        if not user:
            logger.error(f'Kullanıcı ID {current_user.id} refresh sonrası None döndü.')
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Kullanıcı verisi yenilenirken bir hata oluştu.")

        logger.info(f"Kullanıcı {user.id} profilini güncelledi: {user_update.dict(exclude_unset=True)}")
        return user

    except Exception as err:
        db.rollback()
        logger.error(f"Profil güncelleme hatası, kullanıcı ID {current_user.id}: {str(err)}")

        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Profil güncellenirken bir hata oluştu: {str(err)}")


@router.post('/change_password', response_model=dict) # ayarlar panelinde uygulama içinden kullanıcını şifresini değiştirebilmesi kısmı
async def change_password(db: db_dependency, request: PasswordChangeRequest, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar şifre değiştiremez.")

    user = db.query(User).filter(User.id == current_user.id).first()
    if not user or user.hashed_password is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if not bcrypt.checkpw(request.current_password.encode('utf-8'), user.hashed_password.encode('utf-8')):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Mevcut şifre yanlış.")

    user.hashed_password = bcrypt.hashpw(request.new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    try:
        db.commit()
        return {'message': "Şifre başarıyla değiştirildi."}

    except Exception as err:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Şifre değiştirilirken bir hata oluştu.")