import os
import re
import httpx
from fastapi import APIRouter
from datetime import datetime
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from app.services.usda_service import USDAService
from ..services.bmi_service import BMIService
from app.models.bmi_models import Gender, ActivityLevel, Goal

load_dotenv()

usda_service = USDAService()
db = usda_service.db

# ── Firebase init ─────────────────────────────────────────────────────────────
user_firebase_key_path = os.getenv("FIREBASE_KEY_PATH", "app/database/firebase_key.json")
user_cred = credentials.Certificate(user_firebase_key_path)
user_app  = firebase_admin.initialize_app(user_cred, name="user_app")
user_db   = firestore.client(user_app)

USDA_API_KEY = os.getenv("USDA_API_KEY")
router = APIRouter()


# ── Helpers ───────────────────────────────────────────────────────────────────

def _parse_value(value: str):
    """Parse '12.5g' → (12.5, 'g')  |  '12.5' → (12.5, '')  |  '12.5.' → (12.5, '.')"""
    if not value:
        return 0.0, ''
    value = str(value).strip()
    match = re.match(r"^([\d.]+)(.*)$", value)
    if not match:
        return 0.0, ''
    try:
        number = float(match.group(1))
        unit   = match.group(2).strip()
        return number, unit
    except ValueError:
        return 0.0, ''


def _format_value(number: float, unit: str) -> str:
    """Format (12.5, 'g') → '12.5g'  |  (12.5, '') → '12.5'  |  (12.5, '.') → '12.5'"""
    if unit and unit != '.':
        return f"{number}{unit}"
    return str(number)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/core_nutrients/")
def get_nutrients(food: str, food_type: str):
    doc = db.collection(food_type).document(food).get()
    if not doc.exists:
        return {"Error": "Food is not found"}
    return doc.to_dict()


@router.get("/add_SriLankanfood_to_user")
def add_food(access_token: str, food: str, size: int, food_type: str):
    today    = datetime.now().date()
    time_now = datetime.now().time()

    food_data_dict = get_nutrients(food, food_type)
    if "Error" in food_data_dict:
        return food_data_dict

    # Scale nutrients by size (per 100g basis)
    per_size_nutrients = {}
    for nutrient, value in food_data_dict.items():
        number, unit = _parse_value(str(value))
        scaled = (number / 100.0) * size
        per_size_nutrients[nutrient] = _format_value(scaled, unit)

    date_doc = str(today)
    time_doc = str(time_now)

    doc_ref      = user_db.collection("users").document(access_token)\
                          .collection("Nutrients_history").document(date_doc)
    food_doc_ref = user_db.collection("users").document(access_token)\
                          .collection("Meal_history").document(f"{date_doc}_{time_doc}")

    # Save food entry
    food_doc_ref.set({"Food": food, "Size": size})

    # Get existing nutrients for today
    doc  = doc_ref.get()
    data = doc.to_dict()

    if not data:
        # First food of the day — just set
        doc_ref.set(per_size_nutrients)
        return "added successfully"

    # Accumulate on top of existing nutrients
    merged = dict(per_size_nutrients)  # start with new food values
    for nutrient, existing_value in data.items():
        existing_num, existing_unit = _parse_value(str(existing_value))
        new_num, new_unit           = _parse_value(merged.get(nutrient, "0"))
        total = existing_num + new_num
        # Preserve original unit
        unit  = existing_unit if existing_unit else new_unit
        merged[nutrient] = _format_value(total, unit)

    doc_ref.set(merged)
    return "added successfully"


def get_consumed_amounts(access_token: str):
    """Returns (calories, fat, protein, carbs) as floats."""
    today    = datetime.now().date()
    date_doc = str(today)

    doc_ref = user_db.collection("users").document(access_token)\
                     .collection("Nutrients_history").document(date_doc)
    doc     = doc_ref.get()

    if not doc.exists:
        return 0.0, 0.0, 0.0, 0.0

    data = doc.to_dict() or {}

    calories = _parse_value(data.get("Energy(kcal)", "0"))[0]
    protein  = _parse_value(data.get("Proteins",      "0"))[0]
    sfa      = _parse_value(data.get("SFA",            "0"))[0]
    pufa     = _parse_value(data.get("PUFA",           "0"))[0]
    mufa     = _parse_value(data.get("MUFA",           "0"))[0]
    fat      = sfa + pufa + mufa
    carbs    = _parse_value(data.get("Carbohydrates",  "0"))[0]

    # Returns: (calories[0], fat[1], protein[2], carbs[3])
    return calories, fat, protein, carbs


