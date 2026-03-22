from app.database.onboarding_firebase import get_firebase_db
from datetime import datetime, timezone


def upsert_onboarding(user_id: str, data: dict) -> dict:
    db = get_firebase_db()
    data["updated_at"] = datetime.now(timezone.utc).isoformat()

    # ── Stored inside users/{uid}/onboarding/data ──
    doc_ref = (
        db.collection("users")
          .document(user_id)
          .collection("onboarding")
          .document("data")
    )
    doc_ref.set(data, merge=True)
    updated = doc_ref.get().to_dict()
    return {"id": user_id, **updated}


def get_onboarding(user_id: str) -> dict | None:
    db = get_firebase_db()
    doc = (
        db.collection("users")
          .document(user_id)
          .collection("onboarding")
          .document("data")
          .get()
    )
    if not doc.exists:
        return None
    return {"id": user_id, **doc.to_dict()}


def delete_onboarding(user_id: str) -> bool:
    db = get_firebase_db()
    doc_ref = (
        db.collection("users")
          .document(user_id)
          .collection("onboarding")
          .document("data")
    )
    if not doc_ref.get().exists:
        return False
    doc_ref.delete()
    return True