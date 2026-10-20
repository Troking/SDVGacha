import json, struct

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))

for i, m in enumerate(gltf.get('meshes', [])):
    name = m.get('name')
    for j, p in enumerate(m.get('primitives', [])):
        pos_acc = gltf['accessors'][p['attributes']['POSITION']]
        min_p = pos_acc.get('min')
        max_p = pos_acc.get('max')
        print(f"Mesh {name} Prim {j}: min={min_p}, max={max_p}")
