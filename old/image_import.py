import tensorflow as tf
import random
import numpy as np
import cv2
from PIL import Image
from pathlib import Path
import os
from tensorflow.keras.preprocessing.image import ImageDataGenerator

label_array = ["DIS", "ANG", "FEA", "SAD", "SUR", "JOY", "NEU"]
label_to_index = dict((name, index) for index, name in enumerate(label_array))

# Takes as input path to image file and returns
# resized 3 channel RGB image of as numpy array of size (256, 256, 3)


def getPic(img_path):
    return np.array(Image.open(img_path).convert('RGB').resize((256, 256), Image.ANTIALIAS))

# convert('L') converts the image to grayscale

# returns the Label of the image based on its first 3 characters


def get_label(img_path):
    return Path(img_path).absolute().name[0:3]

# Return the images and corresponding labels as numpy arrays


def get_ds(data_path):
    img_paths = list()
    # Recursively find all the image files from the path data_path
    for img_path in glob.glob(data_path+"/**/*"):
        img_paths.append(img_path)
    images = np.zeros((len(img_paths), 256, 256, 3))
    labels = np.zeros(len(img_paths))

    # Read and resize the images
    # Get the encoded labels
    for i, img_path in enumerate(img_paths):
        images[i] = getPic(img_path)
        labels[i] = label_to_index[get_label(img_path)]

    return images, labels


# Model Architecture
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(256, 256, 3)),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(128, activation=tf.nn.relu),
    tf.keras.layers.Dense(10, activation=tf.nn.softmax)
])

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# Load the train and validation data
train_X, train_y = get_ds("./images/")
val_X, val_y = get_ds("./v_images/")

# Finally train it
model.fit(train_X, train_y, validation_data=(val_X, val_y))

# Predictions
model.predict(val_X)
