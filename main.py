

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
from routers.auth import router as auth_router, create_admin
from routers.lesson import router as lesson_router
from routers.error import router as error_router
from routers.tasks import router as tasks_router
from routers.progress import router as progress_router
from routers.sections import router as sections_router
from routers.settings import router as settings_router
from routers.avatar import router as avatar_router
from utils.streak import start_streak_scheduler
from utils.health import start_health_scheduler
from apscheduler.schedulers.asyncio import AsyncIOScheduler



Base.metadata.create_all(bind=engine) # bu kısım sqlalchemy'de tanımlanan veritabanı modellerine karşılık gelen tabloları gerçek veritabanında otomatik oluşturur


app = FastAPI()
app.include_router(auth_router)
app.include_router(lesson_router)
app.include_router(error_router)
app.include_router(tasks_router)
app.include_router(progress_router)
app.include_router(sections_router)
app.include_router(settings_router)
app.include_router(avatar_router)


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





@app.on_event("startup")
async def startup_event():
    create_admin()  # # uygulama çalıştığında otomatik belirlenen isimlerden admin kullanıcısı yoksa admin kullanıcısı oluşacak     # email -> admin@gmail.com    # password -> Admin123!
    start_streak_scheduler()
    start_health_scheduler()


@app.get('/')
async def root():
    return {'message': "Codebite'a hoşgeldin!", 'docs': "/docs"}