import firebase_admin
from firebase_admin import credentials, firestore
import os

_db = None


def get_firebase_db():
    global _db
    if _db is None:
        cred_path = os.getenv("FIREBASE_KEY_PATH", "app/database/firebase_key.json")
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
    return _db