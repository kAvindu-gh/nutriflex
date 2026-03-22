
import os
import httpx
from fastapi import APIRouter
from datetime import datetime
from dotenv import load_dotenv
import re
from datetime import datetime
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
            
            current_nutrient = per_size_nutrinets.get(nutrient,"0g")
            
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
        

def get_consumed_amounts(access_token):
    # Get the current date
    today = datetime.now().date()

    date_doc = str(today)

    # Path of the database
    doc_ref = user_db.collection("users").document(access_token).collection("Nutrients_history").document(date_doc)
    
    if not doc_ref:
        return ["0","0","0","0"]
    
    doc = doc_ref.get()

    data = doc.to_dict()

    # Calories amount in kcal
    calorie_amount = data.get("Energy(kcal)")

    # Protein amount
    proteins_with_unit = data.get("Proteins")
    Proteins_and_unit = re.match(r"([\d.]+)([^\d]+)", proteins_with_unit)

    protein_amount = Proteins_and_unit.group(1)

    # fat amount

    #SFA 
    SFA_with_unit = data.get("SFA")
    SFA_and_unit = re.match(r"([\d.]+)([^\d]+)", SFA_with_unit)
    SFA_amount = float(SFA_and_unit.group(1))

    #PUFA
    PUFA_with_unit = data.get("PUFA")
    PUFA_and_unit = re.match(r"([\d.]+)([^\d]+)", PUFA_with_unit)
    PUFA_amount = float(PUFA_and_unit.group(1))

    #MUFA
    MUFA_with_unit = data.get("MUFA")
    MUFA_and_unit = re.match(r"([\d.]+)([^\d]+)", MUFA_with_unit)
    MUFA_amount = float(MUFA_and_unit.group(1))

    # ALL FAT AMOUNT
    FAT_amount = str(SFA_amount+PUFA_amount+MUFA_amount)

    # Carbohydrate amounts
    Carbs_with_unit = data.get("Carbohydrates")
    Carbs_and_unit = re.match(r"([\d.]+)([^\d]+)", Carbs_with_unit)
    Carbs_amount = float(Carbs_and_unit.group(1))
    

    return calorie_amount, FAT_amount, protein_amount, Carbs_amount


    
@router.post("/add_physical_data_to_user")
def add_physical_measurements(access_token:str,weight:int , height:float, age:int, gender:str, activityLevel:str, goal:str, BMI:str, TDEE:str, status:str ):
    
   




    # Path of the database
    doc_ref = user_db.collection("users").document(access_token).collection("personal data").document("Physical measurements")

    

    user_data = {"weight": weight,
                 "Height": height,
                 "Age": age,
                 "Gender": gender,
                 "BMI":BMI,
                 "TDEE":TDEE,
                 "Status": status,
                 "Goal": goal,
                 "Activity Level": activityLevel}
    
    # Add the data
    doc_ref.set(user_data)



@router.post("/add_daily_nutrient_requirements")
def add_requirements(access_token:str, Calory_requirement_low:str, protien_requirement_low:str, carbohydrate_requirement_low:str,fat_calory_requirements_low:str ):

    

   

    # Dict to store requirements
    requirements = {}

    

    

    
    
    requirements["Calory_requirement_low"] = str(round(Calory_requirement_low/ 4.184,2))+"kcal"
        
    requirements["protien_requirement_low"] = str(protien_requirement_low)+"g"
        
    requirements["carbohydrate_requirement_low"] = str(carbohydrate_requirement_low)+"g"
        
    requirements["fat_calory_requirements_low"] = str(fat_calory_requirements_low)+"g"


    

    # Create a reference to store the daily requirements
    doc_ref_daily_requirements = user_db.collection("users").document(access_token).collection("personal data").document("Daily Requirements")

    doc_ref_daily_requirements.set(requirements)

