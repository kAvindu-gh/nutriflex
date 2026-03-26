'''from firebase_admin import auth
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> str:
    token = credentials.credentials

    # DEV BYPASS — pass "test-user" as token in Swagger
    if token == "test-user":
        print(" DEV BYPASS used — returning test-uid-123")
        return "test-uid-123"

    print(f"Token received (first 30 chars): {token[:30]}...")

    try:
        decoded = auth.verify_id_token(token)
        uid = decoded["uid"]
        print(f" Token verified — UID: {uid}")
        return uid

    except Exception as e:
        # Print the FULL error to the uvicorn terminal
        print(f" Token verification failed: {type(e).__name__}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"{type(e).__name__}: {str(e)}",
        )'''
    