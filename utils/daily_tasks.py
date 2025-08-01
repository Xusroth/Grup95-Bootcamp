

from datetime import datetime, timezone
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from database import SessionLocal
from models import User, DailyTask
import logging


logger = logging.getLogger(__name__)


def cleanup_expired_tasks_scheduler(): # süresi dolan görevleri temizler
    db = SessionLocal()
    try:
        current_time = datetime.now(timezone.utc)

        expired_tasks = db.query(DailyTask).filter(DailyTask.expires_time <= current_time).all()

        if expired_tasks:
            for task in expired_tasks:
                db.delete(task)

            db.commit()
            logger.info(f"Scheduler: {len(expired_tasks)} süresi dolmuş görev temizlendi.")

        else:
            logger.debug("Scheduler: Temizlenecek süresi dolmuş görev bulunamadı.")

        return len(expired_tasks)

    except Exception as err:
        db.rollback()
        logger.error(f"Scheduler görev temizleme hatası: {str(err)}")
        return 0

    finally:
        db.close()


def generate_daily_tasks_scheduler(): # tüm kullanıcılar için günlük görev oluşturur
    from routers.tasks import generate_daily_tasks_for_user # importlar çakıştığı için böyle yaptım

    db = SessionLocal()

    try:
        cleanup_expired_tasks_scheduler()

        users = db.query(User).filter(User.role != 'guest').all()
        total_created = 0
        today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

        for user in users:
            try:
                tasks = generate_daily_tasks_for_user(db, user)
                new_tasks_count = len([t for t in tasks if t.create_time >= today_start])
                total_created += new_tasks_count
                logger.debug(f"Scheduler: Kullanıcı {user.id} ({user.username}) için görevler kontrol edildi.")

            except Exception as err:
                logger.error(f"Scheduler: Kullanıcı {user.id} için görev oluşturma hatası: {str(err)}")
                continue

        logger.info(f"Scheduler: {len(users)} kullanıcı için görevler kontrol edildi. Toplam {total_created} yeni görev oluşturuldu.")
        return total_created

    except Exception as err:
        logger.error(f"Scheduler günlük görev oluşturma hatası: {str(err)}")
        return 0

    finally:
        db.close()


def start_daily_tasks_scheduler(): # her gün 23.59'da görevleri otomatik olarak temizler ve yeniden oluşturur
    scheduler = AsyncIOScheduler()

    try:
        scheduler.add_job(
            func=cleanup_expired_tasks_scheduler,
            trigger=CronTrigger(hour=23, minute=59, second=0),
            id='cleanup_expired_tasks',
            name='Süresi Dolmuş Görevleri Temizle',
            replace_existing=True
        )

        scheduler.add_job(
            func=generate_daily_tasks_scheduler,
            trigger=CronTrigger(hour=0, minute=1, second=0),  # 00.01 geçe çalış
            id='generate_daily_tasks',
            name='Günlük Görevler Oluştur',
            replace_existing=True
        )

        scheduler.add_job( # db'nin şişmemesi için her 6 saatte bir süresi dolmuş görevler temizlenir
            func=cleanup_expired_tasks_scheduler,
            trigger=CronTrigger(hour='*/6', minute=30),
            id='cleanup_expired_tasks_periodic',
            name='Periyodik Görev Temizleme',
            replace_existing=True
        )

        scheduler.start()
        logger.info("Günlük görev scheduler'ı başarıyla başlatıldı.")
        logger.info("- Görev temizleme: Her gün 00:00:30 ve her 6 saatte bir")
        logger.info("- Görev oluşturma: Her gün 00:01:00")

        return scheduler

    except Exception as err:
        logger.error(f"Günlük görev scheduler başlatma hatası: {str(err)}")
        return None


def stop_daily_tasks_scheduler(scheduler): # daily task schedularını durdurur
    if scheduler:
        try:
            scheduler.shutdown()
            logger.info("Günlük görev scheduler'ı durduruldu.")

        except Exception as err:
            logger.error(f"Günlük görev scheduler durdurma hatası: {str(err)}")