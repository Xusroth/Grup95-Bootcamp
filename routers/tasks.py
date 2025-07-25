

from fastapi import APIRouter, HTTPException, Depends
from typing import Annotated, Optional
from starlette import status
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import SessionLocal
from models import User, DailyTask, Question as QuestionModels, Lesson, Section, Progress as ProgressModels, user_lessons, UserQuestion
from schemas import DailyTaskResponse, DailyTaskCreate, DailyTaskUpdate, AnswerQuestionRequest, ProgressResponse, Progress
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
    {'type': 'maintain_streak', 'target': 1, 'description': 'Bir derste streak\'i koru.'},
    {'type': 'review_mistakes', 'target': 3, 'description': 'Yanlış cevaplanmış 3 soruyu gözden geçir.'}
]


def generate_daily_tasks(db: db_dependency, user: User):
    if user.role == 'guest':
        logger.debug(f"Kullanıcı {user.id} misafir, görev oluşturulmadı.")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar günlük görev alamaz.")

    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    logger.debug(f"Bugün: {today}")

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
        logger.warning(f"Kullanıcı {user.id} için ders bulunamadı. Görev oluşturulmadı.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Görev oluşturmak için önce bir ders seçmelisiniz.")

    created_tasks = []

    # kullanıcı seviye testini almadıysa take_level_test görevi öncelikli olarak ekleniyor!!
    if not user.has_taken_level_test and tasks_to_create > 0:
        lesson = random.choice(lessons)
        existing_level_task = db.query(DailyTask).filter(
            DailyTask.user_id == user.id,
            DailyTask.lesson_id == lesson.id,
            DailyTask.task_type == 'take_level_test',
            DailyTask.expires_time > datetime.now(timezone.utc)
        ).first()
        if not existing_level_task:
            level_task = DailyTask(
                user_id=user.id,
                lesson_id=lesson.id,
                section_id=None,
                task_type='take_level_test',
                target=1,
                current_progress=0,
                is_completed=False,
                create_time=datetime.now(timezone.utc),
                expires_time=datetime.now(timezone.utc) + timedelta(days=1),
                level=user.level or 'beginner'
            )
            db.add(level_task)
            created_tasks.append(level_task)
            tasks_to_create -= 1
            logger.debug(f"Kullanıcı {user.id} için take_level_test görevi oluşturuldu: lesson_id={lesson.id}")

    # Kalan görevleri rastgele seç
    available_task_types = [task for task in TASK_TYPES if task['type'] != 'take_level_test']
    if len(available_task_types) < tasks_to_create:
        logger.error("Yeterli görev türü yok. En az yeterli görev türü gerekli.")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Yeterli görev türü tanımlı değil.")

    selected_tasks = random.sample(available_task_types, k=tasks_to_create)
    logger.debug(f"Seçilen görev türleri: {[task['type'] for task in selected_tasks]}")
    selected_lessons = random.choices(lessons, k=tasks_to_create)
    logger.debug(f"Seçilen dersler: {[lesson.title for lesson in selected_lessons]}")

    for task, lesson in zip(selected_tasks, selected_lessons):
        section = None
        if task['type'] in ['solve_questions', 'complete_section']:
            sections = db.query(Section).filter(Section.lesson_id == lesson.id).order_by(Section.order.asc()).all()
            if not sections:
                logger.warning(f"Ders {lesson.id} için bölüm bulunamadı. Görev oluşturulmadı.")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail=f"Ders ID {lesson.id} için bölüm bulunamadı.")

            progress = db.query(ProgressModels).filter(
                ProgressModels.user_id == user.id,
                ProgressModels.lesson_id == lesson.id,
                ProgressModels.subsection_completion < 3
            ).order_by(ProgressModels.section_id.asc()).first()

            if progress and progress.section_id:
                section = db.query(Section).filter(Section.id == progress.section_id).first()
            else:
                section = sections[0]
                progress = Progress(
                    user_id=user.id,
                    lesson_id=lesson.id,
                    section_id=section.id,
                    completed_questions=0,
                    total_questions=db.query(Question).filter(Question.section_id == section.id).count(),
                    completion_percentage=0.0,
                    current_subsection='beginner',
                    subsection_completion=0
                )
                db.add(progress)
                logger.debug(f"Kullanıcı {user.id} için yeni Progress kaydı oluşturuldu: section_id={section.id}")

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
        created_tasks.append(daily_task)

    try:
        db.commit()
        logger.info(f"Kullanıcı {user.id} için {len(created_tasks)} günlük görev oluşturuldu.")
    except Exception as e:
        db.rollback()
        logger.error(f"Görev oluşturma sırasında hata: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Görev oluşturma sırasında bir hata oluştu.")

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


@router.post('/answer_question', response_model=dict)
async def answer_question(request: AnswerQuestionRequest, db: db_dependency, current_user: User = Depends(get_current_user)):
    user = db.query(User).filter(User.id == current_user.id).first() # user mevcut database oturumundan tekrar sorgula yoksa patlıyor kabul etmiyor
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    question = db.query(QuestionModels).filter(QuestionModels.id == request.question_id).first() # soruların kontrolü
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Soru bulunamadı.")

    if user.health_count == 0: # health_count kontrolü
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Can sayınız 0. Lütfen canlarınızın dolmasını bekleyin.")

    # sorunun daha önce cevaplanıp cevaplanmadığının kontrol edilmesi (buna göre userdan ilerleme ve health_count takibi yapılacak)
    user_question = db.query(UserQuestion).filter(UserQuestion.user_id == user.id, UserQuestion.question_id == request.question_id).first()
    if user_question:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu soruyu zaten cevapladınız.")

    progress = db.query(ProgressModels).filter( # progress güncelleme kısmı
        ProgressModels.user_id == user.id,
        ProgressModels.lesson_id == question.lesson_id,
        ProgressModels.section_id == question.section_id
    ).first()
    if not progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="İlerleme kaydı bulunamadı.")

    is_correct = question.correct_answer == request.user_answer     # true false kontrolü
    if is_correct:
        progress.completed_questions += 1
        progress.completion_percentage = (progress.completed_questions / progress.total_questions * 100) if progress.total_questions > 0 else 0

    else:
        user.health_count = max(user.health_count - 1, 0)
        user.health_count_update_time = datetime.now(timezone.utc)
        logger.debug(f"Kullanıcı {user.id} yanlış cevap verdi, health_count: {user.health_count}")

    user_question = UserQuestion(user_id=user.id, question_id=request.question_id, used_at=datetime.now(timezone.utc)) # UserQuestion tablosuna soru kaydediliyor
    db.add(user_question)

    db.commit()
    db.refresh(progress)
    db.refresh(user)

    return {
        "is_correct": is_correct,
        "health_count": user.health_count,
        "progress": Progress.model_validate(progress).dict()
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