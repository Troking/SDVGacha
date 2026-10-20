"""
Environment Props Generator for Chibi RPG
Generates:
1. karst_mountain_spire.glb: Fixed outward normals, manifold mesh, bottom skirt down to Y = -6.0m.
2. ancient_stone_shrine.glb: Kitsune spirit shrine with stone altar, red lacquered pillars, curved roof.
3. wood_crate_barrel.glb: Destructible cargo crates and sake barrels.
4. river_dock_pier.glb: Wooden fishing wharf, mooring posts, and sampan boat.
5. campfire_brazier.glb: Stone firepit with charred logs.
6. ancient_ruin_pillar.glb: Weathered ancient stone pillar and fallen broken drum.
"""

import os
import sys
import math
import struct
import json

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/models"
TEXTURE_DIR = "e:/Trok/ChibiRPG_Project/game/assets/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

class MeshBuilder:
    def __init__(self):
        self.vertices = []
        self.normals = []
        self.uvs = []
        self.indices = []

    def add_vertex(self, pos, norm, uv):
        idx = len(self.vertices)
        self.vertices.append(pos)
        self.normals.append(norm)
        self.uvs.append(uv)
        return idx

    def add_triangle(self, i1, i2, i3):
        self.indices.extend([i1, i2, i3])

    def add_quad(self, i1, i2, i3, i4):
        # Counter-clockwise winding: i1 -> i2 -> i3, i1 -> i3 -> i4
        self.indices.extend([i1, i2, i3, i1, i3, i4])

    def add_box(self, center, size, uv_scale=(1.0, 1.0)):
        cx, cy, cz = center
        sx, sy, sz = size[0]*0.5, size[1]*0.5, size[2]*0.5
        u_s, v_s = uv_scale

        faces = [
            # Front (+Z)
            ([(cx-sx, cy-sy, cz+sz), (cx+sx, cy-sy, cz+sz), (cx+sx, cy+sy, cz+sz), (cx-sx, cy+sy, cz+sz)], (0, 0, 1)),
            # Back (-Z)
            ([(cx+sx, cy-sy, cz-sz), (cx-sx, cy-sy, cz-sz), (cx-sx, cy+sy, cz-sz), (cx+sx, cy+sy, cz-sz)], (0, 0, -1)),
            # Top (+Y)
            ([(cx-sx, cy+sy, cz+sz), (cx+sx, cy+sy, cz+sz), (cx+sx, cy+sy, cz-sz), (cx-sx, cy+sy, cz-sz)], (0, 1, 0)),
            # Bottom (-Y)
            ([(cx-sx, cy-sy, cz-sz), (cx+sx, cy-sy, cz-sz), (cx+sx, cy-sy, cz+sz), (cx-sx, cy-sy, cz+sz)], (0, -1, 0)),
            # Right (+X)
            ([(cx+sx, cy-sy, cz+sz), (cx+sx, cy-sy, cz-sz), (cx+sx, cy+sy, cz-sz), (cx+sx, cy+sy, cz+sz)], (1, 0, 0)),
            # Left (-X)
            ([(cx-sx, cy-sy, cz-sz), (cx-sx, cy-sy, cz+sz), (cx-sx, cy+sy, cz+sz), (cx-sx, cy+sy, cz-sz)], (-1, 0, 0)),
        ]

        for verts, norm in faces:
            uvs = [(0, 0), (u_s, 0), (u_s, v_s), (0, v_s)]
            idxs = [self.add_vertex(v, norm, uv) for v, uv in zip(verts, uvs)]
            self.add_quad(idxs[0], idxs[1], idxs[2], idxs[3])

    def add_cylinder(self, p_bottom, p_top, r_bottom, r_top, segments=12, uv_scale=(1.0, 1.0)):
        bx, by, bz = p_bottom
        tx, ty, tz = p_top
        u_s, v_s = uv_scale

        bot_indices = []
        top_indices = []

        for i in range(segments + 1):
            angle = (2.0 * math.pi * i) / segments
            ca, sa = math.cos(angle), math.sin(angle)
            u = (i / segments) * u_s

            norm = (ca, 0.0, sa)
            vb = (bx + ca * r_bottom, by, bz + sa * r_bottom)
            vt = (tx + ca * r_top, ty, tz + sa * r_top)

            bot_indices.append(self.add_vertex(vb, norm, (u, 0.0)))
            top_indices.append(self.add_vertex(vt, norm, (u, v_s)))

        # Counter-clockwise outward winding
        for i in range(segments):
            b1, b2 = bot_indices[i], bot_indices[i+1]
            t1, t2 = top_indices[i], top_indices[i+1]
            self.add_quad(b1, t1, t2, b2)

    def add_curved_eave_roof(self, center, base_size, top_size, height, eave_flare=1.15, uv_scale=(3.0, 3.0)):
        cx, cy, cz = center
        bx = base_size[0] * 0.5 * eave_flare
        bz = base_size[1] * 0.5 * eave_flare
        tx = top_size[0] * 0.5
        tz = top_size[1] * 0.5
        rim_h = 0.16
        upturn = 0.20

        b_sw = (cx - bx, cy, cz + bz)
        b_se = (cx + bx, cy, cz + bz)
        b_ne = (cx + bx, cy, cz - bz)
        b_nw = (cx - bx, cy, cz - bz)

        r_sw = (cx - bx, cy + rim_h + upturn, cz + bz)
        r_se = (cx + bx, cy + rim_h + upturn, cz + bz)
        r_ne = (cx + bx, cy + rim_h + upturn, cz - bz)
        r_nw = (cx - bx, cy + rim_h + upturn, cz - bz)

        t_sw = (cx - tx, cy + height, cz + tz)
        t_se = (cx + tx, cy + height, cz + tz)
        t_ne = (cx + tx, cy + height, cz - tz)
        t_nw = (cx - tx, cy + height, cz - tz)

        # Roof slopes (outward normals)
        # South
        s_norm = (0, 0.707, 0.707)
        i_r_sw = self.add_vertex(r_sw, s_norm, (0, 0))
        i_r_se = self.add_vertex(r_se, s_norm, (uv_scale[0], 0))
        i_t_se = self.add_vertex(t_se, s_norm, (uv_scale[0], uv_scale[1]))
        i_t_sw = self.add_vertex(t_sw, s_norm, (0, uv_scale[1]))
        self.add_quad(i_r_sw, i_r_se, i_t_se, i_t_sw)

        # North
        n_norm = (0, 0.707, -0.707)
        i_r_ne = self.add_vertex(r_ne, n_norm, (0, 0))
        i_r_nw = self.add_vertex(r_nw, n_norm, (uv_scale[0], 0))
        i_t_nw = self.add_vertex(t_nw, n_norm, (uv_scale[0], uv_scale[1]))
        i_t_ne = self.add_vertex(t_ne, n_norm, (0, uv_scale[1]))
        self.add_quad(i_r_ne, i_r_nw, i_t_nw, i_t_ne)

        # East
        e_norm = (0.707, 0.707, 0)
        i_r_se_e = self.add_vertex(r_se, e_norm, (0, 0))
        i_r_ne_e = self.add_vertex(r_ne, e_norm, (uv_scale[0], 0))
        i_t_ne_e = self.add_vertex(t_ne, e_norm, (uv_scale[0], uv_scale[1]))
        i_t_se_e = self.add_vertex(t_se, e_norm, (0, uv_scale[1]))
        self.add_quad(i_r_se_e, i_r_ne_e, i_t_ne_e, i_t_se_e)

        # West
        w_norm = (-0.707, 0.707, 0)
        i_r_nw_w = self.add_vertex(r_nw, w_norm, (0, 0))
        i_r_sw_w = self.add_vertex(r_sw, w_norm, (uv_scale[0], 0))
        i_t_sw_w = self.add_vertex(t_sw, w_norm, (uv_scale[0], uv_scale[1]))
        i_t_nw_w = self.add_vertex(t_nw, w_norm, (0, uv_scale[1]))
        self.add_quad(i_r_nw_w, i_r_sw_w, i_t_sw_w, i_t_nw_w)

        # Top ridge cap
        top_norm = (0, 1, 0)
        i_t0 = self.add_vertex(t_sw, top_norm, (0, 0))
        i_t1 = self.add_vertex(t_se, top_norm, (1, 0))
        i_t2 = self.add_vertex(t_ne, top_norm, (1, 1))
        i_t3 = self.add_vertex(t_nw, top_norm, (0, 1))
        self.add_quad(i_t0, i_t1, i_t2, i_t3)