@router.post("/add_physical_data_to_user")
def add_physical_measurements(access_token: str, weight: int, height: float,
                               age: int, gender: str, activityLevel: str,
                               goal: str, BMI: str, TDEE: str, status: str):
    doc_ref = user_db.collection("users").document(access_token)\
                     .collection("personal data").document("Physical measurements")
    doc_ref.set({
        "weight": weight, "Height": height, "Age": age,
        "Gender": gender, "BMI": BMI, "TDEE": TDEE,
        "Status": status, "Goal": goal, "Activity Level": activityLevel
    })


@router.post("/add_daily_nutrient_requirements")
def add_requirements(access_token: str, Calory_requirement_low: str,
                     protien_requirement_low: str,
                     carbohydrate_requirement_low: str,
                     fat_calory_requirements_low: str):
    requirements = {
        "Calory_requirement_low":       f"{round(float(Calory_requirement_low) / 4.184, 2)}kcal",
        "protien_requirement_low":      f"{protien_requirement_low}g",
        "carbohydrate_requirement_low": f"{carbohydrate_requirement_low}g",
        "fat_calory_requirements_low":  f"{fat_calory_requirements_low}g",
    }
    doc_ref = user_db.collection("users").document(access_token)\
                     .collection("personal data").document("Daily Requirements")
    doc_ref.set(requirements)


def get_requirements(access_token: str):
    doc_ref = user_db.collection("users").document(access_token)\
                     .collection("personal data").document("Daily Requirements")
    doc  = doc_ref.get()
    data = doc.to_dict() or {}
    return {
        "Calory_requirement_low":       data.get("Calory_requirement_low",       "2400kcal"),
        "Protein_requirement_low":      data.get("protien_requirement_low",      "150g"),
        "Carbohydrate_requirement_low": data.get("carbohydrate_requirement_low", "620g"),
        "Fat_requirement_low":          data.get("fat_calory_requirements_low",  "220g"),
    }


@router.post("/Meal_Prep_With_Five_Cards")
def add_meal_plan_to_user(access_token: str,
                           rice: str,       rice_size: str,
                           meat: str,       meat_size: str,
                           vegetable1: str, vegetable1_size: str,
                           vegetable2: str, vegetable2_size: str,
                           mallum: str,     mallum_size: str,
                           salad: str,      salad_size: str):

    # Add each food to Firestore
    add_food(access_token, rice,       int(rice_size),       "rice")
    add_food(access_token, meat,       int(meat_size),       "Meat or equivalents")
    add_food(access_token, vegetable1, int(vegetable1_size), "Vegetables")
    add_food(access_token, vegetable2, int(vegetable2_size), "Vegetables")
    add_food(access_token, mallum,     int(mallum_size),     "Mallum")
    add_food(access_token, salad,      int(salad_size),      "Salads")

    # Get totals and requirements
    requirements = get_requirements(access_token)
    # consumed: (calories[0], fat[1], protein[2], carbs[3])
    consumed = get_consumed_amounts(access_token)

    cal_consumed  = consumed[0]
    fat_consumed  = consumed[1]
    prot_consumed = consumed[2]
    carb_consumed = consumed[3]

    cal_req  = _parse_value(requirements["Calory_requirement_low"])[0]  or 2400
    prot_req = _parse_value(requirements["Protein_requirement_low"])[0] or 150
    carb_req = _parse_value(requirements["Carbohydrate_requirement_low"])[0] or 620
    fat_req  = _parse_value(requirements["Fat_requirement_low"])[0]     or 220

    def _pct(consumed_val: float, req: float) -> float:
        if req == 0:
            return 0.0
        return round((consumed_val / req) * 100, 4)

    return {
        "Calory consumed: ":                  f"{cal_consumed}kcal",
        "Calory requirement: ":               f"{cal_req}kcal",
        "Calory consumed percentage: ":       _pct(cal_consumed,  cal_req),
        "Protein consumed: ":                 f"{prot_consumed}g",
        "Protein requirement: ":              f"{prot_req}g",
        "Protein consumed percentage: ":      _pct(prot_consumed, prot_req),
        "Carbohydrate consumed: ":            f"{carb_consumed}g",
        "Carbohydrate requirement: ":         f"{carb_req}g",
        "Carbohydrate consumed percentage: ": _pct(carb_consumed, carb_req),
        "Fat consumed: ":                     f"{fat_consumed}g",
        "Fat requirement: ":                  f"{fat_req}g",
        "Fat consumed percentage: ":          _pct(fat_consumed,  fat_req),
    }