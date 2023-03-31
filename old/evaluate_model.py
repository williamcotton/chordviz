import torch
import numpy as np

from training_and_validation import val_dataset, model, device


def predict(model, image):
    image = torch.tensor(image, dtype=torch.float32).unsqueeze(0).to(device)
    output = model(image)
    predicted_tablature = output.squeeze().detach().cpu().numpy()
    return np.round(predicted_tablature).astype(int)


# Test the model on a single image
test_image, test_label = val_dataset[0]
predicted_tablature = predict(model, test_image)
print(f"True tablature: {test_label}")
print(f"Predicted tablature: {predicted_tablature}")
