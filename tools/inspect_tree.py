import json

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))

print("=== SCENES & HIERARCHY ===")
for s in gltf.get('scenes', []):
    print("Scene nodes:", s.get('nodes'))

def print_tree(node_idx, indent=0):
    node = gltf['nodes'][node_idx]
    name = node.get('name')
    mesh = node.get('mesh')
    skin = node.get('skin')
    trans = node.get('translation')
    rot = node.get('rotation')
    scale = node.get('scale')
    extra = f" (mesh: {mesh}, skin: {skin})" if mesh is not None or skin is not None else ""
    print("  " * indent + f"- [{node_idx}] {name}{extra}")
    for child in node.get('children', []):
        print_tree(child, indent + 1)

for root_node in gltf.get('scenes', [{}])[0].get('nodes', []):
    print_tree(root_node)
