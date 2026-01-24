# import libs
from pydantic import BaseModel

class BMIOutput(BaseModel):
    bmi: float
    status: str

# function of calculate bmi
def calculate_bmi(weight, height):
    # weight = float(input("Enter your weight in kilograms: "))
    # height = float(input("Enter your height in metres: "))
    bmi = weight / (height ** 2)

    if bmi < 18.5:
        status = "Underweight"
    elif 18.5 <= bmi <= 24.9:
        status = "Normal"
    elif 24.9 < bmi <= 29.9:
        status = "Overweight"
    elif 29.9 < bmi <= 34.9:
        status = "Obesity Class 1"
    elif 34.9 < bmi <= 39.9:
        status = "Obesity Class 2"     
    elif 39.9 < bmi:
        status = "Obesity Class 3"


    return BMIOutput(bmi=bmi, status=status)