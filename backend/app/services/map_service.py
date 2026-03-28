import httpx
import random
import math
import uuid
import os
import asyncio
from datetime import datetime
from typing import List, Optional
from app.database.connection import get_db
from app.models.map_models import StoreLocation, PlaceOrderRequest
from app.services.notification_service import notify_order_placed


# Geoapify API keys - to return nearby stores and map

GEOAPIFY_API_KEY = os.getenv("GEOAPIFY_API_KEY")
GEOAPIFY_PLACES_URL = "https://api.geoapify.com/v2/places"

# Nominatim — reverse-geocoding

NOMINATIM_URL = "https://nominatim.openstreetmap.org"
HEADERS = {"User-Agent": "NutriFlex-App/1.0 (university project)"}

# Store categories — valid Geoapify v2 category names
GEOAPIFY_CATEGORIES = "commercial.supermarket"


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lng / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))


async def get_nearby_stores(lat: float, lng: float, radius_m: int = 5000) -> List[StoreLocation]:
    """
    Fetch real nearby grocery/supermarket stores using Geoapify Places API.
    Falls back to hardcoded stores only if the API call fails completely.
    """
    if GEOAPIFY_API_KEY == "YOUR_GEOAPIFY_KEY_HERE":
        print("No Geoapify API key set — using fallback stores")
        return _fallback_stores(lat, lng)

    try:
        # Geoapify v2 Places — filter and bias must NOT be URL-encoded by httpx
        # so we build the URL manually to ensure correct formatting
        url = (
            f"{GEOAPIFY_PLACES_URL}"
            f"?categories={GEOAPIFY_CATEGORIES}"
            f"&filter=circle:{lng},{lat},{radius_m}"
            f"&bias=proximity:{lng},{lat}"
            f"&limit=10"
            f"&lang=en"
            f"&apiKey={GEOAPIFY_API_KEY}"
        )

        async with httpx.AsyncClient(timeout=12) as client:
            resp = await client.get(url)
            print(f"Geoapify status: {resp.status_code}")
            if resp.status_code != 200:
                print(f"Geoapify error body: {resp.text[:300]}")
            resp.raise_for_status()
            data = resp.json()

        features = data.get("features", [])
        print(f"Geoapify returned {len(features)} stores")

        if not features:
            print("No stores found in radius — using fallback")
            return _fallback_stores(lat, lng)

        stores: List[StoreLocation] = []
        for feat in features:
            props = feat.get("properties", {})
            geo = feat.get("geometry", {})
            coords = geo.get("coordinates", [lng, lat])  # [lng, lat]

            store_lng = coords[0]
            store_lat = coords[1]
            distance = _haversine_km(lat, lng, store_lat, store_lng)

            name = props.get("name") or props.get("brand") or "Local Store"

            # Build address from Geoapify address details
            addr_parts = []
            if props.get("address_line1"):
                addr_parts.append(props["address_line1"])
            if props.get("address_line2"):
                addr_parts.append(props["address_line2"])
            address = ", ".join(addr_parts) if addr_parts else props.get(
                "formatted", "Address not available"
            )

            phone = props.get("contact", {}).get("phone") if isinstance(
                props.get("contact"), dict
            ) else None
            hours = props.get("opening_hours", "Hours not available")

            stores.append(StoreLocation(
                id=props.get("place_id", str(uuid.uuid4())),
                name=name,
                address=address,
                lat=store_lat,
                lng=store_lng,
                distance_km=round(distance, 1),
                phone=phone,
                opening_hours=hours if hours != "Hours not available" else None,
                availability_percent=random.randint(80, 99),
            ))

        stores.sort(key=lambda s: s.distance_km)
        return stores

    except Exception as e:
        print(f"Geoapify error: {e} — using fallback stores")
        return _fallback_stores(lat, lng)


