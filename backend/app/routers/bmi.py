from fastapi import APIRouter, HTTPException
from ..models.bmi_models import BMIInput, BMIResponse
from ..services.bmi_service import BMIService

router = APIRouter(prefix="/bmi", tags=["BMI Calculator"])

@router.post("/calculate", response_model=BMIResponse)
async def calculate_bmi(data: BMIInput):
    try:
        results = BMIService.calculate_all(
            weight_kg=data.weight_kg,
            height_cm=data.height_cm,
            age=data.age,
            gender=data.gender,
            activity_level=data.activity_level,
            goal=data.goal,
            medical_conditions=data.medical_conditions or [],
        )
        return {
            "bmi":            results["bmi"],
            "category":       results["category"],
            "bmr":            results["bmr"],
            "tdee":           results["tdee"],
            "daily_calories": results["daily_calories"],
            "protein_g":      results["protein_g"],
            "carbs_g":        results["carbs_g"],
            "fat_g":          results["fat_g"],
            "goal":           data.goal.value,
            "activity_level": data.activity_level.value,
            "conditions":     results["conditions"],
            "message":        results["message"],
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Calculation error: {str(e)}")