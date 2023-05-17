import torch
from training_loop import train_loader, val_loader, model, criterion, optimizer, device

num_epochs = 30

# This is the main training loop.
for epoch in range(num_epochs):
    # Set the model in training mode.
    model.train()
    train_loss = 0
    # Load a batch of images and their corresponding labels.
    for images, labels in train_loader:
        # Move the images and labels to the device (GPU if available).
        images, labels = images.to(device), labels.to(device)

        # Clear the gradients from the previous iteration.
        optimizer.zero_grad()
        # Forward pass: compute predictions.
        outputs = model(images)
        # Compute the loss between the predictions and the true labels.
        loss = criterion(outputs, labels)
        # Backward pass: compute gradients.
        loss.backward()
        # Update the model parameters.
        optimizer.step()

        # Accumulate the training loss.
        train_loss += loss.item()

    # Compute the average training loss for this epoch.
    train_loss /= len(train_loader)

    # Now we'll evaluate the model on the validation set.
    model.eval()
    val_loss = 0
    with torch.no_grad():
        for images, labels in val_loader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            loss = criterion(outputs, labels)
            val_loss += loss.item()

    # Compute the average validation loss for this epoch.
    val_loss /= len(val_loader)

# Save the trained model parameters.
torch.save(model.state_dict(), "trained_guitar_tab_net.pth")
