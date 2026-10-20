import json, struct

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

for mesh_idx in [2, 4]: # EyeStar, Face_Eye
    m = gltf['meshes'][mesh_idx]
    prim = m['primitives'][0]
    uv_acc = gltf['accessors'][prim['attributes']['TEXCOORD_0']]
    uv_bv = gltf['bufferViews'][uv_acc['bufferView']]
    offset = uv_bv.get('byteOffset', 0) + uv_acc.get('byteOffset', 0)
    count = uv_acc['count']
    uvs = [struct.unpack_from('<2f', bin_data, offset + i * 8) for i in range(count)]
    min_u = min(u[0] for u in uvs)
    max_u = max(u[0] for u in uvs)
    min_v = min(u[1] for u in uvs)
    max_v = max(u[1] for u in uvs)
    print(f"Mesh {m['name']} (vertices={count}): U=[{min_u:.4f}, {max_u:.4f}], V=[{min_v:.4f}, {max_v:.4f}]")
