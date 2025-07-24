

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import Annotated, List
from starlette import status
from sqlalchemy.orm import Session
from database import SessionLocal
from models import User, Lesson as LessonModels, Section as SectionModels, Question as QuestionModels
from schemas import SectionCreate, Section, SectionUpdate, QuestionResponse
from routers.auth import get_current_user
import logging
import json



logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

router = APIRouter(prefix='/sections', tags=['Sections'])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]
user_dependency = Annotated[User, Depends(get_current_user)]

@router.post('/lessons/{lesson_id}/sections', status_code=status.HTTP_201_CREATED, response_model=Section)
async def create_section(db: db_dependency, lesson_id: int, section: SectionCreate, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler section oluşturabilir.")

    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    new_section = SectionModels(
        title=section.title,
        description=section.description,
        lesson_id=lesson_id,
        order=section.order
    )

    db.add(new_section)
    db.commit()
    db.refresh(new_section)
    return new_section


@router.put('/{section_id}', response_model=Section)
async def update_section(section_id: int, section_update: SectionUpdate, db: db_dependency, user: user_dependency):
    if user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece admin kullanıcılar bölüm güncelleyebilir.")

    db_section = db.query(SectionModels).filter(SectionModels.id == section_id).first()
    if not db_section:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bölüm bulunamadı.")

    update_data = section_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_section, key, value)
    db.commit()
    db.refresh(db_section)
    logger.debug(f"Bölüm güncellendi: {db_section.title}, ID: {db_section.id}")
    return db_section


@router.delete('/{section_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_section(section_id: int, db: db_dependency, user: user_dependency):
    if user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece admin kullanıcılar bölüm silebilir.")

    db_section = db.query(SectionModels).filter(SectionModels.id == section_id).first()
    if not db_section:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bölüm bulunamadı.")

    db.delete(db_section)
    db.commit()
    logger.debug(f"Bölüm silindi: ID {section_id}")
    return None


@router.get('/lessons/{lesson_id}/sections', response_model=list[Section])
async def get_sections(db: db_dependency, lesson_id: int):
    lesson = db.query(LessonModels).filter(LessonModels.id == lesson_id).first()
    if not lesson:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ders bulunamadı.")

    sections = db.query(SectionModels).filter(SectionModels.lesson_id == lesson_id).order_by(SectionModels.order).all()
    return [Section.model_validate(i) for i in sections]


@router.get('/sections/{section_id}/questions', response_model=list[QuestionResponse])
async def get_questions_by_section(db: db_dependency, section_id: int, current_user: User = Depends(get_current_user)):
    section = db.query(SectionModels).filter(SectionModels.id == section_id).first()
    if not section:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bölüm bulunamadı.")

    questions = db.query(QuestionModels).filter(QuestionModels.section_id == section_id, QuestionModels.level == current_user.level).all()

    if not questions:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bu bölümde seviyenize uygun soru bulunamadı.")

    return [QuestionResponse(
        id=q.id,
        content=q.content,
        options=json.loads(q.options),
        correct_answer=q.correct_answer,
        lesson_id=q.lesson_id,
        section_id=q.section_id,
        level=q.level
    ) for q in questions]