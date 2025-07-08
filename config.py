

from dotenv import load_dotenv
import os

load_dotenv() # .env dosyasını yükler

SECRET_KEY = os.getenv('SECRET_KEY') # signature
ALGORITHM = os.getenv('ALGORITHM', 'HS256') # daha güvenli algoritma kullanabiliriz
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv('ACCES_TOKEN_EXPIRE_MINUTES', 30)) # token'ın geçerlilik süresi 30 dakika istersek değiştirebiliriz
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///./codebite.db')