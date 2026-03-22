from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.database.connection import init_firebase
from app.routers.cart import router as cart_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    yield


app = FastAPI(
    title="NutriFlex API",
    description="Backend API for NutriFlex — Healthy Meal Delivery App",
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

app.include_router(cart_router, prefix="/api/v1")


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "app": "NutriFlex API"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}