import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_TEXTURES = "e:/Trok/ChibiRPG_Project/game/assets/textures"

def refine_ellen_body():
    orig_cloth = Image.open("e:/Trok/ChibiRPG_Project/game/assets/models/anime_heroine_rigged_服.png").convert("RGBA")
    w, h = orig_cloth.size
    arr = np.array(orig_cloth, dtype=np.float32)

    r_orig = arr[:, :, 0]
    g_orig = arr[:, :, 1]
    b_orig = arr[:, :, 2]
    a_orig = arr[:, :, 3]

    # Luminance channel preserving all hand-painted fabric folds, creases, and AO
    lum = (r_orig * 0.299 + g_orig * 0.587 + b_orig * 0.114) / 255.0

    # 1. Base Gothic Charcoal Maid Palette with natural folds
    # Dark charcoal/slate with subtle cool anime sheen
    r_dark = np.clip(lum * 42.0 + 16.0, 0, 255)
    g_dark = np.clip(lum * 45.0 + 18.0, 0, 255)
    b_dark = np.clip(lum * 58.0 + 24.0, 0, 255)

    base_dark = np.dstack([r_dark, g_dark, b_dark, a_orig]).astype(np.uint8)
    base_img = Image.fromarray(base_dark, "RGBA")
    draw = ImageDraw.Draw(base_img)

    # 2. White Frilled Maid Apron on Coat-Tails (X: 1100..1700, Y: 150..1400)
    # We preserve the underlying folds by modulating white by luminance
    apron_mask = Image.new("L", (w, h), 0)
    ap_draw = ImageDraw.Draw(apron_mask)
    # Scalloped rounded apron shape
    ap_draw.polygon([
        (1160, 200), (1640, 200),
        (1680, 500), (1660, 1200),
        (1580, 1340), (1400, 1370), (1220, 1340),
        (1140, 1200), (1120, 500)
    ], fill=255)
    # Add scalloped frills along bottom hem
    for fx in range(1160, 1640, 28):
        ap_draw.ellipse([fx - 14, 1330, fx + 14, 1380], fill=255)

    apron_arr = np.array(apron_mask, dtype=np.float32) / 255.0
    r_white = np.clip(lum * 60.0 + 195.0, 0, 255)
    g_white = np.clip(lum * 60.0 + 195.0, 0, 255)
    b_white = np.clip(lum * 55.0 + 200.0, 0, 255)

    r_blended = r_dark * (1.0 - apron_arr) + r_white * apron_arr
    g_blended = g_dark * (1.0 - apron_arr) + g_white * apron_arr
    b_blended = b_dark * (1.0 - apron_arr) + b_white * apron_arr

    # 3. Sheer Black Fishnet Stockings over Legs (X: 820..1440, Y: 1600..2048)
    # Use original skin tones from Hu Tao's thighs, then tint with sheer black stocking nylon
    leg_mask = np.zeros((h, w), dtype=np.float32)
    leg_mask[1600:2048, 820:1440] = 1.0

    # Smooth anime skin from original
    r_skin = r_orig
    g_skin = g_orig
    b_skin = b_orig
    # 65% dark nylon tint
    r_stocking = r_skin * 0.35 + 14.0
    g_stocking = g_skin * 0.32 + 12.0
    b_stocking = b_skin * 0.38 + 18.0

    r_blended = r_blended * (1.0 - leg_mask) + r_stocking * leg_mask
    g_blended = g_blended * (1.0 - leg_mask) + g_stocking * leg_mask
    b_blended = b_blended * (1.0 - leg_mask) + b_stocking * leg_mask

    final_arr = np.dstack([r_blended, g_blended, b_blended, a_orig]).astype(np.uint8)
    final_img = Image.fromarray(final_arr, "RGBA")
    draw = ImageDraw.Draw(final_img)

    # 4. White lace garter cuffs at top of stockings (Y: 1610..1660)
    for lx in range(830, 1430, 22):
        draw.ellipse([lx - 10, 1610, lx + 10, 1655], fill=(250, 252, 255, 255))
    # Red garter ribbons
    draw.ellipse([1020, 1630, 1055, 1665], fill=(230, 25, 45, 255))
    draw.ellipse([1220, 1630, 1255, 1665], fill=(230, 25, 45, 255))

    # 5. Silver zipper and tailored corset buttons down center
    draw.line([(680, 120), (680, 920)], fill=(210, 218, 230, 255), width=7)
    for zy in range(130, 910, 20):
        draw.line([(675, zy), (685, zy)], fill=(245, 250, 255, 255), width=3)
    for by in range(240, 840, 140):
        draw.ellipse([620, by, 642, by + 22], fill=(225, 230, 240, 255))
        draw.ellipse([624, by + 4, 638, by + 18], fill=(160, 165, 175, 255))
        draw.ellipse([718, by, 740, by + 22], fill=(225, 230, 240, 255))
        draw.ellipse([722, by + 4, 736, by + 18], fill=(160, 165, 175, 255))

    # 6. Collar & Cravat (X: 800..1200, Y: 0..350)
    # White ruffled collar
    draw.rectangle([830, 40, 1170, 280], fill=(248, 250, 255, 255))
    for cx in range(830, 1170, 18):
        draw.ellipse([cx - 9, 270, cx + 9, 295], fill=(255, 255, 255, 255))
    # Black bow tie
    draw.polygon([(1000, 160), (940, 240), (1000, 220), (1060, 240)], fill=(20, 22, 28, 255))
    # Silver maid medallion with cyan frost gem
    draw.ellipse([988, 215, 1012, 239], fill=(215, 222, 235, 255))
    draw.ellipse([993, 220, 1007, 234], fill=(75, 215, 255, 255))

    # 7. Victoria Housekeeping Emblem (X: 1750..2048, Y: 1100..1400)
    draw.rectangle([1760, 1110, 2030, 1390], fill=(24, 26, 34, 255))
    draw.polygon([(1895, 1140), (1990, 1200), (1950, 1340), (1895, 1370), (1840, 1340), (1800, 1200)], fill=(210, 220, 235, 255))
    draw.polygon([(1895, 1190), (1945, 1230), (1925, 1300), (1895, 1320), (1865, 1300), (1845, 1230)], fill=(65, 215, 255, 255))

    out_path = os.path.join(OUTPUT_TEXTURES, "ellen_body_diffuse.png")
    final_img.save(out_path)
    print("Refined:", out_path)

if __name__ == "__main__":
    refine_ellen_body()