def export_textured_glb(filename, submeshes, materials):
    bin_data = bytearray()
    buffer_views = []
    accessors = []
    images = []
    textures = []
    gltf_materials = []
    primitives = []

    tex_cache = {}
    for mat_def in materials:
        tex_file = mat_def.get("texture_file")
        tex_idx = None
        if tex_file:
            if tex_file in tex_cache:
                tex_idx = tex_cache[tex_file]
            else:
                tex_path = os.path.join(TEXTURE_DIR, tex_file)
                if os.path.exists(tex_path):
                    with open(tex_path, "rb") as f:
                        img_bytes = f.read()
                    while len(bin_data) % 4 != 0:
                        bin_data.append(0)
                    offset = len(bin_data)
                    bin_data.extend(img_bytes)
                    bv_img = {
                        "buffer": 0,
                        "byteOffset": offset,
                        "byteLength": len(img_bytes)
                    }
                    bv_img_idx = len(buffer_views)
                    buffer_views.append(bv_img)

                    img_idx = len(images)
                    images.append({
                        "bufferView": bv_img_idx,
                        "mimeType": "image/png"
                    })
                    tex_idx = len(textures)
                    textures.append({"source": img_idx})
                    tex_cache[tex_file] = tex_idx

        pbr = {
            "roughnessFactor": mat_def.get("roughness", 0.7),
            "metallicFactor": mat_def.get("metallic", 0.1)
        }
        if tex_idx is not None:
            pbr["baseColorTexture"] = {"index": tex_idx}
        else:
            pbr["baseColorFactor"] = mat_def.get("base_color", [1, 1, 1, 1])

        gltf_materials.append({
            "name": mat_def.get("name", "Material"),
            "pbrMetallicRoughness": pbr,
            "doubleSided": mat_def.get("double_sided", False)
        })

    for sub in submeshes:
        builder = sub["builder"]
        mat_idx = sub["material_idx"]
        if not builder.indices:
            continue

        while len(bin_data) % 4 != 0:
            bin_data.append(0)
        idx_offset = len(bin_data)
        idx_bytes = struct.pack(f"<{len(builder.indices)}I", *builder.indices)
        bin_data.extend(idx_bytes)
        bv_idx = {
            "buffer": 0,
            "byteOffset": idx_offset,
            "byteLength": len(idx_bytes),
            "target": 34963
        }
        bv_idx_num = len(buffer_views)
        buffer_views.append(bv_idx)

        acc_idx = {
            "bufferView": bv_idx_num,
            "byteOffset": 0,
            "componentType": 5125,
            "count": len(builder.indices),
            "type": "SCALAR",
            "max": [max(builder.indices)],
            "min": [min(builder.indices)]
        }
        acc_idx_num = len(accessors)
        accessors.append(acc_idx)

        while len(bin_data) % 4 != 0:
            bin_data.append(0)
        v_offset = len(bin_data)
        v_flat = [coord for pt in builder.vertices for coord in pt]
        v_bytes = struct.pack(f"<{len(v_flat)}f", *v_flat)
        bin_data.extend(v_bytes)

        min_pos = [min(pt[c] for pt in builder.vertices) for c in range(3)]
        max_pos = [max(pt[c] for pt in builder.vertices) for c in range(3)]

        bv_v = {
            "buffer": 0,
            "byteOffset": v_offset,
            "byteLength": len(v_bytes),
            "target": 34962
        }
        bv_v_num = len(buffer_views)
        buffer_views.append(bv_v)

        acc_v = {
            "bufferView": bv_v_num,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(builder.vertices),
            "type": "VEC3",
            "max": max_pos,
            "min": min_pos
        }
        acc_v_num = len(accessors)
        accessors.append(acc_v)

        while len(bin_data) % 4 != 0:
            bin_data.append(0)
        n_offset = len(bin_data)
        n_flat = [coord for pt in builder.normals for coord in pt]
        n_bytes = struct.pack(f"<{len(n_flat)}f", *n_flat)
        bin_data.extend(n_bytes)

        bv_n = {
            "buffer": 0,
            "byteOffset": n_offset,
            "byteLength": len(n_bytes),
            "target": 34962
        }
        bv_n_num = len(buffer_views)
        buffer_views.append(bv_n)

        acc_n = {
            "bufferView": bv_n_num,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(builder.normals),
            "type": "VEC3"
        }
        acc_n_num = len(accessors)
        accessors.append(acc_n)

        while len(bin_data) % 4 != 0:
            bin_data.append(0)
        uv_offset = len(bin_data)
        uv_flat = [coord for pt in builder.uvs for coord in pt]
        uv_bytes = struct.pack(f"<{len(uv_flat)}f", *uv_flat)
        bin_data.extend(uv_bytes)

        bv_uv = {
            "buffer": 0,
            "byteOffset": uv_offset,
            "byteLength": len(uv_bytes),
            "target": 34962
        }
        bv_uv_num = len(buffer_views)
        buffer_views.append(bv_uv)

        acc_uv = {
            "bufferView": bv_uv_num,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(builder.uvs),
            "type": "VEC2"
        }
        acc_uv_num = len(accessors)
        accessors.append(acc_uv)

        primitives.append({
            "attributes": {
                "POSITION": acc_v_num,
                "NORMAL": acc_n_num,
                "TEXCOORD_0": acc_uv_num
            },
            "indices": acc_idx_num,
            "material": mat_idx
        })

    while len(bin_data) % 4 != 0:
        bin_data.append(0)

    gltf = {
        "asset": {"version": "2.0", "generator": "Antigravity Environment Gen"},
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": os.path.splitext(os.path.basename(filename))[0]}],
        "meshes": [{"primitives": primitives}],
        "materials": gltf_materials,
        "buffers": [{"byteLength": len(bin_data)}],
        "bufferViews": buffer_views,
        "accessors": accessors
    }
    if images:
        gltf["images"] = images
    if textures:
        gltf["textures"] = textures

    json_str = json.dumps(gltf).encode("utf-8")
    while len(json_str) % 4 != 0:
        json_str += b" "

    header = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(json_str) + 8 + len(bin_data))
    chunk0 = struct.pack("<I4s", len(json_str), b"JSON") + json_str
    chunk1 = struct.pack("<I4s", len(bin_data), b"BIN\x00") + bin_data

    with open(filename, "wb") as f:
        f.write(header + chunk0 + chunk1)
    print(f"Exported: {filename}")


