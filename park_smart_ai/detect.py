from ultralytics import YOLO

model = YOLO("runs/detect/park_smart/weights/best.pt")

results = model.predict(
    source="dataset/images/test/",
    save=True,
    conf=0.5
)

print("Detekcija završena!")