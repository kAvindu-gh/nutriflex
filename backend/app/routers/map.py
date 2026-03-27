from fastapi import APIRouter, HTTPException, Query
from app.models.map_models import (
    NearbyStoresRequest,
    NearbyStoresResponse,
    PlaceOrderRequest,
    GeocodingRequest,
)
from app.services import map_service
from app.database.connection import get_db

router = APIRouter(prefix="/map", tags=["Map"])


@router.post("/nearby-stores", response_model=NearbyStoresResponse)
async def get_nearby_stores(req: NearbyStoresRequest):
    """Get real nearby grocery/supermarket stores via Overpass API."""
    try:
        stores = await map_service.get_nearby_stores(req.lat, req.lng, req.radius_m)
        location_name = await map_service.reverse_geocode(req.lat, req.lng)
        return NearbyStoresResponse(
            stores=stores,
            user_lat=req.lat,
            user_lng=req.lng,
            location_name=location_name,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/geocode")
async def geocode_address(address: str = Query(..., description="Address to geocode")):
    """Convert a text address to lat/lng coordinates using Nominatim."""
    result = await map_service.geocode_address(address)
    if not result:
        raise HTTPException(status_code=404, detail="Address not found")
    return result


@router.get("/reverse-geocode")
async def reverse_geocode(
    lat: float = Query(...),
    lng: float = Query(...),
):
    """Convert lat/lng to a human-readable address."""
    name = await map_service.reverse_geocode(lat, lng)
    return {"location_name": name, "lat": lat, "lng": lng}


@router.post("/{user_id}/place-order")
async def place_order(user_id: str, req: PlaceOrderRequest):
    """Place an order — saves to Firestore and clears the cart."""
    try:
        result = await map_service.place_order(user_id, req)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/orders")
async def get_user_orders(user_id: str):
    """Get all past orders for a user."""
    try:
        db = get_db()
        docs = db.collection("users").document(user_id)\
                 .collection("orders")\
                 .order_by("created_at", direction="DESCENDING")\
                 .limit(20)\
                 .stream()
        orders = [doc.to_dict() for doc in docs]
        return {"orders": orders}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))