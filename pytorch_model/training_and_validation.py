from sklearn.model_selection import train_test_split

from preprocess import load_data
from guitar_tab_dataset import GuitarTabDataset

image_data, label_data = load_data("image_data", "./labeler/labels.db")
train_images, val_images, train_labels, val_labels = train_test_split(
    image_data, label_data, test_size=0.2)

train_dataset = GuitarTabDataset(train_images, train_labels)
val_dataset = GuitarTabDataset(val_images, val_labels)
