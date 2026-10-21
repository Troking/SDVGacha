import os
import math
import struct
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_MODELS = "e:/Trok/ChibiRPG_Project/game/assets/models"
OUTPUT_TEXTURES = "e:/Trok/ChibiRPG_Project/game/assets/textures"
os.makedirs(OUTPUT_MODELS, exist_ok=True)
os.makedirs(OUTPUT_TEXTURES, exist_ok=True)

class GLBBuilder:
    def __init__(self):
        self.submeshes = [] # list of (positions, normals, uvs, indices, mat_idx)
        self.materials = []

    def add_material(self, name, base_color=(1.0, 1.0, 1.0, 1.0), roughness=0.5, metallic=0.0, emissive=None):
        mat_entry = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": list(base_color),
                "roughnessFactor": roughness,
                "metallicFactor": metallic
            }
        }
        if emissive:
            mat_entry["emissiveFactor"] = list(emissive)
        idx = len(self.materials)
        self.materials.append(mat_entry)
        return idx

    def add_mesh_part(self, positions, normals, uvs, indices, mat_idx):
        self.submeshes.append({
            "positions": positions,
            "normals": normals,
            "uvs": uvs,
            "indices": indices,
            "mat_idx": mat_idx
        })

    def export(self, filename):
        bin_data = bytearray()
        buffer_views = []
        accessors = []
        primitives = []

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

        for sm in self.submeshes:
            pos_np = np.array(sm["positions"], dtype=np.float32)
            norm_np = np.array(sm["normals"], dtype=np.float32)
            uv_np = np.array(sm["uvs"], dtype=np.float32)
            idx_np = np.array(sm["indices"], dtype=np.uint32)

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

            primitives.append({
                "attributes": {"POSITION": acc_pos, "NORMAL": acc_norm, "TEXCOORD_0": acc_uv},
                "indices": acc_idx,
                "material": sm["mat_idx"]
            })

        gltf = {
            "asset": {"version": "2.0", "generator": "EllenAuthenticAssets"},
            "scene": 0,
            "scenes": [{"nodes": [0]}],
            "nodes": [{"name": "RootNode", "mesh": 0}],
            "meshes": [{"name": "CombinedMesh", "primitives": primitives}],
            "materials": self.materials,
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

# ==================== 1. SCULPT ELLEN'S MAGNIFICENT SHARK TAIL ====================
def build_shark_tail():
    glb = GLBBuilder()

    # Materials
    m_upper = glb.add_material("Mat_SharkUpperSkin", [0.15, 0.17, 0.22, 1.0], roughness=0.32, metallic=0.12)
    m_belly = glb.add_material("Mat_SharkBelly", [0.92, 0.94, 0.96, 1.0], roughness=0.38, metallic=0.04)
    m_fin = glb.add_material("Mat_SharkFin", [0.12, 0.14, 0.18, 1.0], roughness=0.28, metallic=0.18)
    m_harness = glb.add_material("Mat_HarnessLeather", [0.08, 0.08, 0.10, 1.0], roughness=0.45, metallic=0.10)
    m_buckle = glb.add_material("Mat_SilverBuckle", [0.85, 0.88, 0.95, 1.0], roughness=0.18, metallic=0.92)
    m_led = glb.add_material("Mat_RedLED", [1.0, 0.15, 0.22, 1.0], roughness=0.20, metallic=0.1, emissive=[1.5, 0.15, 0.25])

    # 1. Main organic shark tail body (Smooth multi-ring extrusion)
    # The tail starts at the lower back (0, 0, 0) pointing along -Z (behind the character).
    # It gracefully arcs downwards, then sweeps backwards and curls upwards towards the caudal fin.
    num_rings = 22
    segs_per_ring = 20
    length = 1.15
    base_rw = 0.22
    base_rh = 0.18

    # Generate ring centers and radii
    centers = []
    radii_w = []
    radii_h = []
    for r in range(num_rings):
        t = float(r) / (num_rings - 1)
        # S-curve: drops down slightly, sweeps back, curves up at the tail peduncle
        z = -t * length
        y = -0.12 * math.sin(t * math.pi * 0.9) - 0.05 * t + 0.14 * (t ** 2.2)
        x = 0.04 * math.sin(t * math.pi) # Gentle natural body sway
        rw = base_rw * (1.0 - t * 0.76)
        rh = base_rh * (1.0 - t * 0.72)
        centers.append((x, y, z))
        radii_w.append(rw)
        radii_h.append(rh)

    # Vertices, Normals, UVs for Upper Skin and Belly
    upper_pos, upper_norm, upper_uv, upper_idx = [], [], [], []
    belly_pos, belly_norm, belly_uv, belly_idx = [], [], [], []

    # Build vertex grid
    grid = []
    for r in range(num_rings):
        cx, cy, cz = centers[r]
        rw = radii_w[r]
        rh = radii_h[r]
        ring_v = []
        for s in range(segs_per_ring):
            theta = 2.0 * math.pi * float(s) / segs_per_ring
            # Elliptical cross section
            # theta = 0: top (+Y), theta = pi/2: right (+X), theta = pi: bottom (-Y), theta = 3pi/2: left (-X)
            # Adjust theta so 0 is right, pi/2 is top, pi is left, 3pi/2 is bottom
            vx = cx + math.cos(theta) * rw
            vy = cy + math.sin(theta) * rh
            vz = cz

            # Normal vector from center
            nx = math.cos(theta)
            ny = math.sin(theta)
            nz = -0.15 # slight backward taper angle
            n_len = math.sqrt(nx*nx + ny*ny + nz*nz)
            norm = (nx/n_len, ny/n_len, nz/n_len)

            u = float(s) / segs_per_ring
            v = float(r) / (num_rings - 1)
            is_belly = (theta > math.pi * 1.1 and theta < math.pi * 1.9)
            ring_v.append((vx, vy, vz, norm[0], norm[1], norm[2], u, v, is_belly))
        grid.append(ring_v)

    # Triangulate grid into upper skin and belly meshes
    for r in range(num_rings - 1):
        for s in range(segs_per_ring):
            s_next = (s + 1) % segs_per_ring
            v0 = grid[r][s]
            v1 = grid[r][s_next]
            v2 = grid[r+1][s_next]
            v3 = grid[r+1][s]

            is_belly_quad = v0[8] or v1[8] or v2[8] or v3[8]
            target_pos = belly_pos if is_belly_quad else upper_pos
            target_norm = belly_norm if is_belly_quad else upper_norm
            target_uv = belly_uv if is_belly_quad else upper_uv
            target_idx = belly_idx if is_belly_quad else upper_idx

            base_i = len(target_pos)
            for v in [v0, v1, v2, v3]:
                target_pos.append([v[0], v[1], v[2]])
                target_norm.append([v[3], v[4], v[5]])
                target_uv.append([v[6], v[7]])
            target_idx.extend([base_i, base_i+1, base_i+2, base_i, base_i+2, base_i+3])

    glb.add_mesh_part(upper_pos, upper_norm, upper_uv, upper_idx, m_upper)
    glb.add_mesh_part(belly_pos, belly_norm, belly_uv, belly_idx, m_belly)

    # 2. Mid-tail Iconic Shark Dorsal Fin
    # Attached along the upper spine around r = 7..13
    fin_pos, fin_norm, fin_uv, fin_idx = [], [], [], []
    def add_dorsal_fin():
        # Sculpted swept-back dorsal fin with sharp leading edge and curved trailing notch
        c_mid = centers[9]
        z_base = c_mid[2]
        y_base = c_mid[1] + radii_h[9] * 0.95

        verts = [
            # Base front, base back, tip, notch
            [-0.012, y_base, z_base + 0.12], # 0
            [ 0.012, y_base, z_base + 0.12], # 1
            [-0.010, y_base, z_base - 0.22], # 2
            [ 0.010, y_base, z_base - 0.22], # 3
            [-0.004, y_base + 0.24, z_base - 0.14], # 4 (Tip)
            [ 0.004, y_base + 0.24, z_base - 0.14], # 5 (Tip)
            [-0.006, y_base + 0.06, z_base - 0.17], # 6 (Trailing notch)
            [ 0.006, y_base + 0.06, z_base - 0.17], # 7 (Trailing notch)
        ]
        base_i = len(fin_pos)
        for v in verts:
            fin_pos.append(v)
            fin_norm.append([1.0 if v[0] > 0 else -1.0, 0.4, 0.0])
            fin_uv.append([0.5 + v[0]*10, (v[1] - y_base) * 3.5])

        # Left flank: 0, 4, 6, 2
        fin_idx.extend([base_i+0, base_i+4, base_i+6, base_i+0, base_i+6, base_i+2])
        # Right flank: 1, 3, 7, 5
        fin_idx.extend([base_i+1, base_i+7, base_i+5, base_i+1, base_i+3, base_i+7])
        # Leading edge cap: 0, 1, 5, 4
        fin_idx.extend([base_i+0, base_i+5, base_i+1, base_i+0, base_i+4, base_i+5])
        # Trailing edge notch: 4, 5, 7, 6 and 6, 7, 3, 2
        fin_idx.extend([base_i+4, base_i+7, base_i+5, base_i+4, base_i+6, base_i+7])
        fin_idx.extend([base_i+6, base_i+3, base_i+7, base_i+6, base_i+2, base_i+3])

    add_dorsal_fin()

    # 3. Massive Caudal Tail Fluke (Heterocercal Shark Tail at tip)
    def add_caudal_fin():
        c_tip = centers[-1]
        z_tip = c_tip[2]
        y_tip = c_tip[1]

        # Top lobe (large, swept-back, pointed), bottom lobe (shorter, predatory), center notch
        caudal_verts = [
            # Peduncle base left/right
            [-0.012, y_tip + 0.03, z_tip],     # 0
            [ 0.012, y_tip + 0.03, z_tip],     # 1
            [-0.012, y_tip - 0.03, z_tip],     # 2
            [ 0.012, y_tip - 0.03, z_tip],     # 3
            # Upper lobe tip (long, pointed, high angle)
            [-0.003, y_tip + 0.32, z_tip - 0.24], # 4
            [ 0.003, y_tip + 0.32, z_tip - 0.24], # 5
            # Sub-terminal notch on upper lobe
            [-0.004, y_tip + 0.22, z_tip - 0.21], # 6
            [ 0.004, y_tip + 0.22, z_tip - 0.21], # 7
            # Caudal center notch / fork
            [-0.006, y_tip + 0.02, z_tip - 0.14], # 8
            [ 0.006, y_tip + 0.02, z_tip - 0.14], # 9
            # Lower lobe tip
            [-0.003, y_tip - 0.18, z_tip - 0.16], # 10
            [ 0.003, y_tip - 0.18, z_tip - 0.16], # 11
        ]
        base_i = len(fin_pos)
        for v in caudal_verts:
            fin_pos.append(v)
            fin_norm.append([1.0 if v[0] > 0 else -1.0, 0.2, -0.3])
            fin_uv.append([0.5 + v[0]*15, (v[1] - y_tip + 0.2) * 2.0])

        # Upper lobe left side: (0, 4, 6), (0, 6, 8)
        fin_idx.extend([base_i+0, base_i+4, base_i+6, base_i+0, base_i+6, base_i+8])
        # Upper lobe right side: (1, 7, 5), (1, 9, 7)
        fin_idx.extend([base_i+1, base_i+7, base_i+5, base_i+1, base_i+9, base_i+7])
        # Lower lobe left side: (2, 8, 10)
        fin_idx.extend([base_i+2, base_i+8, base_i+10])
        # Lower lobe right side: (3, 11, 9)
        fin_idx.extend([base_i+3, base_i+11, base_i+9])
        # Leading edge top: (0, 1, 5, 4)
        fin_idx.extend([base_i+0, base_i+5, base_i+1, base_i+0, base_i+4, base_i+5])
        # Leading edge bottom: (2, 3, 11, 10)
        fin_idx.extend([base_i+2, base_i+3, base_i+11, base_i+2, base_i+11, base_i+10])
        # Trailing notch: (4, 5, 7, 6), (6, 7, 9, 8), (8, 9, 11, 10)
        fin_idx.extend([base_i+4, base_i+7, base_i+5, base_i+4, base_i+6, base_i+7])
        fin_idx.extend([base_i+6, base_i+9, base_i+7, base_i+6, base_i+8, base_i+9])
        fin_idx.extend([base_i+8, base_i+11, base_i+9, base_i+8, base_i+10, base_i+11])

    add_caudal_fin()
    glb.add_mesh_part(fin_pos, fin_norm, fin_uv, fin_idx, m_fin)

    # 4. Tactical Leather Harness Straps & Silver Buckles at Base (rings 2 and 4)
    harn_pos, harn_norm, harn_uv, harn_idx = [], [], [], []
    buck_pos, buck_norm, buck_uv, buck_idx = [], [], [], []

    def add_strap(ring_idx, width=0.038):
        cx, cy, cz = centers[ring_idx]
        rw = radii_w[ring_idx] * 1.05
        rh = radii_h[ring_idx] * 1.05

        n_seg = 18
        for i in range(n_seg):
            i_next = (i + 1) % n_seg
            t0 = 2.0 * math.pi * float(i) / n_seg
            t1 = 2.0 * math.pi * float(i_next) / n_seg

            x0, y0 = cx + math.cos(t0) * rw, cy + math.sin(t0) * rh
            x1, y1 = cx + math.cos(t1) * rw, cy + math.sin(t1) * rh

            base_i = len(harn_pos)
            harn_pos.extend([[x0, y0, cz - width*0.5], [x1, y1, cz - width*0.5], [x1, y1, cz + width*0.5], [x0, y0, cz + width*0.5]])
            harn_norm.extend([[math.cos(t0), math.sin(t0), 0], [math.cos(t1), math.sin(t1), 0], [math.cos(t1), math.sin(t1), 0], [math.cos(t0), math.sin(t0), 0]])
            harn_uv.extend([[float(i)/n_seg, 0], [float(i+1)/n_seg, 0], [float(i+1)/n_seg, 1], [float(i)/n_seg, 1]])
            harn_idx.extend([base_i, base_i+1, base_i+2, base_i, base_i+2, base_i+3])

        # Silver Buckle on side (+X)
        bx = cx + rw * 0.98
        by = cy
        bz = cz
        b_base = len(buck_pos)
        # 3D rectangular buckle ring
        buck_pos.extend([
            [bx, by - 0.028, bz - width*0.7], [bx + 0.015, by - 0.028, bz - width*0.7],
            [bx + 0.015, by + 0.028, bz - width*0.7], [bx, by + 0.028, bz - width*0.7],
            [bx, by - 0.028, bz + width*0.7], [bx + 0.015, by - 0.028, bz + width*0.7],
            [bx + 0.015, by + 0.028, bz + width*0.7], [bx, by + 0.028, bz + width*0.7]
        ])
        for _ in range(8):
            buck_norm.append([1.0, 0.0, 0.0])
            buck_uv.append([0.5, 0.5])
        buck_idx.extend([
            b_base+0, b_base+1, b_base+2, b_base+0, b_base+2, b_base+3,
            b_base+4, b_base+6, b_base+5, b_base+4, b_base+7, b_base+6,
            b_base+0, b_base+4, b_base+5, b_base+0, b_base+5, b_base+1,
            b_base+2, b_base+6, b_base+7, b_base+2, b_base+7, b_base+3,
            b_base+1, b_base+5, b_base+6, b_base+1, b_base+6, b_base+2,
            b_base+0, b_base+3, b_base+7, b_base+0, b_base+7, b_base+4
        ])

    add_strap(2, 0.034)
    add_strap(4, 0.030)
    glb.add_mesh_part(harn_pos, harn_norm, harn_uv, harn_idx, m_harness)
    glb.add_mesh_part(buck_pos, buck_norm, buck_uv, buck_idx, m_buckle)

    # 5. Glowing Red LED Warning Stripes along lateral line (r = 5..14)
    led_pos, led_norm, led_uv, led_idx = [], [], [], []
    for side in [-1, 1]:
        for r in range(5, 14, 2):
            cx, cy, cz = centers[r]
            rw = radii_w[r] * 1.02
            # On lateral mid-line
            lx = cx + side * rw
            ly = cy + 0.01
            base_i = len(led_pos)
            w_strip = 0.012
            l_strip = 0.045
            led_pos.extend([
                [lx, ly - w_strip, cz - l_strip*0.5],
                [lx, ly + w_strip, cz - l_strip*0.5],
                [lx, ly + w_strip, cz + l_strip*0.5],
                [lx, ly - w_strip, cz + l_strip*0.5]
            ])
            for _ in range(4):
                led_norm.append([side, 0.2, 0.0])
                led_uv.append([0.5, 0.5])
            if side == 1:
                led_idx.extend([base_i, base_i+1, base_i+2, base_i, base_i+2, base_i+3])
            else:
                led_idx.extend([base_i, base_i+2, base_i+1, base_i, base_i+3, base_i+2])

    glb.add_mesh_part(led_pos, led_norm, led_uv, led_idx, m_led)

    tail_glb_path = os.path.join(OUTPUT_MODELS, "ellen_shark_tail.glb")
    glb.export(tail_glb_path)

# ==================== 2. SCULPT MAID HEADDRESS & SHARK FIN CLIP ====================
def build_maid_headdress():
    glb = GLBBuilder()
    m_lace = glb.add_material("Mat_WhiteLace", [0.96, 0.96, 0.98, 1.0], roughness=0.55, metallic=0.0)
    m_clip = glb.add_material("Mat_SharkFinClip", [0.10, 0.11, 0.15, 1.0], roughness=0.25, metallic=0.35)
    m_ribbon = glb.add_material("Mat_RedRibbon", [0.85, 0.12, 0.20, 1.0], roughness=0.40, metallic=0.05)

    pos_lace, norm_lace, uv_lace, idx_lace = [], [], [], []
    pos_clip, norm_clip, uv_clip, idx_clip = [], [], [], []

    # Curved frilled white lace arching over the head
    # Arch from angle -70 deg to +70 deg over head (radius ~ 0.15m)
    num_pts = 16
    for i in range(num_pts):
        ang0 = -math.pi * 0.38 + (i / float(num_pts)) * math.pi * 0.76
        ang1 = -math.pi * 0.38 + ((i + 1) / float(num_pts)) * math.pi * 0.76

        r_inner = 0.152
        r_outer = 0.185 + 0.012 * math.sin(i * 3.2) # Ruffled frills

        x0_in, y0_in = math.sin(ang0) * r_inner, math.cos(ang0) * r_inner + 1.34
        x1_in, y1_in = math.sin(ang1) * r_inner, math.cos(ang1) * r_inner + 1.34
        x0_out, y0_out = math.sin(ang0) * r_outer, math.cos(ang0) * r_outer + 1.34
        x1_out, y1_out = math.sin(ang1) * r_outer, math.cos(ang1) * r_outer + 1.34

        z = -0.01
        base_i = len(pos_lace)
        pos_lace.extend([[x0_in, y0_in, z - 0.015], [x1_in, y1_in, z - 0.015], [x1_out, y1_out, z + 0.015], [x0_out, y0_out, z + 0.015]])
        for _ in range(4):
            norm_lace.append([0.0, 0.8, 0.6])
            uv_lace.append([float(i)/num_pts, 0.5])
        idx_lace.extend([base_i, base_i+1, base_i+2, base_i, base_i+2, base_i+3])

    glb.add_mesh_part(pos_lace, norm_lace, uv_lace, idx_lace, m_lace)

    # Shark Fin Clip on right side of head (+X ~ 0.14, Y ~ 1.48)
    fx = 0.135
    fy = 1.46
    fz = 0.03
    base_c = len(pos_clip)
    pos_clip.extend([
        [fx - 0.008, fy, fz + 0.04], [fx + 0.008, fy, fz + 0.04], # Base front
        [fx - 0.006, fy, fz - 0.05], [fx + 0.006, fy, fz - 0.05], # Base back
        [fx - 0.002, fy + 0.085, fz - 0.025], [fx + 0.002, fy + 0.085, fz - 0.025], # Fin tip
        [fx - 0.004, fy + 0.025, fz - 0.035], [fx + 0.004, fy + 0.025, fz - 0.035], # Trailing notch
    ])
    for _ in range(8):
        norm_clip.append([1.0, 0.3, 0.0])
        uv_clip.append([0.5, 0.5])

    idx_clip.extend([
        base_c+0, base_c+4, base_c+6, base_c+0, base_c+6, base_c+2,
        base_c+1, base_c+7, base_c+5, base_c+1, base_c+3, base_c+7,
        base_c+0, base_c+5, base_c+1, base_c+0, base_c+4, base_c+5,
        base_c+4, base_c+7, base_c+5, base_c+4, base_c+6, base_c+7,
        base_c+6, base_c+3, base_c+7, base_c+6, base_c+2, base_c+3
    ])
    glb.add_mesh_part(pos_clip, norm_clip, uv_clip, idx_clip, m_clip)

    headdress_glb_path = os.path.join(OUTPUT_MODELS, "ellen_maid_headdress.glb")
    glb.export(headdress_glb_path)

# ==================== 3. GENERATE AUTHENTIC MAID TEXTURES ====================
def build_textures():
    # Load base textures from Hu Tao to retain exact anime UV geometry
    orig_cloth = Image.open("e:/Trok/ChibiRPG_Project/game/assets/models/anime_heroine_rigged_服.png").convert("RGBA")
    orig_hair = Image.open("e:/Trok/ChibiRPG_Project/game/assets/models/anime_heroine_rigged_发.png").convert("RGBA")
    orig_face = Image.open("e:/Trok/ChibiRPG_Project/game/assets/models/anime_heroine_rigged_面.png").convert("RGBA")

    # A. ELLEN'S GOTHIC MAID DRESS (ellen_body_diffuse.png)
    # Start from original cloth to maintain all shading shadows, then transform into maid palette
    cloth_arr = np.array(orig_cloth, dtype=np.float32)

    # 1. Bodice / Vest: Transform dark red/brown coat parts into deep gothic slate charcoal with crisp seams
    # Vest / jacket is at X: 500..850, Y: 0..1000
    w, h = orig_cloth.size
    maid_img = orig_cloth.copy()
    draw = ImageDraw.Draw(maid_img)

    # 1. Crisp White Frilled Maid Collar & Neckline (X: 800..1200, Y: 0..350)
    # Ruffled lace collar
    draw.rectangle([830, 40, 1170, 310], fill=(245, 246, 250, 255))
    # Delicate lace scalloping around collar edges
    for lx in range(830, 1170, 16):
        draw.ellipse([lx - 8, 300, lx + 8, 316], fill=(255, 255, 255, 255))
    # Black satin neck ribbon / bow
    draw.polygon([(1000, 180), (950, 260), (1000, 240), (1050, 260)], fill=(22, 24, 30, 255))
    # Victoria Housekeeping silver pendant
    draw.ellipse([988, 235, 1012, 259], fill=(220, 225, 235, 255))
    draw.ellipse([993, 240, 1007, 254], fill=(80, 210, 255, 255)) # Cyan ice gem

    # 2. Black Fitted Corset / Bodice (X: 520..830, Y: 0..960)
    draw.rectangle([530, 50, 830, 940], fill=(24, 26, 32, 255))
    # Silver zipper down the center
    draw.line([(680, 60), (680, 930)], fill=(195, 200, 210, 255), width=8)
    for zy in range(70, 920, 24):
        draw.line([(674, zy), (686, zy)], fill=(240, 245, 255, 255), width=3)
    # Double-breasted silver buttons
    for by in range(220, 850, 130):
        draw.ellipse([620, by, 642, by + 22], fill=(225, 230, 240, 255))
        draw.ellipse([624, by + 4, 638, by + 18], fill=(160, 165, 175, 255))
        draw.ellipse([718, by, 740, by + 22], fill=(225, 230, 240, 255))
        draw.ellipse([722, by + 4, 736, by + 18], fill=(160, 165, 175, 255))

    # 3. Puffed Sleeves with White Lace Cuffs (X: 200..750, Y: 750..1150)
    # Dark maid puff sleeve
    draw.rectangle([220, 770, 480, 1130], fill=(26, 28, 35, 255))
    # Crisp white frilled lace cuff
    draw.rectangle([220, 1050, 480, 1140], fill=(248, 250, 255, 255))
    for fx in range(220, 480, 18):
        draw.ellipse([fx - 8, 1130, fx + 8, 1150], fill=(255, 255, 255, 255))

    # 4. Pleated Black Maid Skirt & Ruffled Apron (Coat tails region X: 1000..1800, Y: 0..1600)
    # Deep pleated black skirt
    draw.rectangle([1020, 50, 1780, 1580], fill=(22, 24, 30, 255))
    # White ruffled apron overlay
    draw.rectangle([1120, 200, 1680, 1350], fill=(246, 248, 252, 255))
    # Apron scalloped ruffles along hem
    for rx in range(1120, 1680, 24):
        draw.ellipse([rx - 12, 1335, rx + 12, 1365], fill=(255, 255, 255, 255))
    # Apron waist straps & delicate cross lacing
    draw.line([(1140, 220), (1660, 220)], fill=(230, 235, 245, 255), width=16)

    # 5. Sheer Black Fishnet / Diamond-Pattern Stockings over Anime Skin (X: 800..1450, Y: 1600..2048)
    # Fair skin base
    draw.rectangle([820, 1620, 1430, 2030], fill=(248, 218, 205, 255))
    # Sheer dark stocking tint overlay
    stocking_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    st_draw = ImageDraw.Draw(stocking_overlay)
    st_draw.rectangle([820, 1620, 1430, 2030], fill=(25, 22, 32, 185)) # 72% opacity dark tint
    # Diamond / fishnet crisscross lines
    for diag in range(-600, 1600, 36):
        st_draw.line([(820, 1620 + diag), (1430, 1620 + diag + 610)], fill=(45, 40, 55, 120), width=2)
        st_draw.line([(1430, 1620 + diag), (820, 1620 + diag + 610)], fill=(45, 40, 55, 120), width=2)
    # White lace thigh-high garter cuffs
    st_draw.rectangle([820, 1620, 1430, 1670], fill=(255, 255, 255, 255))
    # Red ribbon bows on garters
    st_draw.ellipse([1020, 1630, 1050, 1660], fill=(225, 25, 45, 255))
    st_draw.ellipse([1220, 1630, 1250, 1660], fill=(225, 25, 45, 255))
    maid_img = Image.alpha_composite(maid_img, stocking_overlay)
    draw = ImageDraw.Draw(maid_img)

    # 6. Patent Leather Shoes with Red Inner Soles (X: 0..300, Y: 1400..2048)
    draw.rectangle([10, 1420, 290, 2030], fill=(16, 17, 22, 255))
    # Glossy highlights
    draw.line([(50, 1450), (50, 1980)], fill=(75, 80, 95, 255), width=8)
    # Red sole / heel edge
    draw.rectangle([10, 1980, 290, 2030], fill=(215, 25, 40, 255))

    # 7. Victoria Housekeeping Maid Crest (Replacing Pyro vision at X: 1750..2048, Y: 1100..1400)
    draw.rectangle([1760, 1110, 2030, 1390], fill=(28, 30, 38, 255))
    # Silver shield
    draw.polygon([(1895, 1140), (2000, 1200), (1960, 1350), (1895, 1380), (1830, 1350), (1790, 1200)], fill=(210, 218, 230, 255))
    # Cyan ice core
    draw.polygon([(1895, 1190), (1950, 1230), (1930, 1310), (1895, 1330), (1860, 1310), (1840, 1230)], fill=(70, 215, 255, 255))

    body_out_path = os.path.join(OUTPUT_TEXTURES, "ellen_body_diffuse.png")
    maid_img.save(body_out_path)
    print(f"Exported: {body_out_path}")

    # B. ELLEN'S HAIR: RAVEN BLACK WITH RUBY CRIMSON UNDERSIDE + ALPHA SCISSOR HAT
    hair_arr = np.array(orig_hair, dtype=np.float32)
    hair_img = orig_hair.copy()
    hair_draw = ImageDraw.Draw(hair_img)

    # 1. Hat Visor & Crown Removal (X: 0..1000, Y: 600..1400) -> SET ALPHA TO 0
    # Also talisman and hat flower
    hair_alpha = np.array(hair_img.split()[3])
    # Clear out Hu Tao's hat region so alpha scissor cuts it away completely!
    hair_alpha[620:1380, 0:980] = 0
    # Also clear Hu Tao's long lower twin-tails (Y: 1200..2048, X: 1024..2048) to leave a short/medium layered wolf cut!
    hair_alpha[1180:2048, 1024:2048] = 0

    # 2. Recolor hair to raven-black with midnight blue sheen on top, and fiery ruby crimson on tips/underside
    r_ch, g_ch, b_ch, a_ch = hair_img.split()
    r_arr = np.array(r_ch, dtype=np.float32)
    g_arr = np.array(g_ch, dtype=np.float32)
    b_arr = np.array(b_ch, dtype=np.float32)

    # Dark raven base: scale luminance down to ~ 18-24%
    lum = (r_arr * 0.299 + g_arr * 0.587 + b_arr * 0.114) / 255.0
    # Top hair (bangs and crown): raven black (Color(24, 26, 34))
    r_dark = lum * 55.0 + 12.0
    g_dark = lum * 52.0 + 12.0
    b_dark = lum * 75.0 + 18.0

    # Underside of bangs (Y: 450..650, X: 0..1024): Vibrant crimson red
    crimson_mask = np.zeros_like(lum)
    for y in range(400, 680):
        factor_y = (y - 400) / 280.0
        crimson_mask[y, 0:1024] = factor_y * 0.92

    r_final = r_dark * (1.0 - crimson_mask) + (lum * 140.0 + 115.0) * crimson_mask
    g_final = g_dark * (1.0 - crimson_mask) + (lum * 25.0 + 8.0) * crimson_mask
    b_final = b_dark * (1.0 - crimson_mask) + (lum * 35.0 + 12.0) * crimson_mask

    r_final = np.clip(r_final, 0, 255).astype(np.uint8)
    g_final = np.clip(g_final, 0, 255).astype(np.uint8)
    b_final = np.clip(b_final, 0, 255).astype(np.uint8)

    new_hair = Image.merge("RGBA", (
        Image.fromarray(r_final),
        Image.fromarray(g_final),
        Image.fromarray(b_final),
        Image.fromarray(hair_alpha)
    ))

    hair_out_path = os.path.join(OUTPUT_TEXTURES, "ellen_hair_diffuse.png")
    new_hair.save(hair_out_path)
    print(f"Exported: {hair_out_path}")

    # C. ELLEN'S FACE: PIERCING CRIMSON SHARK EYES & CONFIDENT SMIRK
    face_img = orig_face.copy()
    f_draw = ImageDraw.Draw(face_img)

    # In 2048x2048 face texture:
    # Left eye: X ~ 560..840, Y ~ 800..1080
    # Right eye: X ~ 1210..1490, Y ~ 800..1080
    def draw_ellen_shark_eye(cx, cy, rx, ry, is_right):
        # 1. White sclera background
        f_draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(255, 255, 255, 255))
        # 2. Outer Ruby Crimson Iris
        iris_rx = int(rx * 0.76)
        iris_ry = int(ry * 0.88)
        f_draw.ellipse([cx - iris_rx, cy - iris_ry, cx + iris_rx, cy + iris_ry], fill=(185, 18, 38, 255))
        # 3. Inner fiery scarlet glow
        inner_rx = int(iris_rx * 0.72)
        inner_ry = int(iris_ry * 0.78)
        f_draw.ellipse([cx - inner_rx, cy - inner_ry, cx + inner_rx, cy + inner_ry], fill=(245, 45, 65, 255))
        # 4. Vertical Predatory Shark Slit Pupil
        pupil_w = int(iris_rx * 0.22)
        pupil_h = int(iris_ry * 0.92)
        f_draw.polygon([
            (cx, cy - pupil_h),
            (cx + pupil_w, cy),
            (cx, cy + pupil_h),
            (cx - pupil_w, cy)
        ], fill=(15, 8, 12, 255))
        # 5. Crisp white anime highlights (two diamond specks)
        f_draw.ellipse([cx - int(iris_rx*0.45), cy - int(iris_ry*0.45), cx - int(iris_rx*0.25), cy - int(iris_ry*0.25)], fill=(255, 255, 255, 255))
        f_draw.ellipse([cx + int(iris_rx*0.25), cy + int(iris_ry*0.35), cx + int(iris_rx*0.40), cy + int(iris_ry*0.50)], fill=(255, 255, 255, 230))
        # 6. Upper sharp black anime eyeliner and delicate double lid
        eyeliner_y = cy - ry
        f_draw.arc([cx - rx - 8, cy - ry - 14, cx + rx + 8, cy + ry - 8], start=200, end=340, fill=(20, 16, 22, 255), width=9)
        # Flick / wing on outer corner
        wing_dir = 1 if is_right else -1
        f_draw.line([(cx + wing_dir * rx, eyeliner_y + 4), (cx + wing_dir * (rx + 22), eyeliner_y - 12)], fill=(20, 16, 22, 255), width=6)

    draw_ellen_shark_eye(700, 940, 115, 95, False)
    draw_ellen_shark_eye(1350, 940, 115, 95, True)

    # Soft rosy blush on cheeks (below eyes)
    blush_overlay = Image.new("RGBA", face_img.size, (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(blush_overlay)
    b_draw.ellipse([580, 1040, 780, 1140], fill=(255, 120, 140, 65))
    b_draw.ellipse([1270, 1040, 1470, 1140], fill=(255, 120, 140, 65))
    blush_overlay = blush_overlay.filter(ImageFilter.GaussianBlur(14))
    face_img = Image.alpha_composite(face_img, blush_overlay)
    f_draw = ImageDraw.Draw(face_img)

    # Confident cool slight smirk at mouth (X: 1024, Y: 1390)
    # Slight upward tilt on one side for that iconic Ellen Joe smirk
    f_draw.arc([970, 1370, 1080, 1410], start=20, end=160, fill=(180, 70, 80, 255), width=5)
    f_draw.line([(1065, 1385), (1085, 1378)], fill=(180, 70, 80, 255), width=5)

    face_out_path = os.path.join(OUTPUT_TEXTURES, "ellen_face_diffuse.png")
    face_img.save(face_out_path)
    print(f"Exported: {face_out_path}")

if __name__ == "__main__":
    print("Building authentic Ellen Joe 3D models and textures...")
    build_shark_tail()
    build_maid_headdress()
    build_textures()
    print("All Ellen Joe assets built successfully!")
