from pydantic import BaseModel
from typing import Optional
from enum import Enum
from datetime import datetime


class NotificationType(str, Enum):
    ADD_TO_CART        = "add_to_cart"
    SAVE_RECIPE        = "save_recipe"
    TRENDING_RECIPE    = "trending_recipe"
    ORDER_CONFIRMED    = "order_confirmed"
    FITNESS_DETAILS    = "fitness_details"
    WEEKLY_PROGRESS    = "weekly_progress"
    BMI_CALCULATED     = "bmi_calculated"
    MEAL_PREP_UPDATED  = "meal_prep_updated"
    RECIPE_SEARCHED    = "recipe_searched"
    ORDER_PLACED       = "order_placed"


# ── Token registration ────────────────────────────────────────────────────────
class RegisterTokenRequest(BaseModel):
    user_id: str
    fcm_token: str


# ── Existing triggers ─────────────────────────────────────────────────────────
class AddToCartNotificationRequest(BaseModel):
    user_id: str
    ingredient_name: str
    recipe_name: Optional[str] = None


class SaveRecipeNotificationRequest(BaseModel):
    user_id: str
    recipe_name: str
    recipe_id: str


class TrendingRecipeNotificationRequest(BaseModel):
    user_id: str
    recipe_name: str
    recipe_id: str
    trending_rank: Optional[int] = None


class OrderConfirmedNotificationRequest(BaseModel):
    user_id: str
    order_id: str
    store_name: str
    item_count: int


class FitnessNotificationRequest(BaseModel):
    user_id: str
    calories_burned: Optional[float] = None
    steps: Optional[int] = None
    workout_name: Optional[str] = None
    goal_reached: Optional[bool] = False


class WeeklyProgressNotificationRequest(BaseModel):
    user_id: str
    week_number: int
    calories_avg: Optional[float] = None
    workouts_completed: Optional[int] = None
    goal_achieved: Optional[bool] = False


# ── New triggers ──────────────────────────────────────────────────────────────
class BMINotificationRequest(BaseModel):
    user_id: str
    bmi: float
    status: str          # Normal, Overweight, Underweight, Obese
    weight: float
    height: float
    goal: Optional[str] = None


class MealPrepNotificationRequest(BaseModel):
    user_id: str
    rice: str
    meat: str
    vegetable1: str
    vegetable2: str
    mallum: str
    salad: str
    total_calories: Optional[float] = None
    total_protein: Optional[float] = None


class RecipeSearchNotificationRequest(BaseModel):
    user_id: str
    recipe_name: str
    calories: Optional[float] = None
    protein: Optional[float] = None


class OrderPlacedNotificationRequest(BaseModel):
    user_id: str
    order_id: str
    store_name: str
    item_count: int
    total: float


class BroadcastNotificationRequest(BaseModel):
    title: str
    body: str
    notification_type: NotificationType


# ── In-app notification document model (stored in Firestore) ──────────────────
class InAppNotification(BaseModel):
    notification_id: str
    user_id: str
    type: str
    title: str
    body: str
    is_read: bool = False
    created_at: str = ""

    def to_dict(self) -> dict:
        return {
            "notification_id": self.notification_id,
            "user_id": self.user_id,
            "type": self.type,
            "title": self.title,
            "body": self.body,
            "is_read": self.is_read,
            "created_at": self.created_at or datetime.utcnow().isoformat(),
        }