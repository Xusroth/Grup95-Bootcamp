

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from starlette import status
from typing import Annotated
from database import SessionLocal
from models import User
from models import Progress as ProgressModels # sqlalchemy modeli
from models import Lesson as LessonModels # sqlalchemy modeli
from models import Question as QuestionModels # sqlalchemy modeli
from schemas import Lesson, LessonCreate # pydantic modeli
from schemas import Progress, ProgressCreate # pydantic modeli
from schemas import QuestionCreate, QuestionResponse # pydantic modeli
from routers.auth import get_current_user # routers package'daki auth.py dosyasından import ettim   # gerekli endpointlere ekledim..! # authorize için kullanıyorum gerekli olanlara koyuyorum..!
from config import GEMINI_API_KEY
import google.generativeai as genai
import json




router = APIRouter(prefix='/lesson', tags=['Lesson'])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]



@router.get('/lessons', response_model=list[Lesson]) # bütün dersleri görmek için
async def list_lessons(db: db_dependency):
    lessons = db.query(LessonModels).all()
    return [Lesson.model_validate(i) for i in lessons]


@router.post('/users/{user_id}/lessons/{lesson_id}') # kullanıcının ders seçmesi
async def select_lesson(user_id: int, lesson_id: int, db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Bu işlemi yapmaya yetkiniz yok.')
    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı veya ders bulunamadı!')
    if lesson in user.lessons:
        return {"message": "Ders zaten seçili."}
    user.lessons.append(lesson)
    db.commit()
    return {"message": f"{lesson.title} dersini seçtiniz."}


@router.get('/users/{user_id}/lessons')  # kullanıcının seçtiği dersleri görmek
async def get_user_lessons(user_id: int, db:db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Bu işlemi yapmaya yetkiniz yok.')
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı!")
    return {"lessons": [Lesson.model_validate(i) for i in user.lessons]}


@router.delete('/users/{user_id}/lessons/{lesson_id}') # ders takibi bırakma (ilerleme kayıtlı kalıcak)
async def unfollow_lesson(db: db_dependency, user_id: int, lesson_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
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


@router.post('/users/{user_id}/lessons/{lesson_id}/progress', response_model=Progress) # progress bar ekleme
async def update_progress(db: db_dependency, user_id: int, lesson_id: int, progress: ProgressCreate, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")
    user = db.query(User).filter(User.id == user_id).first()
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not user or not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı veya ders bulunamadı.')

    db_progress = db.query(ProgressModels).filter(ProgressModels.user_id == user_id, ProgressModels.lesson_id == lesson_id).first()
    if not db_progress:
        db_progress = ProgressModels(user_id=user_id, lesson_id=lesson_id, **progress.dict())
        db.add(db_progress)
    else:
        db_progress.completed_questions = progress.completed_questions
        db_progress.total_questions = progress.total_questions

    db_progress.completion_percentage = (progress.completed_questions / progress.total_questions * 100) if progress.total_questions > 0 else 0
    db.commit()
    db.refresh(db_progress)
    return db_progress


@router.get('/users/{user_id}/progress', response_model=list[Progress]) # progress bar görüntüleme
async def get_user_progress(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
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
            {
                'id': progress.id,
                'lesson_id': progress.lesson_id,
                'completed_questions': progress.completed_questions,
                'total_questions': progress.total_questions,
                'progress_percentage': (progress.completed_questions / progress.total_questions * 100) if progress.total_questions > 0 else 0
            }
            for progress in user.progress
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
@router.post('/lessons/{lesson_id}/generate_questions', response_model=list[QuestionResponse]) # burada mecbur çoktan seçmeli şeklinde verdim diğer türlü gemini patlıyor
async def generate_questions(db: db_dependency, lesson_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler sorular üretebilir.")
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    # google genai kısmı
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-2.5-flash') # gemini modelini seçip belirlicez
    prompt = f"""
    Generate exactly 5 multiple-choice programming questions for a lesson titled {lesson.title} in category {lesson.category}.
    Each question must strictly follow this format and include exactly 4 options:
    - Question: [The question text]
    - A: [Option A]
    - B: [Option B]
    - C: [Option C]
    - D: [Option D]
    - Correct Answer: [A, B, C, or D]

    Ensure the questions are relevant to the lesson topic and category. Provide clear, concise, and accurate programming questions. Do not include any introductory text or additional comments.

    Example:
    - Question: What is the correct syntax to print "Hello" in Python?
    - A: print("Hello")
    - B: echo "Hello"
    - C: printf("Hello")
    - D: print['Hello']
    - Correct Answer: A
    """
    try:
        response = model.generate_content(prompt)
        response_text = response.text.strip()
    except Exception as err:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gemini API hatası. {err}")

    # response'un parse edilmesi
    questions = []
    current_question = {}
    lines = response_text.split("\n")
    for i in lines:
        i = i.strip()
        if i.startswith("- Question:"):
            if current_question:
                questions.append(current_question)
            current_question = {"content": i.replace("- Question:", "").strip(), "options": [], "correct_answer": ""}
        elif i.startswith("- A:"):
            current_question["options"].append(i.replace("- A:", "").strip())
        elif i.startswith("- B:"):
            current_question["options"].append(i.replace("- B:", "").strip())
        elif i.startswith("- C:"):
            current_question["options"].append(i.replace("- C:", "").strip())
        elif i.startswith("- D:"):
            current_question["options"].append(i.replace("- D:", "").strip())
        elif i.startswith("- Correct Answer:"):
            current_question["correct_answer"] = i.replace("- Correct Answer:", "").strip()
    if current_question:
        questions.append(current_question)

    # veritabanına kaydedilir
    created_questions = []
    for i in questions:
        if len(i["options"]) == 4 and i["correct_answer"] in ["A", "B", "C", "D"] and i["content"]:
            question = QuestionModels(
                content=i["content"],
                options=json.dumps(i["options"]),
                correct_answer=i["correct_answer"],
                lesson_id=lesson_id
            )
            db.add(question)
            created_questions.append(question)
    db.commit()

    # JSON stringleri list[str] formatına çevirerek yanıt oluşturulur
    response_questions = []
    for i in created_questions:
        db.refresh(i)
        response_questions.append(
            QuestionResponse(
                id=i.id,
                content=i.content,
                options=json.loads(i.options),  # JSON string'i listeye çevirme
                correct_answer=i.correct_answer,
                lesson_id=i.lesson_id
            )
        )

    if not response_questions:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Geçerli soru üretilemedi.")

    return response_questions