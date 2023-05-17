import torch
from torch.utils.data import DataLoader
import torch.nn as nn
from guitar_tab_net import GuitarTabNet
from training_validation_testing_split import train_dataset, val_dataset

# Determine the device (use GPU if available).
device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

# Create the model and move it to the device.
model = GuitarTabNet().to(device)
# Use the L1 loss function (mean absolute error).
criterion = nn.L1Loss()
# Use the Adam optimizer.
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

# Create data loaders for the training and validation sets.
train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True)
val_loader = DataLoader(val_dataset, batch_size=16, shuffle=False)
