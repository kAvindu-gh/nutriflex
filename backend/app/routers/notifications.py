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
    BroadcastNotificationRequest,
)

router = APIRouter(prefix="/notifications", tags=["Notifications"])
notification_service = NotificationService()


# ── Register FCM token on app launch / login ──────────────────────────
@router.post("/register-token")
async def register_token(request: RegisterTokenRequest):
    """
    Call this every time the user opens the app.
    Saves the FCM device token to Firestore so we can send push notifications.
    """
    try:
        await notification_service.register_token(
            user_id=request.user_id,
            fcm_token=request.fcm_token
        )
        return {"success": True, "message": "FCM token registered"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 1. Ingredient added to cart ───────────────────────────────────────
@router.post("/add-to-cart")
async def notify_add_to_cart(request: AddToCartNotificationRequest):
    """
    Triggered when user adds an ingredient to their cart.
    """
    try:
        sent = await notification_service.notify_add_to_cart(
            user_id=request.user_id,
            ingredient_name=request.ingredient_name,
            recipe_name=request.recipe_name
        )
        return {"success": sent, "message": "Add to cart notification sent" if sent else "Token not found"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 2. Recipe saved ───────────────────────────────────────────────────
@router.post("/save-recipe")
async def notify_save_recipe(request: SaveRecipeNotificationRequest):
    """
    Triggered when user saves/favourites a recipe.
    """
    try:
        sent = await notification_service.notify_save_recipe(
            user_id=request.user_id,
            recipe_name=request.recipe_name,
            recipe_id=request.recipe_id
        )
        return {"success": sent, "message": "Save recipe notification sent" if sent else "Token not found"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 3. Trending recipe ────────────────────────────────────────────────
@router.post("/trending-recipe")
async def notify_trending_recipe(request: TrendingRecipeNotificationRequest):
    """
    Triggered when a recipe the user might like starts trending.
    """
    try:
        sent = await notification_service.notify_trending_recipe(
            user_id=request.user_id,
            recipe_name=request.recipe_name,
            recipe_id=request.recipe_id,
            trending_rank=request.trending_rank
        )
        return {"success": sent, "message": "Trending recipe notification sent" if sent else "Token not found"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 4. Order confirmed ────────────────────────────────────────────────
@router.post("/order-confirmed")
async def notify_order_confirmed(request: OrderConfirmedNotificationRequest):
    """
    Triggered automatically when an order is confirmed in the map page.
    """
    try:
        sent = await notification_service.notify_order_confirmed(
            user_id=request.user_id,
            order_id=request.order_id,
            store_name=request.store_name,
            item_count=request.item_count
        )
        return {"success": sent, "message": "Order confirmed notification sent" if sent else "Token not found"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 5. Fitness details ────────────────────────────────────────────────
@router.post("/fitness-details")
async def notify_fitness_details(request: FitnessNotificationRequest):
    """
    Triggered when user completes a workout or hits a daily fitness goal.
    """
    try:
        sent = await notification_service.notify_fitness_details(
            user_id=request.user_id,
            calories_burned=request.calories_burned,
            steps=request.steps,
            workout_name=request.workout_name,
            goal_reached=request.goal_reached
        )
        return {"success": sent, "message": "Fitness notification sent" if sent else "Token not found"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 6. Weekly progress ────────────────────────────────────────────────
@router.post("/weekly-progress")
async def notify_weekly_progress(request: WeeklyProgressNotificationRequest):
    """
    Triggered every week (use a scheduler like APScheduler) to send
    a weekly progress summary to the user.
    """
    try:
        sent = await notification_service.notify_weekly_progress(
            user_id=request.user_id,
            week_number=request.week_number,
            calories_avg=request.calories_avg,
            workouts_completed=request.workouts_completed,
            goal_achieved=request.goal_achieved
        )
        return {"success": sent, "message": "Weekly progress notification sent" if sent else "Token not found"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── 7. Broadcast to all users (e.g. new trending recipes) ────────────
@router.post("/broadcast")
async def broadcast(request: BroadcastNotificationRequest):
    """
    Send a push notification to ALL users.
    Use for trending recipes, app-wide announcements, etc.
    """
    try:
        result = await notification_service.broadcast_to_all(
            title=request.title,
            body=request.body,
            notification_type=request.notification_type
        )
        return {"success": True, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))