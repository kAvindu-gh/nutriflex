from fastapi import APIRouter, HTTPException
from app.services.notification_service import NotificationService
from app.models.notification_models import (
    RegisterTokenRequest,
    AddToCartNotificationRequest,
    SaveRecipeNotificationRequest,
    TrendingRecipeNotificationRequest,
    OrderConfirmedNotificationRequest,
    FitnessNotificationRequest,
    WeeklyProgressNotificationRequest,
    BMINotificationRequest,
    MealPrepNotificationRequest,
    RecipeSearchNotificationRequest,
    OrderPlacedNotificationRequest,
    BroadcastNotificationRequest,
)

router = APIRouter(prefix="/notifications", tags=["Notifications"])
notification_service = NotificationService()


# ── Register FCM token ────────────────────────────────────────────────────────
@router.post("/register-token")
async def register_token(request: RegisterTokenRequest):
    try:
        await notification_service.register_token(
            user_id=request.user_id, fcm_token=request.fcm_token)
        return {"success": True, "message": "FCM token registered"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Fetch in-app notifications ────────────────────────────────────────────────
@router.get("/{user_id}")
def get_notifications(user_id: str, limit: int = 50):
    """Fetch all in-app notifications for a user, newest first."""
    try:
        notifications = notification_service.get_notifications(user_id, limit)
        return {"notifications": notifications, "count": len(notifications)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Mark one as read ──────────────────────────────────────────────────────────
@router.patch("/{user_id}/{notification_id}/read")
def mark_read(user_id: str, notification_id: str):
    try:
        notification_service.mark_read(user_id, notification_id)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Mark all as read ──────────────────────────────────────────────────────────
@router.patch("/{user_id}/read-all")
def mark_all_read(user_id: str):
    try:
        notification_service.mark_all_read(user_id)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Clear all notifications permanently ───────────────────────────────────────
@router.delete("/{user_id}/clear-all")
def clear_all_notifications(user_id: str):
    """Permanently delete all notifications for a user from Firestore."""
    try:
        notification_service.clear_all_notifications(user_id)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Existing triggers ─────────────────────────────────────────────────────────
@router.post("/add-to-cart")
async def notify_add_to_cart(request: AddToCartNotificationRequest):
    try:
        sent = await notification_service.notify_add_to_cart(
            user_id=request.user_id, ingredient_name=request.ingredient_name,
            recipe_name=request.recipe_name)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/save-recipe")
async def notify_save_recipe(request: SaveRecipeNotificationRequest):
    try:
        sent = await notification_service.notify_save_recipe(
            user_id=request.user_id, recipe_name=request.recipe_name,
            recipe_id=request.recipe_id)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/trending-recipe")
async def notify_trending_recipe(request: TrendingRecipeNotificationRequest):
    try:
        sent = await notification_service.notify_trending_recipe(
            user_id=request.user_id, recipe_name=request.recipe_name,
            recipe_id=request.recipe_id, trending_rank=request.trending_rank)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/order-confirmed")
async def notify_order_confirmed(request: OrderConfirmedNotificationRequest):
    try:
        sent = await notification_service.notify_order_confirmed(
            user_id=request.user_id, order_id=request.order_id,
            store_name=request.store_name, item_count=request.item_count)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/fitness-details")
async def notify_fitness_details(request: FitnessNotificationRequest):
    try:
        sent = await notification_service.notify_fitness_details(
            user_id=request.user_id, calories_burned=request.calories_burned,
            steps=request.steps, workout_name=request.workout_name,
            goal_reached=request.goal_reached)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/weekly-progress")
async def notify_weekly_progress(request: WeeklyProgressNotificationRequest):
    try:
        sent = await notification_service.notify_weekly_progress(
            user_id=request.user_id, week_number=request.week_number,
            calories_avg=request.calories_avg,
            workouts_completed=request.workouts_completed,
            goal_achieved=request.goal_achieved)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── New triggers ──────────────────────────────────────────────────────────────
@router.post("/bmi-calculated")
async def notify_bmi_calculated(request: BMINotificationRequest):
    """Triggered automatically when user calculates BMI."""
    try:
        sent = await notification_service.notify_bmi_calculated(
            user_id=request.user_id, bmi=request.bmi,
            status=request.status, weight=request.weight,
            height=request.height, goal=request.goal)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/meal-prep-updated")
async def notify_meal_prep_updated(request: MealPrepNotificationRequest):
    """Triggered when user hits Update My Recipe on the meal prep page."""
    try:
        sent = await notification_service.notify_meal_prep_updated(
            user_id=request.user_id, rice=request.rice, meat=request.meat,
            vegetable1=request.vegetable1, vegetable2=request.vegetable2,
            mallum=request.mallum, salad=request.salad,
            total_calories=request.total_calories,
            total_protein=request.total_protein)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/recipe-searched")
async def notify_recipe_searched(request: RecipeSearchNotificationRequest):
    """Triggered when user searches and finds a new recipe."""
    try:
        sent = await notification_service.notify_recipe_searched(
            user_id=request.user_id, recipe_name=request.recipe_name,
            calories=request.calories, protein=request.protein)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/order-placed")
async def notify_order_placed(request: OrderPlacedNotificationRequest):
    """Triggered when user confirms & places an order from the map page."""
    try:
        sent = await notification_service.notify_order_placed(
            user_id=request.user_id, order_id=request.order_id,
            store_name=request.store_name, item_count=request.item_count,
            total=request.total)
        return {"success": sent}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Broadcast ─────────────────────────────────────────────────────────────────
@router.post("/broadcast")
async def broadcast(request: BroadcastNotificationRequest):
    try:
        result = await notification_service.broadcast_to_all(
            title=request.title, body=request.body,
            notification_type=request.notification_type)
        return {"success": True, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))