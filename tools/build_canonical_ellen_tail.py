import os
import math
import struct
import json

OUTPUT_PATH = r"e:/Trok/ChibiRPG_Project/game/assets/models/ellen_shark_tail.glb"

class GLBBuilder:
    def __init__(self):
        self.materials = []
        self.meshes = []
        self.bin_data = bytearray()
        self.accessors = []
        self.buffer_views = []

    def add_material(self, name, base_color, metallic=0.1, roughness=0.4, emissive=None):
        mat = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": base_color,
                "metallicFactor": metallic,
                "roughnessFactor": roughness
            }
        }
        if emissive:
            mat["emissiveFactor"] = emissive
        self.materials.append(mat)
        return len(self.materials) - 1

    def _pad_bin(self, alignment=4):
        pad = (alignment - (len(self.bin_data) % alignment)) % alignment
        self.bin_data.extend(b'\x00' * pad)

    def add_mesh_part(self, positions, normals, uvs, indices, material_idx):
        if not positions or not indices:
            return

        min_pos = [min(p[i] for p in positions) for i in range(3)]
        max_pos = [max(p[i] for p in positions) for i in range(3)]

        # 1. Indices (UNSIGNED_INT = 5125)
        self._pad_bin(4)
        idx_offset = len(self.bin_data)
        for idx in indices:
            self.bin_data.extend(struct.pack('<I', idx))
        idx_len = len(self.bin_data) - idx_offset

        bv_idx = len(self.buffer_views)
        self.buffer_views.append({
            "buffer": 0,
            "byteOffset": idx_offset,
            "byteLength": idx_len,
            "target": 34963 # ELEMENT_ARRAY_BUFFER
        })
        acc_idx = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_idx,
            "byteOffset": 0,
            "componentType": 5125,
            "count": len(indices),
            "type": "SCALAR"
        })

        # 2. Positions (FLOAT = 5126)
        self._pad_bin(4)
        pos_offset = len(self.bin_data)
        for p in positions:
            self.bin_data.extend(struct.pack('<fff', p[0], p[1], p[2]))
        pos_len = len(self.bin_data) - pos_offset

        bv_pos = len(self.buffer_views)
        self.buffer_views.append({
            "buffer": 0,
            "byteOffset": pos_offset,
            "byteLength": pos_len,
            "target": 34962 # ARRAY_BUFFER
        })
        acc_pos = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_pos,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(positions),
            "type": "VEC3",
            "min": min_pos,
            "max": max_pos
        })

        # 3. Normals (FLOAT = 5126)
        self._pad_bin(4)
        norm_offset = len(self.bin_data)
        for n in normals:
            self.bin_data.extend(struct.pack('<fff', n[0], n[1], n[2]))
        norm_len = len(self.bin_data) - norm_offset

        bv_norm = len(self.buffer_views)
        self.buffer_views.append({
            "buffer": 0,
            "byteOffset": norm_offset,
            "byteLength": norm_len,
            "target": 34962
        })
        acc_norm = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_norm,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(normals),
            "type": "VEC3"
        })

        # 4. UVs (FLOAT = 5126)
        self._pad_bin(4)
        uv_offset = len(self.bin_data)
        for u in uvs:
            self.bin_data.extend(struct.pack('<ff', u[0], u[1]))
        uv_len = len(self.bin_data) - uv_offset

        bv_uv = len(self.buffer_views)
        self.buffer_views.append({
            "buffer": 0,
            "byteOffset": uv_offset,
            "byteLength": uv_len,
            "target": 34962
        })
        acc_uv = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_uv,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(uvs),
            "type": "VEC2"
        })

        self.meshes.append({
            "primitives": [{
                "attributes": {
                    "POSITION": acc_pos,
                    "NORMAL": acc_norm,
                    "TEXCOORD_0": acc_uv
                },
                "indices": acc_idx,
                "material": material_idx
            }]
        })

    def export(self, filepath):
        self._pad_bin(4)
        gltf = {
            "asset": {"version": "2.0", "generator": "EllenSharkTailBuilder"},
            "scene": 0,
            "scenes": [{"nodes": [0]}],
            "nodes": [{
                "name": "EllenSharkTailRoot",
                "children": list(range(1, len(self.meshes) + 1))
            }],
            "materials": self.materials,
            "meshes": self.meshes,
            "accessors": self.accessors,
            "bufferViews": self.buffer_views,
            "buffers": [{"byteLength": len(self.bin_data)}]
        }
        for i, m in enumerate(self.meshes):
            gltf["nodes"].append({
                "name": f"TailPart_{i}",
                "mesh": i
            })

        json_str = json.dumps(gltf, separators=(',', ':'))
        json_bytes = json_str.encode('utf-8')
        json_pad = (4 - (len(json_bytes) % 4)) % 4
        json_bytes += b' ' * json_pad

        bin_pad = (4 - (len(self.bin_data) % 4)) % 4
        self.bin_data.extend(b'\x00' * bin_pad)

        total_len = 12 + 8 + len(json_bytes) + 8 + len(self.bin_data)
        header = struct.pack('<III', 0x46546C67, 2, total_len)
        chunk0 = struct.pack('<II', len(json_bytes), 0x4E4F534A) + json_bytes
        chunk1 = struct.pack('<II', len(self.bin_data), 0x004E4942) + self.bin_data

        with open(filepath, 'wb') as f:
            f.write(header)
            f.write(chunk0)
            f.write(chunk1)
        print(f"Exported canonical tail to: {filepath} ({total_len} bytes)")

