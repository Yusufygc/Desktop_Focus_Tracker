"""
Base repository sınıfı. Tüm repository'ler bu sınıftan türemelidir.
"""
from abc import ABC
from app.core.database import Database

class BaseRepository(ABC):
    def __init__(self, db: Database):
        self.db = db
