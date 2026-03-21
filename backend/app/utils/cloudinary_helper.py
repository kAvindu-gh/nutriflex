import cloudinary
import cloudinary.uploader
from PIL import Image
import io
import os
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables with explicit path
env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)


def _get_format(content_type: str, file_bytes: bytes) -> str:
    """Detect image format from MIME type or actual bytes."""
    mime_map = {
        "image/jpeg": "jpg",
        "image/jpg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
        "image/heic": "jpg",   # convert heic to jpg via Cloudinary
        "image/heif": "jpg",
    }
    if content_type in mime_map:
        return mime_map[content_type]

    # Fallback — detect from bytes using Pillow
    try:
        img = Image.open(io.BytesIO(file_bytes))
        fmt = img.format.lower() if img.format else "jpg"
        return "jpg" if fmt == "jpeg" else fmt
    except Exception:
        return "jpg"  # safe default


def upload_image_to_cloudinary(file_bytes: bytes, user_id: str, content_type: str) -> str:
    fmt = _get_format(content_type, file_bytes)
    result = cloudinary.uploader.upload(
        file_bytes,
        folder=f"nutriflex/profile_pictures/{user_id}",
        public_id="profile",
        overwrite=True,
        resource_type="image",
        format=fmt,
        transformation=[
            {"width": 400, "height": 400, "crop": "fill", "gravity": "face"},
            {"quality": "auto"},
            {"fetch_format": "auto"},
        ]
    )
    return result["secure_url"]


def delete_image_from_cloudinary(user_id: str):
    public_id = f"nutriflex/profile_pictures/{user_id}/profile"
    cloudinary.uploader.destroy(public_id, resource_type="image")