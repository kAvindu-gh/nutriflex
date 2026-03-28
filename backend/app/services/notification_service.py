import httpx
import os
import uuid
import firebase_admin
from firebase_admin import credentials, firestore
import google.auth
import google.auth.transport.requests
from google.oauth2 import service_account
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

if not firebase_admin._apps:
    cred = credentials.Certificate(
        os.getenv("FIREBASE_KEY_PATH", "app/database/firebase_key.json")
    )
    firebase_admin.initialize_app(cred)

db = firestore.client()

FCM_URL = "https://fcm.googleapis.com/v1/projects/flutter-fitness-app-ea9be/messages:send"
SERVICE_ACCOUNT_FILE = os.getenv("FIREBASE_KEY_PATH", "app/database/firebase_key.json")
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")


class NotificationService:

    # ── OAuth2 token for FCM v1 ───────────────────────────────────────────────
    def _get_access_token(self) -> str:
        creds = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=["https://www.googleapis.com/auth/firebase.messaging"],
        )
        creds.refresh(google.auth.transport.requests.Request())
        return creds.token

    # ── Core: send FCM push ───────────────────────────────────────────────────
    async def _send_push(self, fcm_token: str, title: str, body: str,
                         data: dict = None) -> bool:
        try:
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
                            "channel_id": "nutriflex_channel",
                        },
                    },
                    "apns": {
                        "payload": {"aps": {"sound": "default", "badge": 1}}
                    },
                }
            }
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    url,
                    json=payload,
                    headers={
                        "Authorization": f"Bearer {access_token}",
                        "Content-Type": "application/json",
                    },
                )
            return resp.status_code == 200
        except Exception as e:
            print(f"FCM push error: {e}")
            return False

    # ── Core: save in-app notification to Firestore ───────────────────────────
    def _save_in_app(self, user_id: str, notif_type: str,
                     title: str, body: str) -> str:
        notif_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        doc = {
            "notification_id": notif_id,
            "user_id": user_id,
            "type": notif_type,
            "title": title,
            "body": body,
            "is_read": False,
            "created_at": now,
        }
        db.collection("users").document(user_id)\
          .collection("notifications").document(notif_id).set(doc)
        return notif_id

    # ── Core: notify = in-app save + optional FCM push ────────────────────────
    async def _notify(self, user_id: str, notif_type: str,
                      title: str, body: str, data: dict = None) -> bool:
        # Always save in-app
        self._save_in_app(user_id, notif_type, title, body)
        # Try FCM push (silent fail if no token)
        token = await self._get_fcm_token(user_id)
        if token:
            return await self._send_push(token, title, body, data or {})
        return True  # in-app saved successfully even without FCM

    # ── Get FCM token ─────────────────────────────────────────────────────────
    async def _get_fcm_token(self, user_id: str):
        doc = db.collection("user_tokens").document(user_id).get()
        if doc.exists:
            return doc.to_dict().get("fcm_token")
        return None

    # ── Register FCM token ────────────────────────────────────────────────────
    async def register_token(self, user_id: str, fcm_token: str):
        db.collection("user_tokens").document(user_id).set({
            "fcm_token": fcm_token,
            "user_id": user_id,
            "updated_at": datetime.utcnow().isoformat(),
        })

    # ── Fetch in-app notifications for a user ─────────────────────────────────
    def get_notifications(self, user_id: str, limit: int = 50) -> list:
        docs = (
            db.collection("users").document(user_id)
            .collection("notifications")
            .order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
            .stream()
        )
        return [doc.to_dict() for doc in docs]

    # ── Mark notification as read ─────────────────────────────────────────────
    def mark_read(self, user_id: str, notification_id: str):
        db.collection("users").document(user_id)\
          .collection("notifications").document(notification_id)\
          .update({"is_read": True})

    # ── Mark all notifications as read ────────────────────────────────────────
    def mark_all_read(self, user_id: str):
        docs = db.collection("users").document(user_id)\
                 .collection("notifications").stream()
        for doc in docs:
            doc.reference.update({"is_read": True})

    # ── Permanently delete all notifications ──────────────────────────────────
    def clear_all_notifications(self, user_id: str):
        docs = db.collection("users").document(user_id)\
                 .collection("notifications").stream()
        for doc in docs:
            doc.reference.delete()

    # ─────────────────────────────────────────────────────────────────────────
    # TRIGGER METHODS
    # ─────────────────────────────────────────────────────────────────────────

    async def notify_add_to_cart(self, user_id: str, ingredient_name: str,
                                 recipe_name: str = None) -> bool:
        title = "Added to Cart!"
        body = (
            f"{ingredient_name} has been added to your cart"
            + (f" for {recipe_name}" if recipe_name else "") + "."
        )
        return await self._notify(user_id, "add_to_cart", title, body,
                                  {"type": "add_to_cart",
                                   "ingredient_name": ingredient_name,
                                   "recipe_name": recipe_name or ""})

    async def notify_save_recipe(self, user_id: str, recipe_name: str,
                                 recipe_id: str) -> bool:
        return await self._notify(
            user_id, "save_recipe",
            "Recipe Saved!",
            f'"{recipe_name}" has been saved to your favourites.',
            {"type": "save_recipe", "recipe_id": recipe_id,
             "recipe_name": recipe_name},
        )

    async def notify_trending_recipe(self, user_id: str, recipe_name: str,
                                     recipe_id: str,
                                     trending_rank: int = None) -> bool:
        rank_text = f" — #{trending_rank} trending!" if trending_rank else ""
        return await self._notify(
            user_id, "trending_recipe",
            "Trending Recipe Alert!",
            f'"{recipe_name}" is trending right now{rank_text}',
            {"type": "trending_recipe", "recipe_id": recipe_id,
             "recipe_name": recipe_name,
             "trending_rank": str(trending_rank or "")},
        )

    async def notify_order_confirmed(self, user_id: str, order_id: str,
                                     store_name: str,
                                     item_count: int) -> bool:
        return await self._notify(
            user_id, "order_confirmed",
            "Order Confirmed!",
            f"Your order of {item_count} item(s) from {store_name} is confirmed.",
            {"type": "order_confirmed", "order_id": order_id,
             "store_name": store_name, "item_count": str(item_count)},
        )

    async def notify_fitness_details(self, user_id: str,
                                     calories_burned: float = None,
                                     steps: int = None,
                                     workout_name: str = None,
                                     goal_reached: bool = False) -> bool:
        if goal_reached:
            title, body = "Fitness Goal Reached!", \
                          "Amazing! You've hit your fitness goal for today!"
        elif workout_name:
            title = f"{workout_name} Complete!"
            body = f"Great job finishing {workout_name}!"
            if calories_burned:
                body += f" You burned {calories_burned:.0f} kcal."
        else:
            title = "Fitness Update"
            parts = []
            if calories_burned:
                parts.append(f"{calories_burned:.0f} kcal burned")
            if steps:
                parts.append(f"{steps:,} steps")
            body = "Today: " + " · ".join(parts) if parts else "Keep going!"
        return await self._notify(user_id, "fitness_details", title, body,
                                  {"type": "fitness_details"})

    async def notify_weekly_progress(self, user_id: str, week_number: int,
                                     calories_avg: float = None,
                                     workouts_completed: int = None,
                                     goal_achieved: bool = False) -> bool:
        parts = [f"Week {week_number} summary:"]
        if calories_avg:
            parts.append(f"Avg {calories_avg:.0f} kcal/day")
        if workouts_completed is not None:
            parts.append(f"{workouts_completed} workouts done")
        if goal_achieved:
            parts.append("Goal achieved!")
        return await self._notify(
            user_id, "weekly_progress",
            "Weekly Progress Report!",
            " · ".join(parts),
            {"type": "weekly_progress", "week_number": str(week_number)},
        )

    async def notify_bmi_calculated(self, user_id: str, bmi: float,
                                    status: str, weight: float,
                                    height: float,
                                    goal: str = None) -> bool:
        emoji = {"Normal": "✅", "Overweight": "⚠️",
                 "Underweight": "⚠️", "Obese": "🚨"}.get(status, "📊")
        body = (
            f"Your BMI is {bmi:.1f} ({status}). "
            f"Weight: {weight}kg, Height: {height}cm."
        )
        if goal:
            body += f" Goal: {goal}."
        return await self._notify(
            user_id, "bmi_calculated",
            f"{emoji} BMI Calculated!",
            body,
            {"type": "bmi_calculated", "bmi": str(bmi), "status": status},
        )

    async def notify_meal_prep_updated(self, user_id: str, rice: str,
                                       meat: str, vegetable1: str,
                                       vegetable2: str, mallum: str,
                                       salad: str,
                                       total_calories: float = None,
                                       total_protein: float = None) -> bool:
        body = (
            f"Meal prep updated: {rice}, {meat}, {vegetable1}, "
            f"{vegetable2}, {mallum} & {salad}."
        )
        if total_calories:
            body += f" Total: {total_calories:.0f} kcal"
        if total_protein:
            body += f" · {total_protein:.1f}g protein."
        return await self._notify(
            user_id, "meal_prep_updated",
            "🍱 Meal Prep Updated!",
            body,
            {"type": "meal_prep_updated"},
        )

    async def notify_recipe_searched(self, user_id: str, recipe_name: str,
                                     calories: float = None,
                                     protein: float = None) -> bool:
        body = f'New recipe found: "{recipe_name}".'
        if calories:
            body += f" {calories:.0f} kcal"
        if protein:
            body += f" · {protein:.1f}g protein."
        return await self._notify(
            user_id, "recipe_searched",
            "🍽️ New Recipe Added!",
            body,
            {"type": "recipe_searched", "recipe_name": recipe_name},
        )

    async def notify_order_placed(self, user_id: str, order_id: str,
                                  store_name: str, item_count: int,
                                  total: float) -> bool:
        return await self._notify(
            user_id, "order_placed",
            "Order Placed!",
            f"Your order of {item_count} item(s) from {store_name} "
            f"has been placed. Total: ${total:.2f}.",
            {"type": "order_placed", "order_id": order_id,
             "store_name": store_name, "total": str(total)},
        )

    # ── Broadcast to all users ────────────────────────────────────────────────
    async def broadcast_to_all(self, title: str, body: str,
                               notification_type: str) -> dict:
        tokens_docs = db.collection("user_tokens").stream()
        success, failed = 0, 0
        for doc in tokens_docs:
            data = doc.to_dict()
            user_id = data.get("user_id")
            token = data.get("fcm_token")
            if user_id:
                self._save_in_app(user_id, notification_type, title, body)
            if token:
                result = await self._send_push(token, title, body,
                                               {"type": notification_type})
                if result:
                    success += 1
                else:
                    failed += 1
        return {"sent": success, "failed": failed}


# ─────────────────────────────────────────────────────────────────────────────
# MODULE-LEVEL FUNCTIONS for async task scheduling
# ─────────────────────────────────────────────────────────────────────────────

_service = NotificationService()


async def notify_order_placed(user_id: str, order_id: str, store_name: str,
                              item_count: int, total: float) -> bool:
    """Standalone function for fire-and-forget notification via asyncio.create_task()"""
    return await _service.notify_order_placed(user_id, order_id, store_name,
                                               item_count, total)