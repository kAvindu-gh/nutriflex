from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# Response for recipe search
class RecipeSearchResponse(BaseModel):
  
    name: str
    ingredients: List[str]
    instructions: List[str]
    nutrition: Dict[str, Any]  # Full USDA nutrition data
    source: str = "api_ninjas"
    saved_to_firebase: bool = False
    firebase_id: Optional[str] = None

# Recipe display on home page
class TrendingRecipeResponse(BaseModel):

    id: str
    name: str
    calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    image_url: Optional[str] = None
    search_count: int

# Trending recipes response
class TrendingResponse(BaseModel):
    
    recipes: List[TrendingRecipeResponse]
    last_updated: Optional[datetime] = None
    cache_status: str