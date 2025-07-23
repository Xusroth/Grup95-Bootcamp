

from fastapi import APIRouter, HTTPException, Depends
from typing import Annotated, Optional
from starlette import status
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import SessionLocal
from models import User, DailyTask, Question, Lesson, Section, Progress, user_lessons
from schemas import DailyTaskResponse, DailyTaskCreate, DailyTaskUpdate, AnswerQuestionRequest
from routers.auth import get_current_user
from datetime import datetime, timezone, timedelta
import random
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
    {'type': 'take_level_test', 'target': 1, 'description': 'Seviye tespit sınavına gir.'},
    {'type': 'maintain_streak', 'target': 1, 'description': 'Bir derste streak\'i koru.'},
    {'type': 'review_mistakes', 'target': 3, 'description': 'Yanlış cevaplanmış 3 soruyu gözden geçir.'}
]


def generate_daily_tasks(db: db_dependency, user: User):
    if user.role == 'guest':
        logger.debug(f"Kullanıcı {user.id} misafir, görev oluşturulmadı.")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Misafir kullanıcılar günlük görev alamaz."
        )

    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    logger.debug(f"Bugün: {today}")

    existing_tasks = db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.create_time >= today
    ).all()
    logger.debug(f"Kullanıcı {user.id} için mevcut görevler: {len(existing_tasks)}")

    if not existing_tasks:
        lessons = db.query(Lesson).join(user_lessons).filter(user_lessons.c.user_id == user.id).all()
        if not lessons:
            logger.warning(f"Kullanıcı {user.id} için ders bulunamadı. Görev oluşturulmadı.")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Görev oluşturmak için önce bir ders seçmelisiniz."
            )

        if len(TASK_TYPES) < 3:
            logger.error("Yeterli görev türü yok. En az 3 görev türü gerekli.")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Yeterli görev türü tanımlı değil."
            )

        selected_tasks = random.sample(TASK_TYPES, k=3)
        logger.debug(f"Seçilen görev türleri: {[task['type'] for task in selected_tasks]}")

        selected_lessons = random.choices(lessons, k=3)
        logger.debug(f"Seçilen dersler: {[lesson.title for lesson in selected_lessons]}")

        for task, lesson in zip(selected_tasks, selected_lessons):
            section = None
            if task['type'] in ['solve_questions', 'complete_section']:
                sections = db.query(Section).filter(Section.lesson_id == lesson.id).all()
                if sections:
                    section = random.choice(sections)
                    logger.debug(f"Ders {lesson.id} için seçilen bölüm: {section.id}")
                else:
                    logger.debug(f"Ders {lesson.id} için bölüm bulunamadı, section_id=None.")

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
            logger.debug(
                f"Kullanıcı {user.id} için görev oluşturuldu: {task['type']}, lesson_id: {lesson.id}, section_id: {section.id if section else None}")

        try:
            db.commit()
            logger.info(f"Kullanıcı {user.id} için 3 günlük görev oluşturuldu.")
        except Exception as e:
            db.rollback()
            logger.error(f"Görev oluşturma sırasında hata: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Görev oluşturma sırasında bir hata oluştu."
            )


@router.get('/daily', response_model=list[DailyTaskResponse])
async def get_daily_tasks(
        db: db_dependency,
        user: user_dependency,
        lesson_id: Optional[int] = None,
        target_user_id: Optional[int] = None
):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="Misafir kullanıcılar günlük görevleri göremez.")

    logger.debug(
        f"Kullanıcı {user.id} için günlük görevler sorgulanıyor, lesson_id: {lesson_id}, target_user_id: {target_user_id}")

    # Normal kullanıcılar sadece kendi görevlerini görebilir
    if user.role != 'admin' and target_user_id and target_user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Normal kullanıcılar başka kullanıcıların görevlerini göremez."
        )

    # Görevleri oluştur (sadece hedef kullanıcı için)
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

    # Görevleri çek
    query = db.query(DailyTask).filter(
        DailyTask.user_id == target_id,
        DailyTask.expires_time > datetime.now(timezone.utc)
    )
    if lesson_id:
        query = query.filter(DailyTask.lesson_id == lesson_id)
    tasks = query.all()
    logger.debug(f"Kullanıcı {target_id} için {len(tasks)} görev bulundu: {[task.task_type for task in tasks]}")
    return tasks


