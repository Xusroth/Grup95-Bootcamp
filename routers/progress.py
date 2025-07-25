

from fastapi import APIRouter, HTTPException, Depends
from typing import Annotated
from starlette import status
from sqlalchemy.orm import Session
from database import SessionLocal
from models import User, Question, Lesson, Section, Progress, DailyTask, UserQuestion
from schemas import ProgressResponse, AnswerQuestionRequest
from routers.auth import get_current_user
from datetime import datetime, timezone, timedelta
import logging


logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

router = APIRouter(prefix='/progress', tags=['Progress'])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]
user_dependency = Annotated[User, Depends(get_current_user)]

@router.get('/me', response_model=list[ProgressResponse])
async def get_my_progress(db: db_dependency, user: user_dependency):
    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar ilerleme kaydını görüntüleyemez.")

    progress = db.query(Progress).filter(Progress.user_id == user.id).all()
    logger.debug(f"Kullanıcı {user.id} için {len(progress)} ilerleme kaydı bulundu.")
    return progress

@router.post('/answer_question', response_model=dict)
async def answer_question(db: db_dependency, current_user: user_dependency, request: AnswerQuestionRequest):
    user = db.query(User).filter(User.id == current_user.id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar soru cevaplayamaz.")

    if user.health_count <= 0: # health_count'ı kontrol edip duruma göre oto yenileme !!!
        time_diff = datetime.now(timezone.utc) - user.health_count_update_time
        if time_diff < timedelta(hours=2):
            remaining_hours = 2 - (time_diff.total_seconds() / 3600)
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Can hakkınız bitti. {remaining_hours:.2f} saat sonra tekrar deneyin.")

        else:
            user.health_count = 6
            user.health_count_update_time = datetime.now(timezone.utc)
            db.commit()
            db.refresh(user)

    question = db.query(Question).filter(Question.id == request.question_id).first() # soruyu kontrol etme kısmı
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Soru bulunamadı.")

    user_question = db.query(UserQuestion).filter( # aynı soruya cevap verilmeme kısmı
        UserQuestion.user_id == user.id,
        UserQuestion.question_id == request.question_id
    ).first()
    if user_question:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu soruyu zaten cevapladınız.")

    is_correct = request.user_answer == question.correct_answer # true/false kısmı
    progress_updated = False
    progress = None

    if is_correct:
        progress = db.query(Progress).filter(  # Progress güncelleme
            Progress.user_id == user.id,
            Progress.lesson_id == question.lesson_id,
            Progress.section_id == question.section_id
        ).first()
        if not progress:
            section = db.query(Section).filter(Section.id == question.section_id).first()
            if not section:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bölüm bulunamadı.")
            total_questions = db.query(Question).filter(
                Question.section_id == question.section_id,
                Question.level == user.level
            ).count()
            progress = Progress(
                user_id=user.id,
                lesson_id=question.lesson_id,
                section_id=question.section_id,
                completed_questions=0,
                total_questions=total_questions,
                completion_percentage=0.0,
                current_subsection='beginner',
                subsection_completion=0
            )
            db.add(progress)
            db.commit()
            db.refresh(progress)

        progress.completed_questions += 1
        progress.completion_percentage = (
            progress.completed_questions / progress.total_questions * 100
            if progress.total_questions > 0 else 0
        )

        questions_per_subsection = max(1, progress.total_questions // 3) # subsection tamamlama kısmı (kontrol edin) !!!!!
        if progress.completed_questions <= questions_per_subsection:
            progress.current_subsection = 'beginner'
            progress.subsection_completion = min(1, progress.completed_questions // questions_per_subsection)
        elif progress.completed_questions <= 2 * questions_per_subsection:
            progress.current_subsection = 'intermediate'
            progress.subsection_completion = min(2, progress.completed_questions // questions_per_subsection)
        else:
            progress.current_subsection = 'advanced'
            progress.subsection_completion = 3

        if progress.subsection_completion == 3: # section tamamlandıysa bir sonraki bölüme geçme kısmı
            section = db.query(Section).filter(Section.id == progress.section_id).first()
            next_section = db.query(Section).filter(
                Section.lesson_id == question.lesson_id,
                Section.order > section.order
            ).order_by(Section.order.asc()).first()
            if next_section:
                existing_progress = db.query(Progress).filter(
                    Progress.user_id == user.id,
                    Progress.lesson_id == question.lesson_id,
                    Progress.section_id == next_section.id
                ).first()
                if not existing_progress:
                    total_questions = db.query(Question).filter(
                        Question.section_id == next_section.id,
                        Question.level == user.level
                    ).count()
                    new_progress = Progress(
                        user_id=user.id,
                        lesson_id=question.lesson_id,
                        section_id=next_section.id,
                        completed_questions=0,
                        total_questions=total_questions,
                        completion_percentage=0.0,
                        current_subsection='beginner',
                        subsection_completion=0
                    )
                    db.add(new_progress)
                    logger.debug(f"Kullanıcı {user.id} için bölüm tamamlandı, yeni bölüm: {next_section.id}")

        progress_updated = True

        tasks = db.query(DailyTask).filter(  # daily tasks güncelleme kısmı
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

        if progress.subsection_completion == 3: # section tamamlama görevi kısmı
            section_tasks = db.query(DailyTask).filter(
                DailyTask.user_id == user.id,
                DailyTask.lesson_id == question.lesson_id,
                DailyTask.section_id == question.section_id,
                DailyTask.task_type == 'complete_section',
                DailyTask.is_completed == False,
                DailyTask.expires_time > datetime.now(timezone.utc)
            ).all()
            for task in section_tasks:
                task.current_progress = 1
                task.is_completed = True
                user.health_count = min(user.health_count + 2, 6)
                user.health_count_update_time = datetime.now(timezone.utc)
                db.commit()

    else:
        user.health_count = max(user.health_count - 1, 0)
        user.health_count_update_time = datetime.now(timezone.utc)

    user_question = UserQuestion(
        user_id=user.id,
        question_id=request.question_id,
        used_at=datetime.now(timezone.utc))
    db.add(user_question)

    db.commit()
    if progress_updated:
        db.refresh(progress)

    if not is_correct:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Yanlış cevap, 1 can kaybettiniz. Kalan can: {user.health_count}")

    return {'message': "Doğru cevap!",
            'health_count': user.health_count,
            'progress_updated': progress_updated,
            'current_subsection': progress.current_subsection if progress_updated else None,
            'subsection_completion': progress.subsection_completion if progress_updated else None}