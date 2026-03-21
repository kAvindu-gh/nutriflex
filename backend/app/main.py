from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import recipes
from .routers import bmi, usda, nutrients
from app.routers.onboarding_router import router as onboarding_router

app = FastAPI(
    title="NutriFlex API",
    description="FastAPI backend connected to Firebase Firestore",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3164",   # ✅ your current Flutter Web URL
        "http://127.0.0.1:3164"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(recipes.router)
app.include_router(bmi.router)
app.include_router(usda.router)
app.include_router(nutrients.router)
app.include_router(onboarding_router)


@app.get("/")
def root():
    return {"message": "NutriFlex API is running"}