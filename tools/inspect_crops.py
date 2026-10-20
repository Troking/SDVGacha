import struct
from PIL import Image

im = Image.open("game/assets/textures/face_texture_dump.png")
print("Face texture size:", im.size, im.mode)

# Save cropped areas of the eyes and star
# In our previous UV inspection:
# EyeStar: U=[0, 0.024], V=[0.967, 0.998]
# Face_Eye: U=[0.030, 0.820], V=[0.008, 0.636]
w, h = im.size
crop_star = im.crop((int(0.0 * w), int(0.96 * h), int(0.03 * w), int(1.0 * h)))
crop_star.save("game/assets/textures/star_crop.png")

crop_eyes = im.crop((int(0.0 * w), int(0.0 * h), int(0.85 * w), int(0.65 * h)))
crop_eyes.save("game/assets/textures/eyes_crop.png")
print("Saved star_crop.png and eyes_crop.png")
