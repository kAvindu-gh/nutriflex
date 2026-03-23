from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

from .routers import recipes
from .routers import bmi, usda, nutrients
from app.routers.onboarding_router import router as onboarding_router
from app.routers.notifications import router as notification_router
from app.routers import profile
from app.routers.map import router as map_router

app = FastAPI(
    title="NutriFlex API",
    description="FastAPI backend connected to Firebase Firestore",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(recipes.router)
app.include_router(bmi.router)
app.include_router(usda.router)
app.include_router(nutrients.router)
app.include_router(onboarding_router)
app.include_router(notification_router)
app.include_router(profile.router, prefix="/api/v1")
app.include_router(map_router)

# ── Health checks ─────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "NutriFlex Backend is running"}

@app.get("/health")
def health():
    return {"status": "ok"}