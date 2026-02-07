from fastapi import APIRouter, HTTPException
from ..models.bmi_models import BMIInput, BMIResponse
from ..services.bmi_service import BMIService

router = APIRouter(prefix="/bmi", tags=["BMI Calculator"])

@router.post("/calculate", response_model=BMIResponse)
async def calculate_bmi(data: BMIInput):
    """
    Calculate BMI and daily calorie needs
    
    Example request:
    ```json
    {
        "weight_kg": 70,
        "height_cm": 175,
        "age": 25,
        "gender": "male",
        "activity_level": "moderate",
        "goal": "muscle_gain",
        "medical_conditions": []
    }
    ```
    """
    try:
        # Calculate all metrics
        results = BMIService.calculate_all(
            weight_kg=data.weight_kg,
            height_cm=data.height_cm,
            age=data.age,
            gender=data.gender,
            activity_level=data.activity_level,
            goal=data.goal
        )
        
        # Prepare response message
        message = (
            f"Your BMI is {results['bmi']} ({results['category']}). "
            f"Based on your {data.activity_level.value} activity level and goal to "
            f"{data.goal.value.replace('_', ' ')}, you should aim for "
            f"{results['daily_calories']} calories daily."
        )
        
        return {
            "bmi": results["bmi"],
            "category": results["category"],
            "bmr": results["bmr"],
            "tdee": results["tdee"],
            "daily_calories": results["daily_calories"],
            "goal": data.goal.value,
            "activity_level": data.activity_level.value,
            "message": message
        }
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Calculation error: {str(e)}")

@router.get("/quick")
async def quick_bmi(weight: float, height: float):
    """
    Quick BMI calculation (height in cm)
    """
    try:
        # Convert height cm to meters
        height_m = height / 100
        bmi = weight / (height_m ** 2)
        
        # Determine category
        if bmi < 18.5:
            category = "Underweight"
        elif bmi < 25:
            category = "Normal"
        elif bmi < 30:
            category = "Overweight"
        else:
            category = "Obese"
        
        return {
            "bmi": round(bmi, 2),
            "category": category,
            "weight_kg": weight,
            "height_cm": height
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))