def build_canonical_tail():
    glb = GLBBuilder()

    # Canonical materials from Zenless Zone Zero (Ellen Joe)
    # 1. Dark Charcoal/Slate Shark Upper Skin
    m_upper = glb.add_material("Mat_SharkUpperSkin", [0.13, 0.14, 0.17, 1.0], roughness=0.36, metallic=0.18)
    # 2. Crisp Cream-White Shark Belly Countershading
    m_belly = glb.add_material("Mat_SharkBelly", [0.91, 0.93, 0.96, 1.0], roughness=0.30, metallic=0.04)
    # 3. Fin material (dark charcoal with sharp finish)
    m_fin = glb.add_material("Mat_SharkFin", [0.10, 0.11, 0.13, 1.0], roughness=0.22, metallic=0.22)
    # 4. Black leather harness straps around base
    m_harness = glb.add_material("Mat_HarnessLeather", [0.05, 0.05, 0.06, 1.0], roughness=0.48, metallic=0.10)
    # 5. Silver buckles
    m_buckle = glb.add_material("Mat_SilverBuckle", [0.88, 0.90, 0.95, 1.0], roughness=0.14, metallic=0.96)
    # 6. Glowing Red Hazard warning stripes (emissive)
    m_led = glb.add_material("Mat_RedLED", [1.0, 0.10, 0.20, 1.0], roughness=0.15, metallic=0.10, emissive=[2.0, 0.15, 0.25])

    # Symmetrical canonical rest-pose geometry:
    # Origin (0, 0, 0) is at the hips/sacrum attachment.
    # The tail extends naturally BACKWARD along -Z (behind Ellen) from Z = 0.0 to Z = -1.28.
    # Natural shark curvature: sweeps slightly downward from hips (-Y) and levels off towards the caudal fluke.
    num_rings = 24
    segs_per_ring = 22
    total_length = 1.28

    base_rw = 0.18 # Width at hips base
    base_rh = 0.15 # Height at hips base

    centers = []
    radii_w = []
    radii_h = []

    for r in range(num_rings):
        t = float(r) / (num_rings - 1)
        # Z extends BACKWARD along -Z (behind Ellen)
        cz = -t * total_length
        # Graceful downward curve from hips, leveling out near peduncle
        cy = -0.15 * math.sin(t * math.pi * 0.75) - 0.07 * t + 0.04 * (t ** 2.0)
        cx = 0.0 # perfectly symmetrical rest pose!

        # Hydrodynamic shark taper (elliptical, tapering towards the narrow tail peduncle)
        rw = base_rw * (1.0 - t * 0.72)
        rh = base_rh * (1.0 - t * 0.68)

        centers.append((cx, cy, cz))
        radii_w.append(rw)
        radii_h.append(rh)

    # 1. BODY SURFACE (Upper Dark Skin and White Belly)
    upper_pos, upper_norm, upper_uv, upper_idx = [], [], [], []
    belly_pos, belly_norm, belly_uv, belly_idx = [], [], [], []

    grid = []
    for r in range(num_rings):
        cx, cy, cz = centers[r]
        rw = radii_w[r]
        rh = radii_h[r]
        ring_v = []
        for s in range(segs_per_ring):
            theta = 2.0 * math.pi * float(s) / segs_per_ring
            # theta = 0 -> Right (+X)
            # theta = pi/2 -> Top (+Y, Upper Spine)
            # theta = pi -> Left (-X)
            # theta = 3pi/2 -> Bottom (-Y, Belly)
            vx = cx + math.cos(theta) * rw
            vy = cy + math.sin(theta) * rh
            vz = cz

            # Smooth outward normal
            nx = math.cos(theta)
            ny = math.sin(theta)
            nz = -0.12 # slight taper backward towards -Z
            n_len = math.sqrt(nx*nx + ny*ny + nz*nz)
            norm = (nx/n_len, ny/n_len, nz/n_len)

            u = float(s) / segs_per_ring
            v = float(r) / (num_rings - 1)

            # Belly countershading: lower ~40% of the cross section (around -Y)
            # theta between 1.12*pi and 1.88*pi
            is_belly = (theta > math.pi * 1.12 and theta < math.pi * 1.88)
            ring_v.append((vx, vy, vz, norm[0], norm[1], norm[2], u, v, is_belly))
        grid.append(ring_v)

    # Triangulate rings with outward facing CCW winding
    for r in range(num_rings - 1):
        for s in range(segs_per_ring):
            s_next = (s + 1) % segs_per_ring
            v0 = grid[r][s]
            v1 = grid[r][s_next]
            v2 = grid[r+1][s_next]
            v3 = grid[r+1][s]

            is_belly_quad = v0[8] and v1[8] and v2[8] and v3[8]
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

    # 2. DORSAL FIN (Midway on the upper spine around ring 10)
    fin_pos, fin_norm, fin_uv, fin_idx = [], [], [], []
    def add_dorsal_fin():
        c_mid = centers[10]
        z_base = c_mid[2] # negative number (e.g. -0.55)
        y_base = c_mid[1] + radii_h[10] * 0.92

        # Swept backward towards -Z: front base is closer to hips (more positive Z), tip is further back (more negative Z)
        verts = [
            [-0.010, y_base, z_base + 0.12], # 0: Front base left
            [ 0.010, y_base, z_base + 0.12], # 1: Front base right
            [-0.008, y_base, z_base - 0.18], # 2: Rear base left
            [ 0.008, y_base, z_base - 0.18], # 3: Rear base right
            [-0.003, y_base + 0.22, z_base - 0.10], # 4: Fin tip left (swept back)
            [ 0.003, y_base + 0.22, z_base - 0.10], # 5: Fin tip right
            [-0.005, y_base + 0.05, z_base - 0.14], # 6: Trailing notch left
            [ 0.005, y_base + 0.05, z_base - 0.14], # 7: Trailing notch right
        ]
        base_i = len(fin_pos)
        for v in verts:
            fin_pos.append(v)
            fin_norm.append([1.0 if v[0] > 0 else -1.0, 0.4, -0.1])
            fin_uv.append([0.5, 0.5])

        # Left flank (outward facing: CCW when viewed from -X)
        fin_idx.extend([base_i+0, base_i+6, base_i+4, base_i+0, base_i+2, base_i+6])
        # Right flank (outward facing: CCW when viewed from +X)
        fin_idx.extend([base_i+1, base_i+5, base_i+7, base_i+1, base_i+7, base_i+3])
        # Leading edge cap
        fin_idx.extend([base_i+0, base_i+4, base_i+5, base_i+0, base_i+5, base_i+1])
        # Trailing edge notch
        fin_idx.extend([base_i+4, base_i+6, base_i+7, base_i+4, base_i+7, base_i+5])
        fin_idx.extend([base_i+6, base_i+2, base_i+3, base_i+6, base_i+3, base_i+7])

    add_dorsal_fin()

    # 3. MASSIVE SHARK CAUDAL FLUKE (At the tip, r = 23)
    def add_caudal_fin():
        c_tip = centers[-1]
        z_tip = c_tip[2] # around -1.28
        y_tip = c_tip[1]

        # Caudal fluke extends backward into negative Z
        caudal_verts = [
            # Peduncle attachment (Z = z_tip)
            [-0.012, y_tip + 0.02, z_tip],        # 0
            [ 0.012, y_tip + 0.02, z_tip],        # 1
            [-0.012, y_tip - 0.02, z_tip],        # 2
            [ 0.012, y_tip - 0.02, z_tip],        # 3
            # Upper tall swept-back lobe tip
            [-0.003, y_tip + 0.36, z_tip - 0.26], # 4
            [ 0.003, y_tip + 0.36, z_tip - 0.26], # 5
            # Subterminal notch on upper lobe
            [-0.004, y_tip + 0.25, z_tip - 0.23], # 6
            [ 0.004, y_tip + 0.25, z_tip - 0.23], # 7
            # Caudal center notch / fork
            [-0.005, y_tip + 0.01, z_tip - 0.15], # 8
            [ 0.005, y_tip + 0.01, z_tip - 0.15], # 9
            # Lower lobe tip
            [-0.003, y_tip - 0.20, z_tip - 0.18], # 10
            [ 0.003, y_tip - 0.20, z_tip - 0.18], # 11
        ]
        base_i = len(fin_pos)
        for v in caudal_verts:
            fin_pos.append(v)
            fin_norm.append([1.0 if v[0] > 0 else -1.0, 0.2, -0.3])
            fin_uv.append([0.5, 0.5])

        # Upper lobe left/right
        fin_idx.extend([base_i+0, base_i+6, base_i+4, base_i+0, base_i+8, base_i+6])
        fin_idx.extend([base_i+1, base_i+5, base_i+7, base_i+1, base_i+7, base_i+9])
        # Lower lobe left/right
        fin_idx.extend([base_i+2, base_i+10, base_i+8])
        fin_idx.extend([base_i+3, base_i+9, base_i+11])
        # Leading edges
        fin_idx.extend([base_i+0, base_i+4, base_i+5, base_i+0, base_i+5, base_i+1])
        fin_idx.extend([base_i+2, base_i+3, base_i+11, base_i+2, base_i+11, base_i+10])
        # Trailing edge notch
        fin_idx.extend([base_i+4, base_i+6, base_i+7, base_i+4, base_i+7, base_i+5])
        fin_idx.extend([base_i+6, base_i+8, base_i+9, base_i+6, base_i+9, base_i+7])
        fin_idx.extend([base_i+8, base_i+10, base_i+11, base_i+8, base_i+11, base_i+9])

    add_caudal_fin()
    glb.add_mesh_part(fin_pos, fin_norm, fin_uv, fin_idx, m_fin)

    # 4. LEATHER HARNESS BELTS & SILVER BUCKLES (Around rings 2 and 5)
    harn_pos, harn_norm, harn_uv, harn_idx = [], [], [], []
    buck_pos, buck_norm, buck_uv, buck_idx = [], [], [], []

    def add_strap(ring_idx, width=0.034):
        cx, cy, cz = centers[ring_idx]
        rw = radii_w[ring_idx] * 1.04
        rh = radii_h[ring_idx] * 1.04

        n_seg = 18
        for i in range(n_seg):
            i_next = (i + 1) % n_seg
            t0 = 2.0 * math.pi * float(i) / n_seg
            t1 = 2.0 * math.pi * float(i_next) / n_seg

            x0, y0 = cx + math.cos(t0) * rw, cy + math.sin(t0) * rh
            x1, y1 = cx + math.cos(t1) * rw, cy + math.sin(t1) * rh

            base_i = len(harn_pos)
            harn_pos.extend([[x0, y0, cz + width*0.5], [x1, y1, cz + width*0.5], [x1, y1, cz - width*0.5], [x0, y0, cz - width*0.5]])
            harn_norm.extend([[math.cos(t0), math.sin(t0), 0], [math.cos(t1), math.sin(t1), 0], [math.cos(t1), math.sin(t1), 0], [math.cos(t0), math.sin(t0), 0]])
            harn_uv.extend([[float(i)/n_seg, 0], [float(i+1)/n_seg, 0], [float(i+1)/n_seg, 1], [float(i)/n_seg, 1]])
            harn_idx.extend([base_i, base_i+1, base_i+2, base_i, base_i+2, base_i+3])

        # Silver Buckle on right flank (+X)
        bx = cx + rw * 0.98
        by = cy
        bz = cz
        b_base = len(buck_pos)
        buck_pos.extend([
            [bx, by - 0.026, bz - width*0.7], [bx + 0.014, by - 0.026, bz - width*0.7],
            [bx + 0.014, by + 0.026, bz - width*0.7], [bx, by + 0.026, bz - width*0.7],
            [bx, by - 0.026, bz + width*0.7], [bx + 0.014, by - 0.026, bz + width*0.7],
            [bx + 0.014, by + 0.026, bz + width*0.7], [bx, by + 0.026, bz + width*0.7]
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
    add_strap(5, 0.030)
    glb.add_mesh_part(harn_pos, harn_norm, harn_uv, harn_idx, m_harness)
    glb.add_mesh_part(buck_pos, buck_norm, buck_uv, buck_idx, m_buckle)

    # 5. GLOWING RED HAZARD STRIPES (Lateral lines along rings 6..18)
    led_pos, led_norm, led_uv, led_idx = [], [], [], []
    for side in [-1, 1]:
        for r in range(6, 18, 3):
            cx, cy, cz = centers[r]
            rw = radii_w[r] * 1.015
            lx = cx + side * rw
            ly = cy
            base_i = len(led_pos)
            w_strip = 0.010
            l_strip = 0.038
            led_pos.extend([
                [lx, ly - w_strip, cz - l_strip*0.5],
                [lx, ly + w_strip, cz - l_strip*0.5],
                [lx, ly + w_strip, cz + l_strip*0.5],
                [lx, ly - w_strip, cz + l_strip*0.5]
            ])
            for _ in range(4):
                led_norm.append([side, 0.0, 0.0])
                led_uv.append([0.5, 0.5])
            if side == 1:
                led_idx.extend([base_i, base_i+1, base_i+2, base_i, base_i+2, base_i+3])
            else:
                led_idx.extend([base_i, base_i+2, base_i+1, base_i, base_i+3, base_i+2])

    glb.add_mesh_part(led_pos, led_norm, led_uv, led_idx, m_led)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    glb.export(OUTPUT_PATH)

if __name__ == "__main__":
    build_canonical_tail()
