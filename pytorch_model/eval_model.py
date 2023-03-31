import torch
import numpy as np
from guitar_tab_dataset import GuitarTabDataset
from guitar_tab_net import GuitarTabNet
from torch.utils.data import DataLoader
from preprocess import load_data
from training_and_validation import transform_image_data

# Load the trained model
model = GuitarTabNet()
model.load_state_dict(torch.load('trained_guitar_tab_net.pth'))
model.eval()

# Load the test dataset
image_data, label_data = load_data("test_image_data", "./labeler/labels.db")
test_images, test_labels = transform_image_data(image_data, label_data)
test_dataset = GuitarTabDataset(test_images, test_labels)
test_loader = DataLoader(test_dataset, batch_size=16, shuffle=True)

# Evaluate the model
correct = 0
total = 0
with torch.no_grad():
    for images, labels in test_loader:
        outputs = model(images)
        _, predicted = torch.max(outputs.data, 1)
        total += labels.size(0)
        correct += (predicted == labels).sum().item()

print('Accuracy of the model on the test images: {:.2f}%'.format(
    100 * correct / total))
