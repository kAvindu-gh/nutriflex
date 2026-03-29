import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

# Initialize Firebase only once
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

# Firestore client — import this in your services 
# Usage: from app.database import db
db = firestore.client()