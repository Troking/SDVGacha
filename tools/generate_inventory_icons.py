"""
Generates high quality anime-styled RPG icons for inventory and loot drops.
Creates:
- potion_hp.png
- crystal_exp.png
- shield_steel.png
- shield_epic.png
- shield_legend.png
- boots_epic.png
- boots_legend.png
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "game/assets/textures/icons"
os.makedirs(OUTPUT_DIR, exist_ok=True)
SIZE = 128

def create_base():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

def draw_radial_glow(draw, center, radius, color):
    cx, cy = center
    for r in range(radius, 0, -2):
        alpha = int(color[3] * (1.0 - (r / radius) ** 1.5))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(color[0], color[1], color[2], alpha))

def generate_potion_hp():
    img = create_base()
    draw = ImageDraw.Draw(img)
    
    # Background soft glow
    draw_radial_glow(draw, (64, 76), 56, (255, 60, 80, 70))
    
    # Glass flask shape
    # Neck: (52, 28) to (76, 48)
    # Rim: (48, 20) to (80, 28)
    # Cork: (54, 12) to (74, 22)
    # Body: Rounded bottle (28, 44) to (100, 114)
    
    # Cork
    draw.rounded_rectangle([55, 12, 73, 22], radius=3, fill=(180, 130, 80, 255), outline=(110, 70, 35, 255), width=2)
    
    # Liquid in flask (Ruby red gradient)
    liquid = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(liquid)
    ldraw.ellipse([32, 48, 96, 110], fill=(235, 35, 65, 240))
    ldraw.rectangle([48, 44, 80, 70], fill=(235, 35, 65, 240))
    # Liquid highlight / depth
    ldraw.ellipse([40, 56, 88, 104], fill=(255, 75, 105, 255))
    ldraw.ellipse([50, 72, 78, 98], fill=(255, 160, 180, 220))
    
    img = Image.alpha_composite(img, liquid)
    draw = ImageDraw.Draw(img)
    
    # Glass outer bottle
    draw.ellipse([30, 46, 98, 112], outline=(220, 240, 255, 210), width=3)
    draw.rectangle([52, 26, 76, 48], fill=(200, 230, 255, 60), outline=(220, 240, 255, 210), width=3)
    draw.rounded_rectangle([48, 20, 80, 28], radius=3, fill=(210, 235, 255, 160), outline=(230, 245, 255, 230), width=2)
    
    # Glass shine / specular highlight
    draw.arc([36, 52, 92, 106], start=135, end=225, fill=(255, 255, 255, 240), width=4)
    draw.ellipse([42, 60, 52, 70], fill=(255, 255, 255, 220))
    
    # Magical heart / sparkle inside potion
    draw.polygon([(64, 78), (70, 70), (74, 73), (71, 79), (64, 87), (57, 79), (54, 73), (58, 70)], fill=(255, 245, 220, 240))
    # Little rising bubbles
    draw.ellipse([68, 62, 73, 67], fill=(255, 220, 230, 200))
    draw.ellipse([56, 82, 60, 86], fill=(255, 220, 230, 200))
    draw.ellipse([62, 92, 65, 95], fill=(255, 220, 230, 200))
    
    img.save(os.path.join(OUTPUT_DIR, "potion_hp.png"))
    print("Saved potion_hp.png")

def generate_crystal_exp():
    img = create_base()
    draw = ImageDraw.Draw(img)
    
    # Radiant Cyan/Teal Elemental Crystal
    draw_radial_glow(draw, (64, 64), 58, (40, 210, 255, 80))
    
    # Octahedral multi-faceted anime gem
    # Top tip: (64, 16)
    # Bottom tip: (64, 114)
    # Left apex: (24, 64)
    # Right apex: (104, 64)
    # Center diamond: (64, 46) to (64, 82), (48, 64), (80, 64)
    
    # Outer facets
    # Top Left
    draw.polygon([(64, 16), (24, 64), (48, 64), (64, 46)], fill=(50, 180, 240, 255))
    # Top Right
    draw.polygon([(64, 16), (104, 64), (80, 64), (64, 46)], fill=(130, 235, 255, 255))
    # Bottom Left
    draw.polygon([(24, 64), (64, 114), (64, 82), (48, 64)], fill=(25, 120, 190, 255))
    # Bottom Right
    draw.polygon([(104, 64), (64, 114), (64, 82), (80, 64)], fill=(45, 160, 225, 255))
    # Center diamond front facet
    draw.polygon([(64, 46), (80, 64), (64, 82), (48, 64)], fill=(185, 248, 255, 255))
    
    # Crystal facets wireframe / bright edges
    lines = [
        [(64, 16), (24, 64)], [(64, 16), (104, 64)], [(24, 64), (64, 114)], [(104, 64), (64, 114)],
        [(64, 16), (64, 46)], [(64, 114), (64, 82)],
        [(48, 64), (64, 46)], [(64, 46), (80, 64)], [(80, 64), (64, 82)], [(64, 82), (48, 64)],
        [(24, 64), (48, 64)], [(80, 64), (104, 64)]
    ]
    for p1, p2 in lines:
        draw.line([p1, p2], fill=(230, 252, 255, 255), width=2)
        
    # Brilliant flare highlight on corner
    draw_radial_glow(draw, (64, 46), 14, (255, 255, 255, 230))
    draw.ellipse([62, 44, 66, 48], fill=(255, 255, 255, 255))
    
    # Floating elemental motes
    draw.ellipse([34, 30, 39, 35], fill=(200, 245, 255, 220))
    draw.ellipse([92, 34, 96, 38], fill=(200, 245, 255, 220))
    draw.ellipse([90, 96, 94, 100], fill=(200, 245, 255, 200))
    
    img.save(os.path.join(OUTPUT_DIR, "crystal_exp.png"))
    print("Saved crystal_exp.png")

def generate_shield_steel():
    img = create_base()
    draw = ImageDraw.Draw(img)
    draw_radial_glow(draw, (64, 64), 54, (120, 180, 255, 60))
    
    # Classic kite shield silhouette
    # Top: (26, 26) to (102, 26)
    # Bottom point: (64, 116)
    shield_pts = [(26, 26), (102, 26), (104, 68), (64, 116), (24, 68)]
    draw.polygon(shield_pts, fill=(90, 110, 135, 255), outline=(210, 225, 245, 255))
    
    inner_pts = [(32, 32), (96, 32), (98, 66), (64, 108), (30, 66)]
    draw.polygon(inner_pts, fill=(50, 70, 95, 255))
    
    # Cross / emblem
    draw.line([(64, 34), (64, 102)], fill=(215, 230, 250, 255), width=6)
    draw.line([(38, 54), (90, 54)], fill=(215, 230, 250, 255), width=6)
    draw.ellipse([58, 48, 70, 60], fill=(255, 215, 80, 255), outline=(255, 245, 180, 255), width=2)
    
    img.save(os.path.join(OUTPUT_DIR, "shield_steel.png"))
    print("Saved shield_steel.png")

def generate_shield_epic():
    img = create_base()
    draw = ImageDraw.Draw(img)
    draw_radial_glow(draw, (64, 64), 58, (190, 70, 255, 80))
    
    # Ornate Fantasy Bastion Shield (Epic Purple / Gold)
    shield_pts = [(22, 24), (64, 18), (106, 24), (108, 72), (64, 118), (20, 72)]
    draw.polygon(shield_pts, fill=(215, 175, 60, 255))
    
    inner_pts = [(28, 30), (64, 25), (100, 30), (102, 70), (64, 110), (26, 70)]
    draw.polygon(inner_pts, fill=(75, 30, 110, 255))
    
    # Dragon wing / flame crest
    draw.polygon([(64, 36), (82, 58), (64, 94), (46, 58)], fill=(145, 60, 215, 255), outline=(255, 225, 110, 255), width=2)
    draw.polygon([(64, 46), (74, 60), (64, 82), (54, 60)], fill=(240, 130, 255, 255))
    
    # Radiant center gem
    draw.ellipse([58, 56, 70, 68], fill=(255, 240, 140, 255))
    
    img.save(os.path.join(OUTPUT_DIR, "shield_epic.png"))
    print("Saved shield_epic.png")

def generate_shield_legend():
    img = create_base()
    draw = ImageDraw.Draw(img)
    draw_radial_glow(draw, (64, 64), 62, (255, 195, 35, 95))
    
    # Divine Sun Aegis Shield (5-Star Radiant Gold)
    shield_pts = [(20, 24), (64, 14), (108, 24), (110, 70), (64, 120), (18, 70)]
    draw.polygon(shield_pts, fill=(255, 215, 75, 255), outline=(255, 245, 190, 255), width=3)
    
    inner_pts = [(28, 32), (64, 22), (100, 32), (102, 68), (64, 110), (26, 68)]
    draw.polygon(inner_pts, fill=(185, 120, 20, 255))
    
    # Sunburst rays inside
    draw_radial_glow(draw, (64, 62), 34, (255, 235, 120, 180))
    draw.polygon([(64, 28), (68, 62), (64, 96), (60, 62)], fill=(255, 245, 190, 255))
    draw.polygon([(32, 62), (64, 58), (96, 62), (64, 66)], fill=(255, 245, 190, 255))
    draw.ellipse([54, 52, 74, 72], fill=(255, 80, 40, 255), outline=(255, 240, 160, 255), width=3)
    draw.ellipse([58, 56, 70, 68], fill=(255, 220, 90, 255))
    
    img.save(os.path.join(OUTPUT_DIR, "shield_legend.png"))
    print("Saved shield_legend.png")

def generate_boots_epic():
    img = create_base()
    draw = ImageDraw.Draw(img)
    draw_radial_glow(draw, (64, 68), 56, (180, 80, 255, 75))
    
    # Purple & silver enchanted high-agility boots
    # Boot shaft
    draw.polygon([(38, 22), (68, 22), (72, 68), (44, 68)], fill=(65, 30, 95, 255), outline=(190, 140, 240, 255), width=2)
    # Boot foot
    draw.polygon([(44, 68), (72, 68), (102, 88), (98, 102), (36, 102), (36, 88)], fill=(85, 45, 125, 255), outline=(210, 170, 255, 255), width=2)
    # Sole / heel
    draw.polygon([(34, 98), (98, 98), (96, 106), (34, 106)], fill=(30, 15, 45, 255))
    # Wing ornament on heel
    draw.polygon([(34, 50), (14, 38), (28, 60), (12, 54), (32, 74)], fill=(230, 210, 255, 255), outline=(255, 255, 255, 255))
    # Gold buckle straps
    draw.line([(40, 42), (70, 42)], fill=(255, 215, 85, 255), width=4)
    draw.line([(42, 56), (71, 56)], fill=(255, 215, 85, 255), width=4)
    
    img.save(os.path.join(OUTPUT_DIR, "boots_epic.png"))
    print("Saved boots_epic.png")

def generate_boots_legend():
    img = create_base()
    draw = ImageDraw.Draw(img)
    draw_radial_glow(draw, (64, 68), 60, (255, 195, 35, 90))
    
    # Golden Winged Hermes Sandal-Boots
    draw.polygon([(40, 20), (70, 20), (74, 66), (44, 66)], fill=(225, 160, 25, 255), outline=(255, 240, 160, 255), width=2)
    draw.polygon([(44, 66), (74, 66), (104, 86), (100, 102), (36, 102), (36, 86)], fill=(245, 190, 45, 255), outline=(255, 245, 185, 255), width=2)
    draw.polygon([(34, 98), (100, 98), (98, 106), (34, 106)], fill=(120, 70, 15, 255))
    
    # Large feather wings
    draw.polygon([(36, 46), (8, 22), (24, 48), (6, 40), (22, 62), (8, 58), (34, 76)], fill=(255, 255, 255, 255), outline=(255, 235, 140, 255), width=2)
    # Radiant laces & gem
    draw.line([(42, 36), (71, 36)], fill=(255, 250, 210, 255), width=3)
    draw.line([(43, 50), (72, 50)], fill=(255, 250, 210, 255), width=3)
    draw.ellipse([54, 44, 64, 54], fill=(80, 220, 255, 255), outline=(255, 255, 255, 255), width=2)
    
    img.save(os.path.join(OUTPUT_DIR, "boots_legend.png"))
    print("Saved boots_legend.png")

if __name__ == "__main__":
    generate_potion_hp()
    generate_crystal_exp()
    generate_shield_steel()
    generate_shield_epic()
    generate_shield_legend()
    generate_boots_epic()
    generate_boots_legend()
    print("All icons successfully generated!")
