import base64, json, os, sys, io, urllib.request
from PIL import Image

def _key():
    if os.environ.get("GEMINI_API_KEY"):
        return os.environ["GEMINI_API_KEY"].strip()
    d = os.path.dirname(os.path.abspath(__file__))
    for _ in range(6):
        f = os.path.join(d, ".gemini-key")
        if os.path.exists(f):
            return open(f).read().strip()
        d = os.path.dirname(d)
    raise SystemExit("Set GEMINI_API_KEY or put the key in .gemini-key at the repo root")


KEY = _key()
MODEL = os.environ.get("NB_MODEL", "gemini-3.1-flash-image")
URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"


def img_part(im):
    b = io.BytesIO(); im.convert("RGB").save(b, "PNG")
    return {"inlineData": {"mimeType": "image/png", "data": base64.b64encode(b.getvalue()).decode()}}


def generate(prompt, images, aspect="1:1", size="1K"):
    parts = [img_part(i) for i in images] + [{"text": prompt}]
    body = {"contents": [{"role": "user", "parts": parts}],
            "generationConfig": {"responseModalities": ["IMAGE", "TEXT"], "imageConfig": {"aspectRatio": aspect, "imageSize": size}}}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), headers={"Content-Type": "application/json", "x-goog-api-key": KEY})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            d = json.load(r)
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code}: {e.read().decode()[:600]}")
    out, text = None, []
    for c in d.get("candidates", []):
        for p in c.get("content", {}).get("parts", []):
            if "inlineData" in p:
                out = Image.open(io.BytesIO(base64.b64decode(p["inlineData"]["data"])))
            elif "text" in p:
                text.append(p["text"])
    if out is None:
        raise SystemExit("no image: " + json.dumps(d)[:800])
    return out, " ".join(text)[:300], d.get("usageMetadata", {})
