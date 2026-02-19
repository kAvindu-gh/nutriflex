from fastapi import APIRouter, Query, HTTPException
from typing import List
from ..services.recipe_service import recipe_service

router = APIRouter(prefix="/recipes", tags=["Recipes"])

# Get recipe from APIs and Saves to Firebase 'recipes' collection
@router.get("/search")
async def search_recipe(
    query: str = Query(..., min_length=2, description="Recipe name to search")
):
    result = recipe_service.search_complete_recipe(query)
    return result


# Get trending recipes based on search count
@router.get("/trending")
async def get_trending_recipes(
    limit: int = Query(8, ge=1, le=20, description="Number of trending recipes")
):
    result = recipe_service.get_trending_recipes(limit)
    return result

