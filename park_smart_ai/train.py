from ultralytics import YOLO

model = YOLO("yolov8n.pt")  # najmanji i najbrži model, idealan za PoC

model.train(
    data="data.yaml",
    epochs=50,
    imgsz=640,
    batch=8,
    name="park_smart",
    patience=10
)

print("Trening završen!")