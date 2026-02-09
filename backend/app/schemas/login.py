from pydantic import BaseModel,EmailStr

#defines what data expect from the login request
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

#defines what data send back after Logging in
class Loginresponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

    