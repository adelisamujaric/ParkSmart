import asyncio
import uuid
from fastapi import FastAPI, File, UploadFile, Form
from ultralytics import YOLO
from ocr import ocr_iz_cropa
import cv2
import numpy as np
import base64
import threading
import requests
import time
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles
from pathlib import Path

app = FastAPI()
IMAGES_DIR = Path("static/images")
IMAGES_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")  # ← poslije app = FastAPI()


model = YOLO("runs/detect/park_smart/weights/best.pt")

frame_lock = threading.Lock()

latest_data = {
    "kamera": {"frame": None, "results": None},
    "drone": {"frame": None, "results": None},
    "entry": {"frame": None, "results": None},
    "upload": {"frame": None, "results": None},
}

CS_DETECTION_URL = "http://localhost:5164/api/detection/manual"

VIOLATION_CONFIG_MAP = {
    "prekrsaj_invalidsko":     "18DDD194-234F-42EC-A806-39116C9DBF77",
    "prekrsaj_nije_parking":   "FAB2DAC1-661D-4B3D-AF38-834DD7146AFA",
    "prekrsaj_van_okvira":     "45ED7BE3-C817-4025-B88E-C0FEC6C79163",
}

CAMERA_TYPE_MAP = {
    "upload": 0,
    "kamera": 0,
    "drone": 2,
    "entry": 0,
    "exit": 1,
}

LOT_ID = "DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"


def posalji_na_cs(tablica, camera_type, lot_id):
    payload = {
        "licensePlate": tablica,
        "cameraType": CAMERA_TYPE_MAP.get(camera_type, 0),
        "lotId": lot_id,
    }
    try:
        response = requests.post(CS_DETECTION_URL, json=payload, timeout=10)
        print(f"C# odgovor: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Greška pri slanju na C# backend: {e}")


def posalji_drone_na_cs(tablica, lot_id, violation=None, img_base64=None):
    violation_config_id = VIOLATION_CONFIG_MAP.get(violation) if violation else None
    image_url = None
    if img_base64:
        filename = f"{uuid.uuid4()}.jpg"
        filepath = IMAGES_DIR / filename
        with open(filepath, "wb") as f:
            f.write(base64.b64decode(img_base64))
        image_url = f"http://192.168.178.29:8000/static/images/{filename}"

    payload = {
        "licensePlate": tablica,
        "cameraType": 2,
        "droneNumber": 1,
        "lotId": lot_id,
        "violationConfigId": violation_config_id,
        "imageUrl": image_url,
    }
    try:
        response = requests.post(CS_DETECTION_URL, json=payload, timeout=10)
        print(f"C# drone odgovor: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Greška pri slanju drone na C#: {e}")


@app.post("/analyze")
async def analyze(
    file: UploadFile = File(...),
    lot: str = Form(...),
    camera_type: str = Form(...),
    camera_id: str = Form(...)
):
    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    results = model.predict(img, conf=0.5, verbose=False)

    tablice = []
    violations = []

    annotated = results[0].plot()

    for result in results:
        for box in result.boxes:
            cls = int(box.cls[0])
            class_name = model.names[cls]
            print(f"Detektovano: {class_name}, confidence: {float(box.conf[0]):.2f}")

            if class_name == "tablica":
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                crop = img[y1:y2, x1:x2]
                tekst = ocr_iz_cropa(crop)
                if tekst:
                    tablice.append(tekst)

            if class_name in ["prekrsaj_invalidsko", "prekrsaj_nije_parking", "prekrsaj_van_okvira"]:
                violations.append(class_name)

    _, buffer = cv2.imencode('.jpg', annotated)
    img_base64 = base64.b64encode(buffer).decode('utf-8')

    auti = []
    for i, tablica in enumerate(tablice):
        violation = violations[i] if i < len(violations) else None

        auti.append({
            "lot": lot,
            "camera_type": camera_type,
            "camera_id": camera_id,
            "tablica": tablica,
            "violation_id": violation
        })

        if camera_type in ["upload", "entry", "exit", "kamera"]:
            posalji_na_cs(tablica, camera_type, LOT_ID)
        elif camera_type == "drone":
            posalji_drone_na_cs(tablica, LOT_ID, violation=violation, img_base64=img_base64)

    with frame_lock:
        if camera_type in latest_data:
            latest_data[camera_type]["frame"] = img_base64
            latest_data[camera_type]["results"] = auti

    return {
        "rezultati": auti,
        "annotated_image": img_base64
    }


@app.post("/esp_feed")
async def esp_feed(
    file: UploadFile = File(...),
    camera_type: str = Form(...),
    camera_id: str = Form(...)
):
    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    _, buffer = cv2.imencode('.jpg', img)
    img_base64 = base64.b64encode(buffer).decode('utf-8')

    with frame_lock:
        if camera_type in latest_data:
            latest_data[camera_type]["frame"] = img_base64

    return {"status": "ok"}

@app.get("/stream/drone")
async def stream_drone():
    async def generate():
        while True:
            with frame_lock:
                data = latest_data["drone"]
                if data and data["frame"]:
                    frame_bytes = base64.b64decode(data["frame"])
                    yield (b"--frame\r\n"
                           b"Content-Type: image/jpeg\r\n\r\n" +
                           frame_bytes + b"\r\n")
            await asyncio.sleep(1)

    return StreamingResponse(
        generate(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )

@app.get("/latest")
async def get_latest():
    with frame_lock:
        data = latest_data["kamera"]
        if data["frame"] is None:
            return {"available": False}
        return {
            "available": True,
            "annotated_image": data["frame"],
            "rezultati": data["results"]
        }

@app.get("/latest_drone")
async def get_latest_drone():
    with frame_lock:
        data = latest_data["drone"]
        if data["frame"] is None:
            return {"available": False}
        return {
            "available": True,
            "annotated_image": data["frame"],
        }

@app.get("/latest_entry")
async def get_latest_entry():
    with frame_lock:
        data = latest_data["entry"]
        if data["frame"] is None:
            return {"available": False, "tablica": None}

        tablica = None
        if data["results"]:
            tablica = data["results"][0].get("tablica")

        return {
            "available": True,
            "tablica": tablica
        }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)