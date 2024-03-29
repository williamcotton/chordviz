import torch
import numpy as np
from guitar_tab_dataset import GuitarTabDataset
from guitar_tab_net import GuitarTabNet
from torch.utils.data import DataLoader
from training_validation_testing_split import test_dataset

# Load the trained model
model = GuitarTabNet()
model.load_state_dict(torch.load("trained_guitar_tab_net.pth"))
model.eval()

test_loader = DataLoader(test_dataset, batch_size=16, shuffle=True)

# Evaluate the model
correct = 0
total = 0
with torch.no_grad():
    for images, labels in test_loader:
        # Pass the images through the model to get the predicted outputs
        outputs = model(images)
        # Round the outputs to the nearest integer to get the predicted chord
        predicted = outputs.round()
        # Count the total number of labels in the batch
        total += labels.size(0)
        for pred, actual in zip(predicted, labels.float()):
            print("\n")
            print(f"Predicted tablature: {pred[:-2]}")
            print(f"Predicted inTransition: {bool(pred[-2].item())}")
            print(f"Predicted capoPosition: {pred[-1].item()}")
            print(f"Actual tablature: {actual[:-2]}")
            print(f"Actual inTransition: {bool(actual[-2].item())}")
            print(f"Actual capoPosition: {actual[-1].item()}")
            correct += torch.all(pred == actual).item()

print("Accuracy of the model on the test images: {:.2f}%".format(100 * correct / total))
