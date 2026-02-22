
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
user_firebase_key_path = os.getenv("USER_FIREBASE_KEY_PATH", "app/user_firebase-key.json")
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




    food_data_dict=get_nutrients(food, food_type)
    # Dict to store meals nutrients
    per_size_nutrinets = {}
    for nutrient, value in food_data_dict.items():
        # Spliting the amount and unit
        match = re.match(r"([\d.]+)([^\d]+)", value)

        number = float(match.group(1))
        unit = match.group(2)


        # store nutrient values according to the size
        per_size_nutrinets[nutrient] = str((number/100)*size)+unit

    date_doc = str(today)

    # Path of the database
    doc_ref = user_db.collection("users").document(access_token).collection("Nutrients_history").document(date_doc)
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

            # check if the user databse contains the same unit as the newly retirved food
            if unit==current_unit:
                number+=current_number
                # Updating the per_size_nutrients dict with early added food nutrients
                per_size_nutrinets[nutrient] = str(number)+unit

        # Adding the new nutrients numbers
        doc_ref.set(per_size_nutrinets)





    
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
        print(True)
        requirements["Calory_requirement_low"] = str(round(TDEE+TDEE*0.05,2))+"kcal"
        requirements["Calory_requirement_high"] = str(round(TDEE+TDEE*0.2,2))+"kcal"
        requirements["protien_requirement_low"] = str(round(weight*1.6,2))+"g"
        requirements["protien_requirement_high"] = str(round(weight*2.2,2))+"g"
        requirements["carbohydrate_requirement_low"] = str(round(weight*3,2))+"g"
        requirements["carbohydrate_requirement_high"] = str(round(weight*6,2))+"g"
        requirements["fat_calory_requirements_low"] = str(round(weight*0.8,2))+"g"
        requirements["fat_calory_requirements_high"] = str(round(weight*1.2,2))+"g"

    # Create a reference to store the daily requirements
    doc_ref_daily_requirements = user_db.collection("users").document(access_token).collection("personal data").document("Daily Requirements")

    doc_ref_daily_requirements.set(requirements)



    




    

        

    

    
    
    