

from sqlalchemy import Column, String, Integer, Float, Boolean, ForeignKey, Table
from database import Base
from sqlalchemy.orm import relationship

# bu kısımda ilişki many to many olucak çünkü birden fazla kullanıcı birden fazla ders alabilir. Ayrıca bu tür many to many ilişkilerde direkt ForeignKey ile bağlamak mümkün olmaz. Bu yüzden ara tablo yaptım.   # many-to-many ilişkili ara tablolarda her iki sütun da primary key olarak tanımlanır.


user_lessons = Table(
    'user_lessons',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True, index=True),
    Column('lesson_id', Integer, ForeignKey('lessons.id'), primary_key=True, index=True)
)



class Progress(Base):
    __tablename__ = 'progress'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), index=True)
    lesson_id = Column(Integer, ForeignKey('lessons.id'), index=True)
    completed_questions = Column(Integer, default=0)
    total_questions = Column(Integer, default=0)
    completion_percentage = Column(Float, default=0.0)

    user = relationship('User', back_populates='progress')
    lesson = relationship('Lesson', back_populates='progress')


class Question(Base):
    __tablename__ = 'questions'

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String, nullable=False) # soru içeriği
    options = Column(String, nullable=False) # şıklar JSON şeklinde saklanıyor ki flutter tarafından parse olabilsin
    correct_answer = Column(String, nullable=False) # doğru şık
    lesson_id = Column(Integer, ForeignKey('lessons.id'), index=True)
    level = Column(String, nullable=True, index=True) # soruların seviyesini saklamak (beginner, intermediate, advanced)

    lesson = relationship('Lesson', back_populates='questions')


class Lesson(Base):
    __tablename__ = 'lessons'

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)
    category = Column(String, nullable=True) # web geliştirme, ai vb.

    users = relationship('User', secondary=user_lessons, back_populates='lessons')
    progress = relationship('Progress', back_populates='lesson')
    questions = relationship('Question', back_populates='lesson') # one to many ilişki


class User(Base): # sorguları hızlandırmak için genel olarak hepsinde index=True diyerek index oluşturdum (böylece select işlemi hızlanır)
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String) # parolanın şifrelenmiş hali
    role = Column(String, default='user', index=True) # admin ve kullanıcıyı ayırmak için role ekledim
    level = Column(String, nullable=True, index=True) # şimdilik beginner, intermediate ve advanced düzeyleri ekledim maksat prompta kullanıcı seviyesine göre soru generate edebilelim
    has_taken_level_test = Column(Boolean, default=False, index=True) # seviye testine girdi mi girmedi mi onun kontrolü

    lessons = relationship('Lesson', secondary=user_lessons, back_populates='users')
    progress = relationship('Progress', back_populates='user')