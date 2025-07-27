

from operator import or_
from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from fastapi.logger import logger
from typing import Optional
from sqlalchemy import and_, not_, func
from sqlalchemy.orm import Session
from sqlalchemy.sql import delete
from starlette import status
from typing import Annotated
from pydantic import BaseModel
from database import SessionLocal
from models import User, user_lessons
from models import Progress as ProgressModels # sqlalchemy modeli
from models import Lesson as LessonModels # sqlalchemy modeli
from models import Question as QuestionModels # sqlalchemy modeli
from models import Streak as StreakModels # sqlalchemy modeli
from models import Section as SectionModels # sqlalchemy modeli
from models import DailyTask as DailyTaskModels # sqlalchemy modeli
from models import UserQuestion as UserQuestionModels # sqlalchemy modeli
from schemas import Lesson, LessonCreate, LessonUpdate # pydantic modeli
from schemas import Progress, ProgressCreate # pydantic modeli
from schemas import QuestionCreate, QuestionResponse, QuestionUpdate # pydantic modeli
from schemas import UserPublicResponse # pydantic modeli
from schemas import StreakUpdate # pydantic model
from schemas import Section, SectionCreate # pydantic model,
from routers.auth import get_current_user # routers package'daki auth.py dosyasından import ettim   # gerekli endpointlere ekledim..! # authorize için kullanıyorum gerekli olanlara koyuyorum..!
from utils.config import GEMINI_API_KEY
from utils.streak import update_user_streak
import google.generativeai as genai
import json
import logging
from datetime import datetime, timezone, timedelta




router = APIRouter(prefix='/lesson', tags=['Lesson'])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]



class LevelTestAnswer(BaseModel):
    question_id: int
    selected_answer: str


class LevelTestSubmit(BaseModel):
    answers: list[LevelTestAnswer]




@router.get('/lessons', response_model=list[Lesson]) # bütün dersleri görmek için
async def list_lessons(db: db_dependency):
    lessons = db.query(LessonModels).all()
    return [Lesson.model_validate(i) for i in lessons]


