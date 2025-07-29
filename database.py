

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from utils.config import DATABASE_URL

# uygulamayı oluşturmaya başlarken önce sqlite kullanıldı ve çok fazla zaman serileri ve multi task hatasıyla karşılaşıldı. Bu sebeplerden ve backend'i canlıya alıp test yapılacağı için Postresql'e geçiş yapıldı.


engine = create_engine(
    DATABASE_URL,
    pool_size=10, # max bağlantı sayısı
    max_overflow=20, # extra bağlantı sayısı
    pool_timeout=60, # zaman aşımı bekleme süresi
    pool_recycle=1800, # 30 dakikada yeniler
    pool_pre_ping=True # bağlantının geçerli olup olmadığını kontrol eder
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()