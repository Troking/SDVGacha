import os
import math
import struct
import json
import numpy as np

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/models"
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
            ([(cx-sx, cy-sy, cz+sz), (cx+sx, cy-sy, cz+sz), (cx+sx, cy+sy, cz+sz), (cx-sx, cy+sy, cz+sz)], (0, 0, 1)),
            ([(cx+sx, cy-sy, cz-sz), (cx-sx, cy-sy, cz-sz), (cx-sx, cy+sy, cz-sz), (cx+sx, cy+sy, cz-sz)], (0, 0, -1)),
            ([(cx-sx, cy+sy, cz+sz), (cx+sx, cy+sy, cz+sz), (cx+sx, cy+sy, cz-sz), (cx-sx, cy+sy, cz-sz)], (0, 1, 0)),
            ([(cx-sx, cy-sy, cz-sz), (cx+sx, cy-sy, cz-sz), (cx+sx, cy-sy, cz+sz), (cx-sx, cy-sy, cz+sz)], (0, -1, 0)),
            ([(cx+sx, cy-sy, cz+sz), (cx+sx, cy-sy, cz-sz), (cx+sx, cy+sy, cz-sz), (cx+sx, cy+sy, cz+sz)], (1, 0, 0)),
            ([(cx-sx, cy-sy, cz-sz), (cx-sx, cy-sy, cz+sz), (cx-sx, cy+sy, cz+sz), (cx-sx, cy+sy, cz-sz)], (-1, 0, 0)),
        ]
        for quad_verts, norm in faces:
            uvs = [(0, 0), (u_s, 0), (u_s, v_s), (0, v_s)]
            idx = [self.add_vertex(p, norm, uv) for p, uv in zip(quad_verts, uvs)]
            self.add_quad(idx[0], idx[1], idx[2], idx[3])

    def add_cylinder(self, bot_center, top_center, r_bot, r_top, segments=16):
        bx, by, bz = bot_center
        tx, ty, tz = top_center
        dx, dy, dz = tx - bx, ty - by, tz - bz
        length = math.sqrt(dx*dx + dy*dy + dz*dz)
        if length < 0.0001:
            return

        bot_indices = []
        top_indices = []
        for i in range(segments + 1):
            theta = 2.0 * math.pi * (i % segments) / segments
            ct = math.cos(theta)
            st = math.sin(theta)
            norm = (ct, 0.0, st)
            u = float(i) / segments

            b_pt = (bx + ct * r_bot, by, bz + st * r_bot)
            t_pt = (tx + ct * r_top, ty, tz + st * r_top)

            bot_indices.append(self.add_vertex(b_pt, norm, (u, 0.0)))
            top_indices.append(self.add_vertex(t_pt, norm, (u, 1.0)))

        for i in range(segments):
            b1, b2 = bot_indices[i], bot_indices[i+1]
            t1, t2 = top_indices[i], top_indices[i+1]
            self.add_quad(b1, b2, t2, t1)

