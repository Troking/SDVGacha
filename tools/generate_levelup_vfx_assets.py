"""
Generates refined, laconic VFX textures for Level Up Effect:
1. fx_ascension_ring.png: Elegant 512x512 celestial golden mandala ring for ground seal.
2. fx_celestial_sparkle.png: Crisp 256x256 4-pointed diamond star sparkle.
3. fx_light_shaft.png: Soft 256x512 feathered ethereal ascension light beam.
"""

import math
import os
from PIL import Image, ImageDraw

TEXTURE_DIR = "e:/Trok/ChibiRPG_Project/game/assets/textures"
os.makedirs(TEXTURE_DIR, exist_ok=True)

# -------------------------------------------------------------------------
# 1. fx_ascension_ring.png (512x512)
# -------------------------------------------------------------------------
def generate_ascension_ring():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2

    # Draw soft subtle outer ring glow
    glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for r in range(120, 240, 2):
        dist_from_main = abs(r - 200)
        alpha = int(max(0, 35 - dist_from_main * 0.9))
        if alpha > 0:
            color = (255, 220, 130, alpha)
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color, width=2)

    # Concentric precise rings
    # Outer thin ring
    draw.ellipse([cx - 225, cy - 225, cx + 225, cy + 225], outline=(255, 230, 160, 160), width=2)
    # Secondary ring
    draw.ellipse([cx - 200, cy - 200, cx + 200, cy + 200], outline=(255, 245, 200, 220), width=3)
    # Inner ring
    draw.ellipse([cx - 165, cy - 165, cx + 165, cy + 165], outline=(255, 225, 140, 150), width=2)
    # Core circle
    draw.ellipse([cx - 90, cy - 90, cx + 90, cy + 90], outline=(255, 235, 170, 180), width=2)
    draw.ellipse([cx - 45, cy - 45, cx + 45, cy + 45], outline=(255, 250, 220, 200), width=1)

    # 8-pointed star geometry
    for i in range(8):
        angle = i * (math.pi / 4.0)
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)

        # Spoke line
        p1 = (cx + cos_a * 95, cy + sin_a * 95)
        p2 = (cx + cos_a * 195, cy + sin_a * 195)
        draw.line([p1, p2], fill=(255, 235, 170, 140), width=2)

        # Diamond tip on outer ring
        tip_r = 200
        d_size = 8
        d_pts = [
            (cx + cos_a * (tip_r + d_size), cy + sin_a * (tip_r + d_size)),
            (cx + cos_a * tip_r - sin_a * (d_size * 0.6), cy + sin_a * tip_r + cos_a * (d_size * 0.6)),
            (cx + cos_a * (tip_r - d_size), cy + sin_a * (tip_r - d_size)),
            (cx + cos_a * tip_r + sin_a * (d_size * 0.6), cy + sin_a * tip_r - cos_a * (d_size * 0.6)),
        ]
        draw.polygon(d_pts, fill=(255, 250, 210, 230))

        # Small dots between diamonds
        mid_angle = angle + (math.pi / 8.0)
        dot_r = 200
        dx = cx + math.cos(mid_angle) * dot_r
        dy = cy + math.sin(mid_angle) * dot_r
        draw.ellipse([dx - 2.5, dy - 2.5, dx + 2.5, dy + 2.5], fill=(255, 230, 160, 200))

    # Center 4-point star
    for a in [0, math.pi * 0.5]:
        dx1 = math.cos(a) * 36
        dy1 = math.sin(a) * 36
        dx2 = math.cos(a + math.pi) * 36
        dy2 = math.sin(a + math.pi) * 36
        draw.line([(cx + dx1, cy + dy1), (cx + dx2, cy + dy2)], fill=(255, 255, 230, 240), width=3)

    out_path = os.path.join(TEXTURE_DIR, "fx_ascension_ring.png")
    img.save(out_path)
    print("Saved:", out_path)

# -------------------------------------------------------------------------
# 2. fx_celestial_sparkle.png (256x256)
# -------------------------------------------------------------------------
def generate_celestial_sparkle():
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx, cy = size // 2, size // 2

    # Radial bloom gradient
    for y in range(size):
        for x in range(size):
            dx = (x - cx) / float(cx)
            dy = (y - cy) / float(cy)
            dist_sq = dx*dx + dy*dy
            if dist_sq < 1.0:
                dist = math.sqrt(dist_sq)
                # 4-pointed diamond ray shape
                ray_x = max(0.0, 1.0 - abs(dx) * 3.5) * max(0.0, 1.0 - abs(dy) * 12.0)
                ray_y = max(0.0, 1.0 - abs(dy) * 3.5) * max(0.0, 1.0 - abs(dx) * 12.0)
                core_bloom = math.exp(-dist * 4.5) * 0.85
                val = min(1.0, ray_x + ray_y + core_bloom)
                if val > 0.01:
                    alpha = int(val * 255)
                    # Golden white
                    r = int(255)
                    g = int(235 + val * 20)
                    b = int(180 + val * 75)
                    img.putpixel((x, y), (r, g, b, alpha))

    out_path = os.path.join(TEXTURE_DIR, "fx_celestial_sparkle.png")
    img.save(out_path)
    print("Saved:", out_path)

# -------------------------------------------------------------------------
# 3. fx_light_shaft.png (256x512)
# -------------------------------------------------------------------------
def generate_light_shaft():
    w, h = 256, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx = w // 2

    for y in range(h):
        # Vertical gradient: fades out at top and base
        v_norm = y / float(h)
        v_fade = math.sin(v_norm * math.pi) ** 1.2
        for x in range(w):
            h_norm = abs(x - cx) / float(cx)
            if h_norm < 1.0:
                # Gaussian horizontal falloff
                h_fade = math.exp(-h_norm * h_norm * 4.5)
                val = v_fade * h_fade
                if val > 0.01:
                    alpha = int(val * 220)
                    # Warm ethereal golden white
                    r = int(255)
                    g = int(240 - h_norm * 30)
                    b = int(190 - h_norm * 60)
                    img.putpixel((x, y), (r, g, b, alpha))

    out_path = os.path.join(TEXTURE_DIR, "fx_light_shaft.png")
    img.save(out_path)
    print("Saved:", out_path)

if __name__ == "__main__":
    generate_ascension_ring()
    generate_celestial_sparkle()
    generate_light_shaft()
    print("Level-up VFX textures created successfully!")
