from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import date
import re


# ── Response model matching YOUR Firestore field names ────────────────────────
class UserProfileResponse(BaseModel):
    user_id: str
    email: str
    fullName: str                        # matches Firestore field exactly
    mobile: Optional[str] = None
    birthday: Optional[str] = None
    gender: Optional[str] = None
    profile_pic_url: Optional[str] = None


# ── Update model (for PATCH) ──────────────────────────────────────────────────
class ProfileUpdate(BaseModel):
    fullName: Optional[str] = None
    email: Optional[EmailStr] = None
    mobile: Optional[str] = None
    birthday: Optional[str] = None       # ISO format: YYYY-MM-DD
    gender: Optional[str] = None
    profile_pic_url: Optional[str] = None

    @field_validator("fullName")
    @classmethod
    def validate_full_name(cls, v):
        if v is not None:
            v = v.strip()
            if len(v) < 2:
                raise ValueError("Full name must be at least 2 characters.")
            if len(v) > 100:
                raise ValueError("Full name must be at most 100 characters.")
        return v

    @field_validator("mobile")
    @classmethod
    def validate_mobile(cls, v):
        if v is not None:
            pattern = re.compile(r"^\+?[1-9]\d{6,14}$")
            if not pattern.match(v):
                raise ValueError("Invalid mobile number. Use E.164 format e.g. +94768076464")
        return v

    @field_validator("birthday")
    @classmethod
    def validate_birthday(cls, v):
        if v is not None:
            try:
                parsed = date.fromisoformat(v)
                if parsed > date.today():
                    raise ValueError("Birthday cannot be in the future.")
            except ValueError as e:
                if "fromisoformat" in str(e) or "invalid" in str(e).lower():
                    raise ValueError("Birthday must be in YYYY-MM-DD format.")
                raise
        return v

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v):
        allowed = {"male", "female", "non-binary", "prefer not to say"}
        if v is not None and v.lower() not in allowed:
            raise ValueError(f"Gender must be one of: {', '.join(allowed)}")
        return v.lower() if v else v


# ── Field delete model ────────────────────────────────────────────────────────
class FieldDelete(BaseModel):
    field: str

    @field_validator("field")
    @classmethod
    def validate_field(cls, v):
        deletable = {"mobile", "birthday", "gender", "profile_pic_url"}
        if v not in deletable:
            raise ValueError(
                f"'{v}' cannot be deleted. Deletable fields: {', '.join(deletable)}"
            )
        return v