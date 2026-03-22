import requests
import os
import firebase_admin
from firebase_admin import credentials, firestore
from typing import List, Dict, Optional, Any
from datetime import datetime, timedelta
from dotenv import load_dotenv
from .usda_service import usda_service

load_dotenv()

class RecipeService:
    def __init__(self):
        # API Ninjas setup
        self.api_key = os.getenv("API_NINJAS_KEY")
        if not self.api_key:
            print("CRITICAL: No API Ninjas key found in .env file")
        else:
            print("API Ninjas key loaded")

         # Initialize Api Ninjas base url
        self.recipe_api = "https://api.api-ninjas.com/v3/recipe"
        
        # Firebase setup
        try:
            firebase_admin.get_app()
        except ValueError:
            cred_path = os.getenv("FIREBASE_KEY_PATH")
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                print("Firebase initialized !")
            else:
                print("Firebase key not found !")
        
        self.db = firestore.client() if firebase_admin._apps else None
        
        # Cache settings
        self.trending_cache = {
            "recipes": [],
            "last_updated": None,
            "update_interval": timedelta(hours=1)
        }
    
    # Get Recipe details from API Ninjas 
    def get_recipe_from_ninjas(self, query: str) -> Optional[Dict]:
        
        if not self.api_key:
            print("No API Ninjas key configured !")
            return None
        
        try:
            print(f"Calling API Ninjas for: '{query}'")
            
            headers = {"X-Api-Key": self.api_key}
            params = {"title": query}
            
            response = requests.get(
                self.recipe_api, 
                headers=headers, 
                params=params, 
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"Found {len(data)} recipes")
                
                if not data or len(data) == 0:
                    print(f"No recipes found for '{query}'")
                    return None
                
                # Take first recipe
                recipe = data[0]
                print(f"Found: {recipe.get('title', 'Unknown')}")
                
                # Parse ingredients
                ingredients_raw = recipe.get("ingredients", [])
                if isinstance(ingredients_raw, str):
                    ingredients_list = [i.strip() for i in ingredients_raw.split("|") if i.strip()]
                elif isinstance(ingredients_raw, list):
                    ingredients_list = [str(i).strip() for i in ingredients_raw if i and str(i).strip()]
                else:
                    ingredients_list = []
                
                # Parse instructions
                instructions_raw = recipe.get("instructions", [])
                if isinstance(instructions_raw, str):
                    if ". " in instructions_raw:
                        instructions_list = [i.strip() + "." for i in instructions_raw.split(". ") if i.strip() and i.strip() != "."]
                    else:
                        instructions_list = [instructions_raw]
                elif isinstance(instructions_raw, list):
                    instructions_list = [str(step).strip() for step in instructions_raw if step and str(step).strip()]
                else:
                    instructions_list = []
                
                return {
                    "name": recipe.get("title", query.title()),
                    "ingredients": ingredients_list,
                    "instructions": instructions_list
                }
            else:
                print(f"API Ninjas error: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"API Ninjas exception: {e}")
            return None
    
    # Get Nutrition data from USDA Api
    def get_nutrition_from_usda(self, food_name: str) -> Optional[Dict[str, Any]]:
        
        try:
            print(f"Getting USDA nutrition for: '{food_name}'")
            
            # Search USDA by food name
            foods = usda_service.search_foods_by_name(food_name, page_size=1)
            
            if not foods:
                print(f"No USDA data for: {food_name}")
                return None
            
            # Get first result
            food = foods[0]
            fdc_id = food.get("fdcId")
            
            if not fdc_id:
                return None
            
            # Get full nutrition details
            food_details = usda_service.get_food_by_fdc_id(fdc_id)
            
            if not food_details:
                return None
            
            # Extract ALL nutrients using USDA service method
            nutrients = usda_service.extract_all_nutrients(food_details)
            
            # Add metadata
            result = {
                "fdc_id": fdc_id,
                "food_name": food.get("description", food_name),
                "nutrients": nutrients,
                "data_type": food_details.get("dataType", ""),
                "food_category": food_details.get("foodCategory", "")
            }
            
            # Extract key nutrients for easy access
            key_nutrients = {}
            for nutrient_name, nutrient_data in nutrients.items():
                if any(key in nutrient_name.lower() for key in ["energy", "protein", "fat", "carbohydrate"]):
                    key_nutrients[nutrient_name] = nutrient_data
            
            result["key_nutrients"] = key_nutrients
            print(f"Found {len(nutrients)} nutrients for: {food.get('description', food_name)}")
            
            return result
            
        except Exception as e:
            print(f"USDA nutrition error: {e}")
            return None
    
    # Save both recipe and nutrition data to 'recipes' collection using recipe name as ID
    def save_complete_recipe_to_firebase(self, recipe_data: Dict, nutrition_data: Dict) -> Optional[str]:
        
        
        if not self.db:
            print("Firebase not available")
            return None
        
        try:
            recipes_ref = self.db.collection("recipes")
            
            # Create a valid document ID from recipe name
            doc_id = recipe_data["name"].strip().lower()
            doc_id = doc_id.replace(" ", "_")
            doc_id = doc_id.replace("'", "")
            doc_id = doc_id.replace('"', "")
            doc_id = doc_id.replace("/", "_")
            doc_id = doc_id.replace("\\", "_")
            doc_id = doc_id.replace("?", "")
            doc_id = doc_id.replace("!", "")
            doc_id = doc_id.replace(",", "")
            doc_id = doc_id.replace(".", "")
            doc_id = doc_id.replace(":", "")
            doc_id = doc_id.replace(";", "")
            
            # Limit length (Firestore max is 1500 bytes, but keep reasonable)
            if len(doc_id) > 100:
                doc_id = doc_id[:100]
            
            print(f"Using document ID: {doc_id}")
            
            now = datetime.now()
            
            # Prepare complete recipe document
            complete_recipe = {
                "name": recipe_data["name"],
                "ingredients": recipe_data["ingredients"],
                "instructions": recipe_data["instructions"],
                "nutrition": nutrition_data,
                "source": "api_ninjas",
                "last_searched": now,
                "search_count": 1,
                "created_at": now
            }
            
            # Check if document already exists with this ID
            doc_ref = recipes_ref.document(doc_id)
            doc = doc_ref.get()
            
            if doc.exists:
                # Update existing recipe
                existing_data = doc.to_dict()
                current_count = existing_data.get("search_count", 1)
                
                complete_recipe["search_count"] = current_count + 1
                complete_recipe["created_at"] = existing_data.get("created_at", now)
                
                doc_ref.update(complete_recipe)
                print(f"Updated recipe: {recipe_data['name']} (now searched {current_count + 1} times)")
            else:
                # Save new recipe with name as ID
                doc_ref.set(complete_recipe)
                print(f"Saved new recipe with ID: {doc_id}")
            
            # Invalidate cache
            self.trending_cache["last_updated"] = None
            
            return doc_id
            
        except Exception as e:
            print(f"Firebase save error: {e}")
            # Fallback to random ID if name fails
            try:
                fallback_ref = recipes_ref.document()
                fallback_ref.set(complete_recipe)
                print(f"Used fallback random ID: {fallback_ref.id}")
                return fallback_ref.id
            except:
                return None
    
    # Complete Search Flow
    def search_complete_recipe(self, query: str) -> Dict:
      
         # Step 1: Get recipe from API Ninjas
        recipe = self.get_recipe_from_ninjas(query)
        
        if not recipe:
            return {
                "name": f"Recipe not found for '{query}'",
                "ingredients": ["Try searching for: chicken, pasta, fish, rice"],
                "instructions": ["No instructions available"],
                "nutrition": {},
                "source": "not_found",
                "saved_to_firebase": False
            }
        
        # Step 2: Get nutrition from USDA, try with recipe name 
    
        nutrition = self.get_nutrition_from_usda(recipe["name"])
        
        # Try with first ingredient
        if not nutrition and recipe["ingredients"]:
            first_ingredient = recipe["ingredients"][0].split(",")[0].strip()
            nutrition = self.get_nutrition_from_usda(first_ingredient)
        
        # If still no nutrition, create empty structure
        if not nutrition:
            nutrition = {
                "food_name": "Not found in USDA",
                "nutrients": {},
                "key_nutrients": {}
            }
            print("No USDA nutrition data found")
        
        # Step 3: Save to Firebase
        firebase_id = self.save_complete_recipe_to_firebase(recipe, nutrition)
        
        # Step 4: Return combined result
        return {
            "name": recipe["name"],
            "ingredients": recipe["ingredients"],
            "instructions": recipe["instructions"],
            "nutrition": nutrition,
            "source": "api_ninjas",
            "saved_to_firebase": firebase_id is not None,
            "firebase_id": firebase_id
        }
    
    # Get most searched recipes from Firebase 'recipes' collection
    def get_trending_recipes(self, limit: int = 8) -> Dict:
        
        now = datetime.now()
        
        # Check cache
        if (self.trending_cache["last_updated"] and 
            now - self.trending_cache["last_updated"] < self.trending_cache["update_interval"]):
            return {
                "recipes": self.trending_cache["recipes"][:limit],
                "last_updated": self.trending_cache["last_updated"],
                "cache_status": "cached"
            }
        
        if not self.db:
            return {
                "recipes": self._get_mock_trending(limit),
                "last_updated": now,
                "cache_status": "mock (no db)"
            }
        
        try:
            # Get from Firebase 'recipes' collection ordered by search_count
            recipes_ref = self.db.collection("recipes")
            query = recipes_ref.order_by("search_count", direction=firestore.Query.DESCENDING).limit(100)
            docs = query.stream()
            
            trending = []
            for doc in docs:
                data = doc.to_dict()
                
                # Extract calories and protein from nutrition data
                calories = 0
                protein = 0
                fat = 0
                carbs = 0
                
                nutrition = data.get("nutrition", {})
                nutrients = nutrition.get("key_nutrients", {})
                
                # Try to find energy/calories
                for name, values in nutrients.items():
                    name_lower = name.lower()
                    if "energy" in name_lower or "calorie" in name_lower:
                        calories = values.get("value", 0)
                    elif "protein" in name_lower:
                        protein = values.get("value", 0)
                    elif "fat" in name_lower and "total" in name_lower:
                        fat = values.get("value", 0)
                    elif "carbohydrate" in name_lower and "total" in name_lower:
                        carbs = values.get("value", 0)
                
                trending.append({
                    "id": doc.id,
                    "name": data.get("name", "Unknown"),
                    "calories": calories,
                    "protein_g": protein,
                    "fat_g": fat,
                    "carbs_g": carbs,
                    "image_url": None,
                    "search_count": data.get("search_count", 0)
                })
            
            if trending:
                self.trending_cache["recipes"] = trending
                self.trending_cache["last_updated"] = now
                return {
                    "recipes": trending[:limit],
                    "last_updated": now,
                    "cache_status": "fresh"
                }
            
            # Firebase returned no documents yet
            return {
                "recipes": [],
                "last_updated": now,
                "cache_status": "empty"
            }
                
        except Exception as e:
            print(f"Error getting trending: {e}")
            if self.trending_cache["recipes"]:
                return {
                    "recipes": self.trending_cache["recipes"][:limit],
                    "last_updated": self.trending_cache["last_updated"],
                    "cache_status": "cached (error)"
                }
            # Last resort fallback
            return {
                "recipes": [],
                "last_updated": now,
                "cache_status": "error"
            }
          
# Global instance
recipe_service = RecipeService()