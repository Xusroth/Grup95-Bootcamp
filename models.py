

from sqlalchemy import Column, String, Integer, Float, Boolean, ForeignKey, Table, DateTime
from database import Base
from sqlalchemy.orm import relationship
from datetime import datetime, timezone, timedelta


# bu kısımda ilişki many to many olucak çünkü birden fazla kullanıcı birden fazla ders alabilir. Ayrıca bu tür many to many ilişkilerde direkt ForeignKey ile bağlamak mümkün olmaz. Bu yüzden ara tablo yaptım.   # many-to-many ilişkili ara tablolarda her iki sütun da primary key olarak tanımlanır.


user_lessons = Table(
    'user_lessons',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True, index=True),
    Column('lesson_id', Integer, ForeignKey('lessons.id'), primary_key=True, index=True)
)




class User(Base): # sorguları hızlandırmak için genel olarak hepsinde index=True diyerek index oluşturdum (böylece select işlemi hızlanır)
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String) # parolanın şifrelenmiş hali
    role = Column(String, default='user') # admin ve kullanıcıyı ayırmak için role ekledim
    level = Column(String, nullable=True) # şimdilik beginner, intermediate ve advanced düzeyleri ekledim maksat prompta kullanıcı seviyesine göre soru generate edebilelim
    has_taken_level_test = Column(Boolean, default=False) # seviye testine girdi mi girmedi mi onun kontrolü

    lessons = relationship('Lesson', secondary='user_lessons', back_populates='users')
    progress = relationship('Progress', back_populates='user')
    error_reports = relationship('ErrorReport', back_populates='user')
    streaks = relationship('Streak', back_populates='user')
    reset_tokens = relationship('PasswordResetToken', back_populates='user')


class Lesson(Base):
    __tablename__ = 'lessons'

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)
    category = Column(String, nullable=True) # web geliştirme, ai vb.

    users = relationship('User', secondary=user_lessons, back_populates='lessons')
    progress = relationship('Progress', back_populates='lesson')
    questions = relationship('Question', back_populates='lesson') # one to many ilişki
    streaks = relationship('Streak', back_populates='lesson')


class Progress(Base):
    __tablename__ = 'progress'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=False)
    completed_questions = Column(Integer, nullable=True)
    total_questions = Column(Integer, nullable=True)
    completion_percentage = Column(Float, default=0.0) # tamamlama yüzdesi

    user = relationship('User', back_populates='progress')
    lesson = relationship('Lesson', back_populates='progress')


class Question(Base):
    __tablename__ = 'questions'

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String, nullable=False) # soru içeriği
    options = Column(String, nullable=False) # şıklar JSON şeklinde saklanıyor ki flutter tarafından parse olabilsin
    correct_answer = Column(String, nullable=False) # doğru şık
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=False, index=True)
    level = Column(String, nullable=True, index=True) # soruların seviyesini saklamak (beginner, intermediate, advanced)

    lesson = relationship('Lesson', back_populates='questions')


class ErrorReport(Base): # error report feedback kısmı için
    __tablename__ = 'error_reports'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=True, index=True)
    error_message = Column(String, nullable=False)
    details = Column(String, nullable=True) # daha açıklayıcı olması için ek detaylar ekledim (duruma göre kaldırırız) !!
    timestamp = Column(DateTime(timezone=True), default=datetime.now(timezone.utc), index=True)
    status = Column(String, default='pending', index=True) # pending, resolved, rejected vb. durumlar (şimdilik bu üçü var)

    user = relationship('User', back_populates='error_reports')


class Streak(Base):
    __tablename__ = 'streaks'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=False, index=True)
    streak_count = Column(Integer, default=0)
    last_update = Column(DateTime(timezone=True), default=datetime.now(timezone.utc), index=True) # kullanıcıyı takip etmesi için günlük datetime eklendi

    user = relationship('User', back_populates='streaks')
    lesson = relationship('Lesson', back_populates='streaks')


class PasswordResetToken(Base):
    __tablename__ = 'password_reset_tokens'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    token = Column(String, nullable=False, index=True)
    created_time = Column(DateTime(timezone=True), default=datetime.now(timezone.utc), index=True)
    expires_time = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc) + timedelta(hours=1), index=True) # lambda kullandım çünkü özel fonksiyon kullanılmazsa sabit zaman üretiyor

    user = relationship('User', back_populates='reset_tokens')