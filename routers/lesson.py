

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from starlette import status
from typing import Annotated, List
from database import SessionLocal
from models import User
from models import Progress as ProgressModels # sqlalchemy modeli
from models import Lesson as LessonModels # sqlalchemy modeli
from schemas import Lesson, LessonCreate # pydantic modeli
from schemas import Progress, ProgressCreate # pydantic modeli
from routers.auth import get_current_user # routers package'daki auth.py dosyasından import ettim   # gerekli endpointlere ekledim..! # authorize için kullanıyorum gerekli olanlara koyuyorum..!


router = APIRouter(prefix='/lesson', tags=['Lesson'])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]



@router.get('/lessons', response_model=List[Lesson]) # bütün dersleri görmek için
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


@router.get('/users/{user_id}/progress', response_model=List[Progress]) # progress bar görüntüleme
async def get_user_progress(db: db_dependency, user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail='Bu işlemi yapmaya yetkiniz yok.')
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Kullanıcı bulunamadı.')
    return [Progress.model_validate(i) for i in user.progress]


@router.get('/admin/users/lessons', response_model=List[dict]) # admin tüm userların derslerini görebilir
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


@router.get('/admin/users/progress', response_model=List[dict]) # admin tüm userların progress bar ilerlemelerini görebilir
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
