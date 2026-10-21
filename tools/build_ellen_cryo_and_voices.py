import os
import math
import wave
import struct
import random
import asyncio
from PIL import Image, ImageDraw, ImageFilter

VOICE_DIR = r"e:\Trok\ChibiRPG_Project\game\assets\sounds\voice"
SOUND_DIR = r"e:\Trok\ChibiRPG_Project\game\assets\sounds"
TEXTURE_DIR = r"e:\Trok\ChibiRPG_Project\game\assets\textures"

os.makedirs(VOICE_DIR, exist_ok=True)
os.makedirs(SOUND_DIR, exist_ok=True)
os.makedirs(TEXTURE_DIR, exist_ok=True)

# -------------------------------------------------------------
# 1. GENERATE ELLEN JOE ANIME SEIYUU VOICE PACK (edge-tts)
# -------------------------------------------------------------
ELLEN_VOICES = {
    # Attacks & Grunts
    "ellen_attack_1.mp3": ("遅いよ！", "+8%", "-1Hz"),
    "ellen_attack_2.mp3": ("シャーク・バイト！", "+10%", "+0Hz"),
    "ellen_attack_3.mp3": ("そこっ！", "+12%", "-1Hz"),
    "ellen_finisher_1.mp3": ("切り刻んであげる！", "+14%", "+2Hz"),
    "ellen_finisher_2.mp3": ("終わりだよ、サメのエサになりな！", "+10%", "+1Hz"),

    # Elemental Cryo Skill Shouts
    "ellen_skill_cryo_1.mp3": ("凍りつきな！フロスト・シュレッド！", "+12%", "+2Hz"),
    "ellen_skill_cryo_2.mp3": ("シャーク・ストーム！冷たくしてあげる！", "+14%", "+3Hz"),

    # Locomotion & Actions
    "ellen_jump_1.mp3": ("とうっ！", "+15%", "+1Hz"),
    "ellen_jump_2.mp3": ("ふっ！", "+10%", "-2Hz"),
    "ellen_land_1.mp3": ("ふぅ、着地。", "-2%", "-3Hz"),
    "ellen_dash_1.mp3": ("すり抜けるよ。", "+4%", "-2Hz"),
    "ellen_dash_2.mp3": ("逃がさない。", "+6%", "-1Hz"),
    "ellen_climb_1.mp3": ("はぁ…面倒くさいなぁ…", "-4%", "-4Hz"),

    # Reactions & Idle
    "ellen_hurt_1.mp3": ("っ痛…！", "+10%", "+2Hz"),
    "ellen_hurt_2.mp3": ("チッ、生意気な…！", "+8%", "-1Hz"),
    "ellen_idle_1.mp3": ("ふぁ〜あ…眠い…少しサボらせてくれない？", "-6%", "-4Hz"),
    "ellen_idle_2.mp3": ("静かだね…ロリポップ、まだあったっけ。", "-4%", "-3Hz"),
    "ellen_chest_1.mp3": ("おっ、宝箱。甘いお菓子でも入ってればいいのに。", "-2%", "-2Hz"),
    "ellen_glider_1.mp3": ("空中散歩も…たまには悪くないね。", "-2%", "-2Hz"),
    "ellen_lvlup_1.mp3": ("ふふっ、ハサミのキレが少し増したかも。", "+2%", "-1Hz"),
}

async def generate_voices():
    try:
        import edge_tts
        print("[VOICES] Generating Ellen Joe seiyuu voice clips...")
        for filename, (text, rate, pitch) in ELLEN_VOICES.items():
            dest = os.path.join(VOICE_DIR, filename)
            communicate = edge_tts.Communicate(text, "ja-JP-NanamiNeural", rate=rate, pitch=pitch)
            await communicate.save(dest)
            print(f"  + Generated: {filename}")
        print("[VOICES] All Ellen Joe voice clips generated successfully!")
    except Exception as e:
        print(f"[VOICES] Warning during voice generation: {e}")

# -------------------------------------------------------------
# 2. GENERATE CRYO AUDIO SFX (WAV)
# -------------------------------------------------------------
def generate_wav(path, duration, generator_func, sample_rate=44100):
    num_samples = int(duration * sample_rate)
    with wave.open(path, "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        frames = bytearray()
        for i in range(num_samples):
            t = float(i) / sample_rate
            val = generator_func(t, duration)
            val = max(-1.0, min(1.0, val))
            sample = int(val * 32767.0)
            frames.extend(struct.pack("<h", sample))
        wav.writeframes(frames)
    print(f"  + Generated Sound: {os.path.basename(path)}")

def cryo_burst_sample(t, dur):
    # Explosive freezing blast: sharp initial glass crack + sub-bass roar + icy bell shimmer
    env = math.exp(-t * 5.0)
    # 1. Sub bass boom
    bass = math.sin(2.0 * math.pi * (75.0 - t * 30.0) * t) * 0.45
    # 2. Freezing whoosh noise
    noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 3.5) * 0.35
    # 3. Crystal bell overtones (chimes)
    chime1 = math.sin(2.0 * math.pi * 1760.0 * t) * math.exp(-t * 6.0) * 0.25
    chime2 = math.sin(2.0 * math.pi * 2637.0 * t) * math.exp(-t * 8.0) * 0.20
    chime3 = math.sin(2.0 * math.pi * 3520.0 * t) * math.exp(-t * 10.0) * 0.15
    return (bass + noise + chime1 + chime2 + chime3) * env

def ice_shatter_sample(t, dur):
    # Sharp brittle ice shattering impact
    env = math.exp(-t * 12.0)
    crack = (random.random() * 2.0 - 1.0) * 0.60
    glint = math.sin(2.0 * math.pi * 2093.0 * t) * 0.30 + math.sin(2.0 * math.pi * 4186.0 * t) * 0.20
    return (crack + glint) * env

