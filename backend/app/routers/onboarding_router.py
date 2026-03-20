from fastapi import APIRouter, HTTPException
from app.models.onboard_models import OnboardingStep, OnboardingResponse
from app.services.onboarding_service import (
    upsert_onboarding,
    get_onboarding,
    delete_onboarding,
)

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])


@router.post("/{user_id}", response_model=OnboardingResponse)
def update_step(user_id: str, data: OnboardingStep):
    return upsert_onboarding(user_id, data.model_dump(exclude_unset=True))


@router.get("/{user_id}", response_model=OnboardingResponse)
def fetch_onboarding(user_id: str):
    record = get_onboarding(user_id)
    if not record:
        raise HTTPException(status_code=404, detail="No onboarding found for this user")
    return record


@router.delete("/{user_id}", status_code=204)
def remove_onboarding(user_id: str):
    success = delete_onboarding(user_id)
    if not success:
        raise HTTPException(status_code=404, detail="No onboarding found for this user")