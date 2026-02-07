from typing import Tuple
from ..models.bmi_models import ActivityLevel, Goal, Gender

class BMIService:
    
    # Calculate BMI and category.
    @staticmethod
    def calculate_bmi(weight_kg: float, height_cm: float) -> Tuple[float, str]:
        """  Formula: BMI = weight(kg) / (height(m))²  """
        
        # Convert cm to meters
        height_m = height_cm / 100
        
        # Calculate BMI
        bmi = weight_kg / (height_m ** 2)
        
        # Determine category
        if bmi < 18.5:
            category = "Underweight"
        elif bmi < 25:
            category = "Normal"
        elif bmi < 30:
            category = "Overweight"
        elif bmi < 35:
            category = "Obesity Class 1"
        elif bmi < 40:
            category = "Obesity Class 2"
        else:
            category = "Obesity Class 3"
        
        return round(bmi, 2), category
    
    # Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation.
    @staticmethod
    def calculate_bmr(weight_kg: float, height_cm: float, age: int, gender: Gender) -> float:
    
        if gender == Gender.MALE:
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
        else:  # FEMALE
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
        
        return round(bmr, 2)
    

    # Calculate Total Daily Energy Expenditure (TDEE).
    @staticmethod
    def calculate_tdee(bmr: float, activity_level: ActivityLevel) -> float:
        
        activity_multipliers = {
            ActivityLevel.SEDENTARY: 1.2,
            ActivityLevel.LIGHT: 1.375,
            ActivityLevel.MODERATE: 1.55,
            ActivityLevel.ACTIVE: 1.725,
            ActivityLevel.VERY_ACTIVE: 1.9
        }
        
        multiplier = activity_multipliers.get(activity_level, 1.2)
        return round(bmr * multiplier, 2)
    
    #  Adjust calories based on fitness goal.
    @staticmethod
    def adjust_for_goal(tdee: float, goal: Goal) -> float:
        
        goal_adjustments = {
            Goal.WEIGHT_LOSS: -500,    # 500 calorie deficit
            Goal.MAINTENANCE: 0,
            Goal.MUSCLE_GAIN: 300      # 300 calorie surplus
        }
        
        adjustment = goal_adjustments.get(goal, 0)
        return round(tdee + adjustment, 2)
    
    @staticmethod
    def calculate_all(
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: Gender,
        activity_level: ActivityLevel,
        goal: Goal
    ) -> dict:
        
        """
        Calculate all metrics at once
        """
        # 1. Calculate BMI
        bmi, category = BMIService.calculate_bmi(weight_kg, height_cm)
        
        # 2. Calculate BMR
        bmr = BMIService.calculate_bmr(weight_kg, height_cm, age, gender)
        
        # 3. Calculate TDEE
        tdee = BMIService.calculate_tdee(bmr, activity_level)
        
        # 4. Adjust for goal
        daily_calories = BMIService.adjust_for_goal(tdee, goal)
        
        return {
            "bmi": bmi,
            "category": category,
            "bmr": bmr,
            "tdee": tdee,
            "daily_calories": daily_calories
        }