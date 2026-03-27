import httpx
import random
import math
import uuid
from datetime import datetime
from typing import List, Optional
from app.database.connection import get_db
from app.models.map_models import StoreLocation, PlaceOrderRequest

# ── Overpass API — 100% free, no key needed ───────────────────────────────────
OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# ── Nominatim geocoding — 100% free, no key needed ───────────────────────────
NOMINATIM_URL = "https://nominatim.openstreetmap.org"

HEADERS = {"User-Agent": "NutriFlex-App/1.0 (university project)"}


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculate distance in km between two coordinates."""
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lng / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))


async def get_nearby_stores(lat: float, lng: float, radius_m: int = 3000) -> List[StoreLocation]:
    """
    Query Overpass API for real supermarkets/grocery stores near given coordinates.
    Falls back to hardcoded stores if API is unreachable.
    """
    query = f"""
    [out:json][timeout:15];
    (
      node["shop"="supermarket"](around:{radius_m},{lat},{lng});
      node["shop"="grocery"](around:{radius_m},{lat},{lng});
      node["shop"="convenience"](around:{radius_m},{lat},{lng});
      node["shop"="greengrocer"](around:{radius_m},{lat},{lng});
    );
    out body;
    """
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(
                OVERPASS_URL,
                data={"data": query},
                headers=HEADERS,
            )
            resp.raise_for_status()
            data = resp.json()

        elements = data.get("elements", [])
        stores: List[StoreLocation] = []

        for el in elements[:10]:  # cap at 10 stores
            tags = el.get("tags", {})
            name = tags.get("name") or tags.get("brand") or "Local Store"
            store_lat = el.get("lat", lat)
            store_lng = el.get("lon", lng)
            distance = _haversine_km(lat, lng, store_lat, store_lng)

            # Build address from tags
            addr_parts = []
            if tags.get("addr:housenumber"):
                addr_parts.append(tags["addr:housenumber"])
            if tags.get("addr:street"):
                addr_parts.append(tags["addr:street"])
            if tags.get("addr:city"):
                addr_parts.append(tags["addr:city"])
            address = ", ".join(addr_parts) if addr_parts else "Address not available"

            phone = tags.get("phone") or tags.get("contact:phone")
            hours = tags.get("opening_hours", "Hours not available")

            stores.append(StoreLocation(
                id=str(el.get("id", uuid.uuid4())),
                name=name,
                address=address,
                lat=store_lat,
                lng=store_lng,
                distance_km=round(distance, 1),
                phone=phone,
                opening_hours=hours,
                availability_percent=random.randint(80, 99),
            ))

        # Sort by distance
        stores.sort(key=lambda s: s.distance_km)

        if stores:
            return stores

        # Fallback if no stores found in radius
        return _fallback_stores(lat, lng)

    except Exception as e:
        print(f"Overpass API error: {e} — using fallback stores")
        return _fallback_stores(lat, lng)


def _fallback_stores(lat: float, lng: float) -> List[StoreLocation]:
    """Hardcoded fallback stores used when Overpass is unreachable."""
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
    """Convert address string to lat/lng using Nominatim (free)."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{NOMINATIM_URL}/search",
                params={
                    "q": address,
                    "format": "json",
                    "limit": 1,
                    "addressdetails": 1,
                },
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

    # Save to Firestore: orders/{order_id}
    db.collection("orders").document(order_id).set(order_data)

    # Also save under user's orders subcollection
    db.collection("users").document(user_id).collection("orders").document(order_id).set(order_data)

    # Clear the user's cart after order is placed
    db.collection("carts").document(user_id).set(
        {"items": [], "updated_at": now},
        merge=True,
    )

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