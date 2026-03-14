from fastapi import APIRouter, HTTPException, Query
from app.services.map_service import MapService
from app.models.map_models import StoreSelectionRequest, OrderConfirmRequest, UpdateInventoryRequest

router = APIRouter(prefix="/map", tags=["Map"])
map_service = MapService()


@router.get("/nearby-stores")
async def get_nearby_stores(
    user_id: str = Query(...),
    latitude: float = Query(...),
    longitude: float = Query(...),
    radius_km: float = Query(default=5.0)
):
    """
    Get nearby stores using Google Maps Distance Matrix API.
    Returns real driving distance, travel time, and live ingredient availability.
    """
    try:
        stores = await map_service.get_nearby_stores(
            user_id=user_id,
            user_lat=latitude,
            user_lng=longitude,
            radius_km=radius_km
        )
        return {"success": True, "stores": stores, "count": len(stores)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/store/{store_id}/availability")
async def get_store_availability(
    store_id: str,
    user_id: str = Query(...)
):
    """
    Get LIVE ingredient availability % for a specific store.
    """
    try:
        availability = await map_service.get_ingredient_availability(
            store_id=store_id,
            user_id=user_id
        )
        return {"success": True, "store_id": store_id, **availability}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/directions")
async def get_directions(
    origin_lat: float = Query(...),
    origin_lng: float = Query(...),
    store_id: str = Query(...)
):
    """
    Get route polyline from user location to store using Google Directions API.
    Flutter uses this polyline to draw the route on the map.
    """
    try:
        directions = await map_service.get_directions(
            origin_lat=origin_lat,
            origin_lng=origin_lng,
            store_id=store_id
        )
        return {"success": True, **directions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/update-inventory")
async def update_inventory(request: UpdateInventoryRequest):
    """
    Update live inventory for a store in Firestore.
    Call this whenever a store's stock changes.
    """
    try:
        await map_service.update_store_inventory(
            store_id=request.store_id,
            ingredient=request.ingredient,
            in_stock=request.in_stock,
            quantity=request.quantity
        )
        return {"success": True, "message": "Inventory updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/select-store")
async def select_store(request: StoreSelectionRequest):
    try:
        result = await map_service.select_store(
            user_id=request.user_id,
            store_id=request.store_id
        )
        return {"success": True, "message": "Store selected successfully", **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/confirm-order")
async def confirm_order(request: OrderConfirmRequest):
    try:
        order = await map_service.confirm_order(
            user_id=request.user_id,
            store_id=request.store_id,
            meal_plan_id=request.meal_plan_id
        )
        return {"success": True, "message": "Order placed successfully", "order": order}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

