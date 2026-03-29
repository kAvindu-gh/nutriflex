import os
import json
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

_db = None


def init_firebase():
    """Initialize Firebase Admin SDK. Called once at app startup via lifespan."""
    global _db
    if not firebase_admin._apps:
        firebase_key_json = os.getenv("FIREBASE_KEY_JSON")
        if firebase_key_json:
            # Railway: load from environment variable
            key_json = json.loads(firebase_key_json)
            cred = credentials.Certificate(key_json)
        else:
            # Local: load from file path
            key_path = os.getenv("FIREBASE_KEY_PATH", "app/database/firebase_key.json")
            cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    _db = firestore.client()
    print("Firebase Firestore initialized !")


def get_db() -> firestore.Client:
    """Generic Firestore client — used by most services."""
    global _db
    if _db is None:
        # Fallback: auto-initialize if lifespan didn't run (e.g. in tests)
        init_firebase()
    return _db


# Alias so old services using get_firestore() don't break
get_firestore = get_db

# Alias used by onboarding
get_firebase_db = get_db


# Scoped collection helpers

def get_cart_collection(user_id: str):
    """Path: users/{user_id}/cart"""
    return get_db().collection("users").document(user_id).collection("cart")


def get_promo_collection():
    """Path: promo_codes/{code}"""
    return get_db().collection("promo_codes")