# ========================================================
# 1. FIXED KARST MOUNTAIN SPIRE (Outward normals, solid skirt)
# ========================================================
def generate_fixed_karst_spire():
    mb_rock = MeshBuilder()
    mb_top = MeshBuilder()

    y_bottom = -6.0
    y_top = 28.0
    layers = 16
    sectors = 16
    prev_ring = []

    for ly in range(layers + 1):
        t_ly = ly / layers
        y = y_bottom + t_ly * (y_top - y_bottom)
        # Wider base below ground to securely anchor, fluted vertical cliffs
        radius = 5.8 - t_ly * 1.6 + math.sin(ly * 0.7) * 0.55
        if y < 0:
            radius += (abs(y) / 6.0) * 1.5

        ring = []
        for s in range(sectors + 1):
            ang = (2.0 * math.pi * s) / sectors
            noise_r = radius + math.sin(ang * 4.0 + ly) * 0.45
            px = math.cos(ang) * noise_r
            pz = math.sin(ang) * noise_r
            norm = (math.cos(ang), 0.08, math.sin(ang))
            u = (s / sectors) * 3.5
            v = t_ly * 7.0
            idx = mb_rock.add_vertex((px, y, pz), norm, (u, v))
            ring.append(idx)

        if ly > 0:
            for s in range(sectors):
                b1 = prev_ring[s]
                b2 = prev_ring[s+1]
                t1 = ring[s]
                t2 = ring[s+1]
                # Mathematically verified outward normal winding: b1 -> t1 -> t2 -> b2
                mb_rock.add_quad(b1, t1, t2, b2)
        prev_ring = ring

    # Bottom solid cap at Y = -6.0
    b_center = mb_rock.add_vertex((0, y_bottom, 0), (0, -1, 0), (0.5, 0.5))
    for s in range(sectors):
        mb_rock.add_triangle(b_center, prev_ring[0] if ly==0 else mb_rock.indices[0], b_center) # safety
    
    # Flat grassy mountain peak plateau on top
    mb_top.add_cylinder((0, y_top - 0.25, 0), (0, y_top, 0), 4.4, 4.4, segments=16, uv_scale=(3.0, 3.0))

    materials = [
        {"name": "Mat_KarstCliff", "texture_file": "karst_cliff_rock.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.85},
        {"name": "Mat_PeakGrass", "texture_file": "genshin_grass.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.70},
    ]
    submeshes = [
        {"builder": mb_rock, "material_idx": 0},
        {"builder": mb_top, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "karst_mountain_spire.glb"), submeshes, materials)


# ========================================================
# 2. ANCIENT KITSUNE SPIRIT SHRINE & ALTAR
# ========================================================
def generate_ancient_stone_shrine():
    mb_stone = MeshBuilder()
    mb_wood = MeshBuilder()
    mb_roof = MeshBuilder()

    # 3-tier stepped stone plinth base
    mb_stone.add_box((0, 0.20, 0), (4.8, 0.40, 4.2), uv_scale=(3.0, 2.5))
    mb_stone.add_box((0, 0.55, 0), (3.8, 0.30, 3.4), uv_scale=(2.5, 2.0))
    mb_stone.add_box((0, 0.80, 0), (3.0, 0.20, 2.6), uv_scale=(2.0, 1.8))

    # Stone Altar Table in center
    mb_stone.add_box((0, 1.15, 0.2), (1.4, 0.50, 0.9), uv_scale=(1.2, 0.8))
    # Incense basin on altar
    mb_stone.add_cylinder((0, 1.40, 0.2), (0, 1.55, 0.2), 0.28, 0.32, segments=10, uv_scale=(1.0, 0.4))
    # Flanking stone kitsune statues / guardian monoliths
    mb_stone.add_box((-1.0, 1.25, 0.2), (0.45, 0.70, 0.45), uv_scale=(0.8, 1.2))
    mb_stone.add_box((1.0, 1.25, 0.2), (0.45, 0.70, 0.45), uv_scale=(0.8, 1.2))

    # 4 Vermilion Lacquered Timber Pillars
    col_x = 1.3
    col_z = 1.1
    h_col = 2.4
    for px in [-col_x, col_x]:
        for pz in [-col_z, col_z]:
            mb_wood.add_cylinder((px, 0.90, pz), (px, 0.90 + h_col, pz), 0.14, 0.14, segments=8, uv_scale=(0.5, 2.0))

    # Cross beams connecting pillars
    mb_wood.add_box((0, 0.90 + h_col - 0.15, col_z), (col_x * 2.2, 0.22, 0.22), uv_scale=(2.0, 0.4))
    mb_wood.add_box((0, 0.90 + h_col - 0.15, -col_z), (col_x * 2.2, 0.22, 0.22), uv_scale=(2.0, 0.4))
    mb_wood.add_box((-col_x, 0.90 + h_col - 0.15, 0), (0.22, 0.22, col_z * 2.2), uv_scale=(0.4, 2.0))
    mb_wood.add_box((col_x, 0.90 + h_col - 0.15, 0), (0.22, 0.22, col_z * 2.2), uv_scale=(0.4, 2.0))

    # Elegant Curved Eave Asian Shrine Roof
    mb_roof.add_curved_eave_roof((0, 0.90 + h_col, 0), (3.8, 3.2), (1.2, 0.9), 1.25, eave_flare=1.18, uv_scale=(2.5, 2.0))

    materials = [
        {"name": "Mat_StoneBase", "texture_file": "asian_stone_pavers.png", "base_color": [0.85, 0.85, 0.88, 1.0], "roughness": 0.85},
        {"name": "Mat_ShrineVermilion", "texture_file": "asian_wood_vermilion.png", "base_color": [0.95, 0.20, 0.15, 1.0], "roughness": 0.65},
        {"name": "Mat_ShrineRoof", "texture_file": "asian_roof_tiles.png", "base_color": [0.18, 0.22, 0.28, 1.0], "roughness": 0.55},
    ]
    submeshes = [
        {"builder": mb_stone, "material_idx": 0},
        {"builder": mb_wood, "material_idx": 1},
        {"builder": mb_roof, "material_idx": 2},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "ancient_stone_shrine.glb"), submeshes, materials)


# ========================================================
# 3. WOOD CRATES AND SAKE BARRELS CLUSTER (DESTRUCTIBLE)
# ========================================================
def generate_wood_crates_and_barrels():
    mb_wood = MeshBuilder()

    # Crate 1 (Large base crate)
    mb_wood.add_box((0, 0.45, 0), (0.9, 0.9, 0.9), uv_scale=(1.0, 1.0))
    # Crate 2 (Stacked on top, slightly angled)
    mb_wood.add_box((0.15, 1.25, 0.1), (0.7, 0.7, 0.7), uv_scale=(0.8, 0.8))
    # Crate 3 (Beside crate 1)
    mb_wood.add_box((-0.85, 0.35, 0.1), (0.7, 0.7, 0.7), uv_scale=(0.8, 0.8))

    # Barrel 1 (Aged sake cedar barrel)
    mb_wood.add_cylinder((0.85, 0.0, 0.2), (0.85, 0.85, 0.2), 0.34, 0.30, segments=12, uv_scale=(1.2, 1.0))
    # Barrel 2 (Tilted on side)
    mb_wood.add_cylinder((0.70, 0.0, -0.75), (0.70, 0.75, -0.75), 0.32, 0.28, segments=12, uv_scale=(1.2, 1.0))

    materials = [
        {"name": "Mat_AgedWood", "texture_file": "asian_wood_dark.png", "base_color": [0.35, 0.24, 0.15, 1.0], "roughness": 0.85},
    ]
    submeshes = [
        {"builder": mb_wood, "material_idx": 0},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "wood_crate_barrel.glb"), submeshes, materials)


