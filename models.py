

from sqlalchemy import Column, String, Integer, Float, Boolean, ForeignKey, Table, DateTime, JSON
from database import Base
from sqlalchemy.orm import relationship
from datetime import datetime, timezone, timedelta


# bu kısımda ilişki many to many olucak çünkü birden fazla kullanıcı birden fazla ders alabilir. Ayrıca bu tür many to many ilişkilerde direkt ForeignKey ile bağlamak mümkün olmaz. Bu yüzden ara tablo yaptım
# many-to-many ilişkili ara tablolarda her iki sütun da primary key olarak tanımlanır.


user_lessons = Table(
    'user_lessons',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True, index=True),
    Column('lesson_id', Integer, ForeignKey('lessons.id'), primary_key=True, index=True)
)




class User(Base): # sorguları hızlandırmak için genel olarak hepsinde index=True diyerek index oluşturuldu (böylece select işlemi hızlanır)
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String) # parolanın şifrelenmiş hali
    role = Column(String, default='user') # admin ve kullanıcıyı ayırmak için role bilgisi
    level = Column(String, nullable=True) # beginner, intermediate ve advanced düzeyleri eklendi amaç prompta her kullanıcının seviyesine göre soru generate edilebilsin
    has_taken_level_test = Column(Boolean, default=False) # seviye testine girdi mi girmedi mi kontrolü
    health_count = Column(Integer, default=6) # can hakkı
    health_count_update_time = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)) # can hakkının güncellenme zamanı
    notification_preferences = Column(JSON, default={'email': True, 'push': True}) # bildirim tercihleri
    theme = Column(String, default='dark') # dark, light tema tercihi
    language = Column(String, default='tr') # dil tercihleri (tr, en)
    avatar = Column(String, default='profile_pic.png') # kullanıcının avatar profili resmi

    lessons = relationship('Lesson', secondary='user_lessons', back_populates='users')
    progress = relationship('Progress', back_populates='user')
    error_reports = relationship('ErrorReport', back_populates='user')
    streaks = relationship('Streak', back_populates='user')
    reset_tokens = relationship('PasswordResetToken', back_populates='user')
    daily_tasks = relationship('DailyTask', back_populates='user')
    user_questions = relationship('UserQuestion', back_populates='user')
    refresh_tokens = relationship('RefreshToken', back_populates='user')


class Lesson(Base):
    __tablename__ = 'lessons'

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)
    category = Column(String, nullable=True) # web geliştirme, ai vb.

    users = relationship('User', secondary=user_lessons, back_populates='lessons')
    progress = relationship('Progress', back_populates='lesson')
    questions = relationship('Question', back_populates='lesson')
    streaks = relationship('Streak', back_populates='lesson')
    daily_tasks = relationship('DailyTask', back_populates='lesson')
    sections = relationship('Section', back_populates='lesson', cascade='all, delete-orphan')


class Progress(Base):
    __tablename__ = 'progress'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=False)
    section_id = Column(Integer, ForeignKey('sections.id'), nullable=False) # section_id'yi zorunlu tutuldu yoksa null dönüyor
    completed_questions = Column(Integer, default=0)
    total_questions = Column(Integer, default=0)
    completion_percentage = Column(Float, default=0.0) # tamamlama yüzdesi
    current_subsection = Column(String(20), default='beginner') # geçerli section alt bölümü
    subsection_completion = Column(Integer, default=0) # tamamlanan section alt bölümü

    user = relationship('User', back_populates='progress')
    lesson = relationship('Lesson', back_populates='progress')
    section = relationship('Section', back_populates='progress')


class Question(Base):
    __tablename__ = 'questions'

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String, nullable=False) # soru içeriği
    options = Column(JSON, nullable=False) # şıklar JSON şeklinde saklanıyor ki flutter tarafından parse olabilsin  (JSON tipini denedim)
    correct_answer = Column(String, nullable=False) # doğru şık
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=False, index=True)
    level = Column(String, nullable=True, index=True) # soruların seviyesini saklamak (beginner, intermediate, advanced)
    section_id = Column(Integer, ForeignKey('sections.id'), nullable=False, index=True)
    subsection = Column(String, nullable=False, index=True) # soruları seviyesine göre çekmek için (flutter için)

    lesson = relationship('Lesson', back_populates='questions')
    section = relationship('Section', back_populates='questions')
    used_by = relationship('UserQuestion', back_populates='question')


class ErrorReport(Base):
    __tablename__ = 'error_reports'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=True, index=True)
    error_message = Column(String, nullable=False)
    details = Column(String, nullable=True) # daha açıklayıcı olması için ek detaylar ekledim
    timestamp = Column(DateTime(timezone=True), default=datetime.now(timezone.utc), index=True)
    status = Column(String, default='pending', index=True) # pending, resolved, rejected durumları

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
    expires_time = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc) + timedelta(hours=1), index=True) # lambda kullandım diğer türlü sürekli sabit datetime üretiyor

    user = relationship('User', back_populates='reset_tokens')


class Section(Base):
    __tablename__ = 'sections'

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=False, index=True)
    order = Column(Integer, nullable=False)

    lesson = relationship('Lesson', back_populates='sections')
    questions = relationship('Question', back_populates='section')
    daily_tasks = relationship('DailyTask', back_populates='section')
    progress = relationship('Progress', back_populates='section')


class DailyTask(Base):
    __tablename__ = 'daily_tasks'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey('lessons.id'), nullable=True, index=True)
    section_id = Column(Integer, ForeignKey('sections.id'), nullable=True, index=True)
    task_type = Column(String, nullable=False) # görev tipi
    target = Column(Integer, nullable=False) # hedef (5 soru çöz, 1 section tamamla vb.)
    current_progress = Column(Integer, default=0) # mevcut ilerleme
    is_completed = Column(Boolean, default=False)
    create_time = Column(DateTime(timezone=True), default=datetime.now(timezone.utc), index=True)
    expires_time = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc) + timedelta(days=1), index=True)
    level = Column(String, nullable=True, index=True) # görevlerin seviyesi gibi

    user = relationship('User', back_populates='daily_tasks')
    lesson = relationship('Lesson', back_populates='daily_tasks')
    section = relationship('Section', back_populates='daily_tasks')


class UserQuestion(Base):
    __tablename__ = 'user_questions'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), index=True)
    question_id = Column(Integer, ForeignKey('questions.id'), index=True)
    used_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    is_correct = Column(Boolean, default=False)  # sorunun doğru mu yanlış mı cevaplandığını belirtir buna göre kullanıcı tekrar sorusunu gözden geçirip çözebilir

    user = relationship('User', back_populates='user_questions')
    question = relationship('Question', back_populates='used_by')


class RefreshToken(Base):
    __tablename__ = 'refresh_tokens'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    token = Column(String, nullable=False, index=True)
    created_time = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), index=True)
    expires_time = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc) + timedelta(days=30), index=True) # refresh token geçerlilik süresi (30 gün belirledim)

    user = relationship('User', back_populates='refresh_tokens')