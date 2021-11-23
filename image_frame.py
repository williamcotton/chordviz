import cv2
import sys

filename = sys.argv[1]


def split_filename(filename):
    name, ext = filename.split('.')
    return name, ext


def convert_to_grayscale(image):
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


input_filename = f'video_data/{filename}'
vidcap = cv2.VideoCapture(input_filename)
name, ext = split_filename(filename)
success, image = vidcap.read()
count = 1
while success:
    output_filename = f'image_data/{name}_frame_{str(count).zfill(5)}.jpg'
    res = cv2.imwrite(output_filename, convert_to_grayscale(image))
    print('Saved image ', count, success, res, output_filename)
    success, image = vidcap.read()
    count += 1
