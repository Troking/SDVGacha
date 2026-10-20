"""
Generates high quality visual FX textures and organic audio SFX for Hu Tao's Pyro Elemental Skill
"""
import os
import math
import wave
import struct
import random
from PIL import Image, ImageDraw, ImageFilter

TEXTURE_DIR = "e:/Trok/ChibiRPG_Project/game/assets/textures"
SOUND_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds"
os.makedirs(TEXTURE_DIR, exist_ok=True)
os.makedirs(SOUND_DIR, exist_ok=True)

# ========================================================
# 1. TEXTURE GENERATION
# ========================================================
def generate_pyro_butterfly_texture():
    # 512x512 Luminous Anime Flame Butterfly
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx, cy = w // 2, h // 2

    # Outer fiery glow halo
    for r in range(180, 20, -10):
        alpha = int(35 * (1.0 - r / 180.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 90, 20, alpha))

    # Upper Wing Left
    pts_ul = [(cx, cy), (cx - 160, cy - 140), (cx - 210, cy - 60), (cx - 140, cy + 20), (cx - 30, cy)]
    draw.polygon(pts_ul, fill=(255, 120, 30, 230), outline=(255, 230, 110, 255))
    # Upper Wing Right
    pts_ur = [(cx, cy), (cx + 160, cy - 140), (cx + 210, cy - 60), (cx + 140, cy + 20), (cx + 30, cy)]
    draw.polygon(pts_ur, fill=(255, 120, 30, 230), outline=(255, 230, 110, 255))

    # Lower Wing Left (Scalloped Swallowtail tip)
    pts_ll = [(cx, cy), (cx - 120, cy + 40), (cx - 150, cy + 160), (cx - 70, cy + 120), (cx, cy)]
    draw.polygon(pts_ll, fill=(235, 60, 20, 220), outline=(255, 200, 80, 255))
    # Lower Wing Right
    pts_lr = [(cx, cy), (cx + 120, cy + 40), (cx + 150, cy + 160), (cx + 70, cy + 120), (cx, cy)]
    draw.polygon(pts_lr, fill=(235, 60, 20, 220), outline=(255, 200, 80, 255))

    # Inner incandescent wing eyes / fire cores
    draw.ellipse([cx - 140, cy - 90, cx - 70, cy - 20], fill=(255, 240, 150, 240))
    draw.ellipse([cx + 70, cy - 90, cx + 140, cy - 20], fill=(255, 240, 150, 240))
    draw.ellipse([cx - 100, cy + 60, cx - 50, cy + 110], fill=(255, 210, 100, 220))
    draw.ellipse([cx + 50, cy + 60, cx + 100, cy + 110], fill=(255, 210, 100, 220))

    # Center Body & Antennae
    draw.ellipse([cx - 12, cy - 70, cx + 12, cy + 80], fill=(255, 255, 220, 255))
    draw.line([(cx - 4, cy - 65), (cx - 45, cy - 140)], fill=(255, 240, 180, 255), width=4)
    draw.line([(cx + 4, cy - 65), (cx + 45, cy - 140)], fill=(255, 240, 180, 255), width=4)
    draw.ellipse([cx - 50, cy - 148, cx - 40, cy - 136], fill=(255, 255, 200, 255))
    draw.ellipse([cx + 40, cy - 148, cx + 50, cy - 136], fill=(255, 255, 200, 255))

    im = im.filter(ImageFilter.GaussianBlur(1.8))
    im.save(os.path.join(TEXTURE_DIR, "fx_pyro_butterfly.png"))
    print("Saved fx_pyro_butterfly.png")

def generate_flame_wisp_texture():
    # 512x512 Soft Organic Flame Wisp
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx, cy = w // 2, h // 2

    # Multi-layered Gaussian flame plume
    for r in range(220, 10, -5):
        t = 1.0 - (r / 220.0)
        # Gradient from deep red -> fiery orange -> bright yellow -> white core
        if t < 0.35:
            col = (230, 45, 15, int(t * 220))
        elif t < 0.75:
            norm_t = (t - 0.35) / 0.40
            col = (255, int(50 + norm_t * 150), 30, int(120 + norm_t * 110))
        else:
            norm_t = (t - 0.75) / 0.25
            col = (255, 220 + int(norm_t * 35), int(100 + norm_t * 155), 255)

        w_rad = max(4, int(r * 0.75))
        h_rad = max(6, int(r * 1.15))
        draw.ellipse([cx - w_rad, cy - h_rad, cx + w_rad, cy + h_rad], fill=col)

    im = im.filter(ImageFilter.GaussianBlur(3.5))
    im.save(os.path.join(TEXTURE_DIR, "fx_flame_wisp.png"))
    print("Saved fx_flame_wisp.png")

