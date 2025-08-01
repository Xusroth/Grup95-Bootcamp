

import smtplib
from email.mime.text import MIMEText
from fastapi import HTTPException
from starlette import status
from utils.config import EMAIL_HOST, EMAIL_PORT, EMAIL_ADDRESS, EMAIL_PASSWORD


def send_reset_email(email: str, token: str):
    redirect_link = f'https://codebite-backend.onrender.com/auth/reset-redirect?token={token}'
    deeplink = f'codebite://reset-password?token={token}'
    plain_content = f"""
        Merhaba,
        
        Şifrenizi sıfırlamak için aşağıdaki bağlantıya tıklayın:
        {redirect_link}
        
        Bağlantı çalışmazsa, yukarıdaki linki kopyalayıp tarayıcınıza veya uygulamanıza yapıştırın.
        Bu bağlantı 1 saat boyunca geçerlidir. Eğer bu talebi siz yapmadıysanız, lütfen bu e-postayı dikkate almayın.
        
        Codebite Ekibi
    """

    msg = MIMEText(plain_content, 'plain')
    msg['Subject'] = 'Codebite Şifre Sıfırlama'
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = email

    try:
        with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.sendmail(EMAIL_ADDRESS, email, msg.as_string())

    except Exception as err:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"E-posta gönderilemedi: {err}")