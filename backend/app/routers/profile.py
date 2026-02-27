from fastapi import APIRouter
from app.models.user import ProfileUpdate, FieldDelete, UserProfileResponse
from app.services import profile_service

router = APIRouter(prefix="/profile", tags=["Profile"])


# ── GET /profile/{user_id} ────────────────────────────────────────────────────
@router.get("/{user_id}", response_model=UserProfileResponse)
def get_profile(user_id: str):
    """
    Fetch the profile for a signed-up user.
    Reads email + fullName from the existing 'users' Firestore collection.
    Optional fields (mobile, birthday, gender, profile_pic_url) are null
    until the user adds them.
    
    user_id = the Firestore document ID (e.g. lDbTtG0CgdO7aDvFzZIl8UqXJFF3)
    """
    return profile_service.get_user_profile(user_id)


# ── PATCH /profile/{user_id} ──────────────────────────────────────────────────
@router.patch("/{user_id}", response_model=UserProfileResponse)
def update_profile(user_id: str, update_data: ProfileUpdate):
    """
    Update one or more profile fields. Send only what you want to change.

    Can edit:    fullName, email, mobile, birthday, gender, profile_pic_url
    Cannot delete: fullName, email
    """
    return profile_service.update_user_profile(user_id, update_data)


# ── DELETE /profile/{user_id}/field ──────────────────────────────────────────
@router.delete("/{user_id}/field", response_model=UserProfileResponse)
def delete_field(user_id: str, body: FieldDelete):
    """
    Clear a specific optional field (sets it to null in Firestore).

    Deletable fields:     mobile, birthday, gender, profile_pic_url
    NOT deletable:        email, fullName  →  returns 400 error

    Request body:
    {
        "field": "mobile"
    }
    """
    return profile_service.delete_user_field(user_id, body.field)