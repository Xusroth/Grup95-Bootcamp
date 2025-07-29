

from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')
SECRET_KEY = os.getenv('SECRET_KEY') # signature
ALGORITHM = os.getenv('ALGORITHM', 'HS256') # güvenlik algoritması
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv('ACCESS_TOKEN_EXPIRE_MINUTES', 30)) # token'ın geçerlilik süresi
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
EMAIL_HOST = os.getenv('EMAIL_HOST')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', 587)) # 587 portu güvenli bağlantıyla e posta göndermek için en yaygın kullanılan port
EMAIL_ADDRESS = os.getenv('EMAIL_ADDRESS')
EMAIL_PASSWORD = os.getenv('EMAIL_PASSWORD')