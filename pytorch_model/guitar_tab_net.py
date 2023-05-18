import torch.nn as nn


class GuitarTabNet(nn.Module):
    def __init__(self):
        super(GuitarTabNet, self).__init__()
        # Two convolutional layers with 32 and 64 filters, respectively.
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, padding=1)
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        # A max pooling layer that reduces the spatial dimensions by half.
        self.pool = nn.MaxPool2d(2, 2)
        # Two fully connected (dense) layers with 128 and 6 neurons, respectively.
        self.fc1 = nn.Linear(64 * 32 * 32, 128)
        self.fc2 = nn.Linear(128, 8)
        # ReLU activation function.
        self.relu = nn.ReLU()

    def forward(self, x):
        # Pass the input through the layers.
        x = self.pool(self.relu(self.conv1(x)))
        x = self.pool(self.relu(self.conv2(x)))
        # Flatten the tensor for the dense layers.
        x = x.view(-1, 64 * 32 * 32)
        x = self.relu(self.fc1(x))
        x = self.fc2(x)
        return x
