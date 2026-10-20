import json

with open('game/assets/models/asian_fantasy_terrain.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))

for i, m in enumerate(gltf.get('materials', [])):
    print(f"Mat {i}: {m['name']}")
    pbr = m.get('pbrMetallicRoughness', {})
    print("  baseColorFactor:", pbr.get('baseColorFactor'))
    print("  baseColorTexture:", pbr.get('baseColorTexture'))

for i, t in enumerate(gltf.get('textures', [])):
    img_idx = t.get('source')
    img = gltf['images'][img_idx]
    print(f"Texture {i}: img {img_idx}, mimeType={img.get('mimeType')}")