def _fallback_stores(lat: float, lng: float) -> List[StoreLocation]:
    """Hardcoded stores shown when API is unavailable."""
    return [
        StoreLocation(
            id="fallback_1",
            name="FreshMart Organic",
            address="123 Green Street, Colombo 5",
            lat=lat + 0.005,
            lng=lng + 0.003,
            distance_km=0.8,
            phone="+94 11 234 5678",
            opening_hours="8:00 AM - 10:00 PM",
            availability_percent=random.randint(88, 99),
        ),
        StoreLocation(
            id="fallback_2",
            name="Keells Super",
            address="564 Marine Street, Colombo 5",
            lat=lat - 0.004,
            lng=lng + 0.006,
            distance_km=1.2,
            phone="+94 11 234 5678",
            opening_hours="8:00 AM - 10:00 PM",
            availability_percent=random.randint(80, 94),
        ),
        StoreLocation(
            id="fallback_3",
            name="Arpico Supercentre",
            address="789 High Level Road, Colombo 6",
            lat=lat + 0.009,
            lng=lng - 0.005,
            distance_km=1.8,
            phone="+94 11 234 5679",
            opening_hours="9:00 AM - 9:00 PM",
            availability_percent=random.randint(75, 92),
        ),
    ]


async def geocode_address(address: str) -> Optional[dict]:
    """Convert address string to lat/lng using Nominatim (free, no key)."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{NOMINATIM_URL}/search",
                params={"q": address, "format": "json", "limit": 1, "addressdetails": 1},
                headers=HEADERS,
            )
            resp.raise_for_status()
            results = resp.json()
            if results:
                r = results[0]
                return {
                    "lat": float(r["lat"]),
                    "lng": float(r["lon"]),
                    "display_name": r.get("display_name", address),
                }
    except Exception as e:
        print(f"Geocoding error: {e}")
    return None


async def reverse_geocode(lat: float, lng: float) -> str:
    """Convert lat/lng to a human-readable address using Nominatim."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{NOMINATIM_URL}/reverse",
                params={"lat": lat, "lon": lng, "format": "json"},
                headers=HEADERS,
            )
            resp.raise_for_status()
            data = resp.json()
            addr = data.get("address", {})
            parts = []
            if addr.get("road"):
                parts.append(addr["road"])
            if addr.get("suburb") or addr.get("city_district"):
                parts.append(addr.get("suburb") or addr.get("city_district"))
            if addr.get("city") or addr.get("town"):
                parts.append(addr.get("city") or addr.get("town"))
            if addr.get("country"):
                parts.append(addr["country"])
            return ", ".join(parts) if parts else data.get("display_name", f"{lat}, {lng}")
    except Exception as e:
        print(f"Reverse geocoding error: {e}")
        return f"{lat:.4f}, {lng:.4f}"


async def place_order(user_id: str, req: PlaceOrderRequest) -> dict:
    """Save order to Firestore and return order confirmation."""
    db = get_db()
    order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
    now = datetime.utcnow().isoformat()

    order_data = {
        "order_id": order_id,
        "user_id": user_id,
        "status": "confirmed",
        "store_id": req.store_id,
        "store_name": req.store_name,
        "store_address": req.store_address,
        "items": [i.model_dump() for i in req.items],
        "subtotal": req.subtotal,
        "delivery_fee": req.delivery_fee,
        "discount": req.discount or 0.0,
        "total": req.total,
        "promo_code": req.promo_code,
        "estimated_delivery": "30-45 min",
        "created_at": now,
    }

    db.collection("orders").document(order_id).set(order_data)
    db.collection("users").document(user_id).collection("orders").document(order_id).set(order_data)
    db.collection("carts").document(user_id).set(
        {"items": [], "updated_at": now}, merge=True
    )

    # Trigger order placed notification (fire and forget)
    asyncio.create_task(notify_order_placed(
        user_id=user_id,
        order_id=order_id,
        store_name=req.store_name,
        item_count=len(req.items),
        total=req.total,
    ))

    return {
        "order_id": order_id,
        "status": "confirmed",
        "store_name": req.store_name,
        "store_address": req.store_address,
        "items": [i.model_dump() for i in req.items],
        "subtotal": req.subtotal,
        "delivery_fee": req.delivery_fee,
        "discount": req.discount or 0.0,
        "total": req.total,
        "estimated_delivery": "30-45 min",
        "created_at": now,
    }