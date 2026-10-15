"""
FocusTracker formatlama yardımcı modülü.
"""


def format_duration(seconds: int, compact: bool = False) -> str:
    """
    Saniyeyi 'X sa Y dk' veya compact=True ise 'Xsa Ydk' formatına çevirir.
    Negatif değerler sıfıra yuvarlanır.
    """
    total_sec = max(0, int(seconds))
    hours, rem = divmod(total_sec, 3600)
    minutes = rem // 60

    if compact:
        if hours > 0:
            return f"{hours}sa {minutes}dk"
        return f"{minutes}dk"

    if hours > 0:
        return f"{hours} sa {minutes} dk"
    return f"{minutes} dk"
