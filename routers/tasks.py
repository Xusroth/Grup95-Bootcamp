

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


def generate_daily_tasks(db: db_dependency, user: User):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar günlük görev alamaz.")

    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    existing_tasks = db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.create_time >= today
    ).all()
    logger.debug(f"Kullanıcı {user.id} için mevcut görevler: {len(existing_tasks)}")

    if len(existing_tasks) >= 3:
        logger.debug(f"Kullanıcı {user.id} için zaten 3 görev var, yeni görev oluşturulmadı.")
        return existing_tasks

    tasks_to_create = 3 - len(existing_tasks)
    lessons = db.query(Lesson).join(user_lessons).filter(user_lessons.c.user_id == user.id).all()
    if not lessons:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Görev oluşturmak için önce bir ders seçmelisiniz.")

    created_tasks = []

    available_task_types = [task for task in TASK_TYPES]

    if user.has_taken_level_test:
        available_task_types = [task for task in available_task_types if task['type'] != 'take_level_test'] # user seviye tespit sınavı aldıysa günlük görevlerde bu atanmaz !!!

    if len(available_task_types) < tasks_to_create:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Yeterli görev türü tanımlı değil.")

    selected_tasks = random.sample(available_task_types, k=tasks_to_create) # rastgele görev seçme kısmı
    selected_lessons = random.choices(lessons, k=tasks_to_create) # rastgele ders seçme kısmı

    for task, lesson in zip(selected_tasks, selected_lessons):
        section = None
        if task['type'] in ['solve_questions', 'complete_section']:
            sections = db.query(Section).filter(Section.lesson_id == lesson.id).order_by(Section.order.asc()).all()
            if not sections:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Ders ID {lesson.id} için bölüm bulunamadı.")

            progress = db.query(ProgressModels).filter(
                ProgressModels.user_id == user.id,
                ProgressModels.lesson_id == lesson.id,
                ProgressModels.subsection_completion < 3
            ).order_by(ProgressModels.section_id.asc()).first()

            if progress and progress.section_id:
                section = db.query(Section).filter(Section.id == progress.section_id).first()

            else:
                section = sections[0]
                progress = ProgressModels(
                    user_id=user.id,
                    lesson_id=lesson.id,
                    section_id=section.id,
                    completed_questions=0,
                    total_questions=db.query(QuestionModels).filter(QuestionModels.section_id == section.id).count(),
                    completion_percentage=0.0,
                    current_subsection='beginner',
                    subsection_completion=0
                )
                db.add(progress)

        if task['type'] == 'take_level_test':
            existing_level_task = db.query(DailyTask).filter(
                DailyTask.user_id == user.id,
                DailyTask.lesson_id == lesson.id,
                DailyTask.task_type == 'take_level_test',
                DailyTask.expires_time > datetime.now(timezone.utc)
            ).first()

            if existing_level_task:
                logger.debug(f"Kullanıcı {user.id} için zaten bir take_level_test görevi var, bu görev atlanıyor.") # terminalden loglara bakın !!!!!!
                continue

        daily_task = DailyTask(
            user_id=user.id,
            lesson_id=lesson.id,
            section_id=section.id if section else None,
            task_type=task['type'],
            target=task['target'],
            current_progress=0,
            is_completed=False,
            create_time=datetime.now(timezone.utc),
            expires_time=datetime.now(timezone.utc) + timedelta(days=1),
            level=user.level if user.level else 'beginner'
        )

        db.add(daily_task)
        logger.debug(f"Kullanıcı {user.id} için görev oluşturuldu: {task['type']}, lesson_id: {lesson.id}, section_id: {section.id if section else None}")
        created_tasks.append(daily_task)

    try:
        db.commit()
        logger.info(f"Kullanıcı {user.id} için {len(created_tasks)} günlük görev oluşturuldu.")

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Görev oluşturma sırasında bir hata oluştu.")

    return created_tasks


@router.get('/daily', response_model=list[DailyTaskResponse])
async def get_daily_tasks(db: db_dependency, user: user_dependency, lesson_id: Optional[int] = None, target_user_id: Optional[int] = None):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar günlük görevleri göremez.")

    logger.debug(
        f"Kullanıcı {user.id} için günlük görevler sorgulanıyor, lesson_id: {lesson_id}, target_user_id: {target_user_id}")

    if user.role != 'admin' and target_user_id and target_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Normal kullanıcılar başka kullanıcıların görevlerini göremez.")

    target_id = target_user_id if user.role == 'admin' and target_user_id else user.id
    target_user = db.query(User).filter(User.id == target_id).first()
    if not target_user:
        logger.debug(f"Hedef kullanıcı {target_id} bulunamadı.")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Kullanıcı ID {target_id} bulunamadı.")

    try:
        generate_daily_tasks(db, target_user)
    except HTTPException as e:
        logger.error(f"Hedef kullanıcı {target_id} için görev oluşturma hatası: {e.detail}")
        raise e

    query = db.query(DailyTask).filter(
        DailyTask.user_id == target_id,
        DailyTask.expires_time > datetime.now(timezone.utc)
    )
    if lesson_id:
        query = query.filter(DailyTask.lesson_id == lesson_id)
    tasks = query.all()
    logger.debug(f"Kullanıcı {target_id} için {len(tasks)} görev bulundu: {[task.task_type for task in tasks]}")
    return tasks


@router.post('/review_mistakes', response_model=list[QuestionResponse])
async def review_mistakes(db: db_dependency, lesson_id: int, current_user: User = Depends(get_current_user), background_tasks: BackgroundTasks = None):
    if current_user.role == 'guest':
        raise HTTPException(status_code=403, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    user = db.query(User).filter(User.id == current_user.id).first()
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()

    if not user or not lesson:
        raise HTTPException(status_code=404, detail="Kullanıcı veya ders bulunamadı.")

    if lesson not in user.lessons:
        raise HTTPException(status_code=400, detail="Bu ders kullanıcı tarafından seçilmemiş.")

    if user.health_count <= 0:
        raise HTTPException(status_code=403, detail="Yeterli can hakkınız yok. Lütfen can hakkı yenilenmesini bekleyin.")

    wrong_questions = db.query(UserQuestion).join(QuestionModels).filter(
        and_(
            UserQuestion.user_id == current_user.id,
            UserQuestion.is_correct == False,
            QuestionModels.lesson_id == lesson_id
        )
    ).all()

    if not wrong_questions:
        logger.info(f"Kullanıcı {current_user.id} için ders {lesson_id} içinde yanlış cevaplanmış soru bulunamadı.")
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

    tasks = db.query(DailyTask).filter(
        DailyTask.user_id == current_user.id,
        DailyTask.lesson_id == lesson_id,
        DailyTask.task_type == 'review_mistakes',
        DailyTask.is_completed == False,
        DailyTask.expires_time > datetime.now(timezone.utc)
    ).all()

    for task in tasks:
        task.current_progress += 1
        if task.current_progress >= task.target:
            task.is_completed = True
            user.health_count = min(user.health_count + 2, 6)
            user.health_count_update_time = datetime.now(timezone.utc)

    background_tasks.add_task(update_user_streak, db, current_user.id, lesson_id)
    background_tasks.add_task(update_user_health_count, db, current_user.id)

    db.commit()
    logger.info(f"Kullanıcı {current_user.id} için ders {lesson_id} içinde {len(response_questions)} yanlış cevaplanmış soru döndürüldü.")
    return response_questions


@router.get('/debug_daily_tasks')
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