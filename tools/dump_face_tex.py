import json

with open('game/assets/models/anime_heroine_rigged.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

face_mat = gltf['materials'][2]
tex_idx = face_mat['pbrMetallicRoughness']['baseColorTexture']['index']
tex = gltf['textures'][tex_idx]
img_idx = tex['source']
img = gltf['images'][img_idx]
print("Face image mimeType:", img.get('mimeType'))

bv = gltf['bufferViews'][img['bufferView']]
offset = bv.get('byteOffset', 0)
length = bv['byteLength']
img_data = bin_data[offset:offset+length]

ext = "png" if "png" in img.get('mimeType', '') else "jpg"
with open(f"game/assets/textures/face_texture_dump.{ext}", "wb") as out:
    out.write(img_data)
print("Dumped face texture:", len(img_data), "bytes")
