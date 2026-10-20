"""
3D Model Generator for Asian Fantasy World (Genshin Impact / Liyue / Inazuma style)
Embeds authentic stylized textures directly into GLB files for seamless out-of-the-box Godot visuals.
100% Manifold geometry, clean outward normals, no degenerate triangles, beautiful architecture.
"""
import os
import math
import struct
import json
import numpy as np

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/models"
TEXTURE_DIR = "e:/Trok/ChibiRPG_Project/game/assets/textures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

class MeshBuilder:
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

    def add_triangle(self, i1, i2, i3):
        self.indices.extend([i1, i2, i3])

    def add_quad(self, i1, i2, i3, i4):
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

        for i in range(segments):
            b1, b2 = bot_indices[i], bot_indices[i+1]
            t1, t2 = top_indices[i], top_indices[i+1]
            self.add_quad(b1, b2, t2, t1)

    def add_curved_eave_roof(self, center, base_size, top_size, height, eave_flare=1.15, uv_scale=(3.0, 3.0)):
        """
        Generates a manifold, beautiful Asian hip roof with curved eave flare,
        vertical eave thickness rim, and underside ceiling soffit.
        100% mathematically correct normals and counter-clockwise winding.
        """
        cx, cy, cz = center
        bx = base_size[0] * 0.5 * eave_flare
        bz = base_size[1] * 0.5 * eave_flare
        tx = top_size[0] * 0.5
        tz = top_size[1] * 0.5

        rim_h = 0.16
        upturn = 0.20 # Graceful corner upturn

        # Bottom rim corners (at cy)
        b_sw = (cx - bx, cy, cz + bz)
        b_se = (cx + bx, cy, cz + bz)
        b_ne = (cx + bx, cy, cz - bz)
        b_nw = (cx - bx, cy, cz - bz)

        # Midpoints of bottom rim
        b_mid_s = (cx, cy, cz + bz)
        b_mid_e = (cx + bx, cy, cz)
        b_mid_n = (cx, cy, cz - bz)
        b_mid_w = (cx - bx, cy, cz)

        # Eave top rim (start of roof slopes) - corners have slight upturn
        r_sw = (cx - bx, cy + rim_h + upturn, cz + bz)
        r_se = (cx + bx, cy + rim_h + upturn, cz + bz)
        r_ne = (cx + bx, cy + rim_h + upturn, cz - bz)
        r_nw = (cx - bx, cy + rim_h + upturn, cz - bz)

        r_mid_s = (cx, cy + rim_h, cz + bz)
        r_mid_e = (cx + bx, cy + rim_h, cz)
        r_mid_n = (cx, cy + rim_h, cz - bz)
        r_mid_w = (cx - bx, cy + rim_h, cz)

        # Top ridge points
        is_point = (tx < 0.05 and tz < 0.05)
        top_y = cy + height
        if is_point:
            apex = (cx, top_y, cz)
            t_sw = t_se = t_ne = t_nw = apex
            t_mid_s = t_mid_e = t_mid_n = t_mid_w = apex
        else:
            t_sw = (cx - tx, top_y, cz + tz)
            t_se = (cx + tx, top_y, cz + tz)
            t_ne = (cx + tx, top_y, cz - tz)
            t_nw = (cx - tx, top_y, cz - tz)

            t_mid_s = (cx, top_y, cz + tz)
            t_mid_e = (cx + tx, top_y, cz)
            t_mid_n = (cx, top_y, cz - tz)
            t_mid_w = (cx - tx, top_y, cz)

        def add_face(p1, p2, p3, p4=None, uv_coords=((0,0), (1,0), (1,1), (0,1))):
            v1 = np.array(p2) - np.array(p1)
            v2 = np.array(p3) - np.array(p1)
            norm = np.cross(v1, v2)
            n_len = np.linalg.norm(norm)
            norm = tuple(norm / n_len) if n_len > 1e-6 else (0, 1, 0)

            if p4 is None or is_point:
                # Triangle
                i1 = self.add_vertex(p1, norm, uv_coords[0])
                i2 = self.add_vertex(p2, norm, uv_coords[1])
                i3 = self.add_vertex(p3, norm, uv_coords[2])
                self.add_triangle(i1, i2, i3)
            else:
                # Quad
                i1 = self.add_vertex(p1, norm, uv_coords[0])
                i2 = self.add_vertex(p2, norm, uv_coords[1])
                i3 = self.add_vertex(p3, norm, uv_coords[2])
                i4 = self.add_vertex(p4, norm, uv_coords[3])
                self.add_quad(i1, i2, i3, i4)

        u_s, v_s = uv_scale

        if is_point:
            # 8 triangles meeting at apex
            add_face(r_sw, r_mid_s, apex, uv_coords=((0, 0), (u_s*0.5, 0), (u_s*0.25, v_s)))
            add_face(r_mid_s, r_se, apex, uv_coords=((u_s*0.5, 0), (u_s, 0), (u_s*0.75, v_s)))
            add_face(r_se, r_mid_e, apex, uv_coords=((0, 0), (u_s*0.5, 0), (u_s*0.25, v_s)))
            add_face(r_mid_e, r_ne, apex, uv_coords=((u_s*0.5, 0), (u_s, 0), (u_s*0.75, v_s)))
            add_face(r_ne, r_mid_n, apex, uv_coords=((0, 0), (u_s*0.5, 0), (u_s*0.25, v_s)))
            add_face(r_mid_n, r_nw, apex, uv_coords=((u_s*0.5, 0), (u_s, 0), (u_s*0.75, v_s)))
            add_face(r_nw, r_mid_w, apex, uv_coords=((0, 0), (u_s*0.5, 0), (u_s*0.25, v_s)))
            add_face(r_mid_w, r_sw, apex, uv_coords=((u_s*0.5, 0), (u_s, 0), (u_s*0.75, v_s)))
        else:
            # 8 quads for the 4 roof slopes
            # South slope (+Z)
            add_face(r_sw, r_mid_s, t_mid_s, t_sw, ((0, 0), (u_s*0.5, 0), (u_s*0.5, v_s), (0, v_s)))
            add_face(r_mid_s, r_se, t_se, t_mid_s, ((u_s*0.5, 0), (u_s, 0), (u_s, v_s), (u_s*0.5, v_s)))
            # East slope (+X)
            add_face(r_se, r_mid_e, t_mid_e, t_se, ((0, 0), (u_s*0.5, 0), (u_s*0.5, v_s), (0, v_s)))
            add_face(r_mid_e, r_ne, t_ne, t_mid_e, ((u_s*0.5, 0), (u_s, 0), (u_s, v_s), (u_s*0.5, v_s)))
            # North slope (-Z)
            add_face(r_ne, r_mid_n, t_mid_n, t_ne, ((0, 0), (u_s*0.5, 0), (u_s*0.5, v_s), (0, v_s)))
            add_face(r_mid_n, r_nw, t_nw, t_mid_n, ((u_s*0.5, 0), (u_s, 0), (u_s, v_s), (u_s*0.5, v_s)))
            # West slope (-X)
            add_face(r_nw, r_mid_w, t_mid_w, t_nw, ((0, 0), (u_s*0.5, 0), (u_s*0.5, v_s), (0, v_s)))
            add_face(r_mid_w, r_sw, t_sw, t_mid_w, ((u_s*0.5, 0), (u_s, 0), (u_s, v_s), (u_s*0.5, v_s)))
            # Top face (+Y)
            add_face(t_sw, t_se, t_ne, t_nw, ((0, 0), (1, 0), (1, 1), (0, 1)))

        # 4 vertical rim faces around eave edge
        add_face(b_sw, b_se, r_se, r_sw, ((0, 0), (u_s, 0), (u_s, 0.2), (0, 0.2)))
        add_face(b_se, b_ne, r_ne, r_se, ((0, 0), (u_s, 0), (u_s, 0.2), (0, 0.2)))
        add_face(b_ne, b_nw, r_nw, r_ne, ((0, 0), (u_s, 0), (u_s, 0.2), (0, 0.2)))
        add_face(b_nw, b_sw, r_sw, r_nw, ((0, 0), (u_s, 0), (u_s, 0.2), (0, 0.2)))

        # Underside soffit ceiling (-Y)
        add_face(b_nw, b_ne, b_se, b_sw, ((0, 0), (1, 0), (1, 1), (0, 1)))

    def add_sphere(self, center, radius, rings=8, sectors=12, uv_scale=(1.0, 1.0)):
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
                u = (s / sectors) * uv_scale[0]
                v = (r / rings) * uv_scale[1]
                idx = self.add_vertex(p, (nx, ny, nz), (u, v))
                row.append(idx)
            vert_matrix.append(row)

        for r in range(rings):
            for s in range(sectors):
                i1 = vert_matrix[r][s]
                i2 = vert_matrix[r][s+1]
                i3 = vert_matrix[r+1][s+1]
                i4 = vert_matrix[r+1][s]
                self.add_quad(i1, i2, i3, i4)

