import torch
from torch.utils.data import Dataset


class GuitarTabDataset(Dataset):
    def __init__(self, images, labels):
        self.images = images
        self.labels = labels

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        image = self.images[idx]
        label = self.labels[idx]

        # Convert the images and labels to PyTorch tensors.
        return torch.tensor(image, dtype=torch.float32), torch.tensor(
            label, dtype=torch.float32
        )