def export_glb(filename, submeshes, materials_spec):
    bin_data = bytearray()
    buffer_views = []
    accessors = []
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
        bv = {"buffer": 0, "byteOffset": offset, "byteLength": len(data_bytes)}
        if target is not None:
            bv["target"] = target
        buffer_views.append(bv)
        return bv_idx

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
        materials.append(mat_entry)

    for mb, mat_idx in submeshes:
        if not mb.positions or not mb.indices:
            continue
        pos_np = np.array(mb.positions, dtype=np.float32)
        norm_np = np.array(mb.normals, dtype=np.float32)
        uv_np = np.array(mb.uvs, dtype=np.float32)
        idx_np = np.array(mb.indices, dtype=np.uint32)

        min_pos = pos_np.min(axis=0).tolist()
        max_pos = pos_np.max(axis=0).tolist()

        bv_pos = add_buffer(pos_np.tobytes(), 34962)
        acc_pos = len(accessors)
        accessors.append({"bufferView": bv_pos, "byteOffset": 0, "componentType": 5126, "count": len(pos_np), "type": "VEC3", "min": min_pos, "max": max_pos})

        bv_norm = add_buffer(norm_np.tobytes(), 34962)
        acc_norm = len(accessors)
        accessors.append({"bufferView": bv_norm, "byteOffset": 0, "componentType": 5126, "count": len(norm_np), "type": "VEC3"})

        bv_uv = add_buffer(uv_np.tobytes(), 34962)
        acc_uv = len(accessors)
        accessors.append({"bufferView": bv_uv, "byteOffset": 0, "componentType": 5126, "count": len(uv_np), "type": "VEC2"})

        bv_idx = add_buffer(idx_np.tobytes(), 34963)
        acc_idx = len(accessors)
        accessors.append({"bufferView": bv_idx, "byteOffset": 0, "componentType": 5125, "count": len(idx_np), "type": "SCALAR"})

        meshes_primitives.append({
            "attributes": {"POSITION": acc_pos, "NORMAL": acc_norm, "TEXCOORD_0": acc_uv},
            "indices": acc_idx,
            "material": mat_idx
        })

    gltf = {
        "asset": {"version": "2.0", "generator": "EllenAndZonesModelGen"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "RootNode", "mesh": 0}],
        "meshes": [{"name": "CombinedMesh", "primitives": meshes_primitives}],
        "materials": materials,
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(bin_data)}]
    }

    json_bytes = json.dumps(gltf, separators=(',', ':')).encode('utf-8')
    pad = (4 - (len(json_bytes) % 4)) % 4
    if pad:
        json_bytes += b' ' * pad

    pad_bin = (4 - (len(bin_data) % 4)) % 4
    if pad_bin:
        bin_data.extend(b'\x00' * pad_bin)

    total_len = 12 + 8 + len(json_bytes) + 8 + len(bin_data)
    header = struct.pack('<4sII', b'glTF', 2, total_len)
    chunk0 = struct.pack('<II', len(json_bytes), 0x4E4F534A) + json_bytes
    chunk1 = struct.pack('<II', len(bin_data), 0x004E4942) + bin_data

    with open(filename, 'wb') as f:
        f.write(header)
        f.write(chunk0)
        f.write(chunk1)
    print(f"Exported: {filename} ({total_len} bytes)")

# ==================== 1. ELLEN JOE SHARK TAIL ====================
def generate_ellen_shark_tail():
    mb_tail = MeshBuilder()  # Sleek dark slate shark skin
    mb_fin = MeshBuilder()   # Dorsal fin and caudal tail flukes

    # Smooth tapering shark tail curving backward and slightly downward
    segments = 8
    length = 0.85
    r_base_w = 0.14
    r_base_h = 0.12

    prev_ring = None
    for s in range(segments + 1):
        t = float(s) / segments
        cz = -t * length
        cy = -0.06 * math.sin(t * math.pi) * 0.8 - 0.08 * (t ** 1.8)
        cx = 0.0

        taper = (1.0 - t * 0.72)
        rw = r_base_w * taper
        rh = r_base_h * taper

        ring_pts = []
        for i in range(13):
            theta = 2.0 * math.pi * (i % 12) / 12.0
            x = cx + math.cos(theta) * rw
            y = cy + math.sin(theta) * rh
            z = cz
            norm = (math.cos(theta), math.sin(theta), 0.2 * t)
            norm_mag = math.sqrt(norm[0]**2 + norm[1]**2 + norm[2]**2)
            norm = (norm[0]/norm_mag, norm[1]/norm_mag, norm[2]/norm_mag)
            u = float(i) / 12.0
            v = t
            v_idx = mb_tail.add_vertex((x, y, z), norm, (u, v))
            ring_pts.append(v_idx)

        if prev_ring:
            for i in range(12):
                mb_tail.add_quad(prev_ring[i], prev_ring[i+1], ring_pts[i+1], ring_pts[i])
        prev_ring = ring_pts

    # 1. Prominent Shark Dorsal Fin on top mid-tail (s ~ 3 to 5)
    mb_fin.add_box((0.0, 0.09, -0.34), (0.025, 0.18, 0.22))

    # 2. Large Iconic Shark Caudal Tail Fluke (heterocercal double fin)
    mb_fin.add_box((0.0, 0.10, -length - 0.08), (0.022, 0.26, 0.18))
    mb_fin.add_box((0.0, -0.09, -length - 0.06), (0.022, 0.16, 0.14))

    mats = [
        {"name": "Mat_SharkSkin", "base_color": [0.12, 0.13, 0.17, 1.0], "roughness": 0.35, "metallic": 0.1},
        {"name": "Mat_SharkFin", "base_color": [0.09, 0.10, 0.14, 1.0], "roughness": 0.3, "metallic": 0.2}
    ]
    export_glb(os.path.join(OUTPUT_DIR, "ellen_shark_tail.glb"), [(mb_tail, 0), (mb_fin, 1)], mats)

