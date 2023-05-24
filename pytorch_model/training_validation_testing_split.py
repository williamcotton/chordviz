from sklearn.model_selection import train_test_split
from preprocess import load_data
from guitar_tab_dataset import GuitarTabDataset
from torchvision import transforms
from torch.utils.data import ConcatDataset

image_data, label_data = load_data("image_data", "./labeler/labels.db")

transform = transforms.Compose(
    [
        transforms.RandomRotation(20),  # rotate images
        transforms.RandomResizedCrop(128, scale=(0.8, 1.2)),  # vary the scale
        transforms.RandomAffine(
            degrees=0,
            translate=(0.2, 0.2),  # shift the image around vertically and horizontally
        ),
    ]
)

# Split the dataset into train, validation, and test sets (80% train, 10% validation, 10% test)
train_images, temp_images, train_labels, temp_labels = train_test_split(
    image_data, label_data, test_size=0.2, random_state=42
)
val_images, test_images, val_labels, test_labels = train_test_split(
    temp_images, temp_labels, test_size=0.5, random_state=42
)

## Use these splits to create PyTorch Dataset objects for each set.

# Original dataset
original_dataset = GuitarTabDataset(train_images, train_labels)

# Augmented dataset
augmented_dataset = GuitarTabDataset(train_images, train_labels, transform=transform)

# Concatenate the original and augmented datasets
train_dataset = ConcatDataset([original_dataset, augmented_dataset])

# Validation and test datasets
val_dataset = GuitarTabDataset(val_images, val_labels)
test_dataset = GuitarTabDataset(test_images, test_labels)