@router.post('/users/{user_id}/lessons/{lesson_id}') # kullanıcının ders seçmesi
async def select_lesson(user_id: int, lesson_id: int, db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar ders seçemez.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Bu işlemi yapmaya yetkiniz yok.')

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı veya ders bulunamadı!')

    if lesson in user.lessons:
        return {"message": "Ders zaten seçili."}

    user.lessons.append(lesson) # ders user'a ekleniyor

    first_section = db.query(SectionModels).filter(SectionModels.lesson_id == lesson_id).order_by(SectionModels.order.asc()).first() # section'ın ilk alt bölümünü almak
    if not first_section:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bu ders için bölüm bulunamadı.")

    db_progress = db.query(ProgressModels).filter(
        ProgressModels.user_id == user_id,
        ProgressModels.lesson_id == lesson_id,
        ProgressModels.section_id == first_section.id
    ).first()

    if not db_progress:
        total_questions = db.query(QuestionModels).filter(QuestionModels.section_id == first_section.id).count() # düzeltildi
        db_progress = ProgressModels(
            user_id=user_id,
            lesson_id=lesson_id,
            section_id=first_section.id,
            completed_questions=0,
            total_questions=total_questions,
            completion_percentage=0.0,
            current_subsection='beginner',
            subsection_completion=0
        )

        db.add(db_progress)
        logging.debug(f"Kullanıcı {user_id} için yeni Progress kaydı oluşturuldu: section_id={first_section.id}")

    db.commit()
    return {'message': f"{lesson.title} dersini seçtiniz. İlerleme kaydı oluşturuldu: section: {first_section.id}"}


@router.get('/users/{user_id}/lessons')  # kullanıcının seçtiği dersleri görmek    # admin yetkisine sahip kullanıcılar tüm userların derslerini görebiliyor!
async def get_user_lessons(user_id: int, db:db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Bu işlemi yapmaya yetkiniz yok.')
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı!")
    return {"lessons": [Lesson.model_validate(i) for i in user.lessons]}


@router.delete('/users/{user_id}/lessons/{lesson_id}') # ders takibi bırakma (ilerleme kayıtlı kalıcak)
async def unfollow_lesson(db: db_dependency, user_id: int, lesson_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı veya ders bulunamadı..!")

    if lesson not in user.lessons:
        return {"message": "Dersi zaten seçilmemiş."}
    user.lessons.remove(lesson)
    db.commit()
    return {"message": f"{lesson.title} dersi takibi bırakıldı."}


@router.post('/create', status_code=status.HTTP_201_CREATED, response_model=Lesson) # backend için ders oluşturma (SADECE ADMİNLER)
async def create_lesson(db: db_dependency, lesson: LessonCreate, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler ders oluşturabilir.")
    db_lesson = db.query(LessonModels).filter(LessonModels.title == lesson.title).first()
    if db_lesson:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu başlıkta ders zaten mevcut.")
    new_lesson = LessonModels(**lesson.dict())
    db.add(new_lesson)
    db.commit()
    db.refresh(new_lesson)
    return new_lesson


@router.put('/lessons/{lesson_id}', response_model=Lesson) # !!! SADECE ADMİNLER DERS BİLGİLERİNİ GÜNCELLER !!!
async def update_lesson(db: db_dependency, lesson_id: int, lesson_update: LessonUpdate, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler ders güncelleyebilir.")

    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    if lesson_update.title and lesson_update.title != lesson.title:
        existing_lesson = db.query(LessonModels).filter(LessonModels.title == lesson_update.title).first()
        if existing_lesson:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu başlıkta ders zaten mevcut.")
        lesson.title = lesson_update.title

    if lesson_update.description:
        lesson.description = lesson_update.description

    if lesson_update.category:
        lesson.category = lesson_update.category

    db.commit()
    db.refresh(lesson)
    return lesson


@router.delete('/lessons/{lesson_id}', status_code=status.HTTP_200_OK) # backend için ders silme (SADECE ADMİNLER) # dersi silince veritabanında dersle ilgili her şey siler.
async def delete_lesson(lesson_id: int, db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler ders silebilir.")
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    db.execute(delete(user_lessons).where(user_lessons.c.lesson_id == lesson_id))

    db.query(ProgressModels).filter(ProgressModels.lesson_id == lesson_id).delete()

    db.query(QuestionModels).filter(QuestionModels.lesson_id == lesson_id).delete()

    db.delete(lesson)
    db.commit()
    return {'message': f"{lesson.title} dersi silindi."}


@router.post('/users/{user_id}/lessons/{lesson_id}/progress', response_model=Progress, status_code=status.HTTP_201_CREATED) # progress bar ekleme
async def create_progress(db: db_dependency, user_id: int, lesson_id: int, progress: ProgressCreate, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı veya ders bulunamadı.')

    if lesson not in user.lessons: # dersin user tarafından seçilip seçilmediğinin kontrolü
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu ders kullanıcı tarafından seçilmemiş.")

    first_section = db.query(SectionModels).filter(SectionModels.lesson_id == lesson_id).order_by(SectionModels.order.asc()).first()
    if not first_section:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bu ders için bölüm bulunamadı.")

    db_progress = db.query(ProgressModels).filter(
        ProgressModels.user_id == user_id,
        ProgressModels.lesson_id == lesson_id,
        ProgressModels.section_id == first_section.id
    ).first()

    if db_progress:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu kullanıcı için bu derse ait ilerleme zaten mevcut.")

    total_questions = db.query(QuestionModels).filter(QuestionModels.section_id == first_section.id).count() # düzeltildi

    db_progress = ProgressModels(
        user_id=user_id,
        lesson_id=lesson_id,
        section_id=first_section.id,
        completed_questions=progress.completed_questions,
        total_questions=progress.total_questions,
        completion_percentage=0.0 if progress.total_questions == 0 else (progress.completed_questions / progress.total_questions * 100),
        current_subsection='beginner',
        subsection_completion=0
    )

    db.add(db_progress)
    db.commit()
    db.refresh(db_progress)
    return db_progress


@router.put('/users/{user_id}/lessons/{lesson_id}/progress', response_model=Progress) # progress bar güncelleme
async def update_progress(db: db_dependency, user_id: int, lesson_id: int, progress: ProgressCreate, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı veya ders bulunamadı.')

    if lesson not in user.lessons:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu ders kullanıcı tarafından seçilmemiş.")

    db_progress = db.query(ProgressModels).filter(ProgressModels.user_id == user_id, ProgressModels.lesson_id == lesson_id).first()
    if not db_progress:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bu kullanıcı için bu derse ait ilerleme bulunamadı. Önce ilerleme kaydı oluşturmalısınız.")

    db_progress.completed_questions = progress.completed_questions
    db_progress.total_questions = progress.total_questions
    db_progress.completion_percentage = (progress.completed_questions / progress.total_questions * 100) if progress.total_questions > 0 else 0

    db.commit()
    db.refresh(db_progress)
    return db_progress


@router.get('/users/{user_id}/progress', response_model=list[Progress]) # progress bar görüntüleme  # admin yetkisine sahip kullanıcılar tüm userların progress bar ilerlemesini görebiliyor!
async def get_user_progress(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Bu işlemi yapmaya yetkiniz yok.')
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı bulunamadı.')
    return [Progress.model_validate(i) for i in user.progress]


@router.get('/admin/users/lessons', response_model=list[dict]) # admin tüm userların derslerini görebilir
async def get_all_users_lessons(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler tüm kullanıcıların derslerini görebilir.")
    users = db.query(User).all()
    result = []
    for user in users:
        user_lessons = [
            {
                'id': lesson.id,
                'title': lesson.title,
                'description': lesson.description,
                'category': lesson.category
            }
            for lesson in user.lessons
        ]
        result.append({
            'user_id': user.id,
            'username': user.username,
            'email': user.email,
            'role': user.role,
            'lessons': user_lessons
        })

    return result


@router.get('/admin/users/progress', response_model=list[dict]) # admin tüm userların progress bar ilerlemelerini görebilir
async def get_all_users_progress(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler tüm kullanıcıların ilerlemelerini görebilir.")
    users = db.query(User).all()
    result = []
    for user in users:
        user_progress = [
            Progress.model_validate(progress).dict()
            for progress in user.progress
            if progress.lesson_id is not None
        ]
        result.append({
            'user_id': user.id,
            'username': user.username,
            'email': user.email,
            'role': user.role,
            'progress': user_progress
        })
    return result



# bu kısımda baya bi prompt denedim kodlarda sapıtıyor ayrıca türkçe istersek de sapıtıyor. (promptu ing. verip türkçe istesek de sapıtıyor). şimdilik çoktan seçmeli ancak loopa düşebiliyor..!
# https://aistudio.google.com/app/apikey -> apiyi buradan alıcaz (modeli seçerken ince ayar yapmak lazım)
@router.post('/lessons/{lesson_id}/generate_questions', response_model=list[QuestionResponse])
async def generate_questions(db: db_dependency, lesson_id: int, section_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler sorular üretebilir.")
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    section = db.query(SectionModels).filter(SectionModels.id == section_id, SectionModels.lesson_id == lesson_id).first()
    if not section:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"section_id {section_id} bu ders için bulunamadı.")

    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-2.5-flash')
    if current_user.username == 'admin':
        prompt = f"""
            Generate exactly 6 multiple-choice programming questions for a lesson titled '{lesson.title}' in category '{lesson.category}', specifically for the section titled '{section.title}'.
            Each question must strictly follow this format and include exactly 4 options:
            - Question: [The question text]
            - A: [Option A]
            - B: [Option B]
            - C: [Option C]
            - D: [Option D]
            - Correct Answer: [A, B, C, or D]
            - Level: [beginner, intermediate, advanced]

            Ensure the questions are relevant to the lesson topic '{lesson.title}', category '{lesson.category}', and section topic '{section.title}' (e.g., if section is 'Python'a Giriş', focus on basic Python syntax, variables, etc.).
            Provide clear, concise, and accurate programming questions suitable for all levels (beginner to advanced).
            Do not include any introductory text, additional comments, or explanations.
            Ensure exactly 6 questions are generated, with at least two question per level (beginner, intermediate, advanced).

            Example:
            - Question: What is the correct syntax to print "Hello" in Python?
            - A: print("Hello")
            - B: echo "Hello"
            - C: printf("Hello")
            - D: print['Hello']
            - Correct Answer: A
            - Level: beginner
            """
    else:
        f"""
            Generate exactly 6 multiple-choice programming questions for a lesson titled '{lesson.title}' in category '{lesson.category}', specifically for the section titled '{section.title}' for a {current_user.level} level user.
            Each question must strictly follow this format and include exactly 4 options:
            - Question: [The question text]
            - A: [Option A]
            - B: [Option B]
            - C: [Option C]
            - D: [Option D]
            - Correct Answer: [A, B, C, or D]
            - Level: [beginner, intermediate, advanced]

            Ensure the questions are relevant to the lesson topic '{lesson.title}', category '{lesson.category}', and section topic '{section.title}' (e.g., if section is 'Python'a Giriş', focus on basic Python syntax, variables, etc.).
            For beginner level, focus on basic concepts (e.g., syntax, variables, basic functions).
            For intermediate level, include moderately complex topics (e.g., loops, conditionals, basic data structures).
            For advanced level, include complex topics (e.g., object-oriented programming, advanced algorithms).
            Provide clear, concise, and accurate programming questions. Do not include any introductory text, additional comments, or explanations.
            Ensure exactly 6 questions are generated.

            Example:
            - Question: What is the correct syntax to print "Hello" in Python?
            - A: print("Hello")
            - B: echo "Hello"
            - C: printf("Hello")
            - D: print['Hello']
            - Correct Answer: A
            - Level: beginner
        """
    try:
        response = model.generate_content(prompt)
        response_text = response.text.strip()
    except Exception as err:
        logger.error(f"Gemini API error for lesson_id {lesson_id}, section_id {section_id}: {str(err)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gemini API hatası. {err}")

    questions = []
    current_question = None
    lines = response_text.split("\n")
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if line.startswith("- Question:"):
            if current_question and len(current_question["options"]) == 4 and current_question["correct_answer"] and current_question["level"]:
                questions.append(current_question)
            current_question = {"content": line.replace("- Question:", "").strip(), "options": [], "correct_answer": "", "level": ""}
        elif current_question:
            if line.startswith("- A:"):
                current_question["options"].append(line.replace("- A:", "").strip())
            elif line.startswith("- B:"):
                current_question["options"].append(line.replace("- B:", "").strip())
            elif line.startswith("- C:"):
                current_question["options"].append(line.replace("- C:", "").strip())
            elif line.startswith("- D:"):
                current_question["options"].append(line.replace("- D:", "").strip())
            elif line.startswith("- Correct Answer:"):
                current_question["correct_answer"] = line.replace("- Correct Answer:", "").strip()
            elif line.startswith("- Level:"):
                current_question["level"] = line.replace("- Level:", "").strip()
    if current_question and len(current_question["options"]) == 4 and current_question["correct_answer"] and current_question["level"]:
        questions.append(current_question)

    if len(questions) < 6:
        logger.error(f"Insufficient valid questions parsed for lesson_id {lesson_id}, section_id {section_id}: {len(questions)} questions, expected 5. Response: {response_text}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Yetersiz geçerli soru üretildi: {len(questions)}/6.")

    created_questions = []
    for q in questions:
        if len(q['options']) == 4 and q['correct_answer'] in ['A', 'B', 'C', 'D'] and q['content'] and q['level'] in ['beginner', 'intermediate', 'advanced']:
            question = QuestionModels(
                content=q["content"],
                options=json.dumps(q["options"]),
                correct_answer=q["correct_answer"],
                lesson_id=lesson_id,
                level=q["level"],
                section_id=section_id,
                subsection=q["level"] if q["level"] in ['beginner', 'intermediate', 'advanced'] else 'beginner'
            )
            db.add(question)
            created_questions.append(question)
        else:
            logger.warning(f"Invalid question skipped for lesson_id {lesson_id}, section_id {section_id}: {q}")

    db.commit()

    response_questions = []
    for q in created_questions:
        db.refresh(q)
        response_questions.append(
            QuestionResponse(
                id=q.id,
                content=q.content,
                options=json.loads(q.options),
                correct_answer=q.correct_answer,
                lesson_id=q.lesson_id,
                section_id=q.section_id,
                level=q.level,
                subsection=q.subsection
            )
        )

    if not response_questions:
        logger.error(f"No questions saved to database for lesson_id {lesson_id}, section_id {section_id}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Geçerli soru üretilemedi.")

    return response_questions



@router.post('/users/{user_id}/level-test/{lesson_id}', response_model=dict)
async def level_test(user_id: int, lesson_id: int, db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar seviye belirleme testini yapamaz.")

    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.role == 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin kullanıcıları seviye testi alamaz.")

    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")
    if lesson not in user.lessons:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu dersi seçmediğiniz için bu dersin seviye testini alamazsınız.")

    used_question_id = db.query(UserQuestionModels.question_id).filter(UserQuestionModels.user_id == user_id).subquery() # userın daha önce kullandığı sorular

    questions = [] # seviyeye göre db'den soru çekme (beginner 6, intermediate 8, advanced 6)
    for level, count in [('beginner', 6), ('intermediate', 8), ('advanced', 6)]:
        level_questions = db.query(QuestionModels).filter(
            and_(
                QuestionModels.lesson_id == lesson_id,
                QuestionModels.level == level,
                not_(QuestionModels.id.in_(used_question_id))
            )
        ).order_by(func.random()).limit(count).all()

        if len(level_questions) < count:
            logger.error(f"Yetersiz {level} seviyesi soru: {len(level_questions)}/{count}, lesson_id={lesson_id}")
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Yetersiz {level} seviyesi soru: {len(level_questions)}/{count}. Lütfen daha fazla soru ekleyin.")

        questions.extend(level_questions)


    for question in questions: # sorular UserQuestion'a kaydediliyor
        user_question = UserQuestionModels(
            user_id=user_id,
            question_id=question.id,
            used_at=datetime.now(timezone.utc)
        )
        db.add(user_question)

    db.commit()


    response_questions = [
        {
            "id": q.id,
            "content": q.content,
            "options": json.loads(q.options),
            "correct_answer": q.correct_answer,
            "level": q.level,
            "lesson_id": q.lesson_id,
            "section_id": q.section_id
        } for q in questions
    ]

    logger.debug(
        f"Kullanıcı {user_id} için {len(response_questions)} seviye testi sorusu çekildi: lesson_id={lesson_id}")
    return {"questions": response_questions}


@router.post('/users/{user_id}/level_test/submit', response_model=UserPublicResponse)
async def submit_level_test(db: db_dependency, user_id: int, submission: LevelTestSubmit, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar seviye belirleme testi gönderemez.")

    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.role == 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin kullanıcıları seviye testi gönderemez.")

    correct_count = 0
    lesson_id = None
    for answer in submission.answers:
        question = db.query(QuestionModels).filter(QuestionModels.id == answer.question_id).first()
        if question:
            if not lesson_id:
                lesson_id = question.lesson_id
            if question.correct_answer == answer.selected_answer:
                correct_count += 1

    if not lesson_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Sorulara ait ders bulunamadı.")

    if correct_count <= 6:
        user.level = 'beginner'
    elif 7 <= correct_count <= 14:
        user.level = 'intermediate'
    else:
        user.level = 'advanced'

    user.has_taken_level_test = True

    tasks = db.query(DailyTaskModels).filter(
        DailyTaskModels.user_id == user_id,
        DailyTaskModels.lesson_id == lesson_id,
        DailyTaskModels.task_type == 'take_level_test',
        DailyTaskModels.is_completed == False,
        DailyTaskModels.expires_time > datetime.now(timezone.utc)
    ).all()
    for task in tasks:
        task.current_progress = 1
        task.is_completed = True
        user.health_count = min(user.health_count + 2, 6)
        user.health_count_update_time = datetime.now(timezone.utc)

    db.commit()
    db.refresh(user)
    return user


@router.get('/questions', response_model=list[QuestionResponse]) # belirtilen ders veya bölüme göre soruları getirir. Her ikisi de belirtilirse, hem derse hem bölüme uygun sorular döner  !!!! GÜNCELLEME current_subsection sorugusu da eklendi !!!!
async def get_questions(db: db_dependency, lesson_id: Optional[int] = None, section_id: Optional[int] = None, current_subsection: Optional[str] = None, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar soruları göremez.")

    if not lesson_id and not section_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="En az bir parametre (lesson_id veya section_id) belirtilmeli.")

    if current_subsection and not section_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="section_id belirtilmeden current_subsection belirtilemez.")

    if current_subsection and current_subsection not in ['beginner', 'intermediate', 'advanced']:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Geçersiz current_subsection. Sadece 'beginner', 'intermediate' veya 'advanced' olabilir.")

    query = db.query(QuestionModels)

    if lesson_id:
        query = query.filter(QuestionModels.lesson_id == lesson_id)

    if section_id:
        section = db.query(SectionModels).filter(SectionModels.id == section_id).first()
        if not section:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bölüm bulunamadı.")
        query = query.filter(QuestionModels.section_id == section_id)

    if current_subsection:
        progress = db.query(ProgressModels).filter(ProgressModels.user_id == current_user.id, ProgressModels.section_id == section_id).first()
        if progress and progress.current_subsection != current_subsection:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Bu bölümde alt bölümünüz {progress.current_subsection}. {current_subsection} sorularına erişemezsiniz.")

        answered_correctly = db.query(UserQuestionModels.question_id).filter(UserQuestionModels.user_id == current_user.id, UserQuestionModels.is_correct == True).subquery()

        query = query.filter(or_(QuestionModels.subsection == current_subsection, and_(QuestionModels.subsection.is_(None), QuestionModels.level == current_subsection)),
                                not_(QuestionModels.id.in_(answered_correctly)))

    question_count = query.count()
    logger.debug(f"Lesson ID {lesson_id}, Section ID {section_id}, Subsection {current_subsection} için {question_count} soru bulundu.")

    questions = query.all()

    if not questions:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Belirtilen ders, bölüm veya alt bölüm için uygun soru bulunamadı.")

    return [
        QuestionResponse(
            id=q.id,
            content=q.content,
            options=json.loads(q.options),
            correct_answer=q.correct_answer,
            lesson_id=q.lesson_id,
            section_id=q.section_id,
            level=q.level,
            subsection=q.subsection
        ) for q in questions
    ]


@router.put('/questions/{question_id}', response_model=QuestionResponse)
async def update_question(db: db_dependency, question_update: QuestionUpdate, question_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler soruları güncelleyebilir.")

    question = db.query(QuestionModels).filter(QuestionModels.id == question_id).first()
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Soru bulunamadı.")

    if question_update.content:
        question.content = question_update.content

    if question_update.options:
        question.options = json.dumps(question_update.options)

    if question_update.correct_answer:
        question.correct_answer = question_update.correct_answer

    if question_update.level:
        question.level = question_update.level
        question.subsection = question_update.level

    db.commit()
    db.refresh(question)

    return QuestionResponse(
        id=question.id,
        content=question.content,
        options=json.loads(question.options),
        correct_answer=question.correct_answer,
        lesson_id=question.lesson_id,
        level=question.level
    )


@router.delete('/questions/{question_id}', response_model=dict)
async def delete_question(db: db_dependency, question_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler soruları silebilir.")

    question = db.query(QuestionModels).filter(QuestionModels.id == question_id).first()
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Soru bulunamadı.")

    db.delete(question)
    db.commit()
    return {'message': f"Soru ID {question_id} başarılı bir şekilde silindi."}


@router.put('/users/{user_id}/lessons/{lesson_id}/streak', response_model=dict)
async def update_streak(db: db_dependency, user_id: int, lesson_id: int, current_user: User = Depends(get_current_user), background_tasks: BackgroundTasks = None):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin' and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı veya ders bulunamadı.")

    if lesson not in user.lessons:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Bu ders kullanıcı tarafından seçilmemiş. Lütfen önce dersi seçin.")

    background_tasks.add_task(update_user_streak, db, user_id, lesson_id)

    streak = db.query(StreakModels).filter(StreakModels.user_id == user_id, StreakModels.lesson_id == lesson_id).first()
    if not streak:
        return {'streak_count': 0, 'last_update': None}

    return {'streak_count': streak.streak_count, 'last_update': streak.last_update}


@router.put('/users/{user_id}/lessons/{lesson_id}/streak/admin', response_model=dict)
async def admin_update_streak(db: db_dependency, user_id: int, lesson_id: int, streak_update: StreakUpdate, current_user: User = Depends(get_current_user)):
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar bu işlemi yapamaz.")

    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler streak güncelleyebilir.")

    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı veya ders bulunamadı.")

    streak = db.query(StreakModels).filter(StreakModels.user_id == user_id, StreakModels.lesson_id == lesson_id).first()
    if not streak:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bu kullanıcı için bu derse ait streak bulunamadı.")

    if streak_update.streak_count is not None:
        streak.streak_count = streak_update.streak_count

    if streak_update.last_update:
        streak.last_update = streak_update.last_update

    db.commit()
    db.refresh(streak)
    return {'streak_count': streak.streak_count, 'last_update': streak.last_update}