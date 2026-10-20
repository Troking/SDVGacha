"""
Texture generator for Asian Fantasy World (Genshin Impact / Liyue / Inazuma style)
Generates high quality stylized textures for architecture, nature, and props.
"""
import os
import math
from PIL import Image, ImageDraw, ImageFilter

TEXTURE_DIR = "e:/Trok/ChibiRPG_Project/game/assets/textures"
os.makedirs(TEXTURE_DIR, exist_ok=True)

def generate_asian_roof_tiles():
    # 512x512 Seamless Asian curved ceramic roof tiles (emerald jade teal / deep terracotta)
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (34, 66, 62, 255))
    draw = ImageDraw.Draw(im)

    row_height = 32
    num_rows = h // row_height + 1
    tile_width = 32

    for r in range(num_rows):
        y_top = r * row_height
        y_bot = y_top + row_height
        x_offset = (tile_width // 2) if (r % 2 == 1) else 0

        for c in range(-1, w // tile_width + 2):
            x_left = c * tile_width + x_offset
            x_right = x_left + tile_width
            x_mid = (x_left + x_right) // 2

            c_base = (30, 60, 56)
            c_light = (48, 92, 86)
            c_edge = (20, 42, 38)
            c_gold = (195, 155, 65)

            bbox = [x_left, y_top - 6, x_right, y_bot + 6]
            draw.pieslice(bbox, 0, 180, fill=c_light, outline=c_edge, width=2)
            draw.arc([x_left + 3, y_top, x_right - 3, y_bot], 0, 180, fill=c_base, width=2)
            draw.ellipse([x_mid - 3, y_bot - 4, x_mid + 3, y_bot + 2], fill=c_gold, outline=(80, 55, 20))

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "asian_roof_tiles.png"))
    print("Saved asian_roof_tiles.png")

