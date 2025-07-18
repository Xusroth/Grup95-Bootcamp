

from fastapi import APIRouter, Depends, HTTPException, Request
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
from schemas import Lesson, LessonCreate # pydantic modeli
from schemas import Progress, ProgressCreate # pydantic modeli
from schemas import QuestionCreate, QuestionResponse # pydantic modeli
from schemas import UserPublicResponse # pydantic modeli
from routers.auth import get_current_user # routers package'daki auth.py dosyasından import ettim   # gerekli endpointlere ekledim..! # authorize için kullanıyorum gerekli olanlara koyuyorum..!
from config import GEMINI_API_KEY
import google.generativeai as genai
import json
import logging




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
    if current_user.role != 'admin' and current_user.id != user_id:
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



@router.post('/users/{user_id}/lessons/{lesson_id}/progress', response_model=Progress) # progress bar ekleme
async def update_progress(db: db_dependency, user_id: int, lesson_id: int, progress: ProgressCreate, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin' and current_user.id != user_id:
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


@router.get('/users/{user_id}/progress', response_model=list[Progress]) # progress bar görüntüleme  # admin yetkisine sahip kullanıcılar tüm userların progress bar ilerlemesini görebiliyor!
async def get_user_progress(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
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
    if current_user.username == 'admin':
        prompt = f"""
            Generate exactly 5 multiple-choice programming questions for a lesson titled '{lesson.title}' in category '{lesson.category}'.
            Each question must strictly follow this format and include exactly 4 options:
            - Question: [The question text]
            - A: [Option A]
            - B: [Option B]
            - C: [Option C]
            - D: [Option D]
            - Correct Answer: [A, B, C, or D]
            - Level: [beginner, intermediate, advanced]

            Ensure the questions are relevant to the lesson topic and category, suitable for all levels (beginner to advanced).
            Provide clear, concise, and accurate programming questions. Do not include any introductory text, additional comments, or explanations.
            Ensure exactly 5 questions are generated, with at least one question per level (beginner, intermediate, advanced).

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
        prompt = f"""
            Generate exactly 5 multiple-choice programming questions for a lesson titled '{lesson.title}' in category '{lesson.category}' for a {current_user.level} level user.
            Each question must strictly follow this format and include exactly 4 options:
            - Question: [The question text]
            - A: [Option A]
            - B: [Option B]
            - C: [Option C]
            - D: [Option D]
            - Correct Answer: [A, B, C, or D]
            - Level: [beginner, intermediate, advanced]

            Ensure the questions are relevant to the lesson topic, category, and user level ({current_user.level}). 
            For beginner level, focus on basic concepts (e.g., syntax, variables, basic functions).
            For intermediate level, include moderately complex topics (e.g., loops, conditionals, basic data structures).
            For advanced level, include complex topics (e.g., object-oriented programming, advanced algorithms).
            Provide clear, concise, and accurate programming questions. Do not include any introductory text, additional comments, or explanations.
            Ensure exactly 5 questions are generated.

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
        logging.error(f"Gemini API error for lesson_id {lesson_id}: {str(err)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gemini API hatası. {err}")

    # response'un parse edilmesi
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

    if len(questions) < 5:
        logging.error(
            f"Insufficient valid questions parsed for lesson_id {lesson_id}: {len(questions)} questions, expected 5. Response: {response_text}")

        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Yetersiz geçerli soru üretildi: {len(questions)}/5.")


    created_questions = []
    for q in questions:
        if len(q["options"]) == 4 and q["correct_answer"] in ["A", "B", "C", "D"] and q["content"] and q["level"] in ["beginner", "intermediate", "advanced"]:
            question = QuestionModels(
                content=q["content"],
                options=json.dumps(q["options"]),
                correct_answer=q["correct_answer"],
                lesson_id=lesson_id,
                level=q["level"]
            )
            db.add(question)
            created_questions.append(question)
        else:
            logging.warning(f"Invalid question skipped for lesson_id {lesson_id}: {q}")

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
                level=q.level
            )
        )

    if not response_questions:
        logging.error(f"No questions saved to database for lesson_id {lesson_id}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Geçerli soru üretilemedi.")

    return response_questions