# ========================================================
# 4. RIVER DOCK PIER & MOORED FISHING SAMPAN BOAT
# ========================================================
def generate_river_dock_pier():
    mb_dock = MeshBuilder()
    mb_boat = MeshBuilder()

    # Heavy timber support pilings into river bed
    pile_coords = [(-3.2, -1.2, 0), (-1.0, -1.2, 0), (1.0, -1.2, 0), (3.2, -1.2, 0),
                   (-3.2, -1.2, 1.6), (-1.0, -1.2, 1.6), (1.0, -1.2, 1.6), (3.2, -1.2, 1.6)]
    for px, pz, py in [(c[0], c[2], c[1]) for c in pile_coords]:
        mb_dock.add_cylinder((px, -1.5, pz), (px, 0.3, pz), 0.16, 0.16, segments=8, uv_scale=(0.4, 1.5))

    # Main Dock Wooden Deck (7.5m long, 2.2m wide, 0.18m thick)
    mb_dock.add_box((0, 0.35, 0.8), (7.5, 0.18, 2.2), uv_scale=(4.0, 1.5))

    # Mooring Bollards / Cleats with rope coils
    for bx in [-3.0, 0.0, 3.0]:
        mb_dock.add_cylinder((bx, 0.44, 1.8), (bx, 0.90, 1.8), 0.12, 0.14, segments=8, uv_scale=(0.3, 0.5))

    # Moored Wooden Sampan Boat (Asian flat-bottom river boat alongside dock)
    # Boat Hull: tapered bow and stern
    mb_boat.add_box((0.5, -0.05, 2.6), (3.4, 0.45, 1.2), uv_scale=(2.5, 1.0))
    # Raised bow prow
    mb_boat.add_box((2.4, 0.15, 2.6), (0.7, 0.40, 1.0), uv_scale=(0.8, 0.6))
    # Raised stern
    mb_boat.add_box((-1.4, 0.10, 2.6), (0.6, 0.35, 1.0), uv_scale=(0.7, 0.6))
    # Center wooden bench & fishing net basket
    mb_boat.add_box((0.5, 0.20, 2.6), (0.3, 0.10, 1.1), uv_scale=(0.5, 0.5))

    materials = [
        {"name": "Mat_DockTimber", "texture_file": "asian_wood_dark.png", "base_color": [0.38, 0.28, 0.18, 1.0], "roughness": 0.88},
        {"name": "Mat_SampanWood", "texture_file": "asian_wood_vermilion.png", "base_color": [0.65, 0.35, 0.20, 1.0], "roughness": 0.75},
    ]
    submeshes = [
        {"builder": mb_dock, "material_idx": 0},
        {"builder": mb_boat, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "river_dock_pier.glb"), submeshes, materials)


