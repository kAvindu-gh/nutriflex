from fastapi import APIRouter, HTTPException, UploadFile, File
from app.models.user import ProfileUpdate, FieldDelete, UserProfileResponse
from app.services import profile_service
from app.database.firebase import get_db 

router = APIRouter(prefix="/profile", tags=["Profile"])


# ── GET /profile/{user_id} ────────────────────────────────────────────────────
@router.get("/{user_id}", response_model=UserProfileResponse)
def get_profile(user_id: str):
    """
    Fetch the profile for a signed-up user.
    Reads email + fullName from the existing 'users' Firestore collection.
    Optional fields (mobile, birthday, gender, profile_pic_url) are null
    until the user adds them.
    """
    return profile_service.get_user_profile(user_id)


# ── PATCH /profile/{user_id} ──────────────────────────────────────────────────
@router.patch(
    "/{user_id}",
    response_model=UserProfileResponse,
    openapi_extra={
        "requestBody": {
            "content": {
                "application/json": {
                    "examples": {
                        "Edit fullName only": {
                            "summary": "Change display name",
                            "value": {
                                "fullName": "John Bonfield"
                            }
                        },
                        "Edit email only": {
                            "summary": "Change email address",
                            "value": {
                                "email": "john.bonfield@example.com"
                            }
                        },
                        "Add or edit mobile": {
                            "summary": "Add or update mobile number",
                            "value": {
                                "mobile": "+94768076464"
                            }
                        },
                        "Add or edit birthday": {
                            "summary": "Add or update birthday",
                            "value": {
                                "birthday": "1995-06-15"
                            }
                        },
                        "Add or edit gender": {
                            "summary": "Add or update gender",
                            "value": {
                                "gender": "male"
                            }
                        },
                        "Add or edit profile picture": {
                            "summary": "Add or update profile picture URL",
                            "value": {
                                "profile_pic_url": "https://storage.googleapis.com/your-bucket/profile.jpg"
                            }
                        },
                        "Update multiple fields at once": {
                            "summary": "Edit several fields in one call",
                            "value": {
                                "fullName": "John Bonfield",
                                "mobile": "+94768076464",
                                "birthday": "1995-06-15",
                                "gender": "male"
                            }
                        }
                    }
                }
            }
        }
    }
)
def update_profile(user_id: str, update_data: ProfileUpdate):
    """
    Update one or more profile fields. Send only what you want to change.

    - **fullName** and **email** → can be edited, cannot be deleted
    - **mobile**, **birthday**, **gender**, **profile_pic_url** → can be edited or deleted
    
    **Gender allowed values:** male, female, non-binary, prefer not to say
    
    **Birthday format:** YYYY-MM-DD
    
    **Mobile format:** E.164 e.g. +94768076464
    """
    return profile_service.update_user_profile(user_id, update_data)


# ── DELETE /profile/{user_id}/field ──────────────────────────────────────────
@router.delete(
    "/{user_id}/field",
    response_model=UserProfileResponse,
    openapi_extra={
        "requestBody": {
            "content": {
                "application/json": {
                    "examples": {
                        "Delete mobile": {
                            "summary": "Clear mobile number",
                            "value": {"field": "mobile"}
                        },
                        "Delete birthday": {
                            "summary": "Clear birthday",
                            "value": {"field": "birthday"}
                        },
                        "Delete gender": {
                            "summary": "Clear gender",
                            "value": {"field": "gender"}
                        },
                        "Delete profile picture": {
                            "summary": "Clear profile picture",
                            "value": {"field": "profile_pic_url"}
                        }
                    }
                }
            }
        }
    }
)
def delete_field(user_id: str, body: FieldDelete):
    """
    Clear a specific optional field (sets it to null in Firestore).

    **Deletable:** mobile, birthday, gender, profile_pic_url
    
    **NOT deletable:** email, fullName → returns 400 error
    """
    return profile_service.delete_user_field(user_id, body.field)
 
@router.post(
    "/{user_id}/upload-picture",
    response_model=UserProfileResponse,
    summary="Upload profile picture from local storage"
)
async def upload_profile_picture(
    user_id: str,
    file: UploadFile = File(..., description="Image file — jpeg, png or webp. Max 5MB.")
):
    """
    Upload a profile picture directly from the user's device.

    - Accepts **jpeg, png, webp**
    - Maximum size: **5MB**
    - Saved to Firebase Storage, URL stored in Firestore automatically
    """
    return await profile_service.upload_profile_picture(user_id, file)


# ── Logout ────────────────────────────────────────────────────────────────────
@router.post("/{user_id}/logout")
def logout(user_id: str):
    """
    Logout endpoint. Verifies user exists and returns success.
    Flutter clears local session after this call.
    """
    db = get_db()
    doc = db.collection("users").document(user_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    return {"message": "Logged out successfully", "user_id": user_id}