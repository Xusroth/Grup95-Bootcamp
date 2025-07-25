

from fastapi import APIRouter, HTTPException, Depends
from typing import Annotated
from pydantic import BaseModel
from database import SessionLocal
from starlette import status
from sqlalchemy.orm import Session
from models import User, PasswordResetToken, DailyTask, Progress as ProgressModels, Streak as StreakModels, UserQuestion, ErrorReport
from schemas import UserRegister, UserLogin, UserResponse, UserPublicResponse, UserUpdate, PasswordResetRequest, PasswordReset
import bcrypt
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm # authorize kısmının düzelmesi için deniyorum..!
from jose import jwt, JWTError
from datetime import datetime, timedelta, timezone
from utils.email import send_reset_email
from utils.config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES
import random



router = APIRouter(prefix='/auth', tags=['Authentication']) # bu routerları oluşturup sonra hepsini main dosyasındaki app'e bağlıcaz

oauth2 = OAuth2PasswordBearer(tokenUrl='auth/login')



def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]



# JWT token kısmı
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({'exp': expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM) # hepsinin birleştiği kısım
    return encoded_jwt


async def get_current_user(token: Annotated[str, Depends(oauth2)], db: db_dependency): # email'e göre düzenledim
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail='Geçersiz token',
        headers={'WWW-Authenticate': 'Bearer'})
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=ALGORITHM)
        email: str = payload.get('sub')
        if email is None:
            raise credentials_exception
        user = db.query(User).filter(User.email == email).first()
        if user is None:
            raise credentials_exception
        return user
    except JWTError:
        raise credentials_exception


class Token(BaseModel):
    access_token: str
    token_type: str



