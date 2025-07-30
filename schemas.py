

from typing import Optional, Dict
from datetime import datetime
import re
from pydantic import BaseModel, Field, field_validator, EmailStr

# re -> metinlerde regex ile desen arama ve tanımlama için re kütüphanesini kullandım
# EmailStr -> input olan string'in geçerli bir e-posta adresi olup olmadığını kontrol eder
# field_validator -> belirli alanlara özel doğrulama ve iş kuralları tanımlar



# user
class UserRegister(BaseModel):
    username: str = Field(max_length=60)
    email: EmailStr
    password: str = Field(min_length=8)

    @field_validator('username', mode='before')
    def username_kontrol(username):
        if not re.match(r'^[a-zA-Z0-9_]+$', username):
            raise ValueError('Username sadece harf, rakam ve alt çizgi içerebilir.')
        return username

    @field_validator('email', mode='before')
    def eposta_kontrol(value):
        mail_types = ['@gmail.com', '@outlook.com', '@hotmail.com', '@yahoo.com', '@icloud.com']
        if not any(value.endswith(i) for i in mail_types):
            raise ValueError('Geçersiz E-posta adresi. Lütfen tekrar deneyiniz.')
        return value

    @field_validator('password', mode='before')
    def password_kontrol(password):
        if not re.search(r'[A-Z]', password):
            raise ValueError('Şifre en az bir büyük harf içermeli.')
        if not re.search(r'[a-z]', password):
            raise ValueError('Şifre en az bir küçük harf içermeli.')
        if not re.search(r'\d', password):
            raise ValueError('Şifre en az bir rakam içermeli.')
        return password


class UserLogin(BaseModel):
    username: str # fastapi'den dolayı email kısmını değiştirdim. username alanına siz authorize kısmında email yazın
    password: str


class NotificationPreferences(BaseModel):
    email: bool
    push: bool

    @field_validator('email', 'push')
    def check_boolean(value):
        if not isinstance(value, bool):
            raise ValueError("Bildirim tercihi boolean olmalı.")
        return value


class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, max_length=60)
    email: Optional[EmailStr] = None
    level: Optional[str] = None
    notification_preferences: Optional[NotificationPreferences] = None
    theme: Optional[str] = None
    language: Optional[str] = None
    avatar: Optional[str] = None

    @field_validator('username', mode='before')
    def username_kontrol(username):
        if username and not re.match(r'^[a-zA-Z0-9_]+$', username):
            raise ValueError('Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir.')
        return username

    @field_validator('email', mode='before')
    def eposta_kontrol(value):
        if value:
            mail_types = ['@gmail.com', '@outlook.com', '@hotmail.com', '@yahoo.com', '@icloud.com']
            if not any(value.endswith(i) for i in mail_types):
                raise ValueError('Geçersiz e-posta adresi. Lütfen tekrar deneyiniz.')
        return value

    @field_validator('level', mode='before')
    def level_kontrol(value):
        if value and value not in ['beginner', 'intermediate', 'advanced']:
            raise ValueError('Seviye beginner, intermediate veya advanced olmalı.')
        return value

    @field_validator('avatar', mode='before')
    def avatar_kontrol(value):
        if value:
            # Avatar dosya adı kontrolü
            valid_avatars = [
                'profile_pic.png', 'avatar_boom.png', 'avatar_cat.png', 'avatar_cleaner.png',
                'avatar_coder.png', 'avatar_cool.png', 'avatar_cowbot.png', 'avatar_fairy.png',
                'avatar_frog.png', 'avatar_alien.png', 'avatar_astrout.png', 'avatar_robot.png',
                'avatar_robot_2.png', 'avatar_rock.png', 'avatar_sleepy.png', 'avatar_supergirl.png',
                'avatar_turtle.png', 'avatar_vampire.png', 'avatar_wizard.png'
            ]
            if value not in valid_avatars:
                raise ValueError('Geçersiz avatar seçimi.')
        return value


class AvatarUpdate(BaseModel):
    avatar: str = Field(..., description="Seçilen avatar dosya adı")

    @field_validator('avatar')
    def avatar_kontrol(value):
        valid_avatars = [
            'profile_pic.png', 'avatar_boom.png', 'avatar_cat.png', 'avatar_cleaner.png',
            'avatar_coder.png', 'avatar_cool.png', 'avatar_cowbot.png', 'avatar_fairy.png',
            'avatar_frog.png', 'avatar_alien.png', 'avatar_astrout.png', 'avatar_robot.png',
            'avatar_robot_2.png', 'avatar_rock.png', 'avatar_sleepy.png', 'avatar_supergirl.png',
            'avatar_turtle.png', 'avatar_vampire.png', 'avatar_wizard.png'
        ]

        if not value.endswith(('.png', '.jpg', '.jpeg')):
            value = f"{value}.png"
            
        if value not in valid_avatars:
            raise ValueError('Geçersiz avatar seçimi.')
        return value


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    role: str
    level: Optional[str] = None
    has_taken_level_test: bool
    notification_preferences: NotificationPreferences
    theme: str
    language: str
    avatar: str

    class Config:
        from_attributes = True


