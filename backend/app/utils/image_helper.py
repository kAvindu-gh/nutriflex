from PIL import Image
from fastapi import HTTPException, UploadFile
import io

# ── Expanded allowed types to cover Google Photos formats ─────────────────────
ALLOWED_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
    "application/octet-stream",  # Google Photos sometimes sends this
}

MAX_SIZE_MB = 5
MAX_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024

# ── Valid image signatures (magic bytes) ──────────────────────────────────────
def _detect_image_from_bytes(contents: bytes) -> bool:
    """Check actual file bytes to confirm it's a real image regardless of MIME type."""
    signatures = [
        b'\xff\xd8\xff',           # JPEG
        b'\x89PNG',                 # PNG
        b'RIFF',                    # WEBP (starts with RIFF....WEBP)
        b'GIF87a', b'GIF89a',      # GIF
        b'\x00\x00\x00',           # HEIC/HEIF (ftyp box)
    ]
    for sig in signatures:
        if contents[:len(sig)] == sig:
            return True
    # Also try WEBP specifically
    if len(contents) > 12 and contents[8:12] == b'WEBP':
        return True
    return False


def validate_image(file: UploadFile, contents: bytes):
    # Check file size first
    if len(contents) > MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Maximum size is {MAX_SIZE_MB}MB."
        )

    # Check MIME type OR actual bytes — either is acceptable
    mime_ok = file.content_type in ALLOWED_TYPES
    bytes_ok = _detect_image_from_bytes(contents)

    if not mime_ok and not bytes_ok:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type '{file.content_type}'. Please upload a JPEG, PNG or WEBP image."
        )

    # Final verify with Pillow — most reliable check
    try:
        img = Image.open(io.BytesIO(contents))
        img.verify()
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Could not read the image file. Please try a different photo."
        )