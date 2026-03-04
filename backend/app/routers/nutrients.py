
import os
import httpx
from fastapi import APIRouter
from datetime import datetime
from dotenv import load_dotenv
import re
from datetime import datetime
from app.routers.bmi import calculate_bmi
import firebase_admin
from firebase_admin import credentials, firestore
from app.services.usda_service import USDAService
from ..services.bmi_service import BMIService
from app.models.bmi_models import Gender, ActivityLevel, Goal


# Load environment variables
load_dotenv()

#use the db in usda_service.py
usda_service = USDAService()
db = usda_service.db

# Initialize the user Firebase
user_firebase_key_path = os.getenv("FIREBASE_KEY_PATH", "app/user_firebase-key.json")
user_cred = credentials.Certificate(user_firebase_key_path)
user_app = firebase_admin.initialize_app(user_cred, name="user_app")
user_db = firestore.client(user_app)



# USDA API Key from environment
USDA_API_KEY = os.getenv("USDA_API_KEY")

router = APIRouter()

            
@router.get("/core_nutrients/")
def get_nutrients(food: str, food_type: str):
    doc = db.collection(food_type).document(food).get()

    if not doc.exists:
        return{"Error": "Food is not found"}
    
    
    
    food_data_dict = doc.to_dict()
    

    return food_data_dict 


@router.get("/add_SriLankanfood_to_user")
def add_food(access_token:str,food:str, size:int, food_type:str):

    # Get the current date
    today = datetime.now().date()
    # Current time
    time_now = datetime.now().time()



    food_data_dict=get_nutrients(food, food_type)
    # Dict to store meals nutrients
    per_size_nutrinets = {}
    for nutrient, value in food_data_dict.items():
        # Spliting the amount and unit
        match = re.match(r"([\d.]+)([^\d]+)", value)

        number = float(match.group(1))
        unit = match.group(2)
        # If there is no unit
        if unit==".":
            per_size_nutrinets[nutrient] = str((number/100)*size)
        else:
        # store nutrient values according to the size
            per_size_nutrinets[nutrient] = str((number/100)*size)+unit

    date_doc = str(today)
    time_doc = str(time_now)

    # Path of the database
    doc_ref = user_db.collection("users").document(access_token).collection("Nutrients_history").document(date_doc)
    # Path of the database to store food name
    food_doc_ref = user_db.collection("users").document(access_token).collection("Meal_history").document(date_doc+"_"+time_doc)
    
    # Adding the food to the firestore
    food_doc_ref.set({"Food: ": food, "Size: ": size})


    if not doc_ref:
        return "no"
    # The actual docuent
    doc = doc_ref.get()

    
    
    data = doc.to_dict()

    if not data:
        doc_ref.set(per_size_nutrinets)
        return "added successfully"
    
    if data:

        for nutrient, value in data.items():
            # Spliting the amount and unit
            match = re.match(r"([\d.]+)([^\d]+)", value)

            number = float(match.group(1))
            unit = match.group(2)
            # getting the current food nutrient
            
            current_nutrient = per_size_nutrinets.get(nutrient,0)
            
            # Spliting the amount and unit
            current_match = re.match(r"([\d.]+)([^\d]+)", current_nutrient)

            current_number = float(current_match.group(1))
            current_unit = current_match.group(2)

            # If there is no unit
            if unit==".":
                number+=current_number
                per_size_nutrinets[nutrient] = str(number)

            # check if the user databse contains the same unit as the newly retirved food
            elif unit==current_unit:
                number+=current_number
                # Updating the per_size_nutrients dict with early added food nutrients
                per_size_nutrinets[nutrient] = str(number)+unit

        # Adding the new nutrients numbers
        doc_ref.set(per_size_nutrinets)
        

def get_calory_amount(access_token):
    # Get the current date
    today = datetime.now().date()

    date_doc = str(today)

    # Path of the database
    doc_ref = user_db.collection("users").document(access_token).collection("Nutrients_history").document(date_doc)
    
    if not doc_ref:
        return "0 kcal"
    
    doc = doc_ref.get()

    data = doc.to_dict()

    # Calories amount in kcal
    calorie_amount = data.get("Energy(kcal)")

    return calorie_amount


    
@router.post("/add_physical_data_to_user")
def add_physical_measurements(access_token:str,weight:int , height:float, age:int, gender:str, activityLevel:str, goal:str):
    
    # Converts the strings to enums
    gender_enum = Gender(gender)
    activity_enum = ActivityLevel(activityLevel)
    goal_enum = Goal(goal)



    results = BMIService.calculate_all(
        weight_kg=weight,
        height_cm=height,
        age=age,
        gender=gender_enum,
        activity_level=activity_enum,
        goal=goal_enum
    )


    

    BMI = results["bmi"]
    status = results["category"]
    TDEE = results["tdee"]


    # Path of the database
    doc_ref = user_db.collection("users").document(access_token).collection("personal data").document("Physical measurements")

    

    user_data = {"weight": weight,
                 "Height": height,
                 "Age": age,
                 "Gender": gender,
                 "BMI":BMI,
                 "TDEE":TDEE,
                 "Status": status,
                 "Goal": goal}
    
    # Add the data
    doc_ref.set(user_data)



