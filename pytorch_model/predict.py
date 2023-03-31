import sys
import cv2
import torch
import numpy as np
from guitar_tab_net import GuitarTabNet

# Load the trained model
model = GuitarTabNet()
model.load_state_dict(torch.load('trained_guitar_tab_net.pth'))
model.eval()


def preprocess_image(image_path):
    image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    image = cv2.resize(image, (128, 128)) / 255.0
    image = np.array(image).reshape(1, 1, 128, 128)
    return torch.tensor(image, dtype=torch.float32)


def predict(image_path):
    image_tensor = preprocess_image(image_path)
    with torch.no_grad():
        output = model(image_tensor)
        predicted_tab = (output > 0.5).float()
        tablature = [x.item() if x.item() != -
                     1 else 'X' for x in predicted_tab[0]]
        return tablature


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python predict.py path/to/image.jpg")
        sys.exit(1)

    image_path = sys.argv[1]
    prediction = predict(image_path)
    print(f"Predicted tablature: {prediction}")