@router.post('/answer_question')
async def answer_question(db: db_dependency, user: user_dependency, request: AnswerQuestionRequest):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar soru cevaplayamaz.")

    if user.health_count <= 0:
        time_diff = datetime.now(timezone.utc) - user.health_count_update_time
        if time_diff < timedelta(hours=2):
            remaining_hours = 2 - (time_diff.total_seconds() / 3600)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Can hakkınız bitti. {remaining_hours:.2f} saat sonra tekrar deneyin."
            )
        else:
            user.health_count = 6
            user.health_count_update_time = datetime.now(timezone.utc)
            db.commit()

    question = db.query(Question).filter(Question.id == request.question_id).first()
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Soru bulunamadı.")

    is_correct = request.user_answer == question.correct_answer
    if not is_correct:
        user.health_count -= 1
        user.health_count_update_time = datetime.now(timezone.utc)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Yanlış cevap, 1 can kaybettiniz. Kalan can: {user.health_count}"
        )

    tasks = db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.lesson_id == question.lesson_id,
        DailyTask.section_id == question.section_id,
        DailyTask.task_type == 'solve_questions',
        DailyTask.is_completed == False,
        DailyTask.expires_time > datetime.now(timezone.utc)
    ).all()

    for task in tasks:
        task.current_progress += 1
        if task.current_progress >= task.target:
            task.is_completed = True
            user.health_count = min(user.health_count + 2, 6)
            user.health_count_update_time = datetime.now(timezone.utc)
        db.commit()

    section = db.query(Section).filter(Section.id == question.section_id).first()
    if section:
        questions_in_section = db.query(Question).filter(
            Question.section_id == section.id,
            Question.level == user.level
        ).count()
        correct_answers = db.query(Question).filter(
            Question.section_id == section.id,
            Question.level == user.level,
            Question.correct_answer == request.user_answer
        ).count()

        if correct_answers >= questions_in_section:
            section_tasks = db.query(DailyTask).filter(
                DailyTask.user_id == user.id,
                DailyTask.lesson_id == question.lesson_id,
                DailyTask.section_id == section.id,
                DailyTask.task_type == 'complete_section',
                DailyTask.is_completed == False,
                DailyTask.expires_time > datetime.now(timezone.utc)
            ).all()
            for task in section_tasks:
                task.current_progress = 1
                task.is_completed = True
                user.health_count = min(user.health_count + 2, 6)
                db.commit()

    progress = db.query(Progress).filter(
        Progress.user_id == user.id,
        Progress.lesson_id == question.lesson_id
    ).first()
    if progress:
        progress.completed_questions += 1
        progress.completion_percentage = (
            progress.completed_questions / progress.total_questions * 100
            if progress.total_questions > 0 else 0
        )
        db.commit()

    return {
        'message': "Doğru cevap!",
        'health_count': user.health_count,
        'progress_updated': bool(progress)
    }


@router.post('/take_level_test')
async def take_level_test(db: db_dependency, user: user_dependency, lesson_id: int):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar seviye testi alamaz.")

    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    tasks = db.query(DailyTask).filter(
        DailyTask.user_id == user.id,
        DailyTask.lesson_id == lesson_id,
        DailyTask.task_type == 'take_level_test',
        DailyTask.is_completed == False,
        DailyTask.expires_time > datetime.now(timezone.utc)
    ).all()

    for task in tasks:
        task.current_progress = 1
        task.is_completed = True
        user.health_count = min(user.health_count + 2, 6)
        user.health_count_update_time = datetime.now(timezone.utc)
        db.commit()

    return {'message': "Seviye testi alındı!"}


@router.get('/health_count')
async def get_health_count(db: db_dependency, user: user_dependency):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar can bilgisi göremez.")
    if user.health_count <= 0 and (datetime.now(timezone.utc) - user.health_count_update_time) >= timedelta(hours=2):
        user.health_count = 6
        user.health_count_update_time = datetime.now(timezone.utc)
        db.commit()
    return {
        'health_count': user.health_count,
        'health_count_update_time': user.health_count_update_time
    }


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