@router.post('/users/{user_id}/level-test/{lesson_id}', response_model=dict) # seviye tespiti için 10 soruluk test (sonuçlara göre -> beginner/intermediate/advanced) # !!! GÜNCELLENDİ !!!
async def level_test(user_id: int, lesson_id: int, db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    if user.role == 'admin': # admin seviye testi almasın diye yaptım.
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin kullanıcıları seviye testi alamaz.")

    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")
    if lesson not in user.lessons:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu dersi seçmediğiniz için bu dersin seviye testini alamazsınız.")

    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel("gemini-2.5-flash")
    prompt = f"""
    Generate 10 multiple-choice programming questions for a lesson titled '{lesson.title}' in category '{lesson.category}' to assess the programming level of a user (beginner, intermediate, or advanced).
    Each question must strictly follow this format and include exactly 4 options:
    - Question: [The question text]
    - A: [Option A]
    - B: [Option B]
    - C: [Option C]
    - D: [Option D]
    - Correct Answer: [A, B, C, or D]
    - Level: [beginner, intermediate, advanced]
    Ensure questions are relevant to the lesson topic ('{lesson.title}') and category ('{lesson.category}').
    Distribute questions across levels: at least 3 beginner, 4 intermediate, 3 advanced.
    For beginner level, focus on basic concepts (e.g., syntax, variables, basic functions).
    For intermediate level, include moderately complex topics (e.g., loops, conditionals, basic data structures).
    For advanced level, include complex topics (e.g., algorithms, advanced programming concepts).
    Provide clear, concise, and accurate programming questions. Do not include any introductory text, additional comments, or explanations.
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
        logging.info(f"Level test response for user_id {user_id}, lesson_id {lesson_id}:\n{response_text}")
        if not response_text:
            logging.error(f"Gemini API returned empty response for user_id {user_id}, lesson_id {lesson_id}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Gemini API boş yanıt döndürdü.")
    except Exception as err:
        logging.error(f"Gemini API error for user_id {user_id}, lesson_id {lesson_id}: {str(err)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gemini API hatası: {str(err)}")

    # yanıtın parse edilmesi
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

    if not questions:
        logging.error(f"No valid questions parsed for user_id {user_id}: {response_text}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Hiçbir geçerli soru parse edilemedi: {response_text[:200]}...")

        # test sorularını kaydet
    created_questions = []
    for q in questions:
        if len(q["options"]) == 4 and q["correct_answer"] in ["A", "B", "C", "D"] and q["content"] and q["level"] in ["beginner", "intermediate", "advanced"]:
            question = QuestionModels(
                content=q["content"],
                options=json.dumps(q["options"]),
                correct_answer=q["correct_answer"],
                lesson_id=lesson_id,
                level=q["level"]  # seviyeleri kaydetme
            )
            db.add(question)
            created_questions.append(question)
        else:
            logging.warning(f"Invalid question skipped for user_id {user_id}, lesson_id {lesson_id}: {q}")

    db.commit()

    # yanıtın hazırlanması
    response_questions = []
    for q in created_questions:
        db.refresh(q)
        response_questions.append({
            "id": q.id,
            "content": q.content,
            "options": json.loads(q.options),
            "correct_answer": q.correct_answer,
            "level": q.level,
            "lesson_id": q.lesson_id
        })

    if not response_questions:
        logging.error(f"No questions saved to database for user_id {user_id}, lesson_id {lesson_id}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Sorular veritabanına kaydedilemedi.")

    return {"questions": response_questions}


@router.post('/users/{user_id}/level_test/submit', response_model=UserPublicResponse)
async def submit_level_test(db: db_dependency, user_id: int, submission: LevelTestSubmit, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Bu işlemi yapmaya yetkiniz yok.")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı.")

    # admin kullanıcıları seviye testi gönderemesin
    if user.role == 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin kullanıcıları seviye testi gönderemez.")

    correct_count = 0
    for answer in submission.answers:
        question = db.query(QuestionModels).filter(QuestionModels.id == answer.question_id).first()
        if question and question.correct_answer == answer.selected_answer:
            correct_count += 1

    if correct_count <= 4:
        user.level = 'beginner'
    elif correct_count <= 7:
        user.level = 'intermediate'
    else:
        user.level = 'advanced'

    user.has_taken_level_test = True   # kullanıcı teste girdi True döndü
    db.commit()
    db.refresh(user)
    return user


@router.get('/questions/{lesson_id}', response_model=list[QuestionResponse])
async def get_questions_by_lesson(lesson_id: int, db: db_dependency):
    questions = db.query(QuestionModels).filter(QuestionModels.lesson_id == lesson_id).all()
    if not questions:
        raise HTTPException(status_code=404, detail="Bu derse ait soru bulunamadı.")
    
    return [
        QuestionResponse(
            id=q.id,
            content=q.content,
            options=json.loads(q.options),
            correct_answer=q.correct_answer,
            lesson_id=q.lesson_id,
            level=q.level
        ) for q in questions
    ]