class UserPublicResponse(BaseModel): # bu sınıfın oluşturulma sebebi kullanıcıya role kısmının gözükmesini önlemek
    id: int
    username: str
    email: str
    level: Optional[str] = None
    role : str
    has_taken_level_test: bool
    health_count: int
    health_count_update_time: datetime
    notification_preferences: NotificationPreferences
    theme: str
    language: str
    avatar: str = "profile_pic.png"

    class Config:
        from_attributes = True



# lesson
class LessonBase(BaseModel):
    title: str
    description: str
    category: str


class LessonCreate(LessonBase):
    pass


class Lesson(LessonBase):
    id: int

    class Config:
        from_attributes = True


class LessonUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None



# progress
class ProgressCreate(BaseModel):
    completed_questions: int = 0
    total_questions: int = 0


class Progress(ProgressCreate):
    id: int
    user_id: int
    lesson_id: int
    completed_questions: int
    total_questions: int
    completion_percentage: float

    class Config:
        from_attributes = True


class ProgressResponse(BaseModel):
    id: int
    user_id: int
    lesson_id: int
    section_id: Optional[int]
    completed_questions: int
    total_questions: int
    completion_percentage: float
    current_subsection: str
    subsection_completion: int

    class Config:
        from_attributes = True



# question
class QuestionCreate(BaseModel):
    content: str
    options: list[str]
    correct_answer: str
    lesson_id: int
    section_id: int
    level: str


class QuestionUpdate(BaseModel):
    content: Optional[str] = None
    options: Optional[list[str]] = None
    correct_answer: Optional[str] = None
    section_id: Optional[int] = None
    level: Optional[str] = None

    @field_validator('options', mode='before')
    def options_kontrol(options):
        if options and len(options) != 4:
            raise ValueError('Seçenekler tam olarak 4 tane olmalı.')
        return options

    @field_validator('correct_answer', mode='before')
    def correct_answer_kontrol(correct_answer):
        if correct_answer and correct_answer not in ['A', 'B', 'C', 'D']:
            raise ValueError('Doğru cevap A, B, C veya D olmalı.')
        return correct_answer

    @field_validator('level', mode='before')
    def level_kontrol(value):
        if value and value not in ['beginner', 'intermediate', 'advanced']:
            raise ValueError('Seviye beginner, intermediate veya advanced olmalı.')
        return value


class QuestionResponse(BaseModel):
    id: int
    content: str
    options: list[str]
    correct_answer: str
    lesson_id: int
    section_id: int
    level: str
    subsection: str

    class Config:
        from_attributes = True



# error
class ErrorReportCreate(BaseModel):
    error_message: str = Field(min_length=1)
    details: Optional[str] = None


class ErrorReportUpdate(BaseModel):
    error_message: Optional[str] = None
    details: Optional[str] = None
    status: Optional[str] = None

    @field_validator('status', mode='before')
    def status_kontrol(value):
        if value and value not in ['pending', 'resolved', 'rejected']:
            raise ValueError('Durum pending, resolved veya rejected olmalı.')
        return value


class ErrorReportResponse(BaseModel):
    id: int
    user_id: Optional[int]
    error_message: str
    details: Optional[str]
    timestamp: datetime

    class Config:
        from_attributes = True



# streak
class StreakUpdate(BaseModel):
    streak_count: Optional[int] = None
    last_update: Optional[datetime] = None


class StreakResponse(BaseModel):
    user_id: int
    username: str
    lesson_id: int
    title: str
    streak_count: int
    last_update: Optional[datetime]

    class Config:
        from_attributes = True



# password resetleme
class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordReset(BaseModel):
    token: str
    new_password: str = Field(min_length=8)

    @field_validator('new_password', mode='before')
    def password_kontrol(password):
        if not re.search(r'[A-Z]', password):
            raise ValueError('Şifre en az bir büyük harf içermeli.')
        if not re.search(r'[a-z]', password):
            raise ValueError('Şifre en az bir küçük harf içermeli.')
        if not re.search(r'\d', password):
            raise ValueError('Şifre en az bir rakam içermeli.')
        return password


class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str



# section kısmı
class SectionBase(BaseModel):
    title: str
    description: Optional[str] = None
    lesson_id : int
    order: int  # bölüm sırası


class SectionCreate(SectionBase):
    pass


class Section(SectionBase):
    id: int

    class Config:
        from_attributes = True


class SectionUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    order: Optional[int] = None



# daily task
class DailyTaskCreate(BaseModel):
    task_type: str
    target: int
    lesson_id: Optional[int] = None
    section_id: Optional[int] = None
    level: Optional[str] = None


class DailyTaskUpdate(BaseModel):
    current_progress: Optional[int] = None
    is_completed: Optional[bool] = None


class DailyTaskResponse(BaseModel):
    id: int
    user_id: int
    lesson_id: Optional[int]
    section_id: Optional[int]
    task_type: str
    target: int
    current_progress: int
    is_completed: bool
    create_time: datetime
    expires_time: datetime
    level: Optional[str]

    class Config:
        from_attributes = True


class AnswerQuestionRequest(BaseModel):
    question_id: int
    user_answer: str



# refresh token
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str