def frost_whoosh_sample(t, dur):
    # Swift sub-zero lunge / shearing air
    env = math.sin(math.pi * (t / dur))
    noise = (random.random() * 2.0 - 1.0) * 0.45
    tone = math.sin(2.0 * math.pi * (320.0 + math.sin(t * 18.0) * 120.0) * t) * 0.35
    return (noise + tone) * env

def build_audio():
    print("[AUDIO] Generating Cryo sound effects...")
    generate_wav(os.path.join(SOUND_DIR, "cryo_burst.wav"), 1.2, cryo_burst_sample)
    generate_wav(os.path.join(SOUND_DIR, "ice_shatter.wav"), 0.65, ice_shatter_sample)
    generate_wav(os.path.join(SOUND_DIR, "frost_whoosh.wav"), 0.50, frost_whoosh_sample)

# -------------------------------------------------------------
# 3. GENERATE CRYO VFX TEXTURES (PNG)
# -------------------------------------------------------------
def build_textures():
    print("[TEXTURES] Generating Cryo VFX textures...")
    
    # 1. Glowing Ice Crystal Snowflake (512x512)
    im = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = 256, 256

    # Radial ambient frost glow
    for r in range(220, 20, -10):
        a = int(30 * (1.0 - r / 220.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(60, 200, 255, a))

    # 6-branch symmetrical crystal snowflake
    for arm in range(6):
        ang = arm * (math.pi / 3.0)
        cos_a = math.cos(ang)
        sin_a = math.sin(ang)

        # Main spine
        x_end = cx + cos_a * 190
        y_end = cy + sin_a * 190
        draw.line([(cx, cy), (x_end, y_end)], fill=(220, 245, 255, 255), width=6)
        draw.line([(cx, cy), (x_end, y_end)], fill=(100, 220, 255, 200), width=12)

        # Side barbs
        for d in [60, 110, 150]:
            bx = cx + cos_a * d
            by = cy + sin_a * d
            barb_len = 45 - (d * 0.15)
            for b_dir in [-math.pi / 4.0, math.pi / 4.0]:
                b_ang = ang + b_dir
                b_end_x = bx + math.cos(b_ang) * barb_len
                b_end_y = by + math.sin(b_ang) * barb_len
                draw.line([(bx, by), (b_end_x, b_end_y)], fill=(240, 250, 255, 255), width=4)
                draw.line([(bx, by), (b_end_x, b_end_y)], fill=(60, 190, 255, 180), width=8)

        # Diamond tip
        tip_x = cx + cos_a * 205
        tip_y = cy + sin_a * 205
        draw.polygon([
            (tip_x, tip_y),
            (x_end + math.cos(ang + math.pi/2) * 10, y_end + math.sin(ang + math.pi/2) * 10),
            (x_end + cos_a * 25, y_end + sin_a * 25),
            (x_end - math.cos(ang + math.pi/2) * 10, y_end - math.sin(ang + math.pi/2) * 10)
        ], fill=(255, 255, 255, 255))

    # Center hexagonal crystal core
    hex_pts = []
    for i in range(6):
        a = i * (math.pi / 3.0)
        hex_pts.append((cx + math.cos(a) * 36, cy + math.sin(a) * 36))
    draw.polygon(hex_pts, fill=(230, 250, 255, 240), outline=(80, 210, 255, 255))

    im = im.filter(ImageFilter.GaussianBlur(1.2))
    p1 = os.path.join(TEXTURE_DIR, "fx_cryo_snowflake.png")
    im.save(p1)
    print(f"  + Generated Texture: {p1}")

    # 2. Sharp Glacial Frost Spike (256x512)
    im2 = Image.new("RGBA", (256, 512), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(im2)
    # Shard silhouette
    pts_spike = [
        (128, 20),   # Apex point
        (165, 180),
        (185, 380),
        (150, 490),
        (106, 490),
        (71, 380),
        (91, 180)
    ]
    draw2.polygon(pts_spike, fill=(160, 235, 255, 210), outline=(255, 255, 255, 255))
    # Inner facets
    draw2.line([(128, 20), (128, 490)], fill=(255, 255, 255, 240), width=4)
    draw2.line([(128, 180), (165, 180)], fill=(255, 255, 255, 180), width=2)
    draw2.line([(128, 380), (71, 380)], fill=(255, 255, 255, 180), width=2)
    im2 = im2.filter(ImageFilter.GaussianBlur(1.0))
    p2 = os.path.join(TEXTURE_DIR, "fx_frost_spike.png")
    im2.save(p2)
    print(f"  + Generated Texture: {p2}")

    # 3. Luminous Glacial Runic Magic Circle (512x512)
    im3 = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw3 = ImageDraw.Draw(im3)
    # Rings
    for r, w, a in [(240, 4, 180), (225, 2, 220), (160, 3, 200), (145, 1, 160), (90, 2, 240)]:
        draw3.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(100, 220, 255, a), width=w)
    # Inner 8-pointed star
    star_pts = []
    for i in range(16):
        a = i * (math.pi / 8.0)
        r = 220 if i % 2 == 0 else 110
        star_pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    draw3.polygon(star_pts, outline=(180, 240, 255, 210), width=2)

    im3 = im3.filter(ImageFilter.GaussianBlur(1.0))
    p3 = os.path.join(TEXTURE_DIR, "magic_circle_cryo.png")
    im3.save(p3)
    print(f"  + Generated Texture: {p3}")

async def main():
    await generate_voices()
    build_audio()
    build_textures()
    print("[ALL DONE] Ellen Joe voice pack, Cryo SFX, and VFX textures ready!")

if __name__ == "__main__":
    asyncio.run(main())