def get_requirements(access_token:str):

    doc_ref_physical_measurements = user_db.collection("users").document(access_token).collection("personal data").document("Daily Requirements")
    doc= doc_ref_physical_measurements.get()

    
    
    data = doc.to_dict()
    
    return {"Calory_requirement_low":data["Calory_requirement_low"], "Protein_requirement_low": data["protien_requirement_low"], "Carbohydrate_requirement_low": data["carbohydrate_requirement_low"], "Fat_requirement_low":data["fat_calory_requirements_low"]}

@router.post("/Meal_Prep_With_Five_Cards")
def add_meal_plan_to_user(access_token:str, rice:str, rice_size:str, meat:str,meat_size:str, vegetable1: str,vegetable1_size:str, vegetable2: str, vegetable2_size:str, mallum:str,mallum_size:str, salad:str, salad_size:str):
    add_food(access_token, rice, int(rice_size), "rice" )
    add_food(access_token, meat, int(meat_size), "Meat or equivalents" )
    add_food(access_token, vegetable1, int(vegetable1_size), "Vegetables")
    add_food(access_token, vegetable2, int(vegetable2_size), "Vegetables")
    add_food(access_token, mallum, int(mallum_size), "Mallum")
    add_food(access_token, salad, int(salad_size), "Salads")

    requirements_low = get_requirements(access_token)
    consumed_amounts = get_consumed_amounts(access_token)

    # Calculate calory data

    
    
    calory_requirement_with_unit  = requirements_low["Calory_requirement_low"]
    calory_requirement = re.match(r"([\d.]+)([^\d]+)", calory_requirement_with_unit)
    calory_requirement_in_float = float(calory_requirement.group(1))
    calory_consumed_in_float= float(consumed_amounts[0])
    calory_consumed_percentage =  round((calory_consumed_in_float/calory_requirement_in_float)*100,4)


    # Calculate Protein data
    protein_requirement_with_unit  = requirements_low["Protein_requirement_low"]
    protein_requirement = re.match(r"([\d.]+)([^\d]+)", protein_requirement_with_unit)
    protein_requirement_in_float = float(protein_requirement.group(1))
    protein_consumed_in_float= float(consumed_amounts[2])
    protein_consumed_percentage =  round((calory_consumed_in_float/calory_requirement_in_float)*100,4)

    # Calculate carbs data
    carbs_requirement_with_unit  = requirements_low["Carbohydrate_requirement_low"]
    carbs_requirement = re.match(r"([\d.]+)([^\d]+)", carbs_requirement_with_unit)
    carbs_requirement_in_float = float(carbs_requirement.group(1))
    carbs_consumed_in_float= float(consumed_amounts[3])
    carbs_consumed_percentage =  round((carbs_consumed_in_float/carbs_requirement_in_float)*100,4)

    # Calculate fat data
    fat_requirement_with_unit  = requirements_low["Fat_requirement_low"]
    fat_requirement = re.match(r"([\d.]+)([^\d]+)", fat_requirement_with_unit)
    fat_requirement_in_float = float(fat_requirement.group(1))
    fat_consumed_in_float= float(consumed_amounts[1])
    fat_consumed_percentage =  round((fat_consumed_in_float/fat_requirement_in_float)*100,4)


    




    return{"Calory consumed: ":str(calory_consumed_in_float)+"kcal", 
           "Calory requirement: ":str(calory_requirement_in_float)+"kcal",
           "Calory consumed percentage: ": calory_consumed_percentage,
           "Protein consumed: ": str(protein_consumed_in_float)+"g",
           "Protein requirement: ":str(protein_requirement_in_float)+"g",
           "Protein consumed percentage: ": protein_consumed_percentage,
           "Carbohydrate consumed: ": str(carbs_consumed_in_float)+"g",
           "Carbohydrate requirement: ":str(carbs_requirement_in_float)+"g",
           "Carbohydrate consumed percentage: ": carbs_consumed_percentage,
           "Fat consumed: ": str(fat_consumed_in_float)+"g",
           "Fat requirement: ":str(fat_requirement_in_float)+"g",
           "Fat consumed percentage: ": fat_consumed_percentage,}






    

        

    

    
    
    