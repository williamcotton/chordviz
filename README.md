# chordviz

Predict the next chord (as tablature) on a guitar based on image data.

## Background

Using traditional means of audio analysis for pitch and chord detection suffers from a necessary delay as the audio signal is processed. Inspired by my own experience as a gigging musician watching the guitar or bass player's hands when I didn't have as complete understanding of the song, I set out to use the video camera on my iPhone to predict what chord was being or about to be played.

## Convolutional neural network

The model itself is written in Python using PyTorch. It use two convolutional layers with 32 and 64 filters, a max pooling layer that reduces the spatial dimensions by half, two fully connected layers with 128 and 8 neurons, and a ReLU activation function.

Once trained an image such as:

![image](https://github.com/williamcotton/chordviz/assets/13163/57ea66b4-a4e6-4fd3-9793-ec6fe8c9a7c6)

Results in predictions such as:

```bash
$ python pytorch_model/predict.py image_data/capo_0_shape_G_frame_00022.jpg
Predicted tablature: [3, 2, 0, 0, 3, 3]
Predicted inTransition: False
Predicted capoPosition: 0
```

## Labeler software

Using a simple React application with keyboard shortcuts it is possible to label 5-6 images a second which is almost a necessity when needing to label upwards of 10,000 or more images.

![image](https://github.com/williamcotton/chordviz/assets/13163/cc1b7716-da4f-4bd4-8b6e-e82e56e8c299)
