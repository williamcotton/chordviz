import sys
import cv2
import torch
import numpy as np
from guitar_tab_net import GuitarTabNet

# Load the trained model
model = GuitarTabNet()
model.load_state_dict(torch.load("../trained_guitar_tab_net.pth"))
model.eval()


def preprocess_image(image_path):
    # Load the image in grayscale mode
    image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    # Resize the image to 128x128 pixels
    image = cv2.resize(image, (128, 128)) / 255.0
    # Reshape the image to fit the input shape of the model
    image = np.array(image).reshape(1, 1, 128, 128)
    # Convert the image into a PyTorch tensor
    return torch.tensor(image, dtype=torch.float32)


def predict(image_path):
    image_tensor = preprocess_image(image_path)
    with torch.no_grad():
        output = model(image_tensor)
        predicted_tab = output.round().int()
        tablature = [
            x.item() if x.item() != -1 else "X" for x in predicted_tab[0][:-2]
        ]  # Only take first 6 elements for tablature
        in_transition = bool(
            predicted_tab[0][-2].item()
        )  # The second last element is inTransition
        capo_position = predicted_tab[0][-1].item()  # The last element is capoPosition
        return tablature, in_transition, capo_position


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python predict.py path/to/image.jpg")
        sys.exit(1)

    image_path = sys.argv[1]
    tablature, in_transition, capo_position = predict(image_path)
    print(f"Predicted tablature: {tablature}")
    print(f"Predicted inTransition: {in_transition}")
    print(f"Predicted capoPosition: {capo_position}")
