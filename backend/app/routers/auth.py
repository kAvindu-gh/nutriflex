from fastapi import APIRouter, HTTPException, status
from app.schemas.login import LoginRequest, LoginResponse
from app.services.auth_service import authenticate_user

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

@router.post("/login", response_model=LoginResponse)
def login(data: LoginRequest):
    """
    Login endpoint
    """
    user = authenticate_user(data.email, data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    # Creating a temporary token (later replace with JWT)
    return {
        "access_token": "sample_token_123"
    }
