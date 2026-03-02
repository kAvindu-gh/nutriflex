from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import profile
from dotenv import load_dotenv
import os
from pathlib import Path

# Load environment variables from .env file in the backend directory
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

app = FastAPI(
    title="NutriFlex API",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(profile.router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "NutriFlex API is running"}

@app.get("/health")
def health():
    return {"status": "ok"}