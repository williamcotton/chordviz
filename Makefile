all: image_frames

clean:
	rm -f image_data/*

# Convert video to image frames
image_frames:
	mkdir -p image_data
	python video_to_image_frames.py

# Run the web application
.PHONY: labeler
labeler:
	cd labeler && npm install && npm start

# Run the XCode project for the iOS app
.PHONY: analyzer
analyzer:
	xed analyzer

# Run the Python script to train the model
train_model:
	python pytorch_model/train_model.py

eval_model:
	python pytorch_model/eval_model.py

predict:
	python pytorch_model/predict.py

convert:
	python pytorch_model/coreml_convert.py

predict_server:
	python pytorch_model/predict_server.py
