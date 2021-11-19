import cv2
import sys

filename = sys.argv[1]


def split_filename(filename):
    name, ext = filename.split('.')
    return name, ext


vidcap = cv2.VideoCapture(filename)
name, ext = split_filename(filename)
success, image = vidcap.read()
count = 1
while success:
    cv2.imwrite(f'image_data/{name}_frame_{count}.jpg', image)
    success, image = vidcap.read()
    print('Saved image ', count)
    count += 1
