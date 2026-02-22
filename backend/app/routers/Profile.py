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
        default_data = {
            "email": user.get("email"),
            "role": "user",
            "is_active": True,
            "profile_completed": False,
            "created_at": firestore.SERVER_TIMESTAMP,
            "updated_at": firestore.SERVER_TIMESTAMP,
        }
        doc_ref.set(default_data)
        return ProfileResponse(**default_data)

    data = doc.to_dict()

    # Profile completion check (NutriFlex logic)
    required_fields = ["age", "height", "weight", "goal"]
    data["profile_completed"] = all(data.get(f) for f in required_fields)

    return ProfileResponse(**data)

@router.put("", status_code=status.HTTP_204_NO_CONTENT)
async def update_profile(update_data: ProfileUpdate, user=Depends(get_current_user)):
    uid = user["uid"]
    update_dict = update_data.dict(exclude_unset=True)
    if update_dict:
        db.collection("users").document(uid).update(update_dict)

@router.post("/picture")
async def upload_profile_picture(
    file: UploadFile = File(...),
    user=Depends(get_current_user)
):
    uid = user["uid"]

    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files allowed")

    filename = f"profile_pictures/{uid}_{uuid.uuid4()}"
    blob = bucket.blob(filename)
    blob.upload_from_file(file.file, content_type=file.content_type)
    blob.make_public()

    db.collection("users").document(uid).update({
        "profile_picture": blob.public_url,
        "updated_at": firestore.SERVER_TIMESTAMP
    })

    return {"profile_picture": blob.public_url}

@router.delete("/picture", status_code=204)
async def delete_profile_picture(user=Depends(get_current_user)):
    uid = user["uid"]
    doc_ref = db.collection("users").document(uid)
    doc = doc_ref.get()

    if not doc.exists or "profile_picture" not in doc.to_dict():
        raise HTTPException(status_code=404, detail="No profile picture found")

    doc_ref.update({
        "profile_picture": firestore.DELETE_FIELD,
        "updated_at": firestore.SERVER_TIMESTAMP
    })

@router.delete("", status_code=204)
async def deactivate_account(user=Depends(get_current_user)):
    uid = user["uid"]

    db.collection("users").document(uid).update({
        "is_active": False,
        "updated_at": firestore.SERVER_TIMESTAMP
    })

@router.get("/all")
async def get_all_profiles(user=Depends(get_current_user)):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Access denied")

    users = db.collection("users").stream()
    return [u.to_dict() for u in users]

@router.patch("", status_code=status.HTTP_204_NO_CONTENT)
async def patch_profile(update_data: ProfileUpdate, user=Depends(get_current_user)):
    uid = user["uid"]
    update_dict = update_data.dict(exclude_unset=True)

    if not update_dict:
        raise HTTPException(status_code=400, detail="No fields provided")

    update_dict["updated_at"] = firestore.SERVER_TIMESTAMP

    db.collection("users").document(uid).update(update_dict)