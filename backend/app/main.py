from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import recipes
from .routers import bmi, usda, nutrients
from app.routers.onboarding_router import router as onboarding_router
from app.routers.notifications import router as notification_router

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

app.include_router(recipes.router)
app.include_router(bmi.router)
app.include_router(usda.router)
app.include_router(nutrients.router)
app.include_router(onboarding_router)
app.include_router(notification_router)


@app.get("/")
def root():
    return {"message": "NutriFlex API is running"}