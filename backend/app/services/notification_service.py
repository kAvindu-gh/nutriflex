import httpx
import os
import firebase_admin
from firebase_admin import credentials, firestore
import google.auth
import google.auth.transport.requests
from google.oauth2 import service_account
from datetime import datetime
from dotenv import load_dotenv

# ── Load .env file ─────────────────────────────────────────────────────
load_dotenv()

# ── Firebase connection directly here (no __init__.py needed) ──────────
if not firebase_admin._apps:
    cred = credentials.Certificate(
        os.getenv(
            "FIREBASE_KEY_PATH",
            "app/database/firebase_key.json"
        )
    )
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ── FCM v1 API setup ───────────────────────────────────────────────────
FCM_URL = "https://fcm.googleapis.com/v1/projects/flutter-fitness-app-ea9be/messages:send"
SERVICE_ACCOUNT_FILE = os.getenv(
    "FIREBASE_KEY_PATH",
    "app/database/firebase_key.json"
)
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")


class NotificationService:

    # ------------------------------------------------------------------ #
    #  Get OAuth2 access token for FCM v1 API                            #
    # ------------------------------------------------------------------ #
    def _get_access_token(self) -> str:
        credentials_obj = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=["https://www.googleapis.com/auth/firebase.messaging"]
        )
        request = google.auth.transport.requests.Request()
        credentials_obj.refresh(request)
        return credentials_obj.token

    # ------------------------------------------------------------------ #
    #  Core: Send FCM push notification to one device                    #
    # ------------------------------------------------------------------ #
    async def _send_push(self, fcm_token: str, title: str, body: str,
                          data: dict = None) -> bool:
        access_token = self._get_access_token()
        url = FCM_URL.format(project_id=FIREBASE_PROJECT_ID)

        payload = {
            "message": {
                "token": fcm_token,
                "notification": {"title": title, "body": body},
                "data": {k: str(v) for k, v in (data or {}).items()},
                "android": {
                    "priority": "high",
                    "notification": {
                        "sound": "default",
                        "channel_id": "nutriflex_channel"
                    }
                },
                "apns": {
                    "payload": {"aps": {"sound": "default", "badge": 1}}
                }
            }
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json"
                }
            )
        return response.status_code == 200

    # ------------------------------------------------------------------ #
    #  Get FCM token for a user from Firestore                           #
    # ------------------------------------------------------------------ #
    async def _get_fcm_token(self, user_id: str):
        doc = db.collection("user_tokens").document(user_id).get()
        if doc.exists:
            return doc.to_dict().get("fcm_token")
        return None

    # ------------------------------------------------------------------ #
    #  1. Register / update FCM token when user logs in                  #
    # ------------------------------------------------------------------ #
    async def register_token(self, user_id: str, fcm_token: str):
        db.collection("user_tokens").document(user_id).set({
            "fcm_token":  fcm_token,
            "user_id":    user_id,
            "updated_at": datetime.utcnow().isoformat()
        })

    # ------------------------------------------------------------------ #
    #  2. Ingredient added to cart notification                          #
    # ------------------------------------------------------------------ #
    async def notify_add_to_cart(self, user_id: str, ingredient_name: str,
                                  recipe_name: str = None) -> bool:
        token = await self._get_fcm_token(user_id)
        if not token:
            return False

        title = "🛒 Added to Cart!"
        body = (
            f"{ingredient_name} has been added to your cart"
            + (f" for {recipe_name}" if recipe_name else "") + "."
        )
        return await self._send_push(
            fcm_token=token, title=title, body=body,
            data={"type": "add_to_cart", "ingredient_name": ingredient_name,
                  "recipe_name": recipe_name or ""}
        )

    # ------------------------------------------------------------------ #
    #  3. Recipe saved notification                                       #
    # ------------------------------------------------------------------ #
    async def notify_save_recipe(self, user_id: str, recipe_name: str,
                                  recipe_id: str) -> bool:
        token = await self._get_fcm_token(user_id)
        if not token:
            return False

        return await self._send_push(
            fcm_token=token,
            title="❤️ Recipe Saved!",
            body=f'"{recipe_name}" has been saved to your favourites.',
            data={"type": "save_recipe", "recipe_id": recipe_id,
                  "recipe_name": recipe_name}
        )

    # ------------------------------------------------------------------ #
    #  4. Trending recipe notification                                    #
    # ------------------------------------------------------------------ #
    async def notify_trending_recipe(self, user_id: str, recipe_name: str,
                                      recipe_id: str,
                                      trending_rank: int = None) -> bool:
        token = await self._get_fcm_token(user_id)
        if not token:
            return False

        rank_text = f" — #{trending_rank} trending!" if trending_rank else ""
        return await self._send_push(
            fcm_token=token,
            title="🔥 Trending Recipe Alert!",
            body=f'"{recipe_name}" is trending right now{rank_text}',
            data={"type": "trending_recipe", "recipe_id": recipe_id,
                  "recipe_name": recipe_name,
                  "trending_rank": str(trending_rank or "")}
        )

    # ------------------------------------------------------------------ #
    #  5. Order confirmed notification                                    #
    # ------------------------------------------------------------------ #
    async def notify_order_confirmed(self, user_id: str, order_id: str,
                                      store_name: str,
                                      item_count: int) -> bool:
        token = await self._get_fcm_token(user_id)
        if not token:
            return False

        return await self._send_push(
            fcm_token=token,
            title="✅ Order Confirmed!",
            body=f"Your order of {item_count} item(s) from {store_name} has been confirmed.",
            data={"type": "order_confirmed", "order_id": order_id,
                  "store_name": store_name, "item_count": str(item_count)}
        )

    # ------------------------------------------------------------------ #
    #  6. Fitness details notification                                    #
    # ------------------------------------------------------------------ #
    async def notify_fitness_details(self, user_id: str,
                                      calories_burned: float = None,
                                      steps: int = None,
                                      workout_name: str = None,
                                      goal_reached: bool = False) -> bool:
        token = await self._get_fcm_token(user_id)
        if not token:
            return False

        if goal_reached:
            title = "🏆 Fitness Goal Reached!"
            body  = "Amazing work! You've hit your fitness goal for today!"
        elif workout_name:
            title = f"💪 {workout_name} Complete!"
            body  = f"Great job finishing {workout_name}!"
            if calories_burned:
                body += f" You burned {calories_burned:.0f} kcal."
        else:
            title = "💪 Fitness Update"
            parts = []
            if calories_burned:
                parts.append(f"{calories_burned:.0f} kcal burned")
            if steps:
                parts.append(f"{steps:,} steps")
            body = "Today: " + " · ".join(parts) if parts else "Keep up the great work!"

        return await self._send_push(
            fcm_token=token, title=title, body=body,
            data={"type": "fitness_details",
                  "calories_burned": str(calories_burned or ""),
                  "steps": str(steps or ""),
                  "workout_name": workout_name or "",
                  "goal_reached": str(goal_reached)}
        )

    # ------------------------------------------------------------------ #
    #  7. Weekly progress notification                                    #
    # ------------------------------------------------------------------ #
    async def notify_weekly_progress(self, user_id: str, week_number: int,
                                      calories_avg: float = None,
                                      workouts_completed: int = None,
                                      goal_achieved: bool = False) -> bool:
        token = await self._get_fcm_token(user_id)
        if not token:
            return False

        parts = [f"Week {week_number} summary:"]
        if calories_avg:
            parts.append(f"Avg {calories_avg:.0f} kcal/day")
        if workouts_completed is not None:
            parts.append(f"{workouts_completed} workouts done")
        if goal_achieved:
            parts.append("🎯 Goal achieved!")

        return await self._send_push(
            fcm_token=token,
            title="📊 Weekly Progress Report!",
            body=" · ".join(parts),
            data={"type": "weekly_progress",
                  "week_number": str(week_number),
                  "calories_avg": str(calories_avg or ""),
                  "workouts_completed": str(workouts_completed or ""),
                  "goal_achieved": str(goal_achieved)}
        )

    # ------------------------------------------------------------------ #
    #  8. Broadcast to ALL users                                         #
    # ------------------------------------------------------------------ #
    async def broadcast_to_all(self, title: str, body: str,
                                notification_type: str) -> dict:
        tokens_docs = db.collection("user_tokens").stream()
        success, failed = 0, 0

        for doc in tokens_docs:
            token = doc.to_dict().get("fcm_token")
            if token:
                result = await self._send_push(
                    fcm_token=token, title=title, body=body,
                    data={"type": notification_type}
                )
                if result:
                    success += 1
                else:
                    failed += 1

        return {"sent": success, "failed": failed}