import json

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    magic = f.read(4)
    version = f.read(4)
    length = f.read(4)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    json_bytes = f.read(chunk_length)
    gltf = json.loads(json_bytes.decode('utf-8'))

print("=== NODES ===")
for i, n in enumerate(gltf.get('nodes', [])):
    mesh_idx = n.get('mesh')
    skin_idx = n.get('skin')
    print(f"Node {i}: {n.get('name')} (mesh: {mesh_idx}, skin: {skin_idx})")

print("\n=== SKINS ===")
for i, s in enumerate(gltf.get('skins', [])):
    print(f"Skin {i}: {s.get('name')}, joints: {len(s.get('joints', []))}")
    for j in s.get('joints', []):
        print(f"  Joint node {j}: {gltf['nodes'][j].get('name')}")

print("\n=== MESHES ===")
for i, m in enumerate(gltf.get('meshes', [])):
    name = m.get('name')
    target_names = m.get('extras', {}).get('targetNames', [])
    targets_count = 0
    for p in m.get('primitives', []):
        targets_count = max(targets_count, len(p.get('targets', [])))
    print(f"Mesh {i}: {name}, targets: {targets_count}, target_names: {target_names}")

print("\n=== ANIMATIONS ===")
for i, a in enumerate(gltf.get('animations', [])):
    print(f"Anim {i}: {a.get('name')}")
