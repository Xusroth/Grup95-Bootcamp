

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import Annotated
from database import SessionLocal
from starlette import status
from models import ErrorReport, User
from schemas import ErrorReportCreate, ErrorReportResponse, ErrorReportUpdate
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
    if current_user.role == 'guest':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Misafir kullanıcılar hata raporu oluşturamaz.")

    if not current_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Hata raporu oluşturmak için oturum açmış olmalısınız.")

    try:
        db_report = ErrorReport(
            user_id=current_user.id,
            error_message=report.error_message,
            details=report.details
        )

        db.add(db_report)
        db.commit()
        db.refresh(db_report)
        return db_report

    except Exception as err:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Hata kayıt edilemedi. {err}")


@router.get('/my_reports', response_model=list[ErrorReportResponse]) # kullanıcı kendi oluşturduğu reportları görebilir
async def get_my_error_reports(db: db_dependency, current_user: User = Depends(get_current_user)):
    reports = db.query(ErrorReport).filter(ErrorReport.user_id == current_user.id).all()
    return reports


@router.get('/reports', response_model=list[ErrorReportResponse])
async def get_error_reports(db: db_dependency, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler hata raporlarını görebilir.")

    reports = db.query(ErrorReport).all()
    return reports


@router.put('/reports/{report_id}', response_model=ErrorReportResponse)
async def update_error_report(db: db_dependency, report_id: int, report_update: ErrorReportUpdate, current_user: User = Depends(get_current_user)):
    if current_user.role != 'admin':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sadece adminler hata raporlarını güncelleyebilir.")

    report = db.query(ErrorReport).filter(ErrorReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hata raporu bulunamadı.")

    if report_update.error_message:
        report.error_message = report_update.error_message

    if report_update.details:
        report.details = report_update.details

    if report_update.status:
        report.status = report_update.status

    db.commit()
    db.refresh(report)
    return report