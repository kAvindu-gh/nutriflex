from fastapi import APIRouter, HTTPException
from app.services.summary_service import get_user_summary

router = APIRouter(prefix="/summary", tags=["Summary"])


@router.get("/{user_id}")
def get_summary(user_id: str):
    """
    Returns a rich summary of the user's health data:
    nutrients history, BMI, meals, orders.
    """
    try:
        return get_user_summary(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))