from typing import Tuple, List, Dict
from ..models.bmi_models import ActivityLevel, Goal, Gender

# ── Health condition rules ─────────────────────────────────────────────────
# Each condition can modify macros and add a note to the plan message.
# Values are multipliers applied to the BASE fat/carb/protein gram targets.
# ──────────────────────────────────────────────────────────────────────────
CONDITION_RULES: Dict[str, Dict] = {
    "diabetes": {
        "carb_multiplier":    0.75,   # reduce carbs by 25 % (low-GI approach)
        "fat_multiplier":     1.0,
        "protein_multiplier": 1.1,    # slightly higher protein
        "calorie_adjustment": 0,
        "note": (
            "You have diabetes. Carbohydrate intake has been reduced by 25 % "
            "to support blood sugar management. Prioritise low-GI foods such as "
            "legumes, vegetables, and whole grains. Monitor portions carefully."
        ),
    },
    "blood pressure": {
        "carb_multiplier":    1.0,
        "fat_multiplier":     0.85,   # reduce saturated-fat-heavy total fat by 15 %
        "protein_multiplier": 1.0,
        "calorie_adjustment": 0,
        "note": (
            "You have high blood pressure. Fat intake has been reduced by 15 % "
            "and sodium-rich foods should be avoided. Focus on potassium-rich foods "
            "like bananas, leafy greens, and low-fat dairy."
        ),
    },
    "cholesterol": {
        "carb_multiplier":    1.0,
        "fat_multiplier":     0.70,   # reduce fat by 30 % (limit saturated/trans fats)
        "protein_multiplier": 1.05,
        "calorie_adjustment": 0,
        "note": (
            "You have high cholesterol. Fat intake has been reduced by 30 %. "
            "Avoid saturated and trans fats. Prefer unsaturated fats from sources "
            "like olive oil, avocado, and nuts. Increase soluble fibre intake."
        ),
    },
}


class BMIService:

    @staticmethod
    def calculate_bmi(weight_kg: float, height_cm: float) -> Tuple[float, str]:
        if weight_kg <= 0 or height_cm <= 0:
            raise ValueError("Height and weight must be greater than zero.")

        height_m = height_cm / 100
        bmi = weight_kg / (height_m ** 2)

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

    @staticmethod
    def calculate_bmr(weight_kg: float, height_cm: float, age: int, gender: Gender) -> float:
        if gender == Gender.MALE:
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
        else:
            bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
        return round(bmr, 2)

    @staticmethod
    def calculate_tdee(bmr: float, activity_level: ActivityLevel) -> float:
        multipliers = {
            ActivityLevel.SEDENTARY:   1.2,
            ActivityLevel.LIGHT:       1.375,
            ActivityLevel.MODERATE:    1.55,
            ActivityLevel.ACTIVE:      1.725,
            ActivityLevel.VERY_ACTIVE: 1.9,
        }
        return round(bmr * multipliers.get(activity_level, 1.2), 2)

    @staticmethod
    def adjust_for_goal(tdee: float, goal: Goal) -> float:
        adjustments = {
            Goal.WEIGHT_LOSS: -500,
            Goal.MAINTENANCE: 0,
            Goal.MUSCLE_GAIN: 300,
        }
        return round(tdee + adjustments.get(goal, 0), 2)

    @staticmethod
    def base_macros(daily_calories: float) -> Dict[str, float]:
        """
        Default macro split (no conditions):
          Protein 30 % · Carbs 45 % · Fat 25 %
        Protein & carbs = 4 kcal/g · Fat = 9 kcal/g
        """
        return {
            "protein_g": round((daily_calories * 0.30) / 4, 1),
            "carbs_g":   round((daily_calories * 0.45) / 4, 1),
            "fat_g":     round((daily_calories * 0.25) / 9, 1),
        }

    @staticmethod
    def apply_conditions(
        macros: Dict[str, float],
        medical_conditions: List[str],
    ) -> Tuple[Dict[str, float], List[str], List[str]]:
        """
        Apply condition rules to macros.
        Returns adjusted macros, list of matched condition keys, list of notes.
        """
        matched_keys: List[str] = []
        notes:        List[str] = []

        # Accumulate multipliers (multiple conditions stack)
        carb_mult    = 1.0
        fat_mult     = 1.0
        protein_mult = 1.0

        for raw in medical_conditions:
            key = raw.strip().lower()
            if key in CONDITION_RULES:
                rule = CONDITION_RULES[key]
                carb_mult    *= rule["carb_multiplier"]
                fat_mult     *= rule["fat_multiplier"]
                protein_mult *= rule["protein_multiplier"]
                matched_keys.append(raw)
                notes.append(rule["note"])

        adjusted = {
            "protein_g": round(macros["protein_g"] * protein_mult, 1),
            "carbs_g":   round(macros["carbs_g"]   * carb_mult,    1),
            "fat_g":     round(macros["fat_g"]      * fat_mult,     1),
        }
        return adjusted, matched_keys, notes

    @staticmethod
    def build_message(
        bmi: float,
        category: str,
        goal: Goal,
        activity_level: ActivityLevel,
        daily_calories: float,
        condition_notes: List[str],
    ) -> str:
        goal_text = {
            Goal.WEIGHT_LOSS: "lose weight",
            Goal.MAINTENANCE: "maintain your weight",
            Goal.MUSCLE_GAIN: "build muscle",
        }.get(goal, goal.value)

        base = (
            f"Your BMI is {bmi} ({category}). "
            f"Based on your {activity_level.value.replace('_', ' ')} activity level "
            f"and goal to {goal_text}, you should aim for "
            f"{int(daily_calories)} calories daily."
        )

        if condition_notes:
            base += "\n\n⚕ Special health condition adjustments applied:\n"
            for note in condition_notes:
                base += f"\n• {note}"

        return base

    @staticmethod
    def calculate_all(
        weight_kg: float,
        height_cm: float,
        age: int,
        gender: Gender,
        activity_level: ActivityLevel,
        goal: Goal,
        medical_conditions: List[str],
    ) -> dict:
        bmi, category     = BMIService.calculate_bmi(weight_kg, height_cm)
        bmr               = BMIService.calculate_bmr(weight_kg, height_cm, age, gender)
        tdee              = BMIService.calculate_tdee(bmr, activity_level)
        daily_calories    = BMIService.adjust_for_goal(tdee, goal)

        macros            = BMIService.base_macros(daily_calories)
        macros, matched, notes = BMIService.apply_conditions(macros, medical_conditions)

        message = BMIService.build_message(
            bmi, category, goal, activity_level, daily_calories, notes
        )

        return {
            "bmi":            bmi,
            "category":       category,
            "bmr":            bmr,
            "tdee":           tdee,
            "daily_calories": daily_calories,
            "protein_g":      macros["protein_g"],
            "carbs_g":        macros["carbs_g"],
            "fat_g":          macros["fat_g"],
            "conditions":     matched,
            "message":        message,
        }