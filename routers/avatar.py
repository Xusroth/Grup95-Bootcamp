from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Annotated
from database import SessionLocal
from models import User
from schemas import AvatarUpdate, UserPublicResponse
from routers.auth import get_current_user
from starlette import status
import logging

# Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Router tanımlaması
router = APIRouter(prefix='/avatar', tags=['Avatar'])

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]


@router.put('/update', response_model=UserPublicResponse)
async def update_user_avatar(
    db: db_dependency, 
    avatar_update: AvatarUpdate, 
    current_user: User = Depends(get_current_user)
):
    """
    Kullanıcının profil avatar'ını günceller
    
    Args:
        avatar_update: Yeni avatar dosya adı
        current_user: Giriş yapmış kullanıcı
        
    Returns:
        UserPublicResponse: Güncellenmiş kullanıcı bilgileri
        
    Raises:
        HTTPException: Misafir kullanıcı veya geçersiz dosya formatı durumunda
    """
    # Misafir kullanıcı kontrolü
    if current_user.role == 'guest':
        logger.warning(f"Misafir kullanıcı {current_user.id} avatar güncellemeye çalıştı")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Misafir kullanıcılar avatar güncelleyemez."
        )
    
    # Avatar dosya formatı kontrolü
    allowed_extensions = ('.png', '.jpg', '.jpeg')
    if not avatar_update.avatar.lower().endswith(allowed_extensions):
        logger.warning(f"Kullanıcı {current_user.id} geçersiz dosya formatı: {avatar_update.avatar}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Desteklenmeyen dosya formatı. Sadece PNG, JPG ve JPEG desteklenir."
        )
    
    try:
        # Kullanıcıyı mevcut session'da tekrar sorgula
        user = db.query(User).filter(User.id == current_user.id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kullanıcı bulunamadı."
            )
        
        # Kullanıcının avatar'ını güncelle
        old_avatar = user.avatar
        user.avatar = avatar_update.avatar
        db.commit()
        db.refresh(user)
        
        logger.info(f"Kullanıcı {user.id} avatar'ını güncelledi: {old_avatar} -> {avatar_update.avatar}")
        return user
        
    except Exception as e:
        db.rollback()
        logger.error(f"Avatar güncelleme hatası, kullanıcı {current_user.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Avatar güncellenirken bir hata oluştu: {str(e)}"
        )


@router.get('/current', response_model=dict)
async def get_user_avatar(
    db: db_dependency, 
    current_user: User = Depends(get_current_user)
):
    """
    Kullanıcının mevcut avatar'ını döndürür
    
    Returns:
        dict: Kullanıcı ID, username ve avatar bilgileri
    """
    return {
        "user_id": current_user.id,
        "username": current_user.username,
        "avatar": current_user.avatar or "profile_pic.png"  # Varsayılan avatar
    }


@router.get('/available', response_model=dict)
async def get_available_avatars():
    """
    Kullanılabilir avatar listesini döndürür
    
    Returns:
        dict: Mevcut avatar dosyaları listesi ve toplam sayısı
    """
    # Mevcut avatar dosyalarını listele (frontend/assets/avatars/ klasöründekiler)
    available_avatars = [
        "profile_pic.png",  # Varsayılan avatar
        "avatar_boom.png",
        "avatar_cat.png",
        "avatar_cleaner.png",
        "avatar_coder.png",
        "avatar_cool.png",
        "avatar_cowbot.png",
        "avatar_fairy.png",
        "avatar_frog.png",
        "avatar_alien.png",
        "avatar_astrout.png",
        "avatar_robot.png",
        "avatar_robot_2.png",
        "avatar_rock.png",
        "avatar_sleepy.png",
        "avatar_supergirl.png",
        "avatar_turtle.png",
        "avatar_vampire.png",
        "avatar_wizard.png"
    ]
    
    logger.info(f"Avatar listesi istendi, {len(available_avatars)} avatar mevcut")
    return {
        "available_avatars": available_avatars,
        "total_count": len(available_avatars),
        "default_avatar": "profile_pic.png"
    }


@router.put('/admin/users/{user_id}', response_model=UserPublicResponse)
async def admin_update_user_avatar(
    db: db_dependency, 
    user_id: int, 
    avatar_update: AvatarUpdate, 
    current_user: User = Depends(get_current_user)
):
    """
    Admin yetkisiyle herhangi bir kullanıcının avatar'ını günceller
    
    Args:
        user_id: Hedef kullanıcının ID'si
        avatar_update: Yeni avatar dosya adı
        current_user: Admin kullanıcı
        
    Returns:
        UserPublicResponse: Güncellenmiş kullanıcı bilgileri
        
    Raises:
        HTTPException: Admin yetkisi yoksa veya kullanıcı bulunamassa
    """
    # Admin yetkisi kontrolü
    if current_user.role != 'admin':
        logger.warning(f"Yetkisiz kullanıcı {current_user.id} admin avatar güncellemeye çalıştı")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Sadece adminler bu işlemi yapabilir."
        )
    
    # Hedef kullanıcıyı bul
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        logger.warning(f"Admin {current_user.id} bulunamayan kullanıcı {user_id} için avatar güncellemeye çalıştı")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Kullanıcı bulunamadı."
        )
    
    # Avatar formatı kontrolü
    allowed_extensions = ('.png', '.jpg', '.jpeg')
    if not avatar_update.avatar.lower().endswith(allowed_extensions):
        logger.warning(f"Admin {current_user.id} geçersiz dosya formatı: {avatar_update.avatar}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Desteklenmeyen dosya formatı. Sadece PNG, JPG ve JPEG desteklenir."
        )
    
    try:
        # Avatar'ı güncelle
        old_avatar = target_user.avatar
        target_user.avatar = avatar_update.avatar
        db.commit()
        db.refresh(target_user)
        
        logger.info(f"Admin {current_user.id}, kullanıcı {user_id} avatar'ını güncelledi: {old_avatar} -> {avatar_update.avatar}")
        return target_user
        
    except Exception as e:
        db.rollback()
        logger.error(f"Admin avatar güncelleme hatası, admin {current_user.id}, hedef {user_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Avatar güncellenirken bir hata oluştu: {str(e)}"
        )


@router.get('/admin/users/{user_id}', response_model=dict)
async def admin_get_user_avatar(
    db: db_dependency, 
    user_id: int, 
    current_user: User = Depends(get_current_user)
):
    """
    Admin yetkisiyle herhangi bir kullanıcının avatar'ını görüntüler
    
    Args:
        user_id: Hedef kullanıcının ID'si
        current_user: Admin kullanıcı
        
    Returns:
        dict: Kullanıcı avatar bilgileri
    """
    # Admin yetkisi kontrolü
    if current_user.role != 'admin':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Sadece adminler bu işlemi yapabilir."
        )
    
    # Hedef kullanıcıyı bul
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Kullanıcı bulunamadı."
        )
    
    return {
        "user_id": target_user.id,
        "username": target_user.username,
        "avatar": target_user.avatar or "profile_pic.png"
    }
