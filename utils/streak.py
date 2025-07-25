

from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session
from models import Streak as StreakModels, User, Lesson as LessonModels
from apscheduler.schedulers.asyncio import AsyncIOScheduler
import logging



logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def update_user_streak(db: Session, user_id: int, lesson_id: int): # userın seçtiği ders için streak durumunu kontrol eder
    try:
        user = db.query(User).filter(User.id == user_id).first()
        lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
        if not user or not lesson:
            logger.error(f"Kullanıcı ID {user_id} veya ders ID {lesson_id} bulunamadı.")
            return

        if lesson not in user.lessons:
            logger.error(f"Kullanıcı {user_id} için ders {lesson_id} seçilmemiş.")
            return

        streak = db.query(StreakModels).filter(StreakModels.user_id == user_id, StreakModels.lesson_id == lesson_id).first()
        today = datetime.now(timezone.utc).date()
        yesterday = today - timedelta(days=1)

        if not streak:
            streak = StreakModels(
                user_id=user_id,
                lesson_id=lesson_id,
                streak_count=1,
                last_update=datetime.now(timezone.utc)
            )
            db.add(streak)
            logger.debug(f"Kullanıcı {user_id} için yeni streak oluşturuldu: ders {lesson_id}, streak_count=1")

        else:
            last_update_date = streak.last_update.date()

            if last_update_date == today:
                logger.debug(f"Kullanıcı {user_id} için bugün streak zaten güncellenmiş: {streak.streak_count}")
                return

            elif last_update_date == yesterday:
                streak.streak_count += 1
                streak.last_update = datetime.now(timezone.utc)
                logger.debug(f"Kullanıcı {user_id} için streak artırıldı: {streak.streak_count}")

            else:
                streak.streak_count = 1
                streak.last_update = datetime.now(timezone.utc)
                logger.debug(f"Kullanıcı {user_id} için streak sıfırlandı: {streak.streak_count}")

        db.commit()
        db.refresh(streak)

    except Exception as err:
        db.rollback()
        logger.error(f"Streak güncelleme hatası, kullanıcı ID {user_id}, ders ID {lesson_id}: {str(err)}")


def update_all_users_streaks(): # tüm userların streak durumunu kontrol eder
    db = SessionLocal()
    try:
        streaks = db.query(StreakModels).join(User).filter(User.role != 'guest').all()
        today = datetime.now(timezone.utc).date()
        yesterday = today - timedelta(days=1)

        for streak in streaks:
            last_update_date = streak.last_update.date()
            if last_update_date < yesterday:
                streak.streak_count = 0  # Streak sıfırlanır
                streak.last_update = datetime.now(timezone.utc)
                logger.debug(f"Kullanıcı {streak.user_id} için streak sıfırlandı: ders {streak.lesson_id}")
        db.commit()

    except Exception as e:
        db.rollback()
        logger.error(f"Streak toplu güncelleme hatası: {str(e)}")
    finally:
        db.close()


def start_streak_scheduler(): # main.py kısmına yazılacak !!!
    scheduler = AsyncIOScheduler()
    scheduler.add_job(update_all_users_streaks, 'interval', days=1)
    scheduler.start()
    logger.info("Streak sıfırlama zamanlayıcısı başlatıldı.")