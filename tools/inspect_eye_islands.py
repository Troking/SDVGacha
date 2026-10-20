import json, struct

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

m = gltf['meshes'][4] # Face_Eye
prim = m['primitives'][0]
pos_acc = gltf['accessors'][prim['attributes']['POSITION']]
uv_acc = gltf['accessors'][prim['attributes']['TEXCOORD_0']]

pos_bv = gltf['bufferViews'][pos_acc['bufferView']]
pos_off = pos_bv.get('byteOffset', 0) + pos_acc.get('byteOffset', 0)

uv_bv = gltf['bufferViews'][uv_acc['bufferView']]
uv_off = uv_bv.get('byteOffset', 0) + uv_acc.get('byteOffset', 0)

count = pos_acc['count']
vertices = []
for i in range(count):
    p = struct.unpack_from('<3f', bin_data, pos_off + i * 12)
    uv = struct.unpack_from('<2f', bin_data, uv_off + i * 8)
    vertices.append((p, uv))

# Check left eye vs right eye based on X
left_eye = [v for v in vertices if v[0][0] > 0.01]
right_eye = [v for v in vertices if v[0][0] < -0.01]
print(f"Left eye vertices: {len(left_eye)}, Right eye vertices: {len(right_eye)}")
if left_eye:
    u_l = [v[1][0] for v in left_eye]
    v_l = [v[1][1] for v in left_eye]
    print(f"Left eye UV: U=[{min(u_l):.3f}, {max(u_l):.3f}], V=[{min(v_l):.3f}, {max(v_l):.3f}]")
if right_eye:
    u_r = [v[1][0] for v in right_eye]
    v_r = [v[1][1] for v in right_eye]
    print(f"Right eye UV: U=[{min(u_r):.3f}, {max(u_r):.3f}], V=[{min(v_r):.3f}, {max(v_r):.3f}]")
