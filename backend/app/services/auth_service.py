from app.utils.security import verify_password

# Creating a dummy user (later replace with Firebase or DB)
fake_user_db = {
    "user@nutriflex.com": {
        "email": "user@nutriflex.com",
        "hashed_password": "$2b$12$examplehashedpassword"
    }
}

def authenticate_user(email: str, password: str):
    """
    Validate user credentials
    """
    user = fake_user_db.get(email)
    if not user:
        return None

    if not verify_password(password, user["hashed_password"]):
        return None

    return user
