from app.database.firebase import get_db
from app.models.user import ProfileUpdate
from fastapi import HTTPException
from datetime import datetime


USERS_COLLECTION = "users"


# ─────────────────────────────────────────────────────────────────────────────
# GET profile — reads email + fullName from existing 'users' collection,
# plus any optional fields we've added (mobile, birthday, gender, pic)
# ─────────────────────────────────────────────────────────────────────────────
def get_user_profile(user_id: str) -> dict:
    db = get_db()
    doc = db.collection(USERS_COLLECTION).document(user_id).get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found.")

    data = doc.to_dict()

    # Remove sensitive / internal fields before returning
    data.pop("password", None)
    data.pop("passwordHash", None)
    data.pop("password_hash", None)
    data.pop("emailVerified", None)
    data.pop("createdAt", None)

    # Ensure optional profile fields always exist in response (even if null)
    return {
        "user_id": user_id,
        "email": data.get("email", ""),
        "fullName": data.get("fullName", ""),
        "mobile": data.get("mobile"),
        "birthday": data.get("birthday"),
        "gender": data.get("gender"),
        "profile_pic_url": data.get("profile_pic_url"),
    }


# ─────────────────────────────────────────────────────────────────────────────
# PATCH — update one or more fields (merges into the existing document)
# ─────────────────────────────────────────────────────────────────────────────
def update_user_profile(user_id: str, update_data: ProfileUpdate) -> dict:
    db = get_db()
    user_ref = db.collection(USERS_COLLECTION).document(user_id)

    if not user_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found.")

    # Only include fields that were explicitly sent in the request
    updates = {k: v for k, v in update_data.model_dump().items() if v is not None}

    if not updates:
        raise HTTPException(status_code=400, detail="No fields provided to update.")

    # If email is changing, make sure it's not taken by someone else
    if "email" in updates:
        existing = (
            db.collection(USERS_COLLECTION)
            .where("email", "==", updates["email"])
            .limit(1)
            .get()
        )
        for e in existing:
            if e.id != user_id:
                raise HTTPException(
                    status_code=400, detail="Email already in use by another account."
                )

    updates["updatedAt"] = datetime.utcnow().isoformat()
    user_ref.update(updates)

    return get_user_profile(user_id)


# ─────────────────────────────────────────────────────────────────────────────
# DELETE field — sets an optional field back to null
# email and fullName are protected and cannot be deleted
# ─────────────────────────────────────────────────────────────────────────────
def delete_user_field(user_id: str, field: str) -> dict:
    db = get_db()
    user_ref = db.collection(USERS_COLLECTION).document(user_id)

    if not user_ref.get().exists:
        raise HTTPException(status_code=404, detail="User not found.")

    user_ref.update({
        field: None,
        "updatedAt": datetime.utcnow().isoformat(),
    })

    return get_user_profile(user_id)