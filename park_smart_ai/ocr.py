import re

import easyocr
import cv2

reader = easyocr.Reader(['en'], gpu=False)


def ocr_iz_cropa(crop):
    """Prima crop slike (numpy array) i čita tekst"""
    # Upscaling - povećaj crop 2x za bolji OCR
    crop = cv2.resize(crop, None, fx=2, fy=2, interpolation=cv2.INTER_CUBIC)

    najbolji_tekst = ""
    najbolji_confidence = 0

    for kut in [0, 90, 180, 270]:
        if kut == 0:
            rotirana = crop
        elif kut == 90:
            rotirana = cv2.rotate(crop, cv2.ROTATE_90_CLOCKWISE)
        elif kut == 180:
            rotirana = cv2.rotate(crop, cv2.ROTATE_180)
        elif kut == 270:
            rotirana = cv2.rotate(crop, cv2.ROTATE_90_COUNTERCLOCKWISE)

        ocr_result = reader.readtext(rotirana)

        if ocr_result and ocr_result[0][2] > najbolji_confidence:
            najbolji_confidence = ocr_result[0][2]
            najbolji_tekst = ocr_result[0][1]

    return re.sub(r'[^A-Z0-9\-]', '', najbolji_tekst.upper()) if najbolji_confidence > 0.3 else None


def procitaj_tablicu(image_path):
    """Prima putanju slike, detektuje i čita sve tablice - za testiranje"""
    from ultralytics import YOLO
    model = YOLO("runs/detect/park_smart/weights/best.pt")

    img = cv2.imread(image_path)
    results = model.predict(image_path, conf=0.5, verbose=False)

    tablice = []

    for result in results:
        for box in result.boxes:
            cls = int(box.cls[0])
            class_name = model.names[cls]

            if class_name == "tablica":
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                crop = img[y1:y2, x1:x2]
                tekst = ocr_iz_cropa(crop)

                if tekst:
                    tablice.append({"tablica": tekst})

    return tablice


if __name__ == "__main__":
    test_slika = "dataset/images/test/02270155-IMG_0753.png"
    rezultat = procitaj_tablicu(test_slika)
    print("Detektovane tablice:", rezultat)