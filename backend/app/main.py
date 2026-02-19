from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import recipes

app = FastAPI(
    title="NutriFlex API",
    description="Recipe search with API Ninjas + USDA nutrition data",
    version="3.0.0"
)

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(recipes.router)

@app.get("/")
async def root():
    return {
        "message": "NutriFlex API - Recipe + USDA Nutrition",
    }

