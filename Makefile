all: image_frames

clean:
	rm -f image_data/*

image_frames:
	python video_to_image_frames.py