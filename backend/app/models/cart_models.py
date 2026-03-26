from pydantic import BaseModel
from typing import List, Optional


class CartItem(BaseModel):
    recipe_id: str
    recipe_name: str
    calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    image_path: Optional[str] = None
    quantity: int = 1
    price_per_item: float = 4.99  # default price


class AddToCartRequest(BaseModel):
    recipe_id: str
    recipe_name: str
    calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    image_path: Optional[str] = None
    quantity: int = 1
    price_per_item: float = 4.99


class UpdateQuantityRequest(BaseModel):
    quantity: int


class CartResponse(BaseModel):
    user_id: str
    items: List[CartItem]
    item_count: int
    subtotal: float
    delivery_fee: float
    total: float


class PromoCodeRequest(BaseModel):
    promo_code: str