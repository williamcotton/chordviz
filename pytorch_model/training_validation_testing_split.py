from sklearn.model_selection import train_test_split
from preprocess import load_data
from guitar_tab_dataset import GuitarTabDataset

image_data, label_data = load_data("image_data", "./labeler/labels.db")

# Split the dataset into train, validation, and test sets (80% train, 10% validation, 10% test)
train_images, temp_images, train_labels, temp_labels = train_test_split(
    image_data, label_data, test_size=0.2, random_state=42
)
val_images, test_images, val_labels, test_labels = train_test_split(
    temp_images, temp_labels, test_size=0.5, random_state=42
)

train_dataset = GuitarTabDataset(train_images, train_labels)
val_dataset = GuitarTabDataset(val_images, val_labels)
test_dataset = GuitarTabDataset(test_images, test_labels)
