import torch
from torch.utils.data import Dataset
from torchvision import transforms
from PIL import Image
import numpy as np


class GuitarTabDataset(Dataset):
    def __init__(self, images, labels, transform=None):
        self.images = images
        self.labels = labels
        self.transform = transform

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        # The original images are grayscale with shape (128, 128)
        image = self.images[idx].reshape(128, 128)
        # Convert to PIL Image
        image = Image.fromarray((image * 255).astype(np.uint8), mode="L")
        label = self.labels[idx]

        if self.transform:
            image = self.transform(image)

        # Convert the image back to a tensor after the transform
        image = transforms.ToTensor()(image)

        return image, torch.tensor(label, dtype=torch.float32)
