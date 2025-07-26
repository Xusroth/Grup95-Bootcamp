

from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from models import User
from database import SessionLocal
import logging


logger = logging.getLogger(__name__)



def update_user_health_count(db: Session, user_id: int):
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            logger.error(f"Kullanıcı ID {user_id} bulunamadı.")
            return

        if user.role == 'guest':
            logger.debug(f"Kullanıcı {user_id} misafir, can hakkı güncellenmedi.")
            return

        current_time = datetime.now(timezone.utc)
        if user.health_count_update_time:

            if user.health_count_update_time.tzinfo is None:
                user.health_count_update_time = user.health_count_update_time.replace(tzinfo=timezone.utc)
            time_diff = (current_time - user.health_count_update_time).total_seconds() / 3600
            if time_diff >= 2:
                user.health_count = min(user.health_count + 2, 6)
                user.health_count_update_time = current_time
                logger.debug(f"Kullanıcı {user_id} için can hakkı güncellendi: {user.health_count}")
            else:
                logger.debug(f"Kullanıcı {user_id} için can hakkı zaten güncel: {user.health_count}")
        else:
            user.health_count = min(user.health_count + 1, 6)
            user.health_count_update_time = current_time
            logger.debug(f"Kullanıcı {user_id} için ilk can hakkı güncellendi: {user.health_count}")

        db.commit()
        db.refresh(user)

    except Exception as err:
        db.rollback()
        logger.error(f"Can hakkı güncelleme hatası, kullanıcı ID {user_id}: {str(err)}")


def update_all_users_health():
    db = SessionLocal()
    try:
        users = db.query(User).filter(User.role != 'guest').all()
        current_time = datetime.now(timezone.utc)

        for user in users:
            last_update = user.health_count_update_time
            if last_update is None:
                user.health_count = min(user.health_count + 1, 6)
                user.health_count_update_time = current_time
                logger.debug(f"Kullanıcı {user.id} için ilk can hakkı güncellendi: {user.health_count}")

            else:
                if last_update.tzinfo is None:
                    last_update = last_update.replace(tzinfo=timezone.utc)
                time_diff = (current_time - last_update).total_seconds() / 3600

                if time_diff >= 1:
                    user.health_count = min(user.health_count + 1, 6)
                    user.health_count_update_time = current_time
                    logger.debug(f"Kullanıcı {user.id} için can hakkı güncellendi: {user.health_count}")

        db.commit()
        logger.info("Tüm kullanıcıların can hakları güncellendi.")

    except Exception as err:
        db.rollback()
        logger.error(f"Can hakkı toplu güncelleme hatası: {str(err)}")
        raise

    finally:
        db.close()


def start_health_scheduler():
    scheduler = AsyncIOScheduler()
    scheduler.add_job(update_all_users_health, 'interval', hours=1)
    scheduler.start()
    logger.info("Can hakkı yenileme zamanlayıcısı başlatıldı.")