all: image_frames

clean:
	rm -f image_data/*

image_frames:
	mkdir -p image_data
	python video_to_image_frames.py