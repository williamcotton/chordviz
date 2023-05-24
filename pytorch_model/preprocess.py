import os
import cv2
import numpy as np
import sqlite3


def load_data(image_dir, db_file):
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()

    images = []
    labels = []

    for filename in os.listdir(image_dir):
        # Load the corresponding label
        cursor.execute(
            "SELECT tablature, inTransition, capoPosition FROM labels WHERE filename=?",
            (filename,),
        )
        fetched_row = cursor.fetchone()
        if fetched_row is None:
            print(f"Warning: No tablature found for {filename}. Skipping this file.")
            continue
        tablature_str, in_transition, capo_position = fetched_row
        try:
            tablature = [int(x) if x != "X" else (-1) for x in tablature_str.split(",")]
        except ValueError:
            print(
                f"Warning: Invalid tablature found for {filename}. Skipping this file."
            )
            raise
        label = tablature
        label.append(int(in_transition))
        label.append(capo_position)
        labels.append(label)

        # Load the image
        image = cv2.imread(os.path.join(image_dir, filename), cv2.IMREAD_GRAYSCALE)
        # Resize and normalize the image
        image = cv2.resize(image, (128, 128)) / 255.0
        images.append(image)

    images = np.array(images).reshape(-1, 1, 128, 128)
    labels = np.array(labels)

    return images, labels
