from fastapi import APIRouter, HTTPException
from ..models.bmi_models import BMIInput, BMIResponse
from ..services.bmi_service import BMIService
from app.routers import nutrients

router = APIRouter(prefix="/bmi", tags=["BMI Calculator"])




@router.post("/calculate", response_model=BMIResponse)
async def calculate_bmi(user_id: str, data: BMIInput):

    
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
        # Passing the data to the add_physical_measurements function in nutrients.py
        nutrients.add_physical_measurements(user_id, data.weight_kg, data.height_cm, data.age, data.gender, data.activity_level, data.goal, results["bmi"],results["tdee"], results["category"] )
        nutrients.add_requirements(user_id, results["daily_calories"], results["protein_g"], results["carbs_g"], results["fat_g"] )

        
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