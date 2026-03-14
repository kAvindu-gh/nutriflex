from pydantic import BaseModel
from typing import Optional


class StoreSelectionRequest(BaseModel):
    user_id: str
    store_id: str


class OrderConfirmRequest(BaseModel):
    user_id: str
    store_id: str
    meal_plan_id: str


class UpdateInventoryRequest(BaseModel):
    store_id: str
    ingredient: str
    in_stock: bool
    quantity: int


class StoreResponse(BaseModel):
    store_id: str
    name: str
    address: str
    latitude: float
    longitude: float
    distance_km: float
    distance_text: str          # e.g. "0.8 km" from Google
    travel_time_min: int
    travel_time_text: str       # e.g. "15-20 min" from Google
    rating: float
    phone: str
    opening_hours: str
    ingredient_availability_percent: float
    google_maps_url: str        # deep link to open in Google Maps app
