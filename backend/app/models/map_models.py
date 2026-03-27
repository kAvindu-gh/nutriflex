from pydantic import BaseModel
from typing import List, Optional


class StoreLocation(BaseModel):
    id: str
    name: str
    address: str
    lat: float
    lng: float
    distance_km: float
    phone: Optional[str] = None
    opening_hours: Optional[str] = None
    availability_percent: int  # random 80-99


class NearbyStoresRequest(BaseModel):
    lat: float
    lng: float
    radius_m: int = 3000  # 3km default


class NearbyStoresResponse(BaseModel):
    stores: List[StoreLocation]
    user_lat: float
    user_lng: float
    location_name: str


class OrderItem(BaseModel):
    recipe_id: str
    recipe_name: str
    quantity: int
    price_per_item: float


class PlaceOrderRequest(BaseModel):
    store_id: str
    store_name: str
    store_address: str
    items: List[OrderItem]
    subtotal: float
    delivery_fee: float
    total: float
    promo_code: Optional[str] = None
    discount: Optional[float] = 0.0


class PlaceOrderResponse(BaseModel):
    order_id: str
    status: str
    store_name: str
    store_address: str
    items: List[OrderItem]
    subtotal: float
    delivery_fee: float
    discount: float
    total: float
    estimated_delivery: str
    created_at: str


class GeocodingRequest(BaseModel):
    address: str