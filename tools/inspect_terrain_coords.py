import json, struct

with open('game/assets/models/asian_fantasy_terrain.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

mesh = gltf['meshes'][0]
for j, p in enumerate(mesh['primitives']):
    pos_acc = gltf['accessors'][p['attributes']['POSITION']]
    min_p = pos_acc.get('min')
    max_p = pos_acc.get('max')
    mat_idx = p.get('material')
    mat_name = gltf['materials'][mat_idx]['name']
    print(f"Prim {j} ({mat_name}): count={pos_acc['count']}, min={min_p}, max={max_p}")
