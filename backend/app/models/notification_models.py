from pydantic import BaseModel
from typing import Optional
from enum import Enum


class NotificationType(str, Enum):
    ADD_TO_CART        = "add_to_cart"
    SAVE_RECIPE        = "save_recipe"
    TRENDING_RECIPE    = "trending_recipe"
    ORDER_CONFIRMED    = "order_confirmed"
    FITNESS_DETAILS    = "fitness_details"
    WEEKLY_PROGRESS    = "weekly_progress"


class RegisterTokenRequest(BaseModel):
    user_id: str
    fcm_token: str


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


class BroadcastNotificationRequest(BaseModel):
    title: str
    body: str
    notification_type: NotificationType
