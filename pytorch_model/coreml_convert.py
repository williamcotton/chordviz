import torch
import coremltools as ct
from guitar_tab_net import GuitarTabNet

# Load model
torch_model = GuitarTabNet()
torch_model.load_state_dict(torch.load("trained_guitar_tab_net.pth"))
torch_model.eval()

# Trace the model with random data.
example_input = torch.rand(1, 1, 128, 128)
traced_model = torch.jit.trace(torch_model, example_input)
out = traced_model(example_input)

# Convert the traced model to Core ML format.
model = ct.convert(traced_model, inputs=[ct.TensorType(shape=example_input.shape)])

# Save the converted model.
model.save("trained_guitar_tab_net.mlmodel")
