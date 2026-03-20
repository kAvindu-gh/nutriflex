from pydantic import BaseModel
from typing import Optional


class OnboardingStep(BaseModel):
    goal:       Optional[str] = None
    activity:   Optional[str] = None
    medical:    Optional[str] = None
    diet:       Optional[str] = None
    commitment: Optional[str] = None


class OnboardingResponse(BaseModel):
    id:         str
    goal:       Optional[str] = None
    activity:   Optional[str] = None
    medical:    Optional[str] = None
    diet:       Optional[str] = None
    commitment: Optional[str] = None
    updated_at: Optional[str] = None