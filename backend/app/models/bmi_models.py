from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum

class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"

class ActivityLevel(str, Enum):
    SEDENTARY = "sedentary"      # Little/no exercise
    LIGHT = "light"              # Light exercise 1-3 days/week
    MODERATE = "moderate"        # Moderate exercise 3-5 days/week
    ACTIVE = "active"            # Hard exercise 6-7 days/week
    VERY_ACTIVE = "very_active"  # Very hard exercise + physical job

class Goal(str, Enum):
    WEIGHT_LOSS = "weight_loss"
    MAINTENANCE = "maintenance"
    MUSCLE_GAIN = "muscle_gain"

class BMIInput(BaseModel):
    weight_kg: float = Field(..., gt=0, le=300, description="Weight in kilograms")
    height_cm: float = Field(..., gt=0, le=250, description="Height in centimeters")
    age: int = Field(..., gt=0, le=120, description="Age in years")
    gender: Gender
    activity_level: ActivityLevel
    goal: Goal
    medical_conditions: Optional[List[str]] = Field(default=[], description="List of medical conditions")

class BMIResponse(BaseModel):
    bmi: float = Field(..., description="Calculated BMI value")
    category: str = Field(..., description="BMI category")
    bmr: float = Field(..., description="Basal Metabolic Rate")
    tdee: float = Field(..., description="Total Daily Energy Expenditure")
    daily_calories: float = Field(..., description="Recommended daily calories")
    goal: str
    activity_level: str
    message: str