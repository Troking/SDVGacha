import json
from PIL import Image
import io

with open('game/assets/models/asian_fantasy_terrain.glb', 'rb') as f:
    f.seek(12)
    chunk_length = int.from_bytes(f.read(4), 'little')
    chunk_type = f.read(4)
    gltf = json.loads(f.read(chunk_length).decode('utf-8'))
    bin_chunk_length = int.from_bytes(f.read(4), 'little')
    bin_chunk_type = f.read(4)
    bin_data = f.read(bin_chunk_length)

for i, img in enumerate(gltf.get('images', [])):
    bv = gltf['bufferViews'][img['bufferView']]
    offset = bv.get('byteOffset', 0)
    data = bin_data[offset:offset+bv['byteLength']]
    im = Image.open(io.BytesIO(data))
    print(f"Img {i}: size={im.size}, mode={im.mode}")
    im.save(f"game/assets/textures/terrain_img_{i}.png")
