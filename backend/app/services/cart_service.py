from datetime import datetime, timezone
from fastapi import HTTPException, status

from app.database.connection import get_cart_collection, get_promo_collection
from app.models.cart import CartItem, CartItemCreate, CartItemUpdate, CartSummary

DELIVERY_FEE = 1.99


def _doc_to_cart_item(doc) -> CartItem:
    """Convert a Firestore document snapshot to a CartItem."""
    data = doc.to_dict()
    return CartItem(
        id=doc.id,
        user_id=data["user_id"],
        meal_id=data["meal_id"],
        meal_name=data["meal_name"],
        price_per_unit=data["price_per_unit"],
        quantity=data["quantity"],
        subtotal=data["subtotal"],
        created_at=data["created_at"],
        updated_at=data["updated_at"],
    )


def _build_summary(items: list[CartItem], discount: float = 0.0, promo_code: str = None) -> CartSummary:
    subtotal = round(sum(i.subtotal for i in items), 2)
    delivery = DELIVERY_FEE if items else 0.0
    total = round(subtotal + delivery - discount, 2)
    return CartSummary(
        items=items,
        subtotal=subtotal,
        delivery_fee=delivery,
        discount=discount,
        total=total,
        promo_code=promo_code,
        promo_applied=discount > 0,
    )


# ─────────────────────────────────────────────
# GET CART
# ─────────────────────────────────────────────
def get_cart(user_id: str) -> CartSummary:
    col = get_cart_collection(user_id)
    docs = col.stream()
    items = [_doc_to_cart_item(doc) for doc in docs]
    return _build_summary(items)


# ─────────────────────────────────────────────
# ADD ITEM
# ─────────────────────────────────────────────
def add_cart_item(user_id: str, item_data: CartItemCreate) -> CartItem:
    col = get_cart_collection(user_id)
    now = datetime.now(timezone.utc)

    # Check if meal already in cart (query by meal_id)
    existing_docs = col.where("meal_id", "==", item_data.meal_id).limit(1).stream()
    existing = next(existing_docs, None)

    if existing:
        data = existing.to_dict()
        new_qty = data["quantity"] + item_data.quantity
        new_subtotal = round(data["price_per_unit"] * new_qty, 2)
        existing.reference.update({
            "quantity": new_qty,
            "subtotal": new_subtotal,
            "updated_at": now,
        })
        updated = existing.reference.get()
        return _doc_to_cart_item(updated)

    # New item
    new_doc = {
        "user_id": user_id,
        "meal_id": item_data.meal_id,
        "meal_name": item_data.meal_name,
        "price_per_unit": item_data.price_per_unit,
        "quantity": item_data.quantity,
        "subtotal": round(item_data.price_per_unit * item_data.quantity, 2),
        "created_at": now,
        "updated_at": now,
    }
    ref = col.add(new_doc)[1]
    return _doc_to_cart_item(ref.get())


# ─────────────────────────────────────────────
# UPDATE ITEM QUANTITY
# ─────────────────────────────────────────────
def update_cart_item(user_id: str, item_id: str, update_data: CartItemUpdate) -> CartItem:
    col = get_cart_collection(user_id)
    ref = col.document(item_id)
    doc = ref.get()

    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")

    data = doc.to_dict()
    new_subtotal = round(data["price_per_unit"] * update_data.quantity, 2)

    ref.update({
        "quantity": update_data.quantity,
        "subtotal": new_subtotal,
        "updated_at": datetime.now(timezone.utc),
    })
    return _doc_to_cart_item(ref.get())


# ─────────────────────────────────────────────
# REMOVE SINGLE ITEM  (trash icon in Flutter)
# ─────────────────────────────────────────────
def remove_cart_item(user_id: str, item_id: str) -> None:
    col = get_cart_collection(user_id)
    ref = col.document(item_id)
    doc = ref.get()

    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")

    ref.delete()


# ─────────────────────────────────────────────
# CLEAR ENTIRE CART
# ─────────────────────────────────────────────
def clear_cart(user_id: str) -> None:
    col = get_cart_collection(user_id)
    docs = col.stream()
    for doc in docs:
        doc.reference.delete()


# ─────────────────────────────────────────────
# APPLY PROMO CODE
# ─────────────────────────────────────────────
def apply_promo_code(user_id: str, promo_code: str) -> CartSummary:
    promo_col = get_promo_collection()
    promo_doc = promo_col.document(promo_code.upper()).get()

    if not promo_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired promo code",
        )

    promo = promo_doc.to_dict()
    if not promo.get("is_active", False):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This promo code is no longer active",
        )

    cart = get_cart(user_id)
    if not cart.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot apply promo code to an empty cart",
        )

    discount = round(cart.subtotal * (promo["discount_percent"] / 100), 2)
    return _build_summary(cart.items, discount=discount, promo_code=promo_code.upper())