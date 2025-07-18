

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import Annotated
from database import SessionLocal
from starlette import status
from models import ErrorReport, User
from schemas import ErrorReportCreate, ErrorReportResponse
from routers.auth import get_current_user

router = APIRouter(prefix='/error', tags=['Error Reporting'])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


db_dependency = Annotated[Session, Depends(get_db)]


@router.post('/report', status_code=status.HTTP_201_CREATED, response_model=ErrorReportResponse)
async def report_error(db: db_dependency, report: ErrorReportCreate, current_user: User = Depends(get_current_user)):
    try:
        db_report = ErrorReport(
            user_id=report.user_id or (current_user.id if current_user else None),
            error_message=report.error_message,
            details=report.details
        )

        db.add(db_report)
        db.commit()
        db.refresh(db_report)
        return db_report

    except Exception as err:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Hata loglara kayıt edilemedi. {err}")


@router.get('/reports', response_model=list[ErrorReportResponse])
async def get_error_reports(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler hata raporlarını görebilir.")
    reports = db.query(ErrorReport).all()
    return reports