@router.post("/add_daily_nutrient_requirements")
def add_requirements(access_token:str):

    doc_ref_physical_measurements = user_db.collection("users").document(access_token).collection("personal data").document("Physical measurements")

    # get the physical measurements
    physical_measurements_document = doc_ref_physical_measurements.get()


    physical_measurements = physical_measurements_document.to_dict()

    # Dict to store requirements
    requirements = {}

    goal = physical_measurements.get("Goal")
    TDEE = physical_measurements.get("TDEE")
    gender = physical_measurements.get("Gender")
    weight = physical_measurements.get("weight")

    

    if goal=="muscle_gain":
    
        requirements["Calory_requirement_low"] = str(round(TDEE+TDEE*0.05,2))+"kcal"
        requirements["Calory_requirement_high"] = str(round(TDEE+TDEE*0.2,2))+"kcal"
        requirements["protien_requirement_loss"] = str(round(weight*1.6,2))+"g"
        requirements["protien_requirement_high"] = str(round(weight*2.2,2))+"g"
        requirements["carbohydrate_requirement_low"] = str(round(weight*3,2))+"g"
        requirements["carbohydrate_requirement_high"] = str(round(weight*6,2))+"g"
        requirements["fat_calory_requirements_low"] = str(round(weight*0.8,2))+"g"
        requirements["fat_calory_requirements_high"] = str(round(weight*1.2,2))+"g"


    elif goal=="maintenance":
        requirements["Calory_requirement_low"] = str(TDEE)+"kcal"
        requirements["Calory_requirement_high"] = str(TDEE)+"kcal"
        requirements["Protein_requirement_low"] = str(round(weight*1,2))+"g"
        requirements["Protein_requirement_high"] = str(round(weight*1.2,2))+"g"
        requirements["carbohydrate_requirement_low"] = str(round(weight*4,2))+"g"
        requirements["carbohydrate_requirement_high"] = str(round(weight*5,2))+"g"
        requirements["fat_calory_requirements_low"] = str(round(weight*0.8,2))+"g"
        requirements["fat_calory_requirements_high"] = str(round(weight*1,2))+"g"

    elif goal=="weight_loss":
        requirements["Calory_requirement_low"] = str(round(TDEE-TDEE*0.2,2))+"kcal"
        requirements["Calory_requirement_high"] = str(round(TDEE-TDEE*0.1,2))+"kcal"
        requirements["Protein_requirement_low"] = str(round(weight*1.6,2))+"g"
        requirements["Protein_requirement_high"] = str(round(weight*2.2,2))+"g"
        requirements["carbohydrate_requirement_low"] = str(round(weight*2,2))+"g"
        requirements["carbohydrate_requirement_high"] = str(round(weight*3,2))+"g"
        requirements["fat_calory_requirements_low"] = str(round(weight*0.6,2))+"g"
        requirements["fat_calory_requirements_high"] = str(round(weight*0.8,2))+"g"
    # Create a reference to store the daily requirements
    doc_ref_daily_requirements = user_db.collection("users").document(access_token).collection("personal data").document("Daily Requirements")

    doc_ref_daily_requirements.set(requirements)

def get_requirements(access_token:str):

    doc_ref_physical_measurements = user_db.collection("users").document(access_token).collection("personal data").document("Daily Requirements")
    doc= doc_ref_physical_measurements.get()

    
    
    data = doc.to_dict()
    print(data)
    return data["Calory_requirement_low"]

@router.post("/Meal_Prep_With_Five_Cards")
def add_meal_plan_to_user(access_token:str, rice:str, rice_size:int, meat:str,meat_size:int, vegetable1: str,vegetable1_size:int, vegetable2: str, vegetable2_size:int, mallum:str,mallum_size:int, salad:str, salad_size:int):
    add_food(access_token, rice, rice_size, "rice" )
    add_food(access_token, meat, meat_size, "Meat or equivalents" )
    add_food(access_token, vegetable1, vegetable1_size, "Vegetables")
    add_food(access_token, vegetable2, vegetable2_size, "Vegetables")
    add_food(access_token, mallum, mallum_size, "Mallum")
    add_food(access_token, salad, salad_size, "Salads")

    calory_requirement_low = get_requirements(access_token)
    consumed_calorie_amount = get_calory_amount(access_token)

    return{"Calory consumed: ":consumed_calorie_amount+"kcal", "Calory requirement: ":calory_requirement_low}






    

        

    

    
    
    