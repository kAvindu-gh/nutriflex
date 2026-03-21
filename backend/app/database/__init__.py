import firebase_admin
from firebase_admin import credentials, firestore
import os

# ── Initialize Firebase only once ─────────────────────────────────────
if not firebase_admin._apps:
    cred = credentials.Certificate(
        os.getenv(
            "FIREBASE_SERVICE_ACCOUNT_PATH",
            "app/database/firebase_key.json"  # already in your project!
        )
    )
    firebase_admin.initialize_app(cred)

# ── Firestore client — import this in your services ───────────────────
# Usage: from app.database import db
db = firestore.client()
