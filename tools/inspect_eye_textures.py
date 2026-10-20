import json

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))

for i, m in enumerate(gltf.get('materials', [])):
    name = m.get('name')
    pbr = m.get('pbrMetallicRoughness', {})
    tex = pbr.get('baseColorTexture')
    print(f"Mat {i}: {name}, baseColorTexture={tex}")

for i, t in enumerate(gltf.get('textures', [])):
    source = t.get('source')
    sampler = t.get('sampler')
    img_name = gltf['images'][source].get('name') if source is not None else "None"
    print(f"Texture {i}: source image {source} ({img_name})")

for i, img in enumerate(gltf.get('images', [])):
    print(f"Image {i}: name={img.get('name')}, mimeType={img.get('mimeType')}")
