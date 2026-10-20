import json, struct

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

prim0 = gltf['meshes'][0]['primitives'][0]
joints_acc = gltf['accessors'][prim0['attributes']['JOINTS_0']]
weights_acc = gltf['accessors'][prim0['attributes']['WEIGHTS_0']]

print(f"Hair joints accessor: count={joints_acc['count']}, type={joints_acc['type']}, compType={joints_acc['componentType']}")
print(f"Hair weights accessor: count={weights_acc['count']}, type={weights_acc['type']}, compType={weights_acc['componentType']}")

joints_buffer_view = gltf['bufferViews'][joints_acc['bufferView']]
weights_buffer_view = gltf['bufferViews'][weights_acc['bufferView']]

j_offset = joints_buffer_view.get('byteOffset', 0) + joints_acc.get('byteOffset', 0)
w_offset = weights_buffer_view.get('byteOffset', 0) + weights_acc.get('byteOffset', 0)

used_joints = set()
skin_joints = gltf['skins'][0]['joints']

for i in range(joints_acc['count']):
    if joints_acc['componentType'] == 5121: # UBYTE
        j_indices = struct.unpack_from('<4B', bin_data, j_offset + i * 4)
    elif joints_acc['componentType'] == 5123: # USHORT
        j_indices = struct.unpack_from('<4H', bin_data, j_offset + i * 8)
    
    if weights_acc['componentType'] == 5126: # FLOAT
        weights = struct.unpack_from('<4f', bin_data, w_offset + i * 16)
    
    for j_idx, w in zip(j_indices, weights):
        if w > 0.05:
            node_idx = skin_joints[j_idx]
            node_name = gltf['nodes'][node_idx].get('name')
            used_joints.add((j_idx, node_idx, node_name))

print("Hair used joints:")
for j in sorted(used_joints):
    print(" ", j)
