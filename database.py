

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

DATABASE_URL = "sqlite:///./codebite.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
    pool_size=10, # max bağlantı sayısı
    max_overflow=20, # extra bağlantı sayısı
    pool_timeout=60, # zaman aşımı bekleme süresi
    pool_recycle=1800, # 30 dakikada yeniler
    pool_pre_ping=True # bağlantının geçerli olup olmadığını kontrol eder
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base() # tüm veritabanındaki modellerin türeyeceği temel sınıf