def generate_asian_wood_vermilion():
    # 512x512 Rich vermilion cinnabar red lacquer wood (clean, satiny, no harsh bands)
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (185, 36, 26, 255))
    draw = ImageDraw.Draw(im)

    for y in range(h):
        for x in range(0, w, 4):
            grain = int(math.sin(y * 0.08 + x * 0.03) * 8 + math.cos(y * 0.25) * 5)
            r = min(255, max(0, 185 + grain))
            g = min(255, max(0, 36 + grain // 3))
            b = min(255, max(0, 26 + grain // 4))
            draw.line([(x, y), (x + 3, y)], fill=(r, g, b, 255))

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "asian_wood_vermilion.png"))
    print("Saved asian_wood_vermilion.png")

def generate_asian_wood_dark():
    # 512x512 Dark aged cedar / cypress timber (smooth satin finish)
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (46, 32, 26, 255))
    draw = ImageDraw.Draw(im)

    for y in range(h):
        for x in range(0, w, 4):
            grain = int(math.sin(y * 0.12 + x * 0.02) * 6 + math.sin(y * 0.04) * 8)
            r = min(255, max(0, 46 + grain))
            g = min(255, max(0, 32 + grain))
            b = min(255, max(0, 26 + grain // 2))
            draw.line([(x, y), (x + 3, y)], fill=(r, g, b, 255))

    im = im.filter(ImageFilter.SMOOTH_MORE)
    im.save(os.path.join(TEXTURE_DIR, "asian_wood_dark.png"))
    print("Saved asian_wood_dark.png")

def generate_asian_shoji_wall():
    # 512x512 Traditional warm Japanese plaster / delicate shoji washi wall
    w, h = 512, 512
    # Soft warm ivory washi paper
    im = Image.new("RGBA", (w, h), (246, 243, 236, 255))
    draw = ImageDraw.Draw(im)

    # Subtle paper texture grain
    for y in range(0, h, 6):
        v = int(math.sin(y * 0.2) * 4)
        draw.line([(0, y), (w, y)], fill=(246 + v, 243 + v, 236 + v, 255))

    # Dark wood outer frame (perimeter beams)
    frame_w = 20
    draw.rectangle([0, 0, w, frame_w], fill=(54, 38, 30, 255))
    draw.rectangle([0, h - frame_w, w, h], fill=(54, 38, 30, 255))
    draw.rectangle([0, 0, frame_w, h], fill=(54, 38, 30, 255))
    draw.rectangle([w - frame_w, 0, w, h], fill=(54, 38, 30, 255))

    # Lower wooden wainscot panel (traditional Japanese koshi panel)
    koshi_h = 96
    draw.rectangle([frame_w, h - koshi_h, w - frame_w, h - frame_w], fill=(68, 48, 36, 255))
    # Wainscot vertical slats
    for x in range(frame_w, w - frame_w, 24):
        draw.line([(x, h - koshi_h), (x, h - frame_w)], fill=(50, 34, 25, 255), width=2)

    # Delicate, thin shoji lattice (Kumiko) on upper portion - very thin and graceful!
    grid_w = 48
    grid_h = 36
    lattice_col = (135, 105, 82, 255)
    for x in range(frame_w + grid_w, w - frame_w, grid_w):
        draw.line([(x, frame_w), (x, h - koshi_h)], fill=lattice_col, width=2)
    for y in range(frame_w + grid_h, h - koshi_h, grid_h):
        draw.line([(frame_w, y), (w - frame_w, y)], fill=lattice_col, width=2)

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "asian_shoji_wall.png"))
    print("Saved asian_shoji_wall.png")

def generate_asian_stone_pavers():
    # 512x512 Stylized granite flagstone paving (soft, natural stone tones, NO harsh checkerboards)
    w, h = 512, 512
    base_col = (140, 136, 128)
    im = Image.new("RGBA", (w, h), base_col + (255,))
    draw = ImageDraw.Draw(im)

    # Natural mottled granite stone variation
    for y in range(0, h, 4):
        for x in range(0, w, 4):
            val = int(math.sin(x * 0.05 + y * 0.03) * 8 + math.cos(x * 0.02 - y * 0.06) * 10)
            r = min(255, max(0, base_col[0] + val))
            g = min(255, max(0, base_col[1] + val))
            b = min(255, max(0, base_col[2] + val))
            draw.rectangle([x, y, x + 3, y + 3], fill=(r, g, b, 255))

    # Soft, organic flagstone segments (subtle warm seams, not harsh black lines)
    seam_col = (105, 100, 92, 180)
    step_x = 128
    step_y = 64
    for gy in range(h // step_y + 1):
        y_pos = gy * step_y
        offset = (step_x // 2) if (gy % 2 == 1) else 0
        draw.line([(0, y_pos), (w, y_pos)], fill=seam_col, width=2)
        for gx in range(w // step_x + 2):
            x_pos = gx * step_x + offset
            draw.line([(x_pos, y_pos), (x_pos, y_pos + step_y)], fill=seam_col, width=2)

    # Subtle mossy accents
    for i in range(18):
        mx = int((math.sin(i * 2.3) * 0.5 + 0.5) * w)
        my = int((math.cos(i * 3.1) * 0.5 + 0.5) * h)
        rad = 12 + int(math.sin(i) * 8)
        draw.ellipse([mx - rad, my - rad // 2, mx + rad, my + rad // 2], fill=(90, 108, 80, 70))

    im = im.filter(ImageFilter.GaussianBlur(1.0))
    im.save(os.path.join(TEXTURE_DIR, "asian_stone_pavers.png"))
    print("Saved asian_stone_pavers.png")

def generate_sakura_foliage():
    # 512x512 Soft fluffy pink cherry blossom foliage with painterly petals
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (255, 205, 220, 255))
    draw = ImageDraw.Draw(im)

    for i in range(380):
        cx = int((math.sin(i * 1.3) * 0.5 + 0.5) * w)
        cy = int((math.cos(i * 1.7) * 0.5 + 0.5) * h)
        r = 16 + int(math.sin(i) * 10)

        tone = (math.sin(i * 0.8) + 1.0) * 0.5
        pr = 255
        pg = int(145 + tone * 85)
        pb = int(185 + tone * 55)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(pr, pg, pb, 220))

    im = im.filter(ImageFilter.GaussianBlur(1.5))
    im.save(os.path.join(TEXTURE_DIR, "sakura_foliage.png"))
    print("Saved sakura_foliage.png")

def generate_bamboo_texture():
    # 512x512 Stylized green bamboo stalk with segment nodes
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (85, 160, 65, 255))
    draw = ImageDraw.Draw(im)

    for x in range(w):
        curve = math.sin((x / w) * math.pi)
        r = int(52 + curve * 42)
        g = int(125 + curve * 60)
        b = int(42 + curve * 32)
        draw.line([(x, 0), (x, h)], fill=(r, g, b, 255))

    node_y_positions = [64, 192, 320, 448]
    for ny in node_y_positions:
        draw.rectangle([0, ny - 6, w, ny + 6], fill=(162, 188, 92, 255))
        draw.line([(0, ny - 6), (w, ny - 6)], fill=(52, 98, 36, 255), width=2)
        draw.line([(0, ny + 6), (w, ny + 6)], fill=(42, 82, 28, 255), width=2)

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "bamboo_texture.png"))
    print("Saved bamboo_texture.png")

def generate_asian_lantern_texture():
    # 512x512 Glowing red silk paper lantern with golden rims and calligraphy
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (215, 32, 25, 255))
    draw = ImageDraw.Draw(im)

    for x in range(0, w, 24):
        draw.line([(x, 30), (x, h - 30)], fill=(155, 16, 14, 255), width=2)
        draw.line([(x + 12, 30), (x + 12, h - 30)], fill=(245, 65, 45, 255), width=3)

    # Central golden emblem
    draw.ellipse([w//2 - 80, h//2 - 80, w//2 + 80, h//2 + 80], outline=(235, 185, 60), width=6)
    draw.ellipse([w//2 - 62, h//2 - 62, w//2 + 62, h//2 + 62], outline=(235, 185, 60), width=3)
    draw.line([(w//2, h//2 - 40), (w//2, h//2 + 40)], fill=(245, 215, 85), width=6)
    draw.line([(w//2 - 38, h//2 - 12), (w//2 + 38, h//2 - 12)], fill=(245, 215, 85), width=6)
    draw.line([(w//2 - 28, h//2 + 20), (w//2 + 28, h//2 + 20)], fill=(245, 215, 85), width=6)

    # Golden top and bottom rims
    draw.rectangle([0, 0, w, 28], fill=(215, 170, 48, 255))
    draw.rectangle([0, h - 28, w, h], fill=(215, 170, 48, 255))
    draw.line([(0, 28), (w, 28)], fill=(65, 42, 12, 255), width=2)
    draw.line([(0, h - 28), (w, h - 28)], fill=(65, 42, 12, 255), width=2)

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "asian_paper_lantern.png"))
    print("Saved asian_paper_lantern.png")

def generate_karst_cliff_texture():
    # 512x512 Vertical layered sandstone karst cliff rock with moss
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (118, 108, 98, 255))
    draw = ImageDraw.Draw(im)

    for y in range(0, h, 6):
        wave = math.sin(y * 0.1) * 6
        strata_val = int(math.sin(y * 0.08) * 25)
        col = (118 + strata_val, 108 + strata_val, 98 + strata_val, 255)
        draw.line([(0, y + wave), (w, y + wave)], fill=col, width=3)

    for x in range(30, w, 50):
        points = []
        cx = x
        for y in range(0, h, 20):
            cx += int(math.sin(y * 0.2 + x) * 5)
            points.append((cx, y))
        draw.line(points, fill=(58, 52, 46, 255), width=2)

    for my in range(40, h, 80):
        draw.ellipse([20, my - 6, 160, my + 6], fill=(78, 118, 56, 180))
        draw.ellipse([220, my - 5, 420, my + 5], fill=(70, 108, 50, 180))

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "karst_cliff_rock.png"))
    print("Saved karst_cliff_rock.png")

def generate_water_texture():
    # 512x512 Stylized turquoise anime water with soft caustic foam
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (32, 148, 198, 220))
    draw = ImageDraw.Draw(im)

    for i in range(120):
        cx = int((math.sin(i * 1.8) * 0.5 + 0.5) * w)
        cy = int((math.cos(i * 2.3) * 0.5 + 0.5) * h)
        rad = 22 + int(math.sin(i * 0.9) * 14)
        draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], outline=(185, 242, 255, 110), width=2)

    im = im.filter(ImageFilter.GaussianBlur(1.0))
    im.save(os.path.join(TEXTURE_DIR, "water_stream.png"))
    print("Saved water_stream.png")

def main():
    generate_asian_roof_tiles()
    generate_asian_wood_vermilion()
    generate_asian_wood_dark()
    generate_asian_shoji_wall()
    generate_asian_stone_pavers()
    generate_sakura_foliage()
    generate_bamboo_texture()
    generate_asian_lantern_texture()
    generate_karst_cliff_texture()
    generate_water_texture()
    print("All Asian Fantasy textures generated successfully!")

if __name__ == '__main__':
    main()
