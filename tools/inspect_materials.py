import json

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))

print("=== MATERIALS ===")
for i, m in enumerate(gltf.get('materials', [])):
    print(f"Material {i}: {m.get('name')}")

print("\n=== MESH PRIMITIVES ===")
for i, m in enumerate(gltf.get('meshes', [])):
    print(f"Mesh {i} ({m.get('name')}):")
    for j, p in enumerate(m.get('primitives', [])):
        mat_idx = p.get('material')
        mat_name = gltf['materials'][mat_idx].get('name') if mat_idx is not None else "None"
        attrs = list(p.get('attributes', {}).keys())
        print(f"  Primitive {j}: material={mat_name} (idx {mat_idx}), attrs={attrs}")
