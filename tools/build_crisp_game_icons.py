"""
Generates high-readability anime game icons and portraits
with close-up framing, vibrant colors, clean circular gold rim,
and full multi-resolution ICO support (16x16 up to 256x256).
"""
import os
from PIL import Image, ImageDraw, ImageEnhance

BASE_DIR = "e:/Trok/ChibiRPG_Project"
SOURCE_IMAGE = os.path.join(BASE_DIR, "game/icon.png")

def build_icons():
    # Load 1024x1024 source
    orig = Image.open(SOURCE_IMAGE).convert('RGBA')
    w_orig, h_orig = orig.size

    # Close-up hero crop centered on face: 500x500
    center_x, center_y = 512, 525
    half = 250
    crop = orig.crop((center_x - half, center_y - half, center_x + half, center_y + half))
    
    # Resize to standard 512x512 master resolution with high quality Lanczos
    master = crop.resize((512, 512), Image.Resampling.LANCZOS)

    # Enhance contrast, vibrancy, and sharpness for razor-sharp small icon readability
    enh_col = ImageEnhance.Color(master)
    vibrant = enh_col.enhance(1.10)
    enh_sharp = ImageEnhance.Sharpness(vibrant)
    sharp = enh_sharp.enhance(1.15)
    enh_cont = ImageEnhance.Contrast(sharp)
    boosted = enh_cont.enhance(1.05)

    w, h = 512, 512
    margin = 8

    # High-resolution antialiased circular mask
    mask_hr = Image.new('L', (w * 2, h * 2), 0)
    draw_m = ImageDraw.Draw(mask_hr)
    draw_m.ellipse([margin * 2, margin * 2, (w - margin) * 2, (h - margin) * 2], fill=255)
    mask = mask_hr.resize((w, h), Image.Resampling.LANCZOS)
    boosted.putalpha(mask)

    # Dual golden rim
    rim = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(rim)
    gold_edge = (190, 140, 35, 230)
    gold_bright = (252, 218, 85, 255)
    dr.ellipse([margin, margin, w - margin, h - margin], outline=gold_edge, width=6)
    dr.ellipse([margin + 2, margin + 2, w - margin - 2, h - margin - 2], outline=gold_bright, width=3)

    final_icon = Image.alpha_composite(boosted, rim)

    # 1. Save master icon.png (512x512 RGBA)
    icon_png_path = os.path.join(BASE_DIR, "game/icon.png")
    final_icon.save(icon_png_path, "PNG")
    print(f"Saved: {icon_png_path}")

    # 2. Save player_portrait.png (512x512 RGBA)
    portrait_path = os.path.join(BASE_DIR, "game/assets/textures/player_portrait.png")
    final_icon.save(portrait_path, "PNG")
    print(f"Saved: {portrait_path}")

    # 3. Save multi-resolution Windows ICO (16, 32, 48, 64, 128, 256)
    ico_path = os.path.join(BASE_DIR, "game/icon.ico")
    ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    final_icon.save(ico_path, format="ICO", sizes=ico_sizes)
    print(f"Saved multi-resolution ICO: {ico_path} with sizes: {ico_sizes}")

    # Clean up test scratch files
    test_files = [
        "game/test_crop_icon.png",
        "game/test_port.png",
        "game/test_cover_crop.png",
        "game/crop_380.png",
        "game/crop_480.png",
        "game/crop_580.png",
        "game/test_preview_128.png",
        "game/test_preview_64.png",
        "game/test_preview_48.png",
        "game/test_preview_32.png",
        "game/icon_circle_580.png",
        "game/icon_squircle_580.png",
        "game/icon_square_580.png",
        "game/test_taskbar_simulation.png",
        "game/test_taskbar_circle.png",
        "game/test_extracted_ico_48.png",
        "game/test_comp_500_48.png",
        "game/test_comp_530_48.png",
        "game/test_comp_560_48.png",
    ]
    for tf in test_files:
        full_tf = os.path.join(BASE_DIR, tf)
        if os.path.exists(full_tf):
            try:
                os.remove(full_tf)
            except:
                pass

    print("Icon build and cleanup completed successfully!")

if __name__ == '__main__':
    build_icons()
