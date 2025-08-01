

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from typing import Annotated, Optional
from starlette import status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, asc, or_
from database import SessionLocal
from models import User, DailyTask, Question as QuestionModels, Lesson, Section, Progress as ProgressModels, user_lessons, UserQuestion
from schemas import DailyTaskResponse, DailyTaskCreate, DailyTaskUpdate, AnswerQuestionRequest, ProgressResponse, Progress, QuestionResponse
from routers.auth import get_current_user
from utils.health import update_user_health_count, update_all_users_health
from utils.streak import update_user_streak, update_all_users_streaks
from datetime import datetime, timezone, timedelta
import random
import json
import logging



logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

router = APIRouter(prefix='/tasks', tags=['Daily Tasks'])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


db_dependency = Annotated[Session, Depends(get_db)]
user_dependency = Annotated[User, Depends(get_current_user)]

TASK_TYPES = [
    {'type': 'solve_questions', 'target': 5, 'description': 'Belirli bir derste 5 soru çöz.'},
    {'type': 'complete_section', 'target': 1, 'description': 'Bir dersin bir bölümünü tamamla.'},
    {'type': 'maintain_streak', 'target': 1, 'description': 'Bir derste streak\'i koru.'},
    {'type': 'review_mistakes', 'target': 3, 'description': 'Yanlış cevaplanmış 3 soruyu gözden geçir.'}
]


def cleanup_expired_tasks(db: Session):
    current_time = datetime.now(timezone.utc)

    expired_tasks = db.query(DailyTask).filter(DailyTask.expires_time <= current_time).all()

    if expired_tasks:

        for i in expired_tasks:
            db.delete(i)

        db.commit()
        logger.info("Süresi dolan görevler başarıyla silindi.")

    return len(expired_tasks)


def cleanup_user_expired_tasks(db: Session, user_id: int):
    current_time = datetime.now(timezone.utc)

    expired_tasks = db.query(DailyTask).filter(DailyTask.user_id == user_id, DailyTask.expires_time <= current_time).all()

    if expired_tasks:

        for i in expired_tasks:
            db.delete(i)

        db.commit()
        logger.info(f"Kullanıcı {user_id} için süresi dolan görevler silindi.")

    return len(expired_tasks)


def get_today_start():
    return datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

def get_tomorrow_start():
    return get_today_start() + timedelta(days=1)


def generate_daily_tasks_for_user(db: Session, user: User): # Kullanıcıya göre daily task oluşturma
    if user.role == 'guest':
        logger.warning(f"Misafir kullanıcı {user.id} için görev oluşturulamaz.")
        return []

    cleanup_user_expired_tasks(db, user.id)

    current_time = datetime.now(timezone.utc)
    today_start = get_today_start()
    tomorrow_start = get_tomorrow_start()

    existing_tasks = db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.create_time >= today_start,
        DailyTask.expires_time > current_time
    ).all()

    logger.debug(f"Kullanıcı {user.id} için bugün oluşturulmuş görev sayısı: {len(existing_tasks)}")

    if len(existing_tasks) >= 3:
        logger.debug(f"Kullanıcı {user.id} için bugün zaten 3 görev var.")
        return existing_tasks

    lessons = db.query(Lesson).join(user_lessons).filter(user_lessons.c.user_id == user.id).all()
    if not lessons:
        logger.warning(f"Kullanıcı {user.id} için seçili ders bulunamadı.")
        return existing_tasks

    tasks_to_create = 3 - len(existing_tasks)
    created_tasks = []

    available_task_types = [task for task in TASK_TYPES]

    if user.has_taken_level_test:
        available_task_types = [task for task in available_task_types if task['type'] != 'take_level_test']

    if len(available_task_types) < tasks_to_create:
        logger.error(f"Kullanıcı {user.id} için yeterli görev türü yok.")
        return existing_tasks

    selected_tasks = random.sample(available_task_types, k=tasks_to_create)
    selected_lessons = random.choices(lessons, k=tasks_to_create)

    for task_template, lesson in zip(selected_tasks, selected_lessons):
        section = None

        if task_template['type'] in ['solve_questions', 'complete_section']:
            progress = db.query(ProgressModels).filter(
                ProgressModels.user_id == user.id,
                ProgressModels.lesson_id == lesson.id,
                ProgressModels.subsection_completion < 3
            ).order_by(ProgressModels.section_id.asc()).first()

            if progress and progress.section_id:
                section = db.query(Section).filter(Section.id == progress.section_id).first()
            else:
                first_section = db.query(Section).filter(Section.lesson_id == lesson.id).order_by(Section.order.asc()).first()

                if first_section:
                    section = first_section

                    if not progress:
                        total_questions = db.query(QuestionModels).filter(QuestionModels.section_id == first_section.id).count()

                        progress = ProgressModels(
                            user_id=user.id,
                            lesson_id=lesson.id,
                            section_id=first_section.id,
                            completed_questions=0,
                            total_questions=total_questions,
                            completion_percentage=0.0,
                            current_subsection='beginner',
                            subsection_completion=0
                        )
                        db.add(progress)

        if task_template['type'] == 'take_level_test':
            existing_level_task = db.query(DailyTask).filter(
                DailyTask.user_id == user.id,
                DailyTask.lesson_id == lesson.id,
                DailyTask.task_type == 'take_level_test',
                DailyTask.expires_time > current_time
            ).first()

            if existing_level_task:
                logger.debug(f"Kullanıcı {user.id} için zaten take_level_test görevi var.")
                continue

        daily_task = DailyTask(
            user_id=user.id,
            lesson_id=lesson.id,
            section_id=section.id if section else None,
            task_type=task_template['type'],
            target=task_template['target'],
            current_progress=0,
            is_completed=False,
            create_time=current_time,
            expires_time=tomorrow_start,
            level=user.level if user.level else 'beginner'
        )

        db.add(daily_task)
        created_tasks.append(daily_task)
        logger.debug(f"Kullanıcı {user.id} için görev oluşturuldu: {task_template['type']}")

    try:
        db.commit()
        logger.info(f"Kullanıcı {user.id} için {len(created_tasks)} yeni görev oluşturuldu.")
    except Exception as e:
        db.rollback()
        logger.error(f"Kullanıcı {user.id} için görev oluşturma hatası: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Görev oluşturma sırasında bir hata oluştu.")

    return db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.create_time >= today_start,
        DailyTask.expires_time > current_time
    ).all()


