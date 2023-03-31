import torch
from torch.utils.data import DataLoader
import torch.nn as nn

from guitar_tab_net import GuitarTabNet

from training_and_validation import train_dataset, val_dataset

device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

model = GuitarTabNet().to(device)
criterion = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True)
val_loader = DataLoader(val_dataset, batch_size=16, shuffle=False)
