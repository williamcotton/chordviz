import torch
from torch.nn.utils import prune
from guitar_tab_net import GuitarTabNet

# Load the trained model
model = GuitarTabNet()
model.load_state_dict(torch.load("trained_guitar_tab_net.pth"))
model.eval()

# Define the pruning percentage
pruning_percentage = 0.4  # Prune 40% of the weights

# Perform pruning
parameters_to_prune = (
    (model.conv1, "weight"),
    (model.conv2, "weight"),
    (model.fc1, "weight"),
    (model.fc2, "weight"),
)

prune.global_unstructured(
    parameters_to_prune,
    pruning_method=prune.L1Unstructured,
    amount=pruning_percentage,
)

# Remove pruning structures and make pruning permanent
for module, name in parameters_to_prune:
    prune.remove(module, name)

# Save the pruned model
torch.save(model.state_dict(), "pruned_guitar_tab_net.pth")
