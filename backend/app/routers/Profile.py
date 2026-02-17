# app/routers/Profile.py
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from firebase_admin import firestore, auth
import uuid
from app.services.firebase import db, bucket          # adjust import path
from app.models.profile import ProfileResponse, ProfileUpdate
from app.utils.auth import get_current_user

router = APIRouter(prefix="/profile", tags=["Profile"])

@router.get("", response_model=ProfileResponse)
async def get_profile(user=Depends(get_current_user)):
    uid = user["uid"]
    doc_ref = db.collection("users").document(uid)
    doc = doc_ref.get()
    if not doc.exists:
        doc_ref.set({
            "email": user.get("email"),
            "created_at": firestore.SERVER_TIMESTAMP
        })
        doc = doc_ref.get()
    return ProfileResponse(**doc.to_dict())

@router.put("", status_code=status.HTTP_204_NO_CONTENT)
async def update_profile(update_data: ProfileUpdate, user=Depends(get_current_user)):
    uid = user["uid"]
    update_dict = update_data.dict(exclude_unset=True)
    if update_dict:
        db.collection("users").document(uid).update(update_dict)

@router.post("/picture")
async def upload_profile_picture(file: UploadFile = File(...), user=Depends(get_current_user)):
    uid = user["uid"]
    # ... (same code as before, using bucket and db)
    # Remember to import bucket from services.firebase
    ...

@router.delete("/picture", status_code=204)
async def delete_profile_picture(user=Depends(get_current_user)):
    uid = user["uid"]
    # ... (code to delete)
    ...