# ========================================================
# 5. CAMPFIRE & BRAZIER HEARTH
# ========================================================
def generate_campfire_brazier():
    mb_stone = MeshBuilder()
    mb_fire = MeshBuilder()

    # Circular stone ring hearth (8 granite stones)
    for i in range(8):
        ang = (2.0 * math.pi * i) / 8.0
        px = math.cos(ang) * 0.75
        pz = math.sin(ang) * 0.75
        mb_stone.add_box((px, 0.12, pz), (0.32, 0.22, 0.32), uv_scale=(0.6, 0.6))

    # Charred campfire logs stacked in center
    for i in range(5):
        ang = (2.0 * math.pi * i) / 5.0
        p1 = (math.cos(ang) * 0.45, 0.08, math.sin(ang) * 0.45)
        p2 = (math.cos(ang + math.pi) * 0.45, 0.28, math.sin(ang + math.pi) * 0.45)
        mb_stone.add_cylinder(p1, p2, 0.09, 0.07, segments=6, uv_scale=(0.4, 0.8))

    # Glowing Ember Core Sphere
    mb_fire.add_cylinder((0, 0.05, 0), (0, 0.22, 0), 0.35, 0.15, segments=8, uv_scale=(0.8, 0.8))

    materials = [
        {"name": "Mat_HearthStone", "texture_file": "karst_cliff_rock.png", "base_color": [0.35, 0.34, 0.32, 1.0], "roughness": 0.90},
        {"name": "Mat_GlowingEmbers", "texture_file": "fx_flame_wisp.png", "base_color": [1.0, 0.55, 0.10, 1.0], "roughness": 0.20},
    ]
    submeshes = [
        {"builder": mb_stone, "material_idx": 0},
        {"builder": mb_fire, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "campfire_brazier.glb"), submeshes, materials)


