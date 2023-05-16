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
        outputs = model(images)
        predicted = (outputs > 0.5).float()
        print(f"Predicted tablature: {predicted[0]}")
        print(f"Actual tablature: {labels[0]}")
        total += labels.size(0)
        correct += (predicted == labels.float()).sum().item()

print("Accuracy of the model on the test images: {:.2f}%".format(100 * correct / total))
