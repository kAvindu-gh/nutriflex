from app.database.connection import get_db
from datetime import datetime, timedelta
from typing import Optional


def get_user_summary(user_id: str) -> dict:
    """
    Read all Firestore collections for a user and return a rich summary:
    - Physical measurements (BMI, weight, height, goal)
    - Nutrients history (last 7 days)
    - Meal history (recent meals)
    - Orders (recent orders)
    """
    db = get_db()
    user_ref = db.collection("users").document(user_id)

    # ── 1. Physical measurements ──────────────────────────────────────────────
    bmi_data = {}
    try:
        bmi_doc = user_ref.collection("personal data")\
                          .document("Physical measurements").get()
        if bmi_doc.exists:
            bmi_data = bmi_doc.to_dict() or {}
    except Exception as e:
        print(f"BMI fetch error: {e}")

    # ── 2. Nutrients history (last 7 days) ────────────────────────────────────
    nutrients_history = []
    try:
        docs = user_ref.collection("Nutrients_history")\
                       .order_by("__name__", direction="DESCENDING")\
                       .limit(7).stream()
        for doc in docs:
            data = doc.to_dict() or {}
            nutrients_history.append({
                "date": doc.id,
                "calories": _parse_num(data.get("Energy(kcal)", "0")),
                "protein": _parse_num(data.get("Proteins", "0")),
                "carbs": _parse_num(data.get("Carbohydrates", "0")),
                "fat": _parse_num(data.get("Fat", "0")),
                "fiber": _parse_num(data.get("Fiber", "0")),
            })
        nutrients_history.sort(key=lambda x: x["date"])
    except Exception as e:
        print(f"Nutrients history fetch error: {e}")

    # ── 3. Meal history (recent 10) ───────────────────────────────────────────
    meal_history = []
    try:
        docs = user_ref.collection("Meal_history")\
                       .order_by("__name__", direction="DESCENDING")\
                       .limit(10).stream()
        for doc in docs:
            data = doc.to_dict() or {}
            meal_history.append({
                "timestamp": doc.id,
                **{k: v for k, v in data.items()},
            })
    except Exception as e:
        print(f"Meal history fetch error: {e}")

    # ── 4. Orders history (recent 5) ──────────────────────────────────────────
    orders = []
    try:
        docs = user_ref.collection("orders")\
                       .order_by("created_at", direction="DESCENDING")\
                       .limit(5).stream()
        for doc in docs:
            data = doc.to_dict() or {}
            orders.append({
                "order_id": data.get("order_id", doc.id),
                "store_name": data.get("store_name", ""),
                "total": data.get("total", 0),
                "item_count": len(data.get("items", [])),
                "status": data.get("status", "confirmed"),
                "created_at": data.get("created_at", ""),
            })
    except Exception as e:
        print(f"Orders fetch error: {e}")

    # ── 5. Computed averages ──────────────────────────────────────────────────
    avg_calories = 0.0
    avg_protein = 0.0
    avg_carbs = 0.0
    avg_fat = 0.0
    if nutrients_history:
        n = len(nutrients_history)
        avg_calories = sum(d["calories"] for d in nutrients_history) / n
        avg_protein = sum(d["protein"] for d in nutrients_history) / n
        avg_carbs = sum(d["carbs"] for d in nutrients_history) / n
        avg_fat = sum(d["fat"] for d in nutrients_history) / n

    # ── 6. Daily requirements ─────────────────────────────────────────────────
    daily_req = {}
    try:
        req_doc = user_ref.collection("personal data")\
                          .document("Daily Requirements").get()
        if req_doc.exists:
            daily_req = req_doc.to_dict() or {}
    except Exception as e:
        print(f"Daily req fetch error: {e}")

    return {
        "user_id": user_id,
        # Physical
        "bmi": bmi_data.get("BMI"),
        "bmi_status": bmi_data.get("Status"),
        "weight": bmi_data.get("weight"),
        "height": bmi_data.get("Height"),
        "age": bmi_data.get("Age"),
        "gender": bmi_data.get("Gender"),
        "goal": bmi_data.get("Goal"),
        "activity_level": bmi_data.get("Activity Level"),
        "tdee": bmi_data.get("TDEE"),
        # Nutrients trend (day by day)
        "nutrients_history": nutrients_history,
        # Averages
        "avg_calories": round(avg_calories, 1),
        "avg_protein": round(avg_protein, 1),
        "avg_carbs": round(avg_carbs, 1),
        "avg_fat": round(avg_fat, 1),
        # Meals
        "recent_meals": meal_history,
        "total_meals_logged": len(meal_history),
        # Orders
        "recent_orders": orders,
        "total_orders": len(orders),
        # Daily requirements
        "daily_requirements": daily_req,
    }


def _parse_num(val) -> float:
    """Safely parse a number from Firestore string values like '529.0' or '20.22g'."""
    try:
        if isinstance(val, (int, float)):
            return float(val)
        return float(str(val).replace("g", "").replace("kcal", "").strip())
    except Exception:
        return 0.0