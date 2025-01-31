# utils/password_utils.py
from argon2 import PasswordHasher


class PasswordServive:
    def __init__(self):
        self.ph = PasswordHasher()

    def hash_password(self, password: str) -> str:
        return self.ph.hash(password)

    def verify_password(self, password: str, stored_hash: str) -> bool:
        try:
            return self.ph.verify(stored_hash, password)
        except Exception:
            return False
