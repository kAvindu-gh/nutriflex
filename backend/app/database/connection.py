import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

_db = None


def init_firebase():
    """Initialize Firebase Admin SDK and Firestore client."""
    if not firebase_admin._apps:
        key_path = os.getenv("FIREBASE_KEY_PATH", "app/database/firebase_key.json")
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)

    global _db
    _db = firestore.client()
    print(" Firebase Firestore initialized")


def get_db() -> firestore.Client:
    if _db is None:
        raise RuntimeError("Firestore not initialized. Ensure init_firebase() ran at startup.")
    return _db


def get_cart_collection(user_id: str):
    """Path: users/{user_id}/cart/{item_id}"""
    return get_db().collection("users").document(user_id).collection("cart")


def get_promo_collection():
    """Path: promo_codes/{code}"""
    return get_db().collection("promo_codes")