# ==================== 2. ELLEN JOE SHARK SHEARS WEAPON ====================
def generate_ellen_shark_shears():
    mb_steel = MeshBuilder()  # Silver-chrome razor blades
    mb_black = MeshBuilder()  # Dark matte handles / frame
    mb_glow = MeshBuilder()   # Glowing cyan ice conduits

    # Massive Victoria Housekeeping Maid Shark Shears / Scissors (Length ~ 1.2m)
    # Handle grips (dual loops)
    mb_black.add_box((0.08, -0.32, 0.0), (0.06, 0.16, 0.05))
    mb_black.add_box((-0.08, -0.32, 0.0), (0.06, 0.16, 0.05))
    mb_black.add_box((0.0, -0.20, 0.0), (0.22, 0.06, 0.06))

    # Central pivot bolt / shark crest
    mb_black.add_cylinder((0.0, -0.05, -0.04), (0.0, -0.05, 0.04), 0.07, 0.07, 16)
    mb_glow.add_cylinder((0.0, -0.05, -0.045), (0.0, -0.05, 0.045), 0.045, 0.045, 12)

    # Scissor Blade Left (Scalloped shark tooth edge)
    mb_steel.add_box((0.055, 0.42, 0.0), (0.04, 0.88, 0.025))
    # Beveled cutting edge
    mb_steel.add_box((0.08, 0.42, 0.0), (0.025, 0.84, 0.015))

    # Scissor Blade Right (Opposing shark shear)
    mb_steel.add_box((-0.055, 0.42, 0.0), (0.04, 0.88, 0.025))
    mb_steel.add_box((-0.08, 0.42, 0.0), (0.025, 0.84, 0.015))

    # Glowing Cyan Ice Conduit Running Along Blade Spine
    mb_glow.add_box((0.04, 0.44, 0.015), (0.015, 0.72, 0.01))
    mb_glow.add_box((-0.04, 0.44, 0.015), (0.015, 0.72, 0.01))

    mats = [
        {"name": "Mat_ShearSteel", "base_color": [0.88, 0.92, 0.98, 1.0], "roughness": 0.15, "metallic": 0.92},
        {"name": "Mat_ShearChassis", "base_color": [0.10, 0.10, 0.12, 1.0], "roughness": 0.4, "metallic": 0.4},
        {"name": "Mat_IceConduit", "base_color": [0.2, 0.85, 1.0, 1.0], "roughness": 0.2, "metallic": 0.0, "emissive": [0.3, 0.9, 1.2]}
    ]
    export_glb(os.path.join(OUTPUT_DIR, "ellen_shark_shears.glb"), [(mb_steel, 0), (mb_black, 1), (mb_glow, 2)], mats)

# ==================== 3. BLIGHTED UNDEAD PROPS ====================
def generate_undead_props():
    # 1. Crypt Tomb / Sarcophagus
    mb_stone = MeshBuilder()
    mb_rune = MeshBuilder()

    # Heavy crypt plinth
    mb_stone.add_box((0.0, 0.35, 0.0), (2.4, 0.7, 1.4))
    # Ornate bevelled tomb lid (slightly cracked open)
    mb_stone.add_box((0.0, 0.78, 0.05), (2.55, 0.18, 1.55))
    # Necrotic rune seal
    mb_rune.add_box((0.0, 0.88, 0.05), (1.4, 0.03, 0.6))

    mats_tomb = [
        {"name": "Mat_CryptStone", "base_color": [0.22, 0.20, 0.26, 1.0], "roughness": 0.85, "metallic": 0.05},
        {"name": "Mat_NecroticRune", "base_color": [0.35, 0.95, 0.45, 1.0], "roughness": 0.3, "emissive": [0.4, 1.2, 0.5]}
    ]
    export_glb(os.path.join(OUTPUT_DIR, "undead_crypt_tomb.glb"), [(mb_stone, 0), (mb_rune, 1)], mats_tomb)

    # 2. Corrupted Bone Spire
    mb_bone = MeshBuilder()
    mb_vein = MeshBuilder()

    # Twisted bone monolith pillar tapering to a sharp claw
    mb_bone.add_cylinder((0.0, 0.0, 0.0), (0.0, 2.5, 0.0), 0.75, 0.52, 10)
    mb_bone.add_cylinder((0.0, 2.5, 0.0), (0.15, 5.2, -0.1), 0.52, 0.28, 8)
    mb_bone.add_cylinder((0.15, 5.2, -0.1), (0.35, 7.8, -0.25), 0.28, 0.06, 6)

    # Curving rib claws jutting from the sides
    for side in [-1, 1]:
        mb_bone.add_box((side * 0.85, 2.8, 0.1), (0.7, 0.18, 0.25))
        mb_bone.add_box((side * 1.25, 3.4, 0.1), (0.6, 0.14, 0.22))
        mb_bone.add_box((side * 0.75, 4.2, -0.1), (0.5, 0.12, 0.20))

    # Cursed Purple Blight Veins
    mb_vein.add_box((0.0, 3.0, 0.35), (0.22, 4.5, 0.1))

    mats_bone = [
        {"name": "Mat_CursedBone", "base_color": [0.68, 0.65, 0.60, 1.0], "roughness": 0.65, "metallic": 0.1},
        {"name": "Mat_BlightVein", "base_color": [0.65, 0.15, 0.85, 1.0], "roughness": 0.3, "emissive": [0.8, 0.2, 1.1]}
    ]
    export_glb(os.path.join(OUTPUT_DIR, "undead_bone_spire.glb"), [(mb_bone, 0), (mb_vein, 1)], mats_bone)