def generate_shockwave_ring_texture():
    # 512x512 Expanding Shockwave Ring
    w, h = 512, 512
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx, cy = w // 2, h // 2
    r_outer = 220
    r_inner = 175

    for r in range(r_inner, r_outer):
        t = (r - r_inner) / float(r_outer - r_inner)
        # Parabolic bell curve across ring thickness
        intensity = math.sin(t * math.pi)
        alpha = int(intensity * 240)
        r_c = 255
        g_c = int(140 + intensity * 90)
        b_c = int(40 + intensity * 70)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(r_c, g_c, b_c, alpha), width=3)

    im = im.filter(ImageFilter.GaussianBlur(2.0))
    im.save(os.path.join(TEXTURE_DIR, "fx_shockwave_ring.png"))
    print("Saved fx_shockwave_ring.png")

# ========================================================
# 2. ORGANIC SOUND SYNTHESIS (Flame Burst & Shimmer SFX)
# ========================================================
def generate_organic_flame_burst_sound():
    sample_rate = 44100
    duration = 1.35
    total_samples = int(sample_rate * duration)
    stereo_data = bytearray()

    # Audio synthesis parameters
    # 1. Sub-bass resonant ignition thump (45Hz -> 20Hz boom)
    # 2. Pink noise flame rush (bandpass sweep)
    # 3. Organic campfire crackle & pop sparks
    # 4. Harmonic mystical bell chime (Genshin chime chord)

    # Pre-generate random crackle event timestamps
    crackle_times = [random.uniform(0.04, 0.65) for _ in range(45)]
    crackle_freqs = [random.uniform(900, 2800) for _ in crackle_times]

    # Mystical chord frequencies (Hu Tao spirit chimes: E minor 9th / Genshin pentatonic)
    chime_freqs = [659.25, 783.99, 987.77, 1174.66, 1318.51, 1567.98] # E5, G5, B5, D6, E6, G6

    # Pink noise state
    b0, b1, b2, b3, b4, b5, b6 = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

    for i in range(total_samples):
        t = i / float(sample_rate)

        # 1. Sub-bass Ignition Impact (Visceral body)
        sub_env = (math.sin(min(1.0, t / 0.08) * math.pi * 0.5) ** 2) * math.exp(-t * 3.8)
        sub_freq = 110.0 * math.exp(-t * 4.2) + 38.0
        sub_wave = math.sin(2.0 * math.pi * sub_freq * t) * sub_env * 0.55

        # 2. Blazing Fire Rush (Organic filtered noise)
        white = random.uniform(-1.0, 1.0)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        # Resonant fire rush envelope
        fire_env = (math.sin(min(1.0, t / 0.14) * math.pi * 0.5) ** 2) * math.exp(-t * 3.2)
        fire_rush = pink * 0.075 * fire_env

        # 3. Organic Crackle Pops
        crackle_sum = 0.0
        for c_time, c_freq in zip(crackle_times, crackle_freqs):
            dt = t - c_time
            if 0.0 <= dt < 0.018:
                pop_env = math.sin((dt / 0.018) * math.pi) * math.exp(-dt * 250.0)
                crackle_sum += math.sin(2.0 * math.pi * c_freq * dt) * pop_env * 0.22

        # 4. Ethereal Spirit Chimes (Genshin afterlife bells)
        chime_sum = 0.0
        if t > 0.02:
            chime_t = t - 0.02
            chime_env = math.exp(-chime_t * 2.5) * (math.sin(min(1.0, chime_t / 0.06) * math.pi * 0.5))
            for cf in chime_freqs:
                # Add shimmer detuning
                chime_sum += (math.sin(2.0 * math.pi * cf * chime_t) + 0.4 * math.sin(2.0 * math.pi * (cf * 2.01) * chime_t)) * 0.04 * chime_env

        # Master mix
        sample_l = sub_wave + fire_rush * 1.1 + crackle_sum * 0.95 + chime_sum * 1.2
        sample_r = sub_wave + fire_rush * 0.95 + crackle_sum * 1.1 + chime_sum * 1.1

        # Soft tube saturation / gentle clipping
        sample_l = math.tanh(sample_l * 1.15)
        sample_r = math.tanh(sample_r * 1.15)

        int_l = int(max(-32767, min(32767, sample_l * 32767)))
        int_r = int(max(-32767, min(32767, sample_r * 32767)))
        stereo_data.extend(struct.pack('<hh', int_l, int_r))

    out_path = os.path.join(SOUND_DIR, "flame_burst.wav")
    with wave.open(out_path, 'wb') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(stereo_data)
    print("Saved flame_burst.wav (High-fidelity Organic Pyro Audio)")

def main():
    print("Generating Pyro Skill visual & audio assets...")
    generate_pyro_butterfly_texture()
    generate_flame_wisp_texture()
    generate_shockwave_ring_texture()
    generate_organic_flame_burst_sound()
    print("All Pyro Skill assets created successfully!")

if __name__ == '__main__':
    main()
