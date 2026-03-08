import requests
import os
import firebase_admin
from firebase_admin import credentials, firestore
from typing import Dict, Optional, List, Any
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables from .env file
load_dotenv()

class USDAService:
    # Initialize the USDA Food databases base url.
    BASE_URL = "https://api.nal.usda.gov/fdc/v1"
    
    def __init__(self):
        # Read API key from .env file
        self.api_key = os.getenv("USDA_API_KEY", "DEMO_KEY")
        
        # Initialize Firebase
        try:
            try:
                firebase_admin.get_app()
                self.db = firestore.client()
                print("Firebase already initialized ! ")
            except ValueError:
                cred_path = os.getenv("FIREBASE_KEY_PATH")  
                
                if os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    self.db = firestore.client()
                    print("Firebase initialized with service account ! ")
                else:
                    print("Firebase key not found. Mocking Firebase ! ")
                    self.db = None
        except Exception as e:
            print(f"Firebase init error: {e} ! ")
            self.db = None
    
    # Search USDA database by food name.
    def search_foods_by_name(self, query: str, page_size: int = 10) -> List[Dict]:
        try:
            url = f"{self.BASE_URL}/foods/search"
            params = {
                "api_key": self.api_key,
                "query": query,
                "pageSize": page_size,
                "dataType": ["Survey (FNDDS)", "Foundation"]
            }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            return response.json().get("foods", [])
            
        except Exception as e:
            print(f"Error searching foods: {e}")
            return []
    
    # Get food by USDA FDC ID.
    def get_food_by_fdc_id(self, fdc_id: int) -> Optional[Dict]:
        try:
            url = f"{self.BASE_URL}/food/{fdc_id}"
            params = {"api_key": self.api_key}
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Error getting food by ID {fdc_id}: {e}")
            return None
    
    # Extract ALL nutrients from the USDA database.
    def extract_all_nutrients(self, food_data: Dict) -> Dict[str, Any]:
        nutrients_dict = {}
        
        if "foodNutrients" not in food_data:
            return nutrients_dict
        
        for nutrient in food_data["foodNutrients"]:
            nutrient_info = nutrient.get("nutrient", {})
            nutrient_name = nutrient_info.get("name", "Unknown")
            amount = nutrient.get("amount", 0)
            unit_name = nutrient_info.get("unitName", "")
            
            nutrients_dict[nutrient_name] = {
                "value": amount,
                "unit": unit_name
            }
        
        return nutrients_dict
    
    # Prepare food data in exact Firebase format.
    def prepare_food_for_firebase(self, food_data: Dict) -> Dict[str, Any]:
        if not food_data:
            return {}
        
        # Extract ALL nutrients
        nutrients = self.extract_all_nutrients(food_data)
        
        food_doc = {
            "name": food_data.get("description", "Unknown Food"),
            "fdc_id": str(food_data.get("fdcId", "")),
            "data_type": food_data.get("dataType", ""),
            "publication_date": food_data.get("publicationDate", ""),
            "source": "USDA API",  
            "nutrients": nutrients,  
            "food_category": food_data.get("foodCategory", "Unknown"),
            "saved_at": datetime.utcnow().isoformat() + "Z"
        }
        
        # Add serving size if available
        if "servingSize" in food_data:
            food_doc["serving_size"] = food_data.get("servingSize")
            food_doc["serving_size_unit"] = food_data.get("servingSizeUnit", "")
        
        return food_doc
    
    # Save food to 'foods' collection in Firebase.
    def save_food_to_firebase(self, food_data: Dict) -> Dict[str, Any]:
        if not self.db:
            return {"error": "Firebase not available", "saved": False}
        
        try:
            # Prepare the food document
            food_doc = self.prepare_food_for_firebase(food_data)
            
            if not food_doc:
                return {"error": "Could not prepare food data", "saved": False}
            
            # Get FDC ID for document ID
            fdc_id = food_data.get("fdcId")
            if not fdc_id:
                # Use name as fallback document ID
                doc_id = food_doc["name"].lower().replace(" ", "_").replace(",", "")
            else:
                doc_id = str(fdc_id)
            
            # Save to 'foods' collection
            doc_ref = self.db.collection("foods").document(doc_id)
            doc_ref.set(food_doc)
            
            print(f"Saved food to Firebase: {food_doc['name']} (ID: {doc_id})")
            
            return {
                "success": True,
                "saved": True,
                "document_id": doc_id,
                "name": food_doc["name"],
                "fdc_id": food_doc.get("fdc_id", ""),
                "nutrients_count": len(food_doc.get("nutrients", {}))
            }
            
        except Exception as e:
            print(f"Error saving to Firebase: {e}")
            return {"error": str(e), "saved": False}

    # Search by name and save to Firebase.
    def search_and_save_by_name(self, query: str) -> Dict[str, Any]:
        try:
            # Search for foods
            foods = self.search_foods_by_name(query, page_size=1)
            
            if not foods:
                return {"error": f"No foods found for query: {query}", "saved": False}
            
            # Get the first food's details
            first_food = foods[0]
            fdc_id = first_food.get("fdcId")
            
            if not fdc_id:
                return {"error": "No FDC ID found in search results", "saved": False}
            
            # Get full food details
            full_food_data = self.get_food_by_fdc_id(fdc_id)
            
            if not full_food_data:
                return {"error": f"Could not get details for FDC ID: {fdc_id}", "saved": False}
            
            # Save to Firebase
            save_result = self.save_food_to_firebase(full_food_data)
            
            if save_result.get("saved"):
                return {
                    "success": True,
                    "message": "Food saved to Firebase successfully",
                    "query": query,
                    **save_result
                }
            else:
                return save_result
                
        except Exception as e:
            return {"error": f"Search and save failed: {str(e)}", "saved": False}
    
    # Search by FDC ID and save to Firebase.
    def search_and_save_by_fdc_id(self, fdc_id: int) -> Dict[str, Any]:
        try:
            # Get food details
            food_data = self.get_food_by_fdc_id(fdc_id)
            
            if not food_data:
                return {"error": f"No food found with FDC ID: {fdc_id}", "saved": False}
            
            # Save to Firebase
            save_result = self.save_food_to_firebase(food_data)
            
            if save_result.get("saved"):
                return {
                    "success": True,
                    "message": "Food saved to Firebase successfully",
                    "fdc_id": fdc_id,
                    **save_result
                }
            else:
                return save_result
                
        except Exception as e:
            return {"error": f"Search by FDC ID failed: {str(e)}", "saved": False}
    
    # Get food from Firebase 'foods' collection.
    def get_food_from_firebase(self, name_or_id: str) -> Dict[str, Any]:
        if not self.db:
            return {"error": "Firebase not available"}
        
        try:
            # Try to get by document ID (could be FDC ID or name-based ID)
            doc_ref = self.db.collection("foods").document(name_or_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return {"found": True, "data": doc.to_dict()}
            
            # If not found by direct ID, try searching by name
            query = self.db.collection("foods").where("name", "==", name_or_id).limit(1).get()
            
            if query:
                for doc in query:
                    return {"found": True, "data": doc.to_dict()}
            
            return {"found": False, "error": f"Food not found: {name_or_id}"}
                
        except Exception as e:
            return {"error": str(e)}

# Global instance
usda_service = USDAService()