# ==================== 4. CYBER CITY PROPS ====================
def generate_cyber_props():
    # 1. Cyber Skyscraper Tower
    mb_dark = MeshBuilder()
    mb_neon = MeshBuilder()
    mb_holo = MeshBuilder()

    # Tower base
    mb_dark.add_box((0.0, 4.0, 0.0), (6.0, 8.0, 6.0))
    # Mid spire tier
    mb_dark.add_box((0.0, 12.0, 0.0), (4.8, 8.0, 4.8))
    # High tech antenna crown
    mb_dark.add_box((0.0, 19.0, 0.0), (3.2, 6.0, 3.2))
    mb_dark.add_cylinder((0.0, 22.0, 0.0), (0.0, 28.0, 0.0), 0.25, 0.05, 8)

    # Vertical Neon Conduits (Cyan and Magenta)
    for x_s in [-2.45, 2.45]:
        mb_neon.add_box((x_s, 11.0, 2.45), (0.12, 21.0, 0.12))
        mb_neon.add_box((x_s, 11.0, -2.45), (0.12, 21.0, 0.12))

    # Large Neon Hologram Billboard Panel on tower front
    mb_holo.add_box((0.0, 12.0, 2.5), (3.8, 4.2, 0.08))

    mats_tower = [
        {"name": "Mat_CyberDarkAlloy", "base_color": [0.08, 0.09, 0.12, 1.0], "roughness": 0.28, "metallic": 0.85},
        {"name": "Mat_NeonCyan", "base_color": [0.0, 0.95, 1.0, 1.0], "roughness": 0.15, "emissive": [0.0, 1.5, 1.8]},
        {"name": "Mat_HoloPanel", "base_color": [0.95, 0.10, 0.65, 0.85], "roughness": 0.2, "emissive": [1.5, 0.15, 0.9]}
    ]
    export_glb(os.path.join(OUTPUT_DIR, "cyber_skyscraper_tower.glb"), [(mb_dark, 0), (mb_neon, 1), (mb_holo, 2)], mats_tower)

    # 2. Cyber Street Light & Data Conduit Arch
    mb_pole = MeshBuilder()
    mb_beam = MeshBuilder()

    # Sleek angled cyber pole
    mb_pole.add_box((0.0, 2.2, 0.0), (0.22, 4.4, 0.22))
    mb_pole.add_box((0.65, 4.3, 0.0), (1.1, 0.16, 0.20))
    # Glowing neon lamp head
    mb_beam.add_box((1.15, 4.15, 0.0), (0.45, 0.12, 0.26))

    mats_pole = [
        {"name": "Mat_PoleChassis", "base_color": [0.12, 0.14, 0.18, 1.0], "roughness": 0.35, "metallic": 0.8},
        {"name": "Mat_NeonBeam", "base_color": [0.0, 0.9, 1.0, 1.0], "roughness": 0.1, "emissive": [0.0, 1.8, 2.2]}
    ]
    export_glb(os.path.join(OUTPUT_DIR, "cyber_street_lamp.glb"), [(mb_pole, 0), (mb_beam, 1)], mats_pole)

if __name__ == "__main__":
    generate_ellen_shark_tail()
    generate_ellen_shark_shears()
    generate_undead_props()
    generate_cyber_props()
    print("All models successfully built!")
