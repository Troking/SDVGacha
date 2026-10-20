from PIL import Image
im0 = Image.open("game/assets/textures/terrain_img_0.png")
im1 = Image.open("game/assets/textures/terrain_img_1.png")
print("im0 extrema:", im0.getextrema())
print("im1 extrema:", im1.getextrema())

# Also check colors
print("im0 center pixel:", im0.getpixel((256, 256)))
print("im1 center pixel:", im1.getpixel((256, 256)))
