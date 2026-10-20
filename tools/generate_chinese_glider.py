"""
Chinese Traditional Painting (Guofeng / Shan Shui) Glider Generator
Generates high-res Guofeng texture and 3D GLB model for Hu Tao's celestial phoenix glider.
"""
import os
import math
import struct
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

TEXTURE_DIR = "e:/Trok/ChibiRPG_Project/game/assets/textures"
OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/models"
os.makedirs(TEXTURE_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_guofeng_glider_texture():
    w, h = 1024, 1024
    # Deep imperial crimson and ink-black silk base
    im = Image.new("RGBA", (w, h), (160, 24, 20, 255))
    draw = ImageDraw.Draw(im)

    # Shan Shui brush gradient: ink-wash dark gradient towards edges
    for y in range(h):
        for x in range(w):
            # Radial distance from center-top
            dx = (x - w/2) / (w/2)
            dy = (y - 100) / h
            dist = math.sqrt(dx*dx + dy*dy)
            # Ink gradient
            ink = min(1.0, max(0.0, dist * 0.85))
            r = int(185 * (1.0 - ink * 0.65) + 35 * ink)
            g = int(28 * (1.0 - ink * 0.7) + 18 * ink)
            b = int(24 * (1.0 - ink * 0.7) + 24 * ink)
            # Silk weave micro-pattern
            weave = (x % 4 == 0 or y % 4 == 0) * 8
            draw.point((x, y), fill=(min(255, r + weave), min(255, g + weave), min(255, b + weave), 255))

    # Classical Chinese Auspicious Cloud Scrolls (Xiangyun 祥云)
    def draw_xiangyun(cx, cy, scale=1.0, flip=False):
        gold = (235, 195, 65, 230)
        gold_shadow = (110, 80, 20, 200)
        s = scale
        # Main curl spirals
        offsets = [(0, 0), (25*s, -8*s), (50*s, -4*s), (70*s, 10*s), (-20*s, 8*s), (-40*s, 2*s)]
        for ox, oy in offsets:
            x = cx - ox if flip else cx + ox
            y = cy + oy
            r = int(22 * s)
            draw.ellipse([x - r, y - r, x + r, y + r], outline=gold_shadow, width=4)
            draw.ellipse([x - r + 2, y - r + 2, x + r - 2, y + r - 2], outline=gold, width=3)
        # Trailing tail scroll
        tail = []
        for t in range(25):
            tx = (cx - 40*s - t*4*s) if flip else (cx + 70*s + t*4*s)
            ty = cy + int(math.sin(t * 0.25) * 8 * s) + int(t * 1.5 * s)
            tail.append((tx, ty))
        if len(tail) > 1:
            draw.line(tail, fill=gold, width=int(4 * s))

    # Auspicious cloud patterns across wings
    for cy in [200, 420, 680]:
        draw_xiangyun(240, cy, scale=1.3, flip=True)
        draw_xiangyun(784, cy, scale=1.3, flip=False)
        draw_xiangyun(360, cy + 90, scale=0.9, flip=True)
        draw_xiangyun(664, cy + 90, scale=0.9, flip=False)

    # Flying Pyro Flame-Butterflies (Hu Tao's hallmark)
    def draw_pyro_butterfly(cx, cy, size=40):
        c_core = (255, 220, 110, 240)
        c_wing = (245, 95, 25, 210)
        c_edge = (255, 180, 40, 240)

        # Left wing
        draw.polygon([(cx, cy), (cx - size, cy - size*0.8), (cx - size*0.9, cy + size*0.2), (cx - size*0.4, cy + size*0.6)], fill=c_wing, outline=c_edge)
        draw.ellipse([cx - size*0.7, cy - size*0.5, cx - size*0.3, cy - size*0.1], fill=c_core)
        # Right wing
        draw.polygon([(cx, cy), (cx + size, cy - size*0.8), (cx + size*0.9, cy + size*0.2), (cx + size*0.4, cy + size*0.6)], fill=c_wing, outline=c_edge)
        draw.ellipse([cx + size*0.3, cy - size*0.5, cx + size*0.7, cy - size*0.1], fill=c_core)
        # Butterfly body & antennae
        draw.line([(cx, cy - size*0.6), (cx, cy + size*0.5)], fill=(255, 245, 180), width=3)
        draw.line([(cx, cy - size*0.6), (cx - 10, cy - size*0.9)], fill=(255, 245, 180), width=2)
        draw.line([(cx, cy - size*0.6), (cx + 10, cy - size*0.9)], fill=(255, 245, 180), width=2)

    # Butterflies dancing along the wing surface
    draw_pyro_butterfly(320, 300, 32)
    draw_pyro_butterfly(704, 300, 32)
    draw_pyro_butterfly(220, 520, 28)
    draw_pyro_butterfly(804, 520, 28)
    draw_pyro_butterfly(512, 180, 36) # Central butterfly above crest

    # Ornate Gold Brocade Trim along borders
    for x in range(0, w, 16):
        draw.line([(x, 0), (x + 8, 20)], fill=(225, 185, 55, 240), width=3)
        draw.line([(x, h - 20), (x + 8, h)], fill=(225, 185, 55, 240), width=3)
    draw.rectangle([0, 0, w, 8], fill=(245, 210, 80, 255))
    draw.rectangle([0, h - 8, w, h], fill=(245, 210, 80, 255))

    im = im.filter(ImageFilter.SMOOTH)
    im.save(os.path.join(TEXTURE_DIR, "glider_chinese_painting.png"))
    print("Saved glider_chinese_painting.png (1024x1024 Guofeng Shan Shui)")

# ========================================================
# 3D MESH GENERATION FOR CHINESE GLIDER WINGS
# ========================================================
class GliderMeshBuilder:
    def __init__(self):
        self.positions = []
        self.normals = []
        self.uvs = []
        self.indices = []

    def add_vertex(self, pos, norm, uv):
        idx = len(self.positions)
        self.positions.append(pos)
        self.normals.append(norm)
        self.uvs.append(uv)
        return idx

    def add_quad(self, i1, i2, i3, i4):
        self.indices.extend([i1, i2, i3, i1, i3, i4])

    def add_double_sided_quad(self, p1, p2, p3, p4, uv1, uv2, uv3, uv4):
        v1 = np.array(p2) - np.array(p1)
        v2 = np.array(p4) - np.array(p1)
        norm = np.cross(v1, v2)
        n_len = np.linalg.norm(norm)
        norm = tuple(norm / n_len) if n_len > 1e-6 else (0, 1, 0)
        norm_inv = (-norm[0], -norm[1], -norm[2])

        # Front face
        i1 = self.add_vertex(p1, norm, uv1)
        i2 = self.add_vertex(p2, norm, uv2)
        i3 = self.add_vertex(p3, norm, uv3)
        i4 = self.add_vertex(p4, norm, uv4)
        self.add_quad(i1, i2, i3, i4)

        # Back face
        j1 = self.add_vertex(p1, norm_inv, uv1)
        j2 = self.add_vertex(p2, norm_inv, uv2)
        j3 = self.add_vertex(p3, norm_inv, uv3)
        j4 = self.add_vertex(p4, norm_inv, uv4)
        self.add_quad(j1, j4, j3, j2)

    def add_box(self, center, size):
        cx, cy, cz = center
        sx, sy, sz = size[0]*0.5, size[1]*0.5, size[2]*0.5
        faces = [
            ([(cx-sx, cy-sy, cz+sz), (cx+sx, cy-sy, cz+sz), (cx+sx, cy+sy, cz+sz), (cx-sx, cy+sy, cz+sz)], (0, 0, 1)),
            ([(cx+sx, cy-sy, cz-sz), (cx-sx, cy-sy, cz-sz), (cx-sx, cy+sy, cz-sz), (cx+sx, cy+sy, cz-sz)], (0, 0, -1)),
            ([(cx-sx, cy+sy, cz+sz), (cx+sx, cy+sy, cz+sz), (cx+sx, cy+sy, cz-sz), (cx-sx, cy+sy, cz-sz)], (0, 1, 0)),
            ([(cx-sx, cy-sy, cz-sz), (cx+sx, cy-sy, cz-sz), (cx+sx, cy-sy, cz+sz), (cx-sx, cy-sy, cz+sz)], (0, -1, 0)),
            ([(cx+sx, cy-sy, cz+sz), (cx+sx, cy-sy, cz-sz), (cx+sx, cy+sy, cz-sz), (cx+sx, cy+sy, cz+sz)], (1, 0, 0)),
            ([(cx-sx, cy-sy, cz-sz), (cx-sx, cy-sy, cz+sz), (cx-sx, cy+sy, cz+sz), (cx-sx, cy+sy, cz-sz)], (-1, 0, 0)),
        ]
        for verts, norm in faces:
            uvs = [(0, 0), (1, 0), (1, 1), (0, 1)]
            idxs = [self.add_vertex(v, norm, uv) for v, uv in zip(verts, uvs)]
            self.add_quad(idxs[0], idxs[1], idxs[2], idxs[3])

    def add_cylinder(self, p1, p2, r1, r2, segs=10):
        bot_idx, top_idx = [], []
        for i in range(segs + 1):
            ang = 2.0 * math.pi * i / segs
            ca, sa = math.cos(ang), math.sin(ang)
            norm = (ca, 0.0, sa)
            vb = (p1[0] + ca*r1, p1[1], p1[2] + sa*r1)
            vt = (p2[0] + ca*r2, p2[1], p2[2] + sa*r2)
            bot_idx.append(self.add_vertex(vb, norm, (i/segs, 0)))
            top_idx.append(self.add_vertex(vt, norm, (i/segs, 1)))
        for i in range(segs):
            self.add_quad(bot_idx[i], bot_idx[i+1], top_idx[i+1], top_idx[i])

    def add_sphere(self, center, radius, rings=6, sectors=8):
        cx, cy, cz = center
        vert_matrix = []
        for r in range(rings + 1):
            theta = math.pi * r / rings
            row = []
            for s in range(sectors + 1):
                phi = 2.0 * math.pi * s / sectors
                nx = math.sin(theta) * math.cos(phi)
                ny = math.cos(theta)
                nz = math.sin(theta) * math.sin(phi)
                p = (cx + nx * radius, cy + ny * radius, cz + nz * radius)
                idx = self.add_vertex(p, (nx, ny, nz), (s / sectors, r / rings))
                row.append(idx)
            vert_matrix.append(row)
        for r in range(rings):
            for s in range(sectors):
                self.add_quad(vert_matrix[r][s], vert_matrix[r][s+1], vert_matrix[r+1][s+1], vert_matrix[r+1][s])

def generate_guofeng_glider_model():
    mb_wing = GliderMeshBuilder()
    mb_frame = GliderMeshBuilder()
    mb_gold = GliderMeshBuilder()
    mb_ribbon = GliderMeshBuilder()

    # Central golden medallion harness (attaches to heroine's back)
    mb_gold.add_cylinder((0, 0, -0.06), (0, 0, 0.06), 0.18, 0.18, segs=14)
    # Auspicious jade core in center
    mb_frame.add_cylinder((0, 0, 0.04), (0, 0, 0.08), 0.10, 0.10, segs=12)

    # 4 Sweeping Oriental Fan / Phoenix Feathers per wing (Left and Right)
    # Wing spread: ~3.2m total (±1.6m on X), trailing back on Z by ~0.8m
    feather_curves = [
        # (root_x, root_z, mid_x, mid_z, tip_x, tip_z, width_root, width_tip, u_center)
        (0.12, 0.0, 0.65, 0.22, 1.55, 0.55, 0.22, 0.06, 0.85),  # Primary top feather
        (0.10, 0.06, 0.58, 0.35, 1.35, 0.72, 0.24, 0.08, 0.75),  # Second feather
        (0.08, 0.10, 0.48, 0.45, 1.05, 0.82, 0.22, 0.07, 0.65),  # Third feather
        (0.06, 0.12, 0.35, 0.48, 0.70, 0.75, 0.18, 0.05, 0.58),  # Under feather
    ]

    for is_right in [True, False]:
        sign = 1.0 if is_right else -1.0
        u_flip = 1.0 if is_right else 0.0

        for rx, rz, mx, mz, tx, tz, wr, wt, uc in feather_curves:
            # Curve points
            p_root_l = (sign * rx, 0.02, rz - wr*0.5)
            p_root_r = (sign * rx, 0.02, rz + wr*0.5)
            p_mid_l  = (sign * mx, 0.08, mz - wr*0.35)
            p_mid_r  = (sign * mx, 0.08, mz + wr*0.35)
            p_tip    = (sign * tx, 0.15, tz)

            # Texture mapping coordinates
            u_base = uc if is_right else (1.0 - uc)
            u_tip  = (uc + 0.12) if is_right else (1.0 - uc - 0.12)

            # Segment 1 (Root to Mid)
            mb_wing.add_double_sided_quad(
                p_root_l, p_root_r, p_mid_r, p_mid_l,
                (u_base - 0.06, 0.2), (u_base + 0.06, 0.2),
                (u_base + 0.08, 0.6), (u_base - 0.08, 0.6)
            )
            # Segment 2 (Mid to Tip triangle/quad)
            mb_wing.add_double_sided_quad(
                p_mid_l, p_mid_r, p_tip, p_tip,
                (u_base - 0.08, 0.6), (u_base + 0.08, 0.6),
                (u_tip, 1.0), (u_tip, 1.0)
            )

            # Gold filigree bone spar along feather spine
            mb_gold.add_cylinder((sign*rx, 0.03, rz), (sign*mx, 0.09, mz), 0.025, 0.018, segs=6)
            mb_gold.add_cylinder((sign*mx, 0.09, mz), (sign*tx, 0.16, tz), 0.018, 0.008, segs=6)
            # Phoenix claw tip ornament
            mb_gold.add_box((sign*tx, 0.16, tz), (0.04, 0.04, 0.08))

        # Flowing Crimson Silk Ribbons (Piao Dai 飘带) trailing behind in the wind
        ribbon_pts = [
            (sign * 0.18, -0.05, 0.15),
            (sign * 0.26, -0.25, 0.45),
            (sign * 0.32, -0.50, 0.75),
            (sign * 0.38, -0.75, 1.10),
            (sign * 0.42, -0.98, 1.45),
        ]
        for i in range(len(ribbon_pts) - 1):
            p1 = ribbon_pts[i]
            p2 = ribbon_pts[i+1]
            rw = 0.09 * (1.0 - i * 0.15)
            # Ribbon quad
            r1_l = (p1[0] - rw*0.5, p1[1], p1[2])
            r1_r = (p1[0] + rw*0.5, p1[1], p1[2])
            r2_l = (p2[0] - rw*0.5, p2[1], p2[2])
            r2_r = (p2[0] + rw*0.5, p2[1], p2[2])
            mb_ribbon.add_double_sided_quad(
                r1_l, r1_r, r2_r, r2_l,
                (0.45, i*0.2), (0.55, i*0.2), (0.55, (i+1)*0.2), (0.45, (i+1)*0.2)
            )
        # Gold bell on ribbon tip
        tip_pos = ribbon_pts[-1]
        mb_gold.add_sphere(tip_pos, 0.03, rings=4, sectors=6)

    # GLB binary packaging
    bin_data = bytearray()
    buffer_views, accessors, images, textures, materials, primitives = [], [], [], [], [], []

    def add_buffer(data_bytes, target=None):
        offset = len(bin_data)
        pad = (4 - (offset % 4)) % 4
        if pad: bin_data.extend(b'\x00' * pad); offset += pad
        bin_data.extend(data_bytes)
        bv = {"buffer": 0, "byteOffset": offset, "byteLength": len(data_bytes)}
        if target: bv["target"] = target
        bv_idx = len(buffer_views)
        buffer_views.append(bv)
        return bv_idx

    # Load glider texture
    tex_path = os.path.join(TEXTURE_DIR, "glider_chinese_painting.png")
    with open(tex_path, 'rb') as f:
        png_bytes = f.read()
    bv_tex = add_buffer(png_bytes)
    images.append({"bufferView": bv_tex, "mimeType": "image/png"})
    textures.append({"source": 0})

    materials = [
        # Mat 0: Silk Wing Surface with Guofeng painting
        {"name": "Mat_GuofengSilkWing", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "roughnessFactor": 0.4, "metallicFactor": 0.1}},
        # Mat 1: Dark Jade Core
        {"name": "Mat_JadeCore", "pbrMetallicRoughness": {"baseColorFactor": [0.12, 0.45, 0.35, 1.0], "roughnessFactor": 0.25}},
        # Mat 2: Imperial Gold Filigree
        {"name": "Mat_GoldFiligree", "pbrMetallicRoughness": {"baseColorFactor": [0.98, 0.85, 0.28, 1.0], "metallicFactor": 0.9, "roughnessFactor": 0.2}},
        # Mat 3: Crimson Silk Ribbon
        {"name": "Mat_CrimsonSilkRibbon", "pbrMetallicRoughness": {"baseColorFactor": [0.85, 0.15, 0.12, 0.95], "roughnessFactor": 0.45}},
    ]

    submeshes = [
        (mb_wing, 0),
        (mb_frame, 1),
        (mb_gold, 2),
        (mb_ribbon, 3),
    ]

    for mb, mat_idx in submeshes:
        if len(mb.positions) == 0: continue
        pos = np.array(mb.positions, dtype=np.float32)
        norm = np.array(mb.normals, dtype=np.float32)
        uv = np.array(mb.uvs, dtype=np.float32)
        idx = np.array(mb.indices, dtype=np.uint32).flatten()

        idx_bv = add_buffer(idx.tobytes(), 34963)
        idx_acc = len(accessors)
        accessors.append({"bufferView": idx_bv, "byteOffset": 0, "componentType": 5125, "count": len(idx), "type": "SCALAR"})

        pos_bv = add_buffer(pos.tobytes(), 34962)
        pos_acc = len(accessors)
        accessors.append({"bufferView": pos_bv, "byteOffset": 0, "componentType": 5126, "count": len(pos), "type": "VEC3", "min": pos.min(axis=0).tolist(), "max": pos.max(axis=0).tolist()})

        norm_bv = add_buffer(norm.tobytes(), 34962)
        norm_acc = len(accessors)
        accessors.append({"bufferView": norm_bv, "byteOffset": 0, "componentType": 5126, "count": len(norm), "type": "VEC3"})

        uv_bv = add_buffer(uv.tobytes(), 34962)
        uv_acc = len(accessors)
        accessors.append({"bufferView": uv_bv, "byteOffset": 0, "componentType": 5126, "count": len(uv), "type": "VEC2"})

        primitives.append({
            "attributes": {"POSITION": pos_acc, "NORMAL": norm_acc, "TEXCOORD_0": uv_acc},
            "indices": idx_acc,
            "material": mat_idx,
            "mode": 4
        })

    pad = (4 - (len(bin_data) % 4)) % 4
    if pad: bin_data.extend(b'\x00' * pad)

    gltf_json = {
        "asset": {"version": "2.0", "generator": "ChineseGuofengGliderGenerator"},
        "scene": 0, "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "GliderWingsRoot"}],
        "meshes": [{"primitives": primitives, "name": "GliderWingsMesh"}],
        "buffers": [{"byteLength": len(bin_data)}],
        "bufferViews": buffer_views,
        "accessors": accessors,
        "materials": materials,
        "images": images,
        "textures": textures
    }

    json_str = json.dumps(gltf_json).encode('utf-8')
    pad = (4 - (len(json_str) % 4)) % 4
    if pad: json_str += b' ' * pad

    total_len = 12 + 8 + len(json_str) + 8 + len(bin_data)
    header = struct.pack('<4sII', b'glTF', 2, total_len)
    json_chunk = struct.pack('<I4s', len(json_str), b'JSON') + json_str
    bin_chunk = struct.pack('<I4s', len(bin_data), b'BIN\x00') + bin_data

    out_file = os.path.join(OUTPUT_DIR, "glider_wings.glb")
    with open(out_file, 'wb') as f:
        f.write(header + json_chunk + bin_chunk)
    print(f"Exported Guofeng Glider: {out_file} ({total_len} bytes)")

def main():
    generate_guofeng_glider_texture()
    generate_guofeng_glider_model()

if __name__ == '__main__':
    main()
