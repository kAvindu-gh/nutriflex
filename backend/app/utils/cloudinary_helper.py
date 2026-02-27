import cloudinary
import cloudinary.uploader
import os
from dotenv import load_dotenv

load_dotenv()

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)


def upload_image_to_cloudinary(file_bytes: bytes, user_id: str, content_type: str) -> str:
    """
    Uploads image bytes to Cloudinary.
    Returns the secure public URL of the uploaded image.
    """
    result = cloudinary.uploader.upload(
        file_bytes,
        folder=f"nutriflex/profile_pictures/{user_id}",
        public_id="profile",          # always overwrites the same file for this user
        overwrite=True,
        resource_type="image",
        format=content_type.split("/")[-1],  # jpeg / png / webp
        transformation=[
            {"width": 400, "height": 400, "crop": "fill", "gravity": "face"},
            {"quality": "auto"},               # auto compress
            {"fetch_format": "auto"}           # serve best format for browser
        ]
    )
    return result["secure_url"]


def delete_image_from_cloudinary(user_id: str):
    """
    Deletes the profile picture from Cloudinary when user removes it.
    """
    public_id = f"nutriflex/profile_pictures/{user_id}/profile"
    cloudinary.uploader.destroy(public_id, resource_type="image")