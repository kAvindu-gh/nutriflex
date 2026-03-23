from fastapi import APIRouter, HTTPException, Query
from ..services.usda_service import usda_service

router = APIRouter(prefix="/usda", tags=["USDA Food Database"])

# Search USDA database by food name and save to Firebase 'foods' collection.
@router.get("/search-by-name")
async def search_by_name_and_save(
    query: str = Query(..., min_length=2, description="Search for food by name and save to Firebase"),
):
    try:
        result = usda_service.search_and_save_by_name(query)
        
        if "error" in result:
            raise HTTPException(status_code=404, detail=result["error"])
        
        return {
            "message": "Food searched and saved successfully",
            "query": query,
            "result": result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")


# Search USDA database by FDC ID and save to Firebase 'foods' collection.
@router.get("/search-by-fdc/{fdc_id}")
async def search_by_fdc_id_and_save(fdc_id: int):
   
    try:
        result = usda_service.search_and_save_by_fdc_id(fdc_id)
        
        if "error" in result:
            raise HTTPException(status_code=404, detail=result["error"])
        
        return {
            "message": "Food searched by FDC ID and saved successfully",
            "fdc_id": fdc_id,
            "result": result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search by FDC ID failed: {str(e)}")


# Get food from the Firebase 'foods' collection by name or ID.
@router.get("/food/{name_or_id}")
async def get_food_from_firebase(name_or_id: str):
    
    try:
        result = usda_service.get_food_from_firebase(name_or_id)
        
        if "error" in result:
            raise HTTPException(status_code=404, detail=result["error"])
        
        if not result.get("found"):
            raise HTTPException(status_code=404, detail="Food not found in Firebase")
        
        return result["data"]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
