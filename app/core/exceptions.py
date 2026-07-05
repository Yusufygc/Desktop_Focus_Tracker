"""
Özel exception sınıfları.
"""

class FocusTrackerException(Exception):
    """Temel uygulama hatası."""
    pass

class DatabaseError(FocusTrackerException):
    """Veritabanı işlemleri sırasında oluşan hatalar."""
    pass

class SessionError(FocusTrackerException):
    """Seans işlemleriyle ilgili hatalar."""
    pass

class ValidationError(FocusTrackerException):
    """Veri doğrulama hataları."""
    pass
