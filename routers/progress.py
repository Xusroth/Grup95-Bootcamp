

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from typing import Annotated
from starlette import status
from sqlalchemy.orm import Session
from database import SessionLocal
from models import User, Question, Lesson, Section, Progress, DailyTask, UserQuestion
from schemas import ProgressResponse, AnswerQuestionRequest
from routers.auth import get_current_user
from datetime import datetime, timezone, timedelta
import logging
from utils.health import update_user_health_count
from utils.streak import update_user_streak


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
async def answer_question(db: db_dependency, current_user: user_dependency, request: AnswerQuestionRequest, background_tasks: BackgroundTasks):
    user = db.query(User).filter(User.id == current_user.id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar soru cevaplayamaz.")

    background_tasks.add_task(update_user_health_count, db, user.id)

    if user.health_count <= 0:
        if user.health_count_update_time:
            if user.health_count_update_time.tzinfo is None:
                user.health_count_update_time = user.health_count_update_time.replace(tzinfo=timezone.utc)
            time_diff = datetime.now(timezone.utc) - user.health_count_update_time
            remaining_hours = 2 - (time_diff.total_seconds() / 3600)
            raise HTTPException(status_code=403, detail=f"Can hakkınız bitti. {remaining_hours:.2f} saat sonra tekrar deneyin.")
        else:
            raise HTTPException(status_code=403, detail="Can hakkınız bitti. Lütfen bekleyin.")

    question = db.query(Question).filter(Question.id == request.question_id).first()
    if not question:
        logger.error(f"Soru ID {request.question_id} bulunamadı.")
        raise HTTPException(status_code=404, detail="Soru bulunamadı.")

    # Kullanıcının bu soruyu daha önce doğru cevaplayıp cevaplamadığını kontrol et
    existing_correct = db.query(UserQuestion).filter(
        UserQuestion.user_id == user.id,
        UserQuestion.question_id == request.question_id,
        UserQuestion.is_correct == True
    ).first()

    if existing_correct:
        raise HTTPException(status_code=400, detail="Bu soruyu zaten doğru cevapladınız.")

    is_correct = request.user_answer == question.correct_answer
    progress_updated = False
    progress = None

    try:
        # UserQuestion kaydını ekle ve hemen commit et
        user_question = UserQuestion(
            user_id=user.id,
            question_id=request.question_id,
            used_at=datetime.now(timezone.utc),
            is_correct=is_correct
        )
        db.add(user_question)
        db.commit()  # UserQuestion kaydını hemen commit et
        db.refresh(user_question)

        if is_correct:
            # Progress kaydını al veya oluştur
            progress = db.query(Progress).filter(
                Progress.user_id == user.id,
                Progress.lesson_id == question.lesson_id,
                Progress.section_id == question.section_id
            ).first()

            if not progress:
                section = db.query(Section).filter(Section.id == question.section_id).first()
                if not section:
                    logger.error(f"Bölüm ID {question.section_id} bulunamadı.")
                    raise HTTPException(status_code=404, detail="Bölüm bulunamadı.")

                total_questions = db.query(Question).filter(Question.section_id == question.section_id).count()

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

            # Her seviyede kaç soru olduğunu hesapla
            beginner_count = db.query(Question).filter(
                Question.section_id == question.section_id,
                Question.subsection == 'beginner'
            ).count()

            intermediate_count = db.query(Question).filter(
                Question.section_id == question.section_id,
                Question.subsection == 'intermediate'
            ).count()

            advanced_count = db.query(Question).filter(
                Question.section_id == question.section_id,
                Question.subsection == 'advanced'
            ).count()

            # Kullanıcının her seviyede çözdüğü doğru soruları say
            beginner_solved = db.query(UserQuestion).join(Question).filter(
                UserQuestion.user_id == user.id,
                UserQuestion.is_correct == True,
                Question.section_id == question.section_id,
                Question.subsection == 'beginner'
            ).count()

            intermediate_solved = db.query(UserQuestion).join(Question).filter(
                UserQuestion.user_id == user.id,
                UserQuestion.is_correct == True,
                Question.section_id == question.section_id,
                Question.subsection == 'intermediate'
            ).count()

            advanced_solved = db.query(UserQuestion).join(Question).filter(
                UserQuestion.user_id == user.id,
                UserQuestion.is_correct == True,
                Question.section_id == question.section_id,
                Question.subsection == 'advanced'
            ).count()

            # Progress güncelle
            progress.completed_questions = beginner_solved + intermediate_solved + advanced_solved
            progress.completion_percentage = (
                progress.completed_questions / progress.total_questions * 100 if progress.total_questions > 0 else 0)

            # Current_subsection ve subsection_completion'ı güncelle
            if advanced_solved >= advanced_count and intermediate_solved >= intermediate_count and beginner_solved >= beginner_count:
                # Tüm seviyeler tamamlandı - sıradaki section'a geç
                progress.current_subsection = 'completed'
                progress.subsection_completion = 3

                # Sıradaki section'ı bul ve aktif et
                current_section = db.query(Section).filter(Section.id == question.section_id).first()
                next_section = db.query(Section).filter(
                    Section.lesson_id == question.lesson_id,
                    Section.order > current_section.order
                ).order_by(Section.order.asc()).first()

                if next_section:
                    # Sıradaki section için progress kaydı oluştur
                    next_progress = db.query(Progress).filter(
                        Progress.user_id == user.id,
                        Progress.lesson_id == question.lesson_id,
                        Progress.section_id == next_section.id
                    ).first()

                    if not next_progress:
                        next_total_questions = db.query(Question).filter(Question.section_id == next_section.id).count()
                        next_progress = Progress(
                            user_id=user.id,
                            lesson_id=question.lesson_id,
                            section_id=next_section.id,
                            completed_questions=0,
                            total_questions=next_total_questions,
                            completion_percentage=0.0,
                            current_subsection='beginner',
                            subsection_completion=0
                        )
                        db.add(next_progress)
                        logger.debug(f"Kullanıcı {user.id} için sıradaki section {next_section.id} aktif edildi.")

            elif intermediate_solved >= intermediate_count and beginner_solved >= beginner_count:
                # Beginner ve intermediate tamamlandı - advanced'e geç
                progress.current_subsection = 'advanced'
                progress.subsection_completion = 2
            elif beginner_solved >= beginner_count:
                # Beginner tamamlandı - intermediate'e geç
                progress.current_subsection = 'intermediate'
                progress.subsection_completion = 1
            else:
                # Hala beginner seviyesinde
                progress.current_subsection = 'beginner'
                progress.subsection_completion = 0

            logger.debug(f"Progress güncellendi: beginner={beginner_solved}/{beginner_count}, "
                         f"intermediate={intermediate_solved}/{intermediate_count}, "
                         f"advanced={advanced_solved}/{advanced_count}, "
                         f"current_subsection={progress.current_subsection}")

            progress_updated = True

            # Daily task kontrolü
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

            # Section tamamlanma kontrolü
            if progress.subsection_completion == 3:
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

        else:
            # Yanlış cevap
            user.health_count = max(user.health_count - 1, 0)
            user.health_count_update_time = datetime.now(timezone.utc)

        db.commit()

        if progress_updated:
            db.refresh(progress)

        background_tasks.add_task(update_user_streak, db, user.id, question.lesson_id)
        background_tasks.add_task(update_user_health_count, db, user.id)

        if not is_correct:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Yanlış cevap, 1 can kaybettiniz. Kalan can: {user.health_count}")

        response_data = {
            'message': "Doğru cevap!",
            'health_count': user.health_count,
            'progress_updated': progress_updated,
            'current_subsection': progress.current_subsection if progress_updated else None,
            'subsection_completion': progress.subsection_completion if progress_updated else None
        }

        # Eğer section tamamlandıysa bunu belirt
        if progress_updated and progress.current_subsection == 'completed':
            response_data['section_completed'] = True
            response_data['message'] = "Doğru cevap! Bu bölümü tamamladınız, sıradaki bölüm aktif edildi."

        return response_data

    except HTTPException as err:
        raise err
    except Exception as err:
        db.rollback()
        logger.error(f"Soru cevaplama hatası, kullanıcı ID {user.id}, soru ID {request.question_id}: {str(err)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Bir hata oluştu:{str(err)}")


@router.get('/users/{user_id}/lessons/{lesson_id}/accessible-sections', response_model=list[dict]) # kullanıcının hangi section'ı alabileceğini göstermeye çalıştım ?
async def get_user_accessible_sections(db: db_dependency, user_id: int, lesson_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()

    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı veya ders bulunamadı.")

    if lesson not in user.lessons:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu ders kullanıcı tarafından seçilmemiş.")

    # Dersin tüm section'larını sırayla al
    sections = db.query(Section).filter(Section.lesson_id == lesson_id).order_by(Section.order).all()

    result = []

    for section in sections:
        # Bu section için progress kaydını al
        progress = db.query(Progress).filter(
            Progress.user_id == user_id,
            Progress.section_id == section.id
        ).first()

        section_data = {
            'id': section.id,
            'title': section.title,
            'description': section.description,
            'order': section.order,
            'is_accessible': False,
            'is_completed': False,
            'current_subsection': None,
            'subsection_completion': 0,
            'completion_percentage': 0.0
        }

        if progress:
            section_data.update({
                'is_accessible': True,
                'is_completed': progress.current_subsection == 'completed',
                'current_subsection': progress.current_subsection,
                'subsection_completion': progress.subsection_completion,
                'completion_percentage': progress.completion_percentage
            })
        else:
            # İlk section her zaman erişilebilir
            if section.order == 1:
                section_data['is_accessible'] = True
            else:
                # Önceki section tamamlanmış mı kontrol et
                previous_section = db.query(Section).filter(
                    Section.lesson_id == lesson_id,
                    Section.order == section.order - 1
                ).first()

                if previous_section:
                    prev_progress = db.query(Progress).filter(
                        Progress.user_id == user_id,
                        Progress.section_id == previous_section.id
                    ).first()

                    if prev_progress and prev_progress.current_subsection == 'completed':
                        section_data['is_accessible'] = True

        result.append(section_data)

    return result