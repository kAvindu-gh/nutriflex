# app/models/profile.py
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date

class ProfileResponse(BaseModel):
    full_name: Optional[str] = None
    mobile: Optional[str] = None
    email: Optional[str] = None
    birthday: Optional[date] = None
    gender: Optional[str] = None
    profile_picture_url: Optional[str] = None

class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    mobile: Optional[str] = None
    birthday: Optional[date] = None
    gender: Optional[str] = None
    # Email is updated via Firebase Auth, include if you allow it