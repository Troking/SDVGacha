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
prim0 = mesh['primitives'][0] # grass
pos_acc = gltf['accessors'][prim0['attributes']['POSITION']]
pos_bv = gltf['bufferViews'][pos_acc['bufferView']]
offset = pos_bv.get('byteOffset', 0) + pos_acc.get('byteOffset', 0)
count = pos_acc['count']

nearby = []
for i in range(count):
    x, y, z = struct.unpack_from('<3f', bin_data, offset + i * 12)
    dist = ((x - 10.0)**2 + (z - (-6.0))**2)**0.5
    if dist < 6.0:
        nearby.append((dist, x, y, z))

nearby.sort()
print(f"Vertices near (10, -6): {len(nearby)}")
for d, x, y, z in nearby[:10]:
    print(f"  dist={d:.2f}, x={x:.2f}, y={y:.2f}, z={z:.2f}")
