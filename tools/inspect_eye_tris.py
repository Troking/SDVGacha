import json, struct

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

# Let's inspect mesh 4 (Face_Eye) primitives and indices
m = gltf['meshes'][4]
prim = m['primitives'][0]
idx_acc = gltf['accessors'][prim['indices']]
idx_bv = gltf['bufferViews'][idx_acc['bufferView']]
idx_off = idx_bv.get('byteOffset', 0) + idx_acc.get('byteOffset', 0)
idx_count = idx_acc['count']

indices = struct.unpack_from(f'<{idx_count}H', bin_data, idx_off)
print("Face_Eye triangles:", idx_count // 3)

# Let's check Mesh 2 (EyeStar)
m2 = gltf['meshes'][2]
prim2 = m2['primitives'][0]
idx_acc2 = gltf['accessors'][prim2['indices']]
idx_bv2 = gltf['bufferViews'][idx_acc2['bufferView']]
idx_off2 = idx_bv2.get('byteOffset', 0) + idx_acc2.get('byteOffset', 0)
idx_count2 = idx_acc2['count']
print("EyeStar triangles:", idx_count2 // 3)
