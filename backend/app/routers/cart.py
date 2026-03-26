from fastapi import APIRouter, HTTPException
from app.models.cart_models import AddToCartRequest, UpdateQuantityRequest, PromoCodeRequest
from app.services import cart_service

router = APIRouter(prefix="/cart", tags=["Cart"])


@router.get("/{user_id}")
def get_cart(user_id: str):
    """Get full cart for a user."""
    try:
        return cart_service.get_cart(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/add")
def add_to_cart(user_id: str, req: AddToCartRequest):
    """Add a recipe to the user's cart. If already present, increments quantity."""
    try:
        return cart_service.add_to_cart(user_id, req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/remove/{recipe_id}")
def remove_from_cart(user_id: str, recipe_id: str):
    """Remove a specific recipe from the cart."""
    try:
        return cart_service.remove_from_cart(user_id, recipe_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/{user_id}/quantity/{recipe_id}")
def update_quantity(user_id: str, recipe_id: str, req: UpdateQuantityRequest):
    """Update the quantity of a specific item. Setting quantity to 0 removes it."""
    try:
        return cart_service.update_item_quantity(user_id, recipe_id, req.quantity)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/clear")
def clear_cart(user_id: str):
    """Clear all items from the cart."""
    try:
        return cart_service.clear_cart(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/promo")
def apply_promo(user_id: str, req: PromoCodeRequest):
    """Validate and apply a promo code."""
    try:
        return cart_service.apply_promo(user_id, req.promo_code)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))