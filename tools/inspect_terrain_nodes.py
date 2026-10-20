import json

with open('game/assets/models/asian_fantasy_terrain.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))

for i, n in enumerate(gltf.get('nodes', [])):
    print(f"Node {i}: {n.get('name')}, mesh={n.get('mesh')}")