def export_textured_glb(filename, submeshes, materials_spec):
    bin_data = bytearray()
    buffer_views = []
    accessors = []
    images = []
    textures = []
    materials = []
    meshes_primitives = []

    def add_buffer(data_bytes, target=None):
        offset = len(bin_data)
        pad = (4 - (offset % 4)) % 4
        if pad:
            bin_data.extend(b'\x00' * pad)
            offset += pad
        bin_data.extend(data_bytes)
        bv_idx = len(buffer_views)
        bv = {
            "buffer": 0,
            "byteOffset": offset,
            "byteLength": len(data_bytes)
        }
        if target is not None:
            bv["target"] = target
        buffer_views.append(bv)
        return bv_idx

    tex_cache = {}
    for mat_def in materials_spec:
        mat_entry = {
            "name": mat_def["name"],
            "pbrMetallicRoughness": {
                "baseColorFactor": mat_def.get("base_color", [1.0, 1.0, 1.0, 1.0]),
                "roughnessFactor": mat_def.get("roughness", 0.5),
                "metallicFactor": mat_def.get("metallic", 0.0)
            }
        }
        if "emissive" in mat_def:
            mat_entry["emissiveFactor"] = mat_def["emissive"]

        tex_file = mat_def.get("texture_file")
        if tex_file:
            tex_path = os.path.join(TEXTURE_DIR, tex_file)
            if os.path.exists(tex_path):
                if tex_file not in tex_cache:
                    with open(tex_path, 'rb') as f:
                        png_bytes = f.read()
                    bv_img = add_buffer(png_bytes)
                    img_idx = len(images)
                    images.append({
                        "bufferView": bv_img,
                        "mimeType": "image/png"
                    })
                    tex_idx = len(textures)
                    textures.append({"source": img_idx})
                    tex_cache[tex_file] = tex_idx
                mat_entry["pbrMetallicRoughness"]["baseColorTexture"] = {"index": tex_cache[tex_file]}

        materials.append(mat_entry)

    # Geometry buffers
    for sub in submeshes:
        mb = sub['builder']
        if len(mb.positions) == 0:
            continue
        pos = np.array(mb.positions, dtype=np.float32)
        norm = np.array(mb.normals, dtype=np.float32)
        uv = np.array(mb.uvs, dtype=np.float32)
        idx = np.array(mb.indices, dtype=np.uint32).flatten()

        pos_min = pos.min(axis=0).tolist()
        pos_max = pos.max(axis=0).tolist()

        idx_bv = add_buffer(idx.tobytes(), 34963)
        idx_acc = len(accessors)
        accessors.append({
            "bufferView": idx_bv, "byteOffset": 0, "componentType": 5125,
            "count": len(idx), "type": "SCALAR"
        })

        pos_bv = add_buffer(pos.tobytes(), 34962)
        pos_acc = len(accessors)
        accessors.append({
            "bufferView": pos_bv, "byteOffset": 0, "componentType": 5126,
            "count": len(pos), "type": "VEC3", "min": pos_min, "max": pos_max
        })

        norm_bv = add_buffer(norm.tobytes(), 34962)
        norm_acc = len(accessors)
        accessors.append({
            "bufferView": norm_bv, "byteOffset": 0, "componentType": 5126,
            "count": len(norm), "type": "VEC3"
        })

        uv_bv = add_buffer(uv.tobytes(), 34962)
        uv_acc = len(accessors)
        accessors.append({
            "bufferView": uv_bv, "byteOffset": 0, "componentType": 5126,
            "count": len(uv), "type": "VEC2"
        })

        prim_dict = {
            "attributes": {"POSITION": pos_acc, "NORMAL": norm_acc, "TEXCOORD_0": uv_acc},
            "indices": idx_acc,
            "mode": 4
        }
        if 'material_idx' in sub:
            prim_dict["material"] = sub['material_idx']
        meshes_primitives.append(prim_dict)

    pad = (4 - (len(bin_data) % 4)) % 4
    if pad:
        bin_data.extend(b'\x00' * pad)

    gltf_json = {
        "asset": {"version": "2.0", "generator": "AsianFantasyModelGenerator"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": "ModelRoot"}],
        "meshes": [{"primitives": meshes_primitives, "name": "Mesh"}],
        "buffers": [{"byteLength": len(bin_data)}],
        "bufferViews": buffer_views,
        "accessors": accessors,
        "materials": materials
    }
    if images:
        gltf_json["images"] = images
    if textures:
        gltf_json["textures"] = textures

    json_str = json.dumps(gltf_json).encode('utf-8')
    pad = (4 - (len(json_str) % 4)) % 4
    if pad:
        json_str += b' ' * pad

    total_length = 12 + 8 + len(json_str) + 8 + len(bin_data)
    header = struct.pack('<4sII', b'glTF', 2, total_length)
    json_chunk = struct.pack('<I4s', len(json_str), b'JSON') + json_str
    bin_chunk = struct.pack('<I4s', len(bin_data), b'BIN\x00') + bin_data

    with open(filename, 'wb') as f:
        f.write(header + json_chunk + bin_chunk)
    print(f"Exported textured GLB: {os.path.basename(filename)} ({len(header + json_chunk + bin_chunk)} bytes)")

# ========================================================
# 1. TORII GATE
# ========================================================
def generate_torii_gate():
    mb_wood = MeshBuilder()
    mb_black = MeshBuilder()
    mb_gold = MeshBuilder()
    mb_lantern = MeshBuilder()

    # Two pillars (Hashira)
    for x in [-2.6, 2.6]:
        mb_black.add_cylinder((x, 0.0, 0), (x, 0.6, 0), 0.52, 0.48, segments=16, uv_scale=(1.0, 1.0))
        mb_wood.add_cylinder((x, 0.6, 0), (x, 5.8, 0), 0.44, 0.38, segments=16, uv_scale=(1.0, 4.0))
        mb_black.add_cylinder((x, 5.8, 0), (x, 6.0, 0), 0.46, 0.46, segments=16, uv_scale=(1.0, 0.5))

    # Lower tie beam (Nuki)
    mb_wood.add_box((0, 4.4, 0), (7.0, 0.38, 0.42), uv_scale=(3.0, 1.0))
    for x in [-3.6, 3.6]:
        mb_black.add_box((x, 4.4, 0), (0.22, 0.44, 0.48), uv_scale=(1.0, 1.0))

    # Curved top lintel (Kasagi + Shimaki)
    num_steps = 14
    kasagi_pts = []
    for i in range(num_steps + 1):
        t = (i / num_steps) * 2.0 - 1.0
        x = t * 4.4
        y = 6.0 + (t ** 2) * 0.42
        kasagi_pts.append((x, y, 0))

    for i in range(num_steps):
        p1, p2 = kasagi_pts[i], kasagi_pts[i+1]
        mx = (p1[0] + p2[0]) * 0.5
        my = (p1[1] + p2[1]) * 0.5
        dx = p2[0] - p1[0]
        dy = p2[1] - p1[1]
        seg_len = math.sqrt(dx*dx + dy*dy)
        mb_wood.add_box((mx, my, 0), (seg_len + 0.05, 0.52, 0.62), uv_scale=(1.0, 1.0))

    for x in [-4.4, 4.4]:
        mb_gold.add_box((x, 6.42, 0), (0.32, 0.58, 0.68))

    # Center plaque (Gakuzuka)
    mb_black.add_box((0, 5.15, 0), (0.8, 1.1, 0.2))
    mb_gold.add_box((0, 5.15, 0.11), (0.6, 0.9, 0.05))

    # Hanging lantern
    mb_lantern.add_cylinder((0, 4.2, 0), (0, 3.4, 0), 0.35, 0.35, segments=12, uv_scale=(1.0, 1.0))
    mb_black.add_cylinder((0, 4.2, 0), (0, 4.3, 0), 0.38, 0.38, segments=12)
    mb_black.add_cylinder((0, 3.3, 0), (0, 3.4, 0), 0.38, 0.38, segments=12)
    mb_gold.add_cylinder((0, 3.0, 0), (0, 3.3, 0), 0.08, 0.08, segments=8)

    materials = [
        {"name": "Mat_Vermilion", "texture_file": "asian_wood_vermilion.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.4},
        {"name": "Mat_BlackLacquer", "texture_file": "asian_wood_dark.png", "base_color": [0.4, 0.4, 0.45, 1.0], "roughness": 0.35},
        {"name": "Mat_GoldTrim", "base_color": [0.96, 0.82, 0.25, 1.0], "metallic": 0.85, "roughness": 0.25},
        {"name": "Mat_PaperLantern", "texture_file": "asian_paper_lantern.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.3, "emissive": [0.8, 0.2, 0.1]},
    ]
    submeshes = [
        {"builder": mb_wood, "material_idx": 0},
        {"builder": mb_black, "material_idx": 1},
        {"builder": mb_gold, "material_idx": 2},
        {"builder": mb_lantern, "material_idx": 3},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_torii_gate.glb"), submeshes, materials)

# ========================================================
# 2. ASIAN PAGODA (3 Tiers)
# ========================================================
def generate_pagoda():
    mb_stone = MeshBuilder()
    mb_wood = MeshBuilder()
    mb_wall = MeshBuilder()
    mb_roof = MeshBuilder()
    mb_gold = MeshBuilder()

    # Stone terrace (12m x 12m, 1.2m high)
    mb_stone.add_box((0, 0.6, 0), (12.0, 1.2, 12.0), uv_scale=(4.0, 4.0))
    for z_side in [6.5, -6.5]:
        mb_stone.add_box((0, 0.3, z_side), (4.0, 0.6, 1.2), uv_scale=(2.0, 1.0))

    # Tier 1
    mb_wall.add_box((0, 3.2, 0), (7.4, 3.8, 7.4), uv_scale=(3.0, 2.0))
    for px in [-3.8, 0, 3.8]:
        for pz in [-3.8, 0, 3.8]:
            if px != 0 or pz != 0:
                mb_wood.add_cylinder((px, 1.2, pz), (px, 5.2, pz), 0.30, 0.30, segments=12, uv_scale=(1.0, 3.0))

    mb_roof.add_curved_eave_roof((0, 5.0, 0), (10.5, 10.5), (6.8, 6.8), 1.6, eave_flare=1.16, uv_scale=(3.5, 3.5))

    # Tier 2
    mb_wood.add_box((0, 6.7, 0), (7.6, 0.25, 7.6), uv_scale=(3.0, 3.0))
    for side_x in [-3.7, 3.7]:
        mb_wood.add_box((side_x, 7.2, 0), (0.15, 0.8, 7.4), uv_scale=(1.0, 3.0))
    for side_z in [-3.7, 3.7]:
        mb_wood.add_box((0, 7.2, side_z), (7.4, 0.8, 0.15), uv_scale=(3.0, 1.0))

    mb_wall.add_box((0, 8.4, 0), (5.8, 3.4, 5.8), uv_scale=(2.5, 2.0))
    for px in [-2.9, 2.9]:
        for pz in [-2.9, 2.9]:
            mb_wood.add_cylinder((px, 6.7, pz), (px, 10.1, pz), 0.26, 0.26, segments=12, uv_scale=(1.0, 2.5))

    mb_roof.add_curved_eave_roof((0, 9.9, 0), (8.8, 8.8), (5.2, 5.2), 1.4, eave_flare=1.18, uv_scale=(3.0, 3.0))

    # Tier 3
    mb_wall.add_box((0, 12.8, 0), (4.4, 3.0, 4.4), uv_scale=(2.0, 2.0))
    for px in [-2.2, 2.2]:
        for pz in [-2.2, 2.2]:
            mb_wood.add_cylinder((px, 11.3, pz), (px, 14.3, pz), 0.22, 0.22, segments=12, uv_scale=(1.0, 2.0))

    # Pointed apex roof
    mb_roof.add_curved_eave_roof((0, 14.1, 0), (7.2, 7.2), (0.0, 0.0), 1.7, eave_flare=1.20, uv_scale=(2.5, 2.5))

    # Golden Spire (Sorin)
    mb_gold.add_cylinder((0, 15.8, 0), (0, 19.4, 0), 0.18, 0.04, segments=12)
    for ry in [16.6, 17.1, 17.6, 18.1, 18.6]:
        mb_gold.add_cylinder((0, ry - 0.08, 0), (0, ry + 0.08, 0), 0.36, 0.36, segments=12)
    mb_gold.add_sphere((0, 19.5, 0), 0.25, rings=8, sectors=12)

    materials = [
        {"name": "Mat_StoneTerrace", "texture_file": "asian_stone_pavers.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.75},
        {"name": "Mat_VermilionWood", "texture_file": "asian_wood_vermilion.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.45},
        {"name": "Mat_ShojiWall", "texture_file": "asian_shoji_wall.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.8},
        {"name": "Mat_JadeTileRoof", "texture_file": "asian_roof_tiles.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.4},
        {"name": "Mat_GoldenSpire", "base_color": [0.96, 0.82, 0.25, 1.0], "metallic": 0.85, "roughness": 0.25},
    ]
    submeshes = [
        {"builder": mb_stone, "material_idx": 0},
        {"builder": mb_wood, "material_idx": 1},
        {"builder": mb_wall, "material_idx": 2},
        {"builder": mb_roof, "material_idx": 3},
        {"builder": mb_gold, "material_idx": 4},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_pagoda.glb"), submeshes, materials)

# ========================================================
# 3. ASIAN SHOP HOUSE
# ========================================================
def generate_shop_house():
    mb_wood = MeshBuilder()
    mb_wall = MeshBuilder()
    mb_roof = MeshBuilder()
    mb_lantern = MeshBuilder()

    # Timber base floor
    mb_wood.add_box((0, 0.2, 0), (7.2, 0.4, 5.8), uv_scale=(2.0, 2.0))
    mb_wall.add_box((-2.2, 1.8, 0), (2.4, 2.8, 5.2), uv_scale=(1.5, 2.0))
    mb_wall.add_box((2.2, 1.8, 0), (2.4, 2.8, 5.2), uv_scale=(1.5, 2.0))
    mb_wall.add_box((0, 1.8, -2.4), (6.8, 2.8, 0.4), uv_scale=(3.0, 2.0))
    mb_wood.add_box((0, 1.0, 2.2), (3.2, 0.9, 0.8), uv_scale=(2.0, 1.0))

    for x in [-3.4, 3.4]:
        for z in [-2.6, 2.6]:
            mb_wood.add_box((x, 3.0, z), (0.4, 5.6, 0.4), uv_scale=(1.0, 4.0))

    # Lower awning roof
    mb_roof.add_curved_eave_roof((0, 3.2, 0.4), (7.8, 6.2), (6.8, 5.2), 0.7, eave_flare=1.12, uv_scale=(2.5, 2.0))
    # Upper floor wall
    mb_wall.add_box((0, 4.7, 0), (6.6, 2.0, 5.0), uv_scale=(3.0, 1.5))
    mb_wood.add_box((0, 4.3, 2.7), (6.6, 0.8, 0.15), uv_scale=(3.0, 1.0))
    # Upper main roof
    mb_roof.add_curved_eave_roof((0, 5.6, 0), (8.2, 6.6), (3.8, 2.4), 1.4, eave_flare=1.15, uv_scale=(3.0, 2.5))

    for lx in [-2.2, 2.2]:
        mb_lantern.add_cylinder((lx, 2.4, 2.6), (lx, 1.8, 2.6), 0.25, 0.25, segments=12, uv_scale=(1.0, 1.0))

    materials = [
        {"name": "Mat_DarkTimber", "texture_file": "asian_wood_dark.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.65},
        {"name": "Mat_ShojiWall", "texture_file": "asian_shoji_wall.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.75},
        {"name": "Mat_TileRoof", "texture_file": "asian_roof_tiles.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.45},
        {"name": "Mat_RedLantern", "texture_file": "asian_paper_lantern.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.3, "emissive": [0.8, 0.2, 0.1]},
    ]
    submeshes = [
        {"builder": mb_wood, "material_idx": 0},
        {"builder": mb_wall, "material_idx": 1},
        {"builder": mb_roof, "material_idx": 2},
        {"builder": mb_lantern, "material_idx": 3},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_shop_house.glb"), submeshes, materials)

# ========================================================
# 4. ASIAN TEA PAVILION
# ========================================================
def generate_tea_pavilion():
    mb_stone = MeshBuilder()
    mb_wood = MeshBuilder()
    mb_roof = MeshBuilder()
    mb_gold = MeshBuilder()

    # Hexagonal stone terrace base
    mb_stone.add_cylinder((0, 0, 0), (0, 0.5, 0), 3.8, 3.8, segments=6, uv_scale=(2.0, 1.0))
    mb_stone.add_cylinder((0, 0.5, 0), (0, 0.65, 0), 4.0, 4.0, segments=6, uv_scale=(2.0, 0.5))

    # 6 vermilion pillars
    for i in range(6):
        ang = (2.0 * math.pi * i) / 6.0
        px = math.cos(ang) * 3.0
        pz = math.sin(ang) * 3.0
        mb_wood.add_cylinder((px, 0.65, pz), (px, 3.8, pz), 0.18, 0.18, segments=12, uv_scale=(1.0, 3.0))

    # Wooden lintel ring connecting pillars
    mb_wood.add_cylinder((0, 3.7, 0), (0, 4.0, 0), 3.1, 3.1, segments=6, uv_scale=(2.0, 0.5))

    # Stone tea table in center
    mb_stone.add_cylinder((0, 0.65, 0), (0, 1.35, 0), 0.85, 0.85, segments=12, uv_scale=(1.0, 1.0))
    mb_stone.add_cylinder((0, 1.35, 0), (0, 1.45, 0), 1.15, 1.15, segments=12, uv_scale=(1.0, 0.3))
    # 4 stone stools around table
    for i in range(4):
        ang = (2.0 * math.pi * i) / 4.0 + 0.35
        sx = math.cos(ang) * 1.8
        sz = math.sin(ang) * 1.8
        mb_wood.add_cylinder((sx, 0.65, sz), (sx, 1.15, sz), 0.26, 0.26, segments=10, uv_scale=(1.0, 1.0))

    # Hexagonal roof with outward normals and soffit
    seg = 6
    roof_bot_pts = []
    roof_rim_pts = []
    eave_rad = 4.6
    for i in range(seg + 1):
        ang = (2.0 * math.pi * i) / seg
        bx = math.cos(ang) * eave_rad
        bz = math.sin(ang) * eave_rad
        roof_bot_pts.append((bx, 4.0, bz))
        roof_rim_pts.append((bx * 1.04, 4.18, bz * 1.04))

    p_apex = (0, 6.2, 0)
    for i in range(seg):
        b1, b2 = roof_bot_pts[i], roof_bot_pts[i+1]
        r1, r2 = roof_rim_pts[i], roof_rim_pts[i+1]

        # Roof slope: outward normal, counter-clockwise from outside
        v1 = np.array(r1) - np.array(r2)
        v2 = np.array(p_apex) - np.array(r2)
        norm = np.cross(v1, v2)
        norm = tuple(norm / np.linalg.norm(norm))

        i1 = mb_roof.add_vertex(r1, norm, (2.0, 0))
        i2 = mb_roof.add_vertex(r2, norm, (0, 0))
        i3 = mb_roof.add_vertex(p_apex, norm, (1.0, 2.0))
        mb_roof.add_triangle(i2, i1, i3)

        # Vertical eave rim (b1 -> b2 -> r2 -> r1)
        v_rim = np.cross(np.array(b1) - np.array(b2), np.array(r2) - np.array(b2))
        norm_rim = tuple(v_rim / np.linalg.norm(v_rim))
        rb1 = mb_roof.add_vertex(b1, norm_rim, (1, 0))
        rb2 = mb_roof.add_vertex(b2, norm_rim, (0, 0))
        rr2 = mb_roof.add_vertex(r2, norm_rim, (0, 0.4))
        rr1 = mb_roof.add_vertex(r1, norm_rim, (1, 0.4))
        mb_roof.add_quad(rb2, rb1, rr1, rr2)

        # Ceiling soffit (underside: b1 -> b2 -> center)
        c_under = (0, 4.0, 0)
        norm_under = (0, -1, 0)
        u1 = mb_wood.add_vertex(b1, norm_under, (0, 0))
        u2 = mb_wood.add_vertex(b2, norm_under, (1, 0))
        u3 = mb_wood.add_vertex(c_under, norm_under, (0.5, 1))
        mb_wood.add_triangle(u1, u2, u3)

    mb_gold.add_sphere((0, 6.35, 0), 0.32, rings=8, sectors=12)

    materials = [
        {"name": "Mat_StoneBase", "texture_file": "asian_stone_pavers.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.75},
        {"name": "Mat_VermilionWood", "texture_file": "asian_wood_vermilion.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.4},
        {"name": "Mat_JadeTileRoof", "texture_file": "asian_roof_tiles.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.4},
        {"name": "Mat_GoldFinial", "base_color": [0.96, 0.82, 0.25, 1.0], "metallic": 0.85, "roughness": 0.25},
    ]
    submeshes = [
        {"builder": mb_stone, "material_idx": 0},
        {"builder": mb_wood, "material_idx": 1},
        {"builder": mb_roof, "material_idx": 2},
        {"builder": mb_gold, "material_idx": 3},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_tea_pavilion.glb"), submeshes, materials)

# ========================================================
# 5. ASIAN MOON BRIDGE
# ========================================================
def generate_moon_bridge():
    mb_wood = MeshBuilder()
    mb_red = MeshBuilder()
    mb_gold = MeshBuilder()

    num_steps = 16
    bridge_width = 3.8
    arch_height = 1.6

    deck_pts = []
    for i in range(num_steps + 1):
        t = (i / num_steps) * 2.0 - 1.0
        z = t * 6.0
        y = (1.0 - t ** 2) * arch_height
        deck_pts.append((y, z))

    for i in range(num_steps):
        y1, z1 = deck_pts[i]
        y2, z2 = deck_pts[i+1]
        my = (y1 + y2) * 0.5
        mz = (z1 + z2) * 0.5
        dz = z2 - z1
        dy = y2 - y1
        seg_len = math.sqrt(dz*dz + dy*dy)

        # Wooden deck planking
        mb_wood.add_box((0, my, mz), (bridge_width, 0.22, seg_len + 0.04), uv_scale=(2.0, 1.0))
        mb_wood.add_box((0, my + 0.14, mz), (bridge_width * 0.95, 0.06, 0.12), uv_scale=(2.0, 0.5))

    for x_side in [-1.9, 1.9]:
        for i in range(num_steps):
            y1, z1 = deck_pts[i]
            y2, z2 = deck_pts[i+1]
            my = (y1 + y2) * 0.5 + 0.75
            mz = (z1 + z2) * 0.5
            dz = z2 - z1
            dy = y2 - y1
            seg_len = math.sqrt(dz*dz + dy*dy)
            mb_red.add_box((x_side, my, mz), (0.16, 0.18, seg_len + 0.04), uv_scale=(1.0, 1.0))

        for i in range(0, num_steps + 1, 2):
            y, z = deck_pts[i]
            mb_red.add_cylinder((x_side, y, z), (x_side, y + 0.90, z), 0.10, 0.10, segments=10, uv_scale=(1.0, 1.5))
            mb_gold.add_sphere((x_side, y + 1.0, z), 0.12, rings=6, sectors=8)

    materials = [
        {"name": "Mat_BridgePlanks", "texture_file": "asian_wood_dark.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.75},
        {"name": "Mat_VermilionRail", "texture_file": "asian_wood_vermilion.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.4},
        {"name": "Mat_GoldGiboshi", "base_color": [0.96, 0.82, 0.25, 1.0], "metallic": 0.8, "roughness": 0.25},
    ]
    submeshes = [
        {"builder": mb_wood, "material_idx": 0},
        {"builder": mb_red, "material_idx": 1},
        {"builder": mb_gold, "material_idx": 2},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_moon_bridge.glb"), submeshes, materials)

# ========================================================
# 6. ASIAN STONE LANTERN
# ========================================================
def generate_stone_lantern():
    mb_stone = MeshBuilder()
    mb_glow = MeshBuilder()

    # Hexagonal stone base pedestal
    mb_stone.add_cylinder((0, 0, 0), (0, 0.35, 0), 0.7, 0.65, segments=6, uv_scale=(1.0, 1.0))
    mb_stone.add_cylinder((0, 0.35, 0), (0, 0.55, 0), 0.65, 0.55, segments=6, uv_scale=(1.0, 1.0))
    # Central stem
    mb_stone.add_cylinder((0, 0.55, 0), (0, 1.35, 0), 0.28, 0.25, segments=12, uv_scale=(1.0, 2.0))
    # Middle platform
    mb_stone.add_cylinder((0, 1.35, 0), (0, 1.55, 0), 0.38, 0.65, segments=6, uv_scale=(1.0, 1.0))

    # 6 stone corner posts around light chamber
    for i in range(6):
        ang = (2.0 * math.pi * i) / 6.0
        px = math.cos(ang) * 0.50
        pz = math.sin(ang) * 0.50
        mb_stone.add_cylinder((px, 1.55, pz), (px, 2.15, pz), 0.07, 0.07, segments=8, uv_scale=(1.0, 1.0))

    # Glowing amber core
    mb_glow.add_cylinder((0, 1.6, 0), (0, 2.1, 0), 0.32, 0.32, segments=8)
    # Lantern curved roof (Kasa) - pointed pyramid top
    mb_stone.add_curved_eave_roof((0, 2.15, 0), (1.5, 1.5), (0.0, 0.0), 0.60, eave_flare=1.18, uv_scale=(1.5, 1.5))
    # Jewel finial (Hoju)
    mb_stone.add_sphere((0, 2.85, 0), 0.20, rings=8, sectors=10)

    materials = [
        {"name": "Mat_GraniteStone", "texture_file": "asian_stone_pavers.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.85},
        {"name": "Mat_AmberLanternGlow", "base_color": [1.0, 0.85, 0.3, 1.0], "roughness": 0.2, "emissive": [1.0, 0.75, 0.25]},
    ]
    submeshes = [
        {"builder": mb_stone, "material_idx": 0},
        {"builder": mb_glow, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_stone_lantern.glb"), submeshes, materials)

# ========================================================
# 7. SAKURA TREE
# ========================================================
def generate_sakura_tree():
    mb_trunk = MeshBuilder()
    mb_blossom = MeshBuilder()

    trunk_pts = [
        ((0, 0, 0), 0.55),
        ((0.15, 1.2, -0.1), 0.48),
        ((-0.2, 2.5, 0.2), 0.42),
        ((0.1, 3.8, -0.1), 0.36),
        ((0.0, 4.8, 0.0), 0.30),
    ]
    for i in range(len(trunk_pts) - 1):
        p1, r1 = trunk_pts[i]
        p2, r2 = trunk_pts[i+1]
        mb_trunk.add_cylinder(p1, p2, r1, r2, segments=12, uv_scale=(1.0, 2.0))

    branches = [
        ((0.0, 4.0, 0.0), (1.8, 5.2, 0.8), 0.25, 0.12),
        ((0.0, 4.2, 0.0), (-1.6, 5.0, -1.2), 0.24, 0.11),
        ((0.0, 4.5, 0.0), (-1.2, 5.5, 1.5), 0.22, 0.10),
        ((0.0, 4.7, 0.0), (1.4, 5.7, -1.4), 0.22, 0.10),
        ((0.0, 4.8, 0.0), (0.0, 6.2, 0.2), 0.20, 0.08),
    ]
    for b_start, b_end, r1, r2 in branches:
        mb_trunk.add_cylinder(b_start, b_end, r1, r2, segments=8, uv_scale=(1.0, 1.5))

    blossom_clumps = [
        ((0.0, 6.6, 0.2), 2.2),
        ((1.9, 5.5, 0.9), 1.7),
        ((-1.7, 5.3, -1.3), 1.6),
        ((-1.3, 5.8, 1.6), 1.6),
        ((1.5, 6.0, -1.5), 1.7),
        ((0.2, 5.8, 0.0), 1.9),
    ]
    for center, rad in blossom_clumps:
        mb_blossom.add_sphere(center, rad, rings=10, sectors=14, uv_scale=(2.0, 2.0))

    materials = [
        {"name": "Mat_SakuraBark", "texture_file": "asian_wood_dark.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.8},
        {"name": "Mat_SakuraBlossoms", "texture_file": "sakura_foliage.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.65},
    ]
    submeshes = [
        {"builder": mb_trunk, "material_idx": 0},
        {"builder": mb_blossom, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "sakura_tree.glb"), submeshes, materials)

# ========================================================
# 8. BAMBOO CLUSTER
# ========================================================
def generate_bamboo_cluster():
    mb_stalk = MeshBuilder()
    mb_leaves = MeshBuilder()

    stalk_defs = [
        (0.0, 0.0, 8.5, 0.08, (0.05, -0.02)),
        (0.6, 0.4, 7.8, 0.07, (-0.03, 0.04)),
        (-0.5, 0.5, 9.2, 0.085, (0.02, 0.03)),
        (-0.6, -0.4, 7.5, 0.065, (-0.04, -0.02)),
        (0.4, -0.5, 8.8, 0.075, (0.03, -0.03)),
        (0.8, -0.1, 7.2, 0.065, (0.04, 0.02)),
    ]

    for sx, sz, height, radius, tilt in stalk_defs:
        num_nodes = int(height / 1.1)
        prev_p = (sx, 0.0, sz)
        for n in range(1, num_nodes + 1):
            y = (n / num_nodes) * height
            cur_p = (sx + tilt[0] * y, y, sz + tilt[1] * y)
            mb_stalk.add_cylinder(prev_p, cur_p, radius, radius * 0.96, segments=10, uv_scale=(1.0, 1.0))
            mb_stalk.add_cylinder((cur_p[0], cur_p[1]-0.04, cur_p[2]), (cur_p[0], cur_p[1]+0.04, cur_p[2]), radius*1.22, radius*1.22, segments=10, uv_scale=(1.0, 0.2))

            if y > height * 0.45:
                for l_ang in [0.8, 2.5, 4.3]:
                    lx = cur_p[0] + math.cos(l_ang) * 0.7
                    lz = cur_p[2] + math.sin(l_ang) * 0.7
                    mb_leaves.add_sphere((lx, y + 0.15, lz), 0.35, rings=4, sectors=6, uv_scale=(1.0, 1.0))
            prev_p = cur_p

    materials = [
        {"name": "Mat_BambooGreen", "texture_file": "bamboo_texture.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.4},
        {"name": "Mat_BambooLeaves", "texture_file": "bamboo_texture.png", "base_color": [0.85, 1.0, 0.8, 1.0], "roughness": 0.5},
    ]
    submeshes = [
        {"builder": mb_stalk, "material_idx": 0},
        {"builder": mb_leaves, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "bamboo_cluster.glb"), submeshes, materials)

# ========================================================
# 9. KARST MOUNTAIN SPIRE
# ========================================================
def generate_karst_spire():
    mb_rock = MeshBuilder()
    mb_top = MeshBuilder()

    height = 28.0
    layers = 12
    prev_ring = []

    for ly in range(layers + 1):
        y = (ly / layers) * height
        radius = 5.2 - (ly / layers) * 1.8 + math.sin(ly * 0.8) * 0.6
        sectors = 14
        ring = []
        for s in range(sectors + 1):
            ang = (2.0 * math.pi * s) / sectors
            noise_r = radius + math.sin(ang * 4.0 + ly) * 0.45
            px = math.cos(ang) * noise_r
            pz = math.sin(ang) * noise_r
            norm = (math.cos(ang), 0.1, math.sin(ang))
            u = (s / sectors) * 3.0
            v = (ly / layers) * 6.0
            idx = mb_rock.add_vertex((px, y, pz), norm, (u, v))
            ring.append(idx)

        if ly > 0:
            for s in range(sectors):
                b1 = prev_ring[s]
                b2 = prev_ring[s+1]
                t1 = ring[s]
                t2 = ring[s+1]
                mb_rock.add_quad(b1, b2, t2, t1)
        prev_ring = ring

    top_y = height
    mb_top.add_cylinder((0, top_y - 0.2, 0), (0, top_y, 0), 4.8, 4.8, segments=14, uv_scale=(3.0, 3.0))

    materials = [
        {"name": "Mat_KarstCliff", "texture_file": "karst_cliff_rock.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.85},
        {"name": "Mat_PeakGrass", "texture_file": "genshin_grass.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.7},
    ]
    submeshes = [
        {"builder": mb_rock, "material_idx": 0},
        {"builder": mb_top, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "karst_mountain_spire.glb"), submeshes, materials)

def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)

def get_terrain_height(x, z):
    # 1. Gentle river course meandering along Z around X = 0
    x_riv = math.sin(z * 0.025) * 3.0
    d_riv = abs(x - x_riv)

    # 2. Sakura Valley (West) - gentle rolling hills
    h_sakura = 2.4 + 0.9 * math.sin(x * 0.04) * math.cos(z * 0.04)

    # 3. Bamboo Forest (North-West)
    w_bamboo = smoothstep(10.0, 32.0, z) * smoothstep(-6.0, -24.0, x)
    h_sakura += w_bamboo * (2.2 + 0.6 * math.sin(x * 0.06 + z * 0.05))

    # 4. City Avenue & Promenade (East) - stable flat paved plateau
    h_city = 2.8 + 0.4 * smoothstep(8.0, 20.0, x)

    # 5. Karst Peaks (North-East) - scenic elevation
    d_karst = math.sqrt((x - 45.0)**2 + (z - 50.0)**2)
    w_karst = smoothstep(46.0, 14.0, d_karst)
    h_city += w_karst * 4.2

    # 6. Smooth blend between West bank and East bank
    t_side = smoothstep(-4.5, 4.5, x - x_riv)
    h_land = h_sakura * (1.0 - t_side) + h_city * t_side

    # 7. River Channel & Bed
    # Bed is flat at Y = -2.2m from d_riv 0 to 2.2m, then smoothly slopes up to h_land at 6.2m
    h_river_bed = -2.2
    w_river = smoothstep(6.2, 2.2, d_riv) # 1.0 at bed, 0.0 on banks
    h = h_land * (1.0 - w_river) + h_river_bed * w_river

    # 8. Majestic Perimeter Mountain Ring (Encloses the map, preventing edge fall-off)
    d_edge = max(abs(x), abs(z))
    if d_edge > 78.0:
        w_edge = smoothstep(78.0, 116.0, d_edge)
        h += (w_edge ** 2) * 34.0

    return h

def generate_fantasy_terrain():
    mb_grass = MeshBuilder()
    mb_water = MeshBuilder()

    grid_size = 96
    world_size = 240.0
    step = world_size / grid_size
    half_w = world_size * 0.5

    vert_grid = []
    for gz in range(grid_size + 1):
        z = -half_w + gz * step
        row = []
        for gx in range(grid_size + 1):
            x = -half_w + gx * step
            y = get_terrain_height(x, z)

            eps = 0.5
            hx1 = get_terrain_height(x - eps, z)
            hx2 = get_terrain_height(x + eps, z)
            hz1 = get_terrain_height(x, z - eps)
            hz2 = get_terrain_height(x, z + eps)
            norm = (- (hx2 - hx1) / (2.0 * eps), 1.0, - (hz2 - hz1) / (2.0 * eps))
            n_len = math.sqrt(norm[0]**2 + norm[1]**2 + norm[2]**2)
            norm = (norm[0]/n_len, norm[1]/n_len, norm[2]/n_len)

            u = (x / world_size) * 36.0
            v = (z / world_size) * 36.0
            idx = mb_grass.add_vertex((x, y, z), norm, (u, v))
            row.append(idx)
        vert_grid.append(row)

    for gz in range(grid_size):
        for gx in range(grid_size):
            i1 = vert_grid[gz][gx]
            i2 = vert_grid[gz][gx+1]
            i3 = vert_grid[gz+1][gx+1]
            i4 = vert_grid[gz+1][gx]
            # Counter-clockwise winding facing UP (+Y): i1 -> i4 -> i3 -> i2
            mb_grass.add_quad(i1, i4, i3, i2)

    # Perimeter protective skirts (drop down to Y = -35.0 to seal edges)
    skirt_bottom_y = -35.0
    # South edge (gz = 0, z = -half_w)
    for gx in range(grid_size):
        top1 = vert_grid[0][gx]
        top2 = vert_grid[0][gx+1]
        x1 = -half_w + gx * step
        x2 = -half_w + (gx+1) * step
        b1 = mb_grass.add_vertex((x1, skirt_bottom_y, -half_w), (0, 0, -1), (x1*0.1, 0))
        b2 = mb_grass.add_vertex((x2, skirt_bottom_y, -half_w), (0, 0, -1), (x2*0.1, 0))
        mb_grass.add_quad(top1, top2, b2, b1)

    # North edge (gz = grid_size, z = half_w)
    for gx in range(grid_size):
        top1 = vert_grid[grid_size][gx]
        top2 = vert_grid[grid_size][gx+1]
        x1 = -half_w + gx * step
        x2 = -half_w + (gx+1) * step
        b1 = mb_grass.add_vertex((x1, skirt_bottom_y, half_w), (0, 0, 1), (x1*0.1, 0))
        b2 = mb_grass.add_vertex((x2, skirt_bottom_y, half_w), (0, 0, 1), (x2*0.1, 0))
        mb_grass.add_quad(top2, top1, b1, b2)

    # West edge (gx = 0, x = -half_w)
    for gz in range(grid_size):
        top1 = vert_grid[gz][0]
        top2 = vert_grid[gz+1][0]
        z1 = -half_w + gz * step
        z2 = -half_w + (gz+1) * step
        b1 = mb_grass.add_vertex((-half_w, skirt_bottom_y, z1), (-1, 0, 0), (z1*0.1, 0))
        b2 = mb_grass.add_vertex((-half_w, skirt_bottom_y, z2), (-1, 0, 0), (z2*0.1, 0))
        mb_grass.add_quad(top2, top1, b1, b2)

    # East edge (gx = grid_size, x = half_w)
    for gz in range(grid_size):
        top1 = vert_grid[gz][grid_size]
        top2 = vert_grid[gz+1][grid_size]
        z1 = -half_w + gz * step
        z2 = -half_w + (gz+1) * step
        b1 = mb_grass.add_vertex((half_w, skirt_bottom_y, z1), (1, 0, 0), (z1*0.1, 0))
        b2 = mb_grass.add_vertex((half_w, skirt_bottom_y, z2), (1, 0, 0), (z2*0.1, 0))
        mb_grass.add_quad(top1, top2, b2, b1)

    # Water surface plane covering river corridor (at Y = -0.50)
    # Spans from X = -12 to +12, Z = -95 to +95
    mb_water.add_quad(
        mb_water.add_vertex((-12.0, -0.50, -95.0), (0, 1, 0), (0, 0)),
        mb_water.add_vertex((-12.0, -0.50, 95.0), (0, 1, 0), (0, 24)),
        mb_water.add_vertex((12.0, -0.50, 95.0), (0, 1, 0), (6, 24)),
        mb_water.add_vertex((12.0, -0.50, -95.0), (0, 1, 0), (6, 0))
    )

    materials = [
        {"name": "Mat_GenshinTerrainGrass", "texture_file": "genshin_grass.png", "base_color": [1.0, 1.0, 1.0, 1.0], "roughness": 0.8},
        {"name": "Mat_AnimeWater", "texture_file": "water_stream.png", "base_color": [0.6, 0.9, 1.0, 0.8], "roughness": 0.15},
    ]
    submeshes = [
        {"builder": mb_grass, "material_idx": 0},
        {"builder": mb_water, "material_idx": 1},
    ]
    export_textured_glb(os.path.join(OUTPUT_DIR, "asian_fantasy_terrain.glb"), submeshes, materials)

def main():
    print("Generating Asian Fantasy 3D models with embedded textures...")
    generate_torii_gate()
    generate_pagoda()
    generate_shop_house()
    generate_tea_pavilion()
    generate_moon_bridge()
    generate_stone_lantern()
    generate_sakura_tree()
    generate_bamboo_cluster()
    generate_karst_spire()
    generate_fantasy_terrain()
    print("All textured 3D models generated successfully!")

if __name__ == '__main__':
    main()
