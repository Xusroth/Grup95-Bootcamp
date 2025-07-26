

from dotenv import load_dotenv
import os

load_dotenv() # .env dosyasını yükler

SECRET_KEY = os.getenv('SECRET_KEY') # signature
ALGORITHM = os.getenv('ALGORITHM', 'HS256') # daha güvenli algoritma kullanabiliriz
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv('ACCES_TOKEN_EXPIRE_MINUTES', 30)) # token'ın geçerlilik süresi 10080 dakika (7 gün) istersek değiştirebiliriz
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///./codebite.db')
EMAIL_HOST = os.getenv('EMAIL_HOST')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', 587)) # 587 portu güvenli bağlantıyla e posta göndermek için en yaygın kullanılan port
EMAIL_ADDRESS = os.getenv('EMAIL_ADDRESS')
EMAIL_PASSWORD = os.getenv('EMAIL_PASSWORD')