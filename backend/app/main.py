from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import bmi, usda, nutrients 

app = FastAPI(
    title="NutriFlex API",
    description="BMI Calculator + USDA Food Database",
    version="1.0.0"
)

# CORS for the frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include ONLY BMI and USDA as routes
app.include_router(bmi.router)
app.include_router(usda.router)
app.include_router(nutrients.router)

@app.get("/")
async def root():
    return {
        "message": "NutriFlex API - BMI + USDA Food Database",
    }
