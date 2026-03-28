from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

from app.database.connection import init_firebase
from app.routers import recipes
from app.routers import bmi, usda, nutrients
from app.routers.onboarding_router import router as onboarding_router
from app.routers.notifications import router as notification_router
from app.routers import profile
from app.routers.cart import router as cart_router
from app.routers.map import router as map_router
from app.routers.summary_router import router as summary_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    yield


app = FastAPI(
    title="NutriFlex API",
    description="FastAPI backend connected to Firebase Firestore",
    version="1.0.0",
    docs_url="/docs",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────────
app.include_router(recipes.router)
app.include_router(bmi.router)
app.include_router(usda.router)
app.include_router(nutrients.router)
app.include_router(onboarding_router)
app.include_router(notification_router)
app.include_router(profile.router, prefix="/api/v1")
app.include_router(cart_router, prefix="/api/v1")
app.include_router(map_router, prefix="/api/v1")
app.include_router(summary_router, prefix="/api/v1")

# ── Health checks ──────────────────────────────────────────────────────────────
@app.get("/", tags=["Health"])
def root():
    return {"message": "NutriFlex Backend is running"}

@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok"}