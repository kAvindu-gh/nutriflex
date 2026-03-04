from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum

class Gender(str, Enum):
    MALE   = "male"
    FEMALE = "female"

class ActivityLevel(str, Enum):
    SEDENTARY   = "sedentary"
    LIGHT       = "light"
    MODERATE    = "moderate"
    ACTIVE      = "active"
    VERY_ACTIVE = "very_active"

class Goal(str, Enum):
    WEIGHT_LOSS = "weight_loss"
    MAINTENANCE = "maintenance"
    MUSCLE_GAIN = "muscle_gain"

class BMIInput(BaseModel):
    weight_kg:          float            = Field(..., gt=0, le=300)
    height_cm:          float            = Field(..., gt=0, le=250)
    age:                int              = Field(..., gt=0, le=120)
    gender:             Gender
    activity_level:     ActivityLevel
    goal:               Goal
    medical_conditions: Optional[List[str]] = Field(default=[])

class BMIResponse(BaseModel):
    bmi:            float
    category:       str
    bmr:            float
    tdee:           float
    daily_calories: float
    protein_g:      float  
    carbs_g:        float
    fat_g:          float
    goal:           str
    activity_level: str
    conditions:     List[str]  # recognised conditions that modified the plan
    message:        str