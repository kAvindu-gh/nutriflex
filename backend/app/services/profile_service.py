from app.database.firebase import get_db
from app.models.user import ProfileUpdate
from app.utils.image_helper import validate_image
from app.utils.cloudinary_helper import upload_image_to_cloudinary, delete_image_from_cloudinary
from fastapi import HTTPException, UploadFile
from datetime import datetime


USERS_COLLECTION = "users"


def get_user_profile(user_id: str) -> dict:
    db = get_db()
    doc = db.collection(USERS_COLLECTION).document(user_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    data = doc.to_dict()
    data.pop("password", None)
    data.pop("passwordHash", None)
    data.pop("password_hash", None)
    data.pop("emailVerified", None)
    data.pop("createdAt", None)
    return {
        "user_id": user_id,
        "email": data.get("email", ""),
        "fullName": data.get("fullName", ""),
        "mobile": data.get("mobile"),
        "birthday": data.get("birthday"),
        "gender": data.get("gender"),
        "profile_pic_url": data.get("profile_pic_url"),
    }


def update_user_profile(user_id: str, update_data: ProfileUpdate) -> dict:
    db = get_db()
    user_ref = db.collection(USERS_COLLECTION).document(user_id)
    if not user_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found.")
    updates = {k: v for k, v in update_data.model_dump().items() if v is not None}
    if not updates:
        raise HTTPException(status_code=400, detail="No fields provided to update.")
    if "email" in updates:
        existing = (
            db.collection(USERS_COLLECTION)
            .where("email", "==", updates["email"])
            .limit(1).get()
        )
        for e in existing:
            if e.id != user_id:
                raise HTTPException(status_code=400, detail="Email already in use.")
    updates["updatedAt"] = datetime.utcnow().isoformat()
    user_ref.update(updates)
    return get_user_profile(user_id)


def delete_user_field(user_id: str, field: str) -> dict:
    db = get_db()
    user_ref = db.collection(USERS_COLLECTION).document(user_id)
    if not user_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found.")

    # If deleting profile pic, also remove it from Cloudinary
    if field == "profile_pic_url":
        try:
            delete_image_from_cloudinary(user_id)
        except Exception:
            pass  # don't block the delete if Cloudinary fails

    user_ref.update({
        field: None,
        "updatedAt": datetime.utcnow().isoformat(),
    })
    return get_user_profile(user_id)


# ─────────────────────────────────────────────────────────────────────────────
# UPLOAD profile picture → Cloudinary → save URL to Firestore
# ─────────────────────────────────────────────────────────────────────────────
async def upload_profile_picture(user_id: str, file: UploadFile) -> dict:
    db = get_db()
    user_ref = db.collection(USERS_COLLECTION).document(user_id)
    if not user_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found.")

    # Read and validate
    contents = await file.read()
    validate_image(file, contents)

    # Upload to Cloudinary and get URL
    public_url = upload_image_to_cloudinary(contents, user_id, file.content_type)

    # Save URL to Firestore
    user_ref.update({
        "profile_pic_url": public_url,
        "updatedAt": datetime.utcnow().isoformat(),
    })

    return get_user_profile(user_id)