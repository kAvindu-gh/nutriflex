from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# ── Import routers ─────────────────────────────────────────────────────
from app.routers.notifications import router as notification_router
 

# ── Create FastAPI app ─────────────────────────────────────────────────
app = FastAPI(
    title="NutriFlex API",
    description="Backend API for NutriFlex mobile application",
    version="1.0.0"
)

# ── CORS (allows Flutter app to connect) ──────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Register routers ───────────────────────────────────────────────────
 
app.include_router(notification_router)

# ── Health check ───────────────────────────────────────────────────────
@app.get("/")
async def root():
    return {"message": "NutriFlex API is running ✅"}