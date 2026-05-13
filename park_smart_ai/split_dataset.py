import os
import shutil
import random

# Putanje - promijeni ovo na tvoju putanju do Label Studio exporta
SOURCE_IMAGES = r"C:\Users\adeli\PycharmProjects\park_smart_ai\dataset_yolo_with_images\images"  # putanja do exportanih slika
SOURCE_LABELS = r"C:\Users\adeli\PycharmProjects\park_smart_ai\dataset_yolo_with_images\labels"  # putanja do exportanih labela

# Putanje do dataset foldera u projektu
DATASET_DIR = r"C:\Users\adeli\PycharmProjects\park_smart_ai\dataset"

# Podjela
TRAIN = 0.7
VALID = 0.2
TEST = 0.1


def split_dataset():
    # Uzmi sve slike
    images = [f for f in os.listdir(SOURCE_IMAGES) if f.endswith(('.jpg', '.jpeg', '.png'))]

    # Shuffle - random raspored
    random.seed(42)
    random.shuffle(images)

    total = len(images)
    train_end = int(total * TRAIN)
    valid_end = int(total * (TRAIN + VALID))

    train_files = images[:train_end]
    valid_files = images[train_end:valid_end]
    test_files = images[valid_end:]

    print(f"Ukupno slika: {total}")
    print(f"Train: {len(train_files)}")
    print(f"Valid: {len(valid_files)}")
    print(f"Test: {len(test_files)}")

    # Kopiraj fajlove
    for split_name, files in [("train", train_files), ("valid", valid_files), ("test", test_files)]:
        img_dir = os.path.join(DATASET_DIR, "images", split_name)
        lbl_dir = os.path.join(DATASET_DIR, "labels", split_name)

        for filename in files:
            # Kopiraj sliku
            src_img = os.path.join(SOURCE_IMAGES, filename)
            dst_img = os.path.join(img_dir, filename)
            shutil.copy2(src_img, dst_img)

            # Kopiraj label (isti naziv, .txt ekstenzija)
            label_name = os.path.splitext(filename)[0] + ".txt"
            src_lbl = os.path.join(SOURCE_LABELS, label_name)
            dst_lbl = os.path.join(lbl_dir, label_name)

            if os.path.exists(src_lbl):
                shutil.copy2(src_lbl, dst_lbl)
            else:
                print(f"Nema labele za: {filename}")

    print("\nDataset uspješno podijeljen!")


if __name__ == "__main__":
    split_dataset()