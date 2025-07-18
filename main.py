

from fastapi import FastAPI, HTTPException, Request, Depends, Path, APIRouter
from fastapi.middleware.cors import CORSMiddleware # CORSMiddleware -> ara katman yazılımı. frontend backend'e request attığında hata olmasın diye kullanılır. (flutter + python olduğu için)
from pydantic import BaseModel, Field
from starlette import status
from sqlalchemy.orm import Session
import bcrypt
from database import SessionLocal, engine
from models import User, Lesson
from schemas import UserRegister, UserLogin
from models import Base
from typing import Annotated
from routers.auth import router as auth_router # routers package'ında oluşturduğum auth.py dosyasının içindeki router'ı auth_router olarak import ettim
from routers.lesson import router as lesson_router # routers package'ında oluşturduğum auth.py dosyasının içindeki lesson'ı lesson_router olarak import ettim
from routers.error import router as error_router # routers package'ında oluşturduğum error.py dosyasının içindeki error'ı error_router olarak import ettim



Base.metadata.create_all(bind=engine) # bu kısım sqlalchemy'de tanımlanan veritabanı modellerine karşılık gelen tabloları gerçek veritabanında otomatik oluşturur


app = FastAPI()
app.include_router(auth_router) # auth_router'ı main'e ekledim.
app.include_router(lesson_router) # lesson_router'ı main'e ekledim.
app.include_router(error_router) # error_router'ı maine'e ekledim.


app.add_middleware( # mobil uygulamanın (flutter) backende erişebilmesi için ayar yaptım.
    CORSMiddleware,
    allow_origins=["*"], # tüm domainlerden gelen isteklere izin verilecek
    allow_credentials=True, # çerez ve kimlik bilgilerinin gönderilip gönderilmeyeceği belirleme (True -> gönderilecek)
    allow_methods=["*"], # bütün http metodlarına izin verilecek
    allow_headers=["*"] # tüm headerlara izin verilecek
)


def get_db(): # database için dependency oluşturdum.
    db = SessionLocal()
    try:
        yield db # yield ifadesi try except için return görevi görür
    finally:
        db.close()


db_dependency = Annotated[Session, Depends(get_db)] # burada daha da kısaltarak Dependency Injection Annotated yaptım





@app.on_event("startup") # uygulama çalıştığında otomatik belirlenen isimlerden admin kullanıcısı yoksa admin kullanıcısı oluşacak     # email -> admin@gmail.com    # password -> Admin123!
async def startup_event():
    db = SessionLocal()
    try:
        # Mevcut admin kullanıcısını kontrol et
        existing_user = db.query(User).filter((User.email == "admin@gmail.com") | (User.username == "admin")).first()
        if not existing_user:
            hashed_password = bcrypt.hashpw("Admin123!".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            admin_user = User(
                username="admin",
                email="admin@gmail.com",
                hashed_password=hashed_password,
                role="admin"
            )
            db.add(admin_user)
            db.commit()
            print("Admin kullanıcısı oluşturuldu: admin@gmail.com")
        else:
            print("Admin kullanıcısı zaten mevcut.")
    except Exception as e:
        print(f"Admin oluşturma hatası: {e}")
        db.rollback()
    finally:
        db.close()





@app.get('/') # welcome fonksiyonu gibi düşün
async def root(request: Request): # request kullanmamın sebebi uygulamaya giren cihazdan gelen bilgileri görebilmek
    return {"message": "Codebite'a hoşgeldin!"}


@app.get('/get_all_user') # veritabanındaki tüm User verisini görmek
async def get_all_user(db:db_dependency):
    return db.query(User).all()


@app.get('/get_all_lesson') # veritabanındaki tüm Lesson verisini görmek
async def get_all_lesson(db: db_dependency):
    return db.query(Lesson).all()


@app.get('/get_by_id/{user_id}') # kullanıcıları id'sine göre getirmek
async def get_by_id(db: db_dependency, user_id: int = Path(gt=0)):
    user = db.query(User).filter(User.id == user_id).first() # first() yazmayı unutma yoksa sonsuz istek atıyor server çöküyor!
    if user is not None:
        return user
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User bulunamadı..!")