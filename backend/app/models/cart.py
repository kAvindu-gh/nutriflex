from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class CartItemCreate(BaseModel):
    meal_id: str
    meal_name: str
    price_per_unit: float
    quantity: int = Field(default=1, ge=1)


class CartItemUpdate(BaseModel):
    quantity: int = Field(ge=1, description="Must be >= 1. Use DELETE to remove.")


class CartItem(BaseModel):
    id: str
    user_id: str
    meal_id: str
    meal_name: str
    price_per_unit: float
    quantity: int
    subtotal: float
    created_at: datetime
    updated_at: datetime


class PromoCodeApply(BaseModel):
    promo_code: str


class CartSummary(BaseModel):
    items: List[CartItem]
    subtotal: float
    delivery_fee: float
    discount: float
    total: float
    promo_code: Optional[str] = None
    promo_applied: bool = False


class PromoCode(BaseModel):
    code: str
    discount_percent: float
    is_active: bool