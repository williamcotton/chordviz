from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import torch
import numpy as np
from guitar_tab_net import GuitarTabNet

app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

# Load the trained model
model = GuitarTabNet()
model.load_state_dict(torch.load("trained_guitar_tab_net.pth"))
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


@app.route("/predict/<filename>", methods=["GET"])
def predict(filename):
    image_path = "image_data/" + filename
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

    result = {
        "tablature": tablature,
        "inTransition": in_transition,
        "capoPosition": capo_position,
    }
    return jsonify(result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3034)
