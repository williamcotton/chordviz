import torch.nn as nn


class GuitarTabNetDeepDrop(nn.Module):
    def __init__(self):
        super(GuitarTabNetDeepDrop, self).__init__()

        # Define the convolutional layers of the network.
        # The Sequential container makes it easier to manage a set of layers that are
        # to be run in sequence.
        self.features = nn.Sequential(
            # First convolutional layer, with 32 filters of size 3x3.
            # Padding is set to 1 to maintain the spatial dimensions of the input.
            nn.Conv2d(1, 32, kernel_size=3, stride=1, padding=1),
            # ReLU (Rectified Linear Unit) activation function.
            nn.ReLU(),
            # Second convolutional layer, with 64 filters of size 3x3.
            nn.Conv2d(32, 64, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            # Max pooling layer, reduces the spatial dimensions by a factor of 2.
            nn.MaxPool2d(kernel_size=2, stride=2),
            # Dropout layer, randomly sets input units to 0 with probability 0.05,
            # to prevent overfitting.
            nn.Dropout2d(p=0.05),
            # Repeat the same pattern of layers, but with more filters in the convolutional layers.
            nn.Conv2d(64, 128, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.Conv2d(128, 128, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Dropout2d(p=0.1),
            # One more repetition, with even more filters.
            nn.Conv2d(128, 256, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.Conv2d(256, 256, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Dropout2d(p=0.15),
        )

        # Define the fully connected layers of the network, which will classify the features
        # extracted by the convolutional layers.
        self.classifier = nn.Sequential(
            # First fully connected layer. The input size needs to be the number of elements
            # in the feature map produced by the convolutional layers.
            nn.Linear(256 * 16 * 16, 1024),
            nn.ReLU(),
            # Dropout layer, to prevent overfitting in the fully connected layers.
            nn.Dropout(p=0.2),
            # Second fully connected layer.
            nn.Linear(1024, 1024),
            nn.ReLU(),
            nn.Dropout(p=0.2),
            # Final fully connected layer. The output size needs to be the number of classes.
            nn.Linear(1024, 6),
        )

    def forward(self, x):
        # Pass the input through the convolutional layers.
        x = self.features(x)
        # Flatten the output of the convolutional layers, so it can be passed into the fully connected layers.
        x = x.view(x.size(0), -1)
        # Pass the flattened features through the fully connected layers.
        x = self.classifier(x)
        return x
