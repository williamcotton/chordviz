import cv2
import sys
import os


def split_filename(filename):
    name, ext = filename.split('.')
    return name, ext


def convert_to_grayscale(image):
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


def crop_image(image, x, y, w, h):
    return image[y:y+h, x:x+w]


# filename = sys.argv[1]

for filename in os.listdir('./video_data'):
    input_filename = f'./video_data/{filename}'
    vidcap = cv2.VideoCapture(input_filename)
    name, ext = split_filename(filename)
    success, image = vidcap.read()
    count = 1
    while success:
        output_filename = f'image_data/{name}_frame_{str(count).zfill(5)}.jpg'
        croped_grayscale_image = convert_to_grayscale(
            crop_image(image, 310, 70, 330, 290))
        res = cv2.imwrite(output_filename, croped_grayscale_image)
        print('Saved image ', count, success, res, output_filename)
        success, image = vidcap.read()
        count += 1
