from app.database.connection import get_db
from app.models.cart_models import CartItem, AddToCartRequest
from typing import List
from datetime import datetime

DELIVERY_FEE = 1.99
VALID_PROMO_CODES = {
    "NUTRI10": 0.10,   # 10% off
    "FLEX20": 0.20,    # 20% off
    "SAVE5": 0.05,     # 5% off
}


def _cart_ref(user_id: str):
    return get_db().collection("carts").document(user_id)


def _build_summary(items: List[CartItem]) -> dict:
    subtotal = sum(i.price_per_item * i.quantity for i in items)
    delivery = DELIVERY_FEE if items else 0.0
    return {
        "subtotal": round(subtotal, 2),
        "delivery_fee": round(delivery, 2),
        "total": round(subtotal + delivery, 2),
    }


def get_cart(user_id: str) -> dict:
    doc = _cart_ref(user_id).get()
    if not doc.exists:
        return {
            "user_id": user_id,
            "items": [],
            "item_count": 0,
            "subtotal": 0.0,
            "delivery_fee": 0.0,
            "total": 0.0,
        }
    data = doc.to_dict()
    items = [CartItem(**i) for i in data.get("items", [])]
    summary = _build_summary(items)
    return {
        "user_id": user_id,
        "items": [i.model_dump() for i in items],
        "item_count": sum(i.quantity for i in items),
        **summary,
    }


def add_to_cart(user_id: str, req: AddToCartRequest) -> dict:
    ref = _cart_ref(user_id)
    doc = ref.get()
    items: List[dict] = []

    if doc.exists:
        items = doc.to_dict().get("items", [])

    # If recipe already in cart, increment quantity
    found = False
    for item in items:
        if item["recipe_id"] == req.recipe_id:
            item["quantity"] = item.get("quantity", 1) + req.quantity
            found = True
            break

    if not found:
        items.append(req.model_dump())

    ref.set(
        {"items": items, "updated_at": datetime.utcnow().isoformat()},
        merge=True,
    )

    cart_items = [CartItem(**i) for i in items]
    summary = _build_summary(cart_items)
    return {
        "user_id": user_id,
        "items": items,
        "item_count": sum(i.quantity for i in cart_items),
        **summary,
    }


def remove_from_cart(user_id: str, recipe_id: str) -> dict:
    ref = _cart_ref(user_id)
    doc = ref.get()
    if not doc.exists:
        return get_cart(user_id)

    items = [
        i for i in doc.to_dict().get("items", [])
        if i["recipe_id"] != recipe_id
    ]
    ref.set(
        {"items": items, "updated_at": datetime.utcnow().isoformat()},
        merge=True,
    )

    cart_items = [CartItem(**i) for i in items]
    summary = _build_summary(cart_items)
    return {
        "user_id": user_id,
        "items": items,
        "item_count": sum(i.quantity for i in cart_items),
        **summary,
    }


def update_item_quantity(user_id: str, recipe_id: str, quantity: int) -> dict:
    ref = _cart_ref(user_id)
    doc = ref.get()
    if not doc.exists:
        return get_cart(user_id)

    items = doc.to_dict().get("items", [])

    if quantity <= 0:
        items = [i for i in items if i["recipe_id"] != recipe_id]
    else:
        for item in items:
            if item["recipe_id"] == recipe_id:
                item["quantity"] = quantity
                break

    ref.set(
        {"items": items, "updated_at": datetime.utcnow().isoformat()},
        merge=True,
    )

    cart_items = [CartItem(**i) for i in items]
    summary = _build_summary(cart_items)
    return {
        "user_id": user_id,
        "items": items,
        "item_count": sum(i.quantity for i in cart_items),
        **summary,
    }


def clear_cart(user_id: str) -> dict:
    ref = _cart_ref(user_id)
    ref.set(
        {"items": [], "updated_at": datetime.utcnow().isoformat()},
        merge=True,
    )
    return {
        "user_id": user_id,
        "items": [],
        "item_count": 0,
        "subtotal": 0.0,
        "delivery_fee": 0.0,
        "total": 0.0,
    }


def apply_promo(user_id: str, promo_code: str) -> dict:
    code = promo_code.strip().upper()
    if code not in VALID_PROMO_CODES:
        return {"valid": False, "discount_percent": 0, "message": "Invalid promo code"}

    discount = VALID_PROMO_CODES[code]
    return {
        "valid": True,
        "discount_percent": int(discount * 100),
        "message": f"{int(discount * 100)}% discount applied!",
    }