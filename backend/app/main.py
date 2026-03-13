from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers.onboarding import router as onboarding_router

app = FastAPI(
    title="NutriFlex API",
    description="FastAPI backend connected to Firebase Firestore",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(onboarding_router)


@app.get("/")
def root():
    return {"message": "NutriFlex API is running"}