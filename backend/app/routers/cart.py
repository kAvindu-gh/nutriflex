from fastapi import APIRouter, Depends, status
from typing import Annotated

from app.models.cart import CartItem, CartItemCreate, CartItemUpdate, CartSummary, PromoCodeApply
from app.services.cart_service import (
    get_cart,
    add_cart_item,
    update_cart_item,
    remove_cart_item,
    clear_cart,
    apply_promo_code,
)
from app.utils.auth import get_current_user

router = APIRouter(prefix="/cart", tags=["Shopping Cart"])

# Reusable dependency alias for the authenticated Firebase UID
UserDep = Annotated[str, Depends(get_current_user)]


@router.get(
    "",
    response_model=CartSummary,
    summary="Get cart with order summary",
)
def get_user_cart(user_id: UserDep):
    """
    Returns all cart items + order summary (subtotal, delivery fee, total).
    Maps directly to the Shopping Cart page in Flutter.
    """
    return get_cart(user_id)


@router.post(
    "/items",
    response_model=CartItem,
    status_code=status.HTTP_201_CREATED,
    summary="Add a meal to cart",
)
def add_item(item: CartItemCreate, user_id: UserDep):
    """
    Adds a meal to the cart.
    If the same meal_id already exists, quantity is incremented instead.
    """
    return add_cart_item(user_id, item)


@router.put(
    "/items/{item_id}",
    response_model=CartItem,
    summary="Update quantity of a cart item",
)
def update_item(item_id: str, update_data: CartItemUpdate, user_id: UserDep):
    """
    Updates the quantity for a cart item (e.g. tapping +/- buttons in Flutter).
    Quantity must be >= 1. To remove, use DELETE.
    """
    return update_cart_item(user_id, item_id, update_data)


@router.delete(
    "/items/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a single item from cart",
)
def delete_item(item_id: str, user_id: UserDep):
    """
    Deletes one cart item. Triggered by the trash icon button in Flutter.
    """
    remove_cart_item(user_id, item_id)


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Clear all items from cart",
)
def clear_user_cart(user_id: UserDep):
    """Removes every item from the user's cart."""
    clear_cart(user_id)


@router.post(
    "/promo",
    response_model=CartSummary,
    summary="Apply a promo code",
)
def apply_promo(promo: PromoCodeApply, user_id: UserDep):
    """
    Validates the promo code and returns an updated CartSummary with
    discount applied. Maps to the 'Apply' button on the promo field in Flutter.
    """
    return apply_promo_code(user_id, promo.promo_code)