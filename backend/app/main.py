 # app/main.py
from fastapi import FastAPI
from app.routers import Profile   # or from .routers import Profile

app = FastAPI()

app.include_router(Profile.router)