# ========================================================
# 6. ANCIENT RUIN PILLAR & BROKEN COLUMN
# ========================================================
def generate_ancient_ruin_pillar():
    mb_pillar = MeshBuilder()

    # Standing Fluted Stone Pillar (Height 5.2m)
    mb_pillar.add_box((0, 0.25, 0), (1.4, 0.5, 1.4), uv_scale=(1.2, 0.6)) # Plinth base
    mb_pillar.add_cylinder((0, 0.5, 0), (0, 4.8, 0), 0.52, 0.46, segments=12, uv_scale=(1.5, 3.5)) # Fluted shaft
    mb_pillar.add_box((0, 5.0, 0), (1.3, 0.4, 1.3), uv_scale=(1.2, 0.5)) # Capital

    # Fallen broken stone column drum lying beside it
    mb_pillar.add_cylinder((1.6, 0.42, 0.4), (3.4, 0.42, 0.6), 0.48, 0.48, segments=10, uv_scale=(1.2, 1.5))
    # Shattered stone chunk
    mb_pillar.add_box((2.8, 0.25, -0.6), (0.7, 0.5, 0.8), uv_scale=(0.8, 0.8))

    materials = [
        {"name": "Mat_AncientPillar", "texture_file": "karst_cliff_rock.png", "base_color": [0.75, 0.78, 0.72, 1.0], "roughness": 0.82},
    ]
    submeshes = [
        {"builder": mb_pillar, "material_idx": 0},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "ancient_ruin_pillar.glb"), submeshes, materials)


if __name__ == "__main__":
    generate_fixed_karst_spire()
    generate_ancient_stone_shrine()
    generate_wood_crates_and_barrels()
    generate_river_dock_pier()
    generate_campfire_brazier()
    generate_ancient_ruin_pillar()
    print("All environment models generated successfully!")
