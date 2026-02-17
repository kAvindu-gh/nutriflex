# app/services/firebase.py
import firebase_admin
from firebase_admin import credentials, auth, firestore, storage
import os

# Use the existing key file
cred = credentials.Certificate("app/database/Custom-firebase-key.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'your-project-id.appspot.com'   # replace with your bucket
})

db = firestore.client()
bucket = storage.bucket()