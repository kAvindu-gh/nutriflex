import httpx
import os
from math import radians, cos, sin, asin, sqrt
from datetime import datetime
from app.database import db  # your existing Firestore client

# ── Mapbox API credentials ─────────────────────────────────────────────
MAPBOX_TOKEN = os.getenv("MAPBOX_ACCESS_TOKEN")

# ── Mapbox API endpoints ───────────────────────────────────────────────
MAPBOX_DIRECTIONS_URL = "https://api.mapbox.com/directions/v5/mapbox/driving"
MAPBOX_MATRIX_URL     = "https://api.mapbox.com/directions-matrix/v1/mapbox/driving"


class MapService:

    # ------------------------------------------------------------------ #
    #  Haversine — quick pre-filter before calling Mapbox API            #
    # ------------------------------------------------------------------ #
    def _haversine(self, lat1, lon1, lat2, lon2) -> float:
        R = 6371
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        dlat, dlon = lat2 - lat1, lon2 - lon1
        a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
        return 2 * R * asin(sqrt(a))

    def _format_distance(self, metres: float) -> str:
        if metres < 1000:
            return f"{int(metres)} m"
        return f"{metres / 1000:.1f} km"

    def _format_duration(self, seconds: float) -> str:
        minutes = int(seconds // 60)
        if minutes < 60:
            return f"{minutes} min"
        hours = minutes // 60
        mins  = minutes % 60
        return f"{hours}h {mins}min"

    # ------------------------------------------------------------------ #
    #  1. Get nearby stores with Mapbox Distance Matrix                  #
    # ------------------------------------------------------------------ #
    async def get_nearby_stores(self, user_id, user_lat, user_lng, radius_km=5.0):

        # Step 1: Fetch all stores from Firestore
        stores_docs = list(db.collection("stores").stream())

        # Step 2: Pre-filter by rough Haversine radius
        candidate_stores = []
        for doc in stores_docs:
            store = doc.to_dict()
            store_lat = store.get("latitude")
            store_lng = store.get("longitude")
            if store_lat and store_lng:
                rough_dist = self._haversine(user_lat, user_lng, store_lat, store_lng)
                if rough_dist <= radius_km * 1.5:
                    candidate_stores.append({"id": doc.id, **store})

        if not candidate_stores:
            return []

        # Step 3: Call Mapbox Distance Matrix API
        # Format: "lng,lat;lng,lat;..."  (Mapbox uses lng,lat order!)
        coords = f"{user_lng},{user_lat}"
        for s in candidate_stores:
            coords += f";{s['longitude']},{s['latitude']}"

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{MAPBOX_MATRIX_URL}/{coords}",
                params={
                    "sources":       "0",           # index 0 = user location
                    "annotations":   "distance,duration",
                    "access_token":  MAPBOX_TOKEN
                }
            )
        matrix_data = response.json()

        distances = matrix_data.get("distances", [[]])[0]   # distances from source (user)
        durations = matrix_data.get("durations", [[]])[0]   # durations from source (user)

        # Step 4: Get user's meal plan ingredients
        required_ingredients = await self._get_meal_plan_ingredients(user_id)

        # Step 5: Build response
        nearby_stores = []
        for i, store in enumerate(candidate_stores):
            distance_m   = distances[i + 1] if i + 1 < len(distances) else None
            duration_s   = durations[i + 1] if i + 1 < len(durations) else None

            if distance_m is None:
                continue

            distance_km = round(distance_m / 1000, 1)
            if distance_km > radius_km:
                continue

            # Live ingredient availability from Firestore
            availability = await self._calculate_availability(
                store_id=store["id"],
                required_ingredients=required_ingredients
            )

            # Mapbox deep link (opens Mapbox / navigation app)
            mapbox_url = (
                f"https://www.google.com/maps/dir/?api=1"
                f"&origin={user_lat},{user_lng}"
                f"&destination={store['latitude']},{store['longitude']}"
            )

            nearby_stores.append({
                "store_id":                        store["id"],
                "name":                            store.get("name", ""),
                "address":                         store.get("address", ""),
                "latitude":                        store["latitude"],
                "longitude":                       store["longitude"],
                "distance_km":                     distance_km,
                "distance_text":                   self._format_distance(distance_m),
                "travel_time_min":                 int(duration_s // 60) if duration_s else 0,
                "travel_time_text":                self._format_duration(duration_s) if duration_s else "",
                "rating":                          store.get("rating", 0.0),
                "phone":                           store.get("phone", ""),
                "opening_hours":                   store.get("opening_hours", ""),
                "ingredient_availability_percent": availability,
                "navigation_url":                  mapbox_url
            })

        nearby_stores.sort(key=lambda x: x["distance_km"])
        return nearby_stores

    # ------------------------------------------------------------------ #
    #  2. Get route directions (polyline for Flutter Mapbox map)         #
    # ------------------------------------------------------------------ #
    async def get_directions(self, origin_lat: float, origin_lng: float,
                              store_id: str) -> dict:
        store_doc = db.collection("stores").document(store_id).get()
        if not store_doc.exists:
            raise ValueError(f"Store {store_id} not found")

        store    = store_doc.to_dict()
        dest_lat = store["latitude"]
        dest_lng = store["longitude"]

        # Mapbox coords format: "lng,lat;lng,lat"
        coords = f"{origin_lng},{origin_lat};{dest_lng},{dest_lat}"

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{MAPBOX_DIRECTIONS_URL}/{coords}",
                params={
                    "geometries":    "polyline6",   # encoded polyline for Flutter
                    "overview":      "full",
                    "steps":         "false",
                    "access_token":  MAPBOX_TOKEN
                }
            )
        data = response.json()

        if not data.get("routes"):
            raise ValueError("No route found from Mapbox")

        route    = data["routes"][0]
        polyline = route["geometry"]               # encoded polyline6 string

        return {
            "polyline":         polyline,
            "distance_text":    self._format_distance(route["distance"]),
            "duration_text":    self._format_duration(route["duration"]),
            "destination_lat":  dest_lat,
            "destination_lng":  dest_lng,
        }

    # ------------------------------------------------------------------ #
    #  3. Live ingredient availability for one store                      #
    # ------------------------------------------------------------------ #
    async def get_ingredient_availability(self, store_id: str, user_id: str) -> dict:
        required_ingredients = await self._get_meal_plan_ingredients(user_id)
        availability_percent = await self._calculate_availability(store_id, required_ingredients)
        missing              = await self._get_missing_ingredients(store_id, required_ingredients)

        return {
            "availability_percent":   availability_percent,
            "total_required":         len(required_ingredients),
            "available_count":        len(required_ingredients) - len(missing),
            "missing_ingredients":    missing,
            "next_nearest_store_hint": "HealthyLife Store" if missing else None,
            "last_updated":           datetime.utcnow().isoformat()
        }

    # ------------------------------------------------------------------ #
    #  4. Update live inventory in Firestore                             #
    # ------------------------------------------------------------------ #
    async def update_store_inventory(self, store_id: str, ingredient: str,
                                      in_stock: bool, quantity: int):
        db.collection("store_inventory").document(store_id).set(
            {ingredient: {"in_stock": in_stock, "quantity": quantity,
                          "updated_at": datetime.utcnow().isoformat()}},
            merge=True
        )

    # ------------------------------------------------------------------ #
    #  5. Save selected store                                            #
    # ------------------------------------------------------------------ #
    async def select_store(self, user_id: str, store_id: str) -> dict:
        db.collection("users").document(user_id).update({
            "selected_store_id": store_id,
            "store_selected_at": datetime.utcnow().isoformat()
        })
        store = db.collection("stores").document(store_id).get().to_dict()
        return {"store_id": store_id, "store_name": store.get("name", "")}

    # ------------------------------------------------------------------ #
    #  6. Confirm & place order                                          #
    # ------------------------------------------------------------------ #
    async def confirm_order(self, user_id: str, store_id: str,
                             meal_plan_id: str) -> dict:
        meal_plan_doc = db.collection("meal_plans").document(meal_plan_id).get()
        if not meal_plan_doc.exists:
            raise ValueError(f"Meal plan {meal_plan_id} not found")

        ingredients = meal_plan_doc.to_dict().get("ingredients", [])
        order_data  = {
            "user_id":      user_id,
            "store_id":     store_id,
            "meal_plan_id": meal_plan_id,
            "ingredients":  ingredients,
            "status":       "pending",
            "created_at":   datetime.utcnow().isoformat()
        }
        order_ref = db.collection("orders").add(order_data)
        return {
            "order_id":         order_ref[1].id,
            "status":           "pending",
            "ingredient_count": len(ingredients),
            "created_at":       order_data["created_at"]
        }

    # ------------------------------------------------------------------ #
    #  Private helpers                                                   #
    # ------------------------------------------------------------------ #
    async def _get_meal_plan_ingredients(self, user_id: str) -> list:
        plans = (
            db.collection("meal_plans")
            .where("user_id",   "==", user_id)
            .where("is_active", "==", True)
            .limit(1).stream()
        )
        for plan in plans:
            return plan.to_dict().get("ingredients", [])
        return []

    async def _calculate_availability(self, store_id: str,
                                       required_ingredients: list) -> float:
        if not required_ingredients:
            return 100.0
        doc = db.collection("store_inventory").document(store_id).get()
        if not doc.exists:
            return 0.0
        inventory = doc.to_dict()
        available = sum(
            1 for item in required_ingredients
            if inventory.get(item, {}).get("in_stock", False)
        )
        return round((available / len(required_ingredients)) * 100, 1)

    async def _get_missing_ingredients(self, store_id: str,
                                        required_ingredients: list) -> list:
        if not required_ingredients:
            return []
        doc = db.collection("store_inventory").document(store_id).get()
        if not doc.exists:
            return required_ingredients
        inventory = doc.to_dict()
        return [
            item for item in required_ingredients
            if not inventory.get(item, {}).get("in_stock", False)
        ]
