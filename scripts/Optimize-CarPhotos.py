"""Prepare locally cached catalog photographs for web delivery. Requires Pillow."""
import json
from pathlib import Path
from PIL import Image, ImageOps

root = Path(__file__).resolve().parents[1]
directory = root / "AutoCar.Web/wwwroot/images/cars"
manifest = directory / "sources.json"
photos = json.loads(manifest.read_text(encoding="utf-8"))
backup = root / "tmp/car-photo-originals"
backup.mkdir(parents=True, exist_ok=True)
before = after = 0
for photo in photos:
    source = (directory / photo["File"]).resolve()
    if source.parent != directory.resolve():
        raise ValueError("Photo path is outside the asset directory")
    before += source.stat().st_size
    if source.suffix == ".webp":
        after += source.stat().st_size
        continue
    destination = source.with_suffix(".webp")
    with Image.open(source) as image:
        image = ImageOps.exif_transpose(image).convert("RGB")
        image.thumbnail((1280, 1280), Image.Resampling.LANCZOS)
        image.save(destination, "WEBP", quality=87, method=6)
    photo["File"] = destination.name
    after += destination.stat().st_size
    source.replace(backup / source.name)
temporary = manifest.with_suffix(".json.tmp")
temporary.write_text(json.dumps(photos, ensure_ascii=False, indent=2), encoding="utf-8")
temporary.replace(manifest)
print(f"Prepared {len(photos)} photographs: {before:,} -> {after:,} bytes")