def create_admin(): # admin oluşturmak için fonksiyon. email -> admin@gmail.com  password -> Admin123!
    db = SessionLocal()
    try:
        hashed_password = bcrypt.hashpw('Admin123!'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        admin_user = User(username='admin', email='admin@gmail.com', hashed_password=hashed_password, role='admin', level=None) # admin her seviyeden soru generate edebilsin diye -> None

        db.add(admin_user)
        db.commit()
    finally:
        db.close()

    if __name__ == "__main__":
        create_admin()





@router.post('/register', status_code=status.HTTP_201_CREATED, response_model=UserPublicResponse) # kullanıcı kayıt
async def register(db: db_dependency, user: UserRegister):
    mevcut_user = db.query(User).filter((User.email == user.email) | (User.username == user.username)).first()
    if mevcut_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu kullanıcı adı veya email zaten kayıtlı.")

    # şifreyi hashliyorum
    hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8') # bcrypt.gensalt() -> şifre hashlemeye özel salt üretir. bu salt aynı şifrelerin her seferinde farklı hashlenmesini sağlar.      # encode('utf-8') -> bcrypt byte formatında çalıştığı için şifreyi byte formatına çeviriyor.

    # yeni kullanıcı oluşturma
    db_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        role='user',   # role kısmını user olarak sabitledim
        level='beginner',  # kullanıcıların leveli default olarak beginner belirledim
        has_taken_level_test=False, # en başta kullanıcılar seviye testine girmediği için False yaptım. sınava girmesine göre boolean değiştirecek
        health_count=6,
        health_count_update_time=datetime.now(timezone.utc)
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@router.post('/login', response_model=Token) # kullanıcı login kısmı (token ekledim güncelledim)
async def login(db: db_dependency, form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    db_user = db.query(User).filter(User.email == form_data.username).first() # user.email kısmı değişti..!
    if not db_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Kullanıcı bulunamadı.")

    if not bcrypt.checkpw(form_data.password.encode('utf-8'), db_user.hashed_password.encode('utf-8')):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Şifre yanlış.")

    access_token = create_access_token(data={'sub': str(db_user.email)}) #  auth/me kısmı ile uyumlu olması için email ile güncelledim
    return {"access_token": access_token, "token_type": "bearer"}


@router.post('/guest', response_model=Token, tags=['Authentication'])
async def guest_login(db: db_dependency):
    guest_username = f'guest_{random.randint(1000, 9999)}'
    guest_email = f'guest_{random.randint(1000, 9999)}@codebite.com'

    existing_user = db.query(User).filter((User.username == guest_username) | (User.email == guest_email)).first()
    if existing_user:
        guest_username = f'guest_{random.randint(1000, 9999)}'
        guest_email = f'guest_{random.randint(1000, 9999)}@codebite.com'

    guest_user = User(
        username=guest_username,
        email=guest_email,
        hashed_password=None,
        role='guest',
        level='beginner',
        has_taken_level_test=False
    )

    db.add(guest_user)
    db.commit()
    db.refresh(guest_user)

    access_token = create_access_token(
        data={'sub': guest_user.email},
        expires_delta=timedelta(hours=1)
    )
    return {'access_token': access_token, 'token_type': 'bearer', 'username' : guest_username}


@router.put('/users/{user_id}', response_model=UserPublicResponse)
async def update_user(db: db_dependency, user_id: int, user_update: UserUpdate, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar profil güncelleyemez.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
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

    if user_update.level:
        user.level = user_update.level

    db.commit()
    db.refresh(user)
    return user


@router.get('/me', response_model=UserPublicResponse) # login olan kullanıcının bilgilerini görebilmesi için
async def get_current_user_info(db: db_dependency, token: str = Depends(oauth2)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get('sub')
        if email is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Geçersiz token.")
        user = db.query(User).filter(User.email == email).first()
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User bulunamadı.")
        return user
    except JWTError as err:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authenticated: {str(err)}")



@router.post('/make_admin/{user_id}', status_code=status.HTTP_200_OK)
async def make_admin(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler bu işlemi yapabilir.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Misafir kullanıcılar admin olamaz.")

    user.role = 'admin'
    user.level = None
    db.commit()
    return {"message": f"{user.username} kullanıcısına admin yetkisi verildi."}


@router.get('/admin/users')
async def list_users(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler kullanıcıları listeleyebilir.")

    user = db.query(User).all()
    return [{"user_id": i.id, "username": i.username, "email": i.email, "role": i.role, "level": i.level, "has_taken_level_test": i.has_taken_level_test, 'health_count': i.health_count, 'health_count_update_time': i.health_count_update_time} for i in user]


@router.delete('/admin/users/{user_id}', status_code=status.HTTP_200_OK, response_model=dict)
async def delete_user(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler kullanıcı silebilir.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Kendi hesabınızı silemezsiniz.")

    db.query(DailyTask).filter(DailyTask.user_id == user_id).delete()
    db.query(ProgressModels).filter(ProgressModels.user_id == user_id).delete()
    db.query(StreakModels).filter(StreakModels.user_id == user_id).delete()
    db.query(UserQuestion).filter(UserQuestion.user_id == user_id).delete()
    db.query(ErrorReport).filter(ErrorReport.user_id == user_id).delete()

    db.delete(user)
    db.commit()
    return {"message": f"{user.username} adlı kullanıcı silindi."}


@router.post('/password_reset_request')
async def request_password_reset(db: db_dependency, request: PasswordResetRequest):
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bu e-posta adresine kayıtlı kullanıcı bulunamadı.")

    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Misafir kullanıcılar şifre sıfırlayamaz.")

    token = create_access_token(data={'sub': user.email, 'purpose': 'password_reset'}, expires_delta=timedelta(hours=1)) # token create kısmı

    reset_token = PasswordResetToken(user_id=user.id, token=token, expires_time=datetime.now(timezone.utc) + timedelta(hours=1)) # token sıfırlama ve db'ye kaydetme kısmı

    db.add(reset_token)
    db.commit()

    send_reset_email(user.email, token) # e posta gönderme kısmı
    return {'message': "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi."}


@router.post('/password_reset')
async def reset_password(db: db_dependency, reset: PasswordReset):
    try:
        payload = jwt.decode(reset.token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get('purpose') != 'password_reset':
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token amacı geçersiz.")

        email = payload.get('sub')
        if not email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz token.")

    except JWTError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz veya süresi dolmuş token.")

    reset_token = db.query(PasswordResetToken).filter(PasswordResetToken.token == reset.token).first()
    if not reset_token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz veya süresi dolmuş token.")

    expires_time = reset_token.expires_time # burada token süresi kontrolü için normalize ettim öyle kontrol ettim ancak böyle db'ye kaydını adam akıllı yapabildim
    if expires_time.tzinfo is None: # !!!!!!! zor bela sqlite timezone bilgisini saklıyor !!!!!!
        expires_time = expires_time.replace(tzinfo=timezone.utc)
    if expires_time < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz veya süresi dolmuş token.")

    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    user.hashed_password = bcrypt.hashpw(reset.new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8') # şifrenin güncellenmesi

    db.delete(reset_token)
    db.commit()
    return {'message': "Şifreniz başarıyla güncellendi."}


@router.delete('/admin/cleanup_guests', status_code=status.HTTP_200_OK) # misafir kullanıcı 7 gün boyunca inaktif olursa db'den otomatik olarak hesabı silinir
async def cleanup_guests(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler bu işlemi yapabilir.")

    cutoff_time = datetime.now(timezone.utc) - timedelta(days=7)
    deleted_count = db.query(User).filter(
        User.role == 'guest',
        User.health_count_update_time < cutoff_time
    ).delete()
    db.commit()
    return {"message": f"{deleted_count} inaktif misafir hesabı silindi."}


@router.get('/health_count')
async def get_health_count(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar can bilgisi göremez.")
    if current_user.health_count <= 0 and (datetime.now(timezone.utc) - current_user.health_count_update_time) >= timedelta(hours=2):
        current_user.health_count = 6
        current_user.health_count_update_time = datetime.now(timezone.utc)
        db.commit()
    return {
        'health_count': current_user.health_count,
        'health_count_update_time': current_user.health_count_update_time
    }


@router.put('/admin/users/{user_id}/health_count', response_model=dict)
async def admin_restore_health_count(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler kullanıcıların can sayısını yenileyebilir.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    user.health_count = 6
    user.health_count_update_time = datetime.now(timezone.utc)

    db.commit()
    db.refresh(user)

    return {'user_id': user.id, 'health_count': user.health_count, 'health_count_update_time': user.health_count_update_time}