def generate_daily_tasks_for_all_users(db: Session): # schedular için tüm kullanıcılara daily task oluşturma
    users = db.query(User).filter(User.role != 'guest').all()
    total_created = 0

    for user in users:
        try:
            created_tasks = generate_daily_tasks_for_user(db, user)
            total_created += len([t for t in created_tasks if t.create_time >= get_today_start()])
            logger.debug(f"Kullanıcı {user.id} için görevler kontrol edildi.")

        except Exception as e:
            logger.error(f"Kullanıcı {user.id} için görev oluşturma hatası: {str(e)}")
            continue

    logger.info(f"Toplam {len(users)} kullanıcı için görevler kontrol edildi. {total_created} yeni görev oluşturuldu.")
    return total_created


@router.get('/daily', response_model=list[DailyTaskResponse])
async def get_daily_tasks(db: db_dependency, user: user_dependency, lesson_id: Optional[int] = None, target_user_id: Optional[int] = None):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar günlük görevleri göremez.")

    if user.role != 'admin' and target_user_id and target_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Normal kullanıcılar başka kullanıcıların görevlerini göremez.")

    target_id = target_user_id if user.role == 'admin' and target_user_id else user.id
    target_user = db.query(User).filter(User.id == target_id).first()

    if not target_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Kullanıcı ID {target_id} bulunamadı.")

    try:
        tasks = generate_daily_tasks_for_user(db, target_user)

    except HTTPException as err:
        raise err

    except Exception as err:
        logger.error(f"Kullanıcı {target_id} için görev oluşturma hatası: {str(err)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Görevler yüklenirken bir hata oluştu.")

    current_time = datetime.now(timezone.utc)
    active_tasks = [task for task in tasks if task.expires_time > current_time]

    if lesson_id:
        active_tasks = [task for task in active_tasks if task.lesson_id == lesson_id]

    logger.debug(f"Kullanıcı {target_id} için {len(active_tasks)} aktif görev döndürülüyor.")
    return active_tasks


@router.post('/review_mistakes', response_model=list[QuestionResponse])
async def review_mistakes(db: db_dependency, lesson_id: int, current_user: User = Depends(get_current_user), background_tasks: BackgroundTasks = None):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    user = db.query(User).filter(User.id == current_user.id).first()
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()

    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı veya ders bulunamadı.")

    if lesson not in user.lessons:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu ders kullanıcı tarafından seçilmemiş.")

    if user.health_count <= 0:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Yeterli can hakkınız yok. Lütfen can hakkı yenilenmesini bekleyin.")

    wrong_questions = db.query(UserQuestion).join(QuestionModels).filter(
        and_(
            UserQuestion.user_id == current_user.id,
            UserQuestion.is_correct == False,
            QuestionModels.lesson_id == lesson_id
        )
    ).all()

    if not wrong_questions:
        logger.info(f'Kullanıcı {current_user.id} için ders {lesson_id} içinde yanlış cevaplanmış soru bulunamadı.')
        return []

    response_questions = []

    for user_question in wrong_questions:
        question = user_question.question

        response_questions.append(
            QuestionResponse(
                id=question.id,
                content=question.content,
                options=json.loads(question.options),
                correct_answer=question.correct_answer,
                lesson_id=question.lesson_id,
                section_id=question.section_id,
                level=question.level
            )
        )

    current_time = datetime.now(timezone.utc)

    tasks = db.query(DailyTask).filter(
        DailyTask.user_id == current_user.id,
        DailyTask.lesson_id == lesson_id,
        DailyTask.task_type == 'review_mistakes',
        DailyTask.is_completed == False,
        DailyTask.expires_time > current_time
    ).all()

    for task in tasks:
        task.current_progress += 1
        if task.current_progress >= task.target:
            task.is_completed = True
            user.health_count = min(user.health_count + 1, 6)
            user.health_count_update_time = datetime.now(timezone.utc)

    if background_tasks:
        background_tasks.add_task(update_user_streak, db, current_user.id, lesson_id)
        background_tasks.add_task(update_user_health_count, db, current_user.id)

    db.commit()
    logger.info(f'Kullanıcı {current_user.id} için ders {lesson_id} içinde {len(response_questions)} yanlış cevaplanmış soru döndürüldü.')
    return response_questions


@router.get('/debug_daily_tasks') # backend test için
async def debug_daily_tasks(db: db_dependency, user: user_dependency):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    lessons = db.query(Lesson).join(user_lessons).filter(user_lessons.c.user_id == user.id).all()

    tasks = db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.expires_time > datetime.now(timezone.utc)
    ).all()

    return {
        "user_id": user.id,
        "username": user.username,
        "selected_lessons": [lesson.title for lesson in lessons],
        "existing_tasks": [{"task_type": task.task_type, "lesson_id": task.lesson_id, "section_id": task.section_id} for task in tasks],
        "current_time_utc": datetime.now(timezone.utc)
    }