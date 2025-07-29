

from fastapi import FastAPI, HTTPException, Request, Depends, Path, APIRouter
from fastapi.middleware.cors import CORSMiddleware # CORSMiddleware -> ara katman yazılımı. frontend backend'e request attığında hata olmasın diye kullandık. (flutter + python)
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
import logging



logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)



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


app.add_middleware( # mobil uygulamanın (flutter) backende erişebilmesi için ayar yapıldı.
    CORSMiddleware,
    allow_origins=["*"], # tüm domainlerden gelen isteklere izin ver
    allow_credentials=True, # çerez ve kimlik bilgilerinin gönderilip gönderilmeyeceği belirler
    allow_methods=["*"], # bütün http metodlarına izin ver
    allow_headers=["*"] # tüm headerlara izin ver
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


db_dependency = Annotated[Session, Depends(get_db)]


health_scheduler = None # health_count zamanlayıcısı
streak_scheduler = None # streak zamanlayıcısı


@app.on_event("startup")
async def startup_event():
    global health_scheduler, streak_scheduler
    logger.info("Uygulama başlatılıyor...")
    create_admin() # uygulama çalıştığında otomatik olarak admin kullanıcısı yoksa admin kullanıcısı oluşacak     # email -> admin@gmail.com    # password -> Admin123!
    health_scheduler = start_health_scheduler()
    streak_scheduler = start_streak_scheduler()
    logger.info("Zamanlayıcılar başlatıldı.")


@app.on_event("shutdown")
async def shutdown_event():
    global health_scheduler, streak_scheduler
    logger.info("Uygulama kapatılıyor..!")
    if health_scheduler:
        health_scheduler.shutdown()
        logger.info("Can hakkı yenileme zamanlayıcısı durduruldu.")
    if streak_scheduler:
        streak_scheduler.shutdown()
        logger.info("Streak yenileme zamanlayıcısı durduruldu.")


@app.get('/')
async def root():
    return {'message': "Codebite'a hoşgeldin!", 'docs': "/docs"}