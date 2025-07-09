

from fastapi import APIRouter, HTTPException, Depends
from typing import Annotated
from pydantic import BaseModel
from database import SessionLocal
from starlette import status
from sqlalchemy.orm import Session
from models import User
from schemas import UserRegister, UserLogin, UserResponse
import bcrypt
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm # authorize kısmının düzelmesi için deniyorum..!
from jose import jwt, JWTError
from datetime import datetime, timedelta, timezone
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES




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
def create_access_token(data: dict):
    to_encode = data.copy()
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
        admin_user = User(username='admin', email='admin@gmail.com', hashed_password=hashed_password, role='admin')

        db.add(admin_user)
        db.commit()
    finally:
        db.close()

    if __name__ == "__main__":
        create_admin()





@router.post('/register', status_code=status.HTTP_201_CREATED) # kullanıcı kayıt
async def register(db: db_dependency, user: UserRegister):
    if user.role == 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin rolü sadece adminler tarafından atanabilir.")
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
        role=user.role
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return {"message": "Kullanıcı başarıyla oluşturuldu.", "user_id": db_user.id, "username": db_user.username, "email": db_user.email, "role": db_user.role}


@router.post('/login', response_model=Token) # kullanıcı login kısmı (token ekledim güncelledim)
async def login(db: db_dependency, form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    db_user = db.query(User).filter(User.email == form_data.username).first() # user.email kısmı değişti..!
    if not db_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Kullanıcı bulunamadı.")
    if not bcrypt.checkpw(form_data.password.encode('utf-8'), db_user.hashed_password.encode('utf-8')):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Şifre yanlış.")
    access_token = create_access_token(data={'sub': str(db_user.email)}) #  auth/me kısmı ile uyumlu olması için email ile güncelledim
    return {"access_token": access_token, "token_type": "bearer"}


@router.get('/me', response_model=UserResponse) # login olan kullanıcının bilgilerini görebilmesi için
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
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler bu işlemi yapabilir.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")
    user.role = 'admin'
    db.commit()
    return {"message": f"{user.username} kullanıcısına admin yetkisi verildi."}


@router.get('/admin/users')
async def list_users(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler kullanıcıları listeleyebilir.")
    user = db.query(User).all()
    return [{"user_id": i.id, "username": i.username, "email": i.email, "role": i.role} for i in user]


@router.delete('/admin/users/{user_id}', status_code=status.HTTP_200_OK)
async def delete_user(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler kullanıcı silebilir.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")
    if user.id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Kendi hesabınızı silemezsiniz.")
    db.delete(user)
    db.commit()
    return {"message": f"{user.username} adlı kullanıcı silindi."}