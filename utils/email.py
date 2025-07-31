

import smtplib
from email.mime.text import MIMEText
from fastapi import HTTPException
from starlette import status
from utils.config import EMAIL_HOST, EMAIL_PORT, EMAIL_ADDRESS, EMAIL_PASSWORD


def send_reset_email(email: str, token: str):
    msg = MIMEText(f'Şifrenizi sıfırlamak için bu linke tıklayın: codebite.com/reset-password?token={token}') # bu kısma flutterdaki yeri yazıcaz
    msg['Subject'] = 'Codebite Şifre Sıfırlama'
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = email

    try:
        with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.sendmail(EMAIL_ADDRESS, email, msg.as_string())
    except Exception as err:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"E-posta gönderilemedi. {err}")