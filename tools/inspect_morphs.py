import json, struct

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

mesh4 = gltf['meshes'][4]
target_names = mesh4['extras']['targetNames']
prim = mesh4['primitives'][0]
targets = prim['targets']

print("Face_Eye targets count:", len(targets))
for i, (name, target) in enumerate(zip(target_names, targets)):
    pos_acc = gltf['accessors'][target['POSITION']]
    min_p = pos_acc.get('min')
    max_p = pos_acc.get('max')
    print(f"Target {i} ({name}): min={min_p}, max={max_p}")
