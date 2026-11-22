"""Verify the running API/MVC photo path without modifying business data."""
import hashlib
import io
import json
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
def fetch(url):
    with urllib.request.urlopen(url, timeout=25) as response:
        assert response.status == 200, (url, response.status)
        return response.read(), response.headers.get_content_type()
def get(url):
    return json.loads(fetch(url)[0])

photos = json.loads((root / 'AutoCar.Web/wwwroot/images/cars/sources.json').read_text(encoding='utf-8'))
catalog = {p['Key']: p for p in photos}
assert len(catalog) == 39
data = get('http://localhost:5180/api/cars?pageSize=100')
cars = data['items']
assert len(cars) == data['total'], 'Pagination must include the complete demo catalog'
assert len(cars) == 78
for car in cars:
    key = car['brand'] + ' ' + car['model']
    assert len(car['images']) == 1, (key, 'Unexpected duplicate seed photographs')
    assert car['images'][0] == '/catalog/' + catalog[key]['File'], (key, car['images'])
checked = []
for photo in photos:
    name = photo['File']
    local = (root / 'AutoCar.Web/wwwroot/images/cars' / name).read_bytes()
    api, mime = fetch('http://localhost:5180/catalog/' + name)
    proxy, proxy_mime = fetch('http://localhost:5080/media/catalog/' + name)
    assert local == api == proxy, name
    assert mime == proxy_mime == 'image/webp', name
    with Image.open(io.BytesIO(proxy)) as image:
        assert image.format == 'WEBP'
        assert max(image.size) <= 1280
        dimensions = image.size
        image.verify()
    assert photo['Artist'] and photo['License'] and photo['LicenseUrl'] and photo['Source']
    checked.append({'model': photo['Key'], 'file': name, 'bytes': len(proxy), 'dimensions': dimensions,
                    'sha256': hashlib.sha256(proxy).hexdigest()})
pages = ['/', '/xe', '/nguon-anh']
for car in cars:
    html = fetch('http://localhost:5080/xe/' + str(car['id']))[0].decode('utf-8')
    assert '/media' + car['images'][0] in html, car['id']
    assert 'Wikimedia Commons' in html and 'photo-credit' in html
for page in pages:
    fetch('http://localhost:5080' + page)
report = {'checkedAtUtc': datetime.now(timezone.utc).isoformat(), 'models': len(checked),
          'sqlBackedCarsWithMatchingPhoto': len(cars), 'detailPagesChecked': len(cars),
          'totalImageBytes': sum(x['bytes'] for x in checked), 'pages': pages, 'images': checked}
(root / 'docs/CAR_IMAGES_VERIFICATION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(f"PASS: {len(checked)} model photographs, {len(cars)} SQL-backed cars and detail pages; API/proxy bytes match.")
