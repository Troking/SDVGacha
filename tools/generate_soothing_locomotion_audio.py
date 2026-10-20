"""
Generates ultra-soothing, natural organic sound effects for locomotion:
1. glider_wind.wav: Soft, velvety mountain breeze with seamless loop.
2. glider_open.wav: Gentle silk wing unfurl with soft airy whoosh.
3. water_swim_stroke.wav: Natural, gentle water paddle and fluid lap.
4. water_splash_enter.wav: Soft bubbly water plunge.
5. water_splash_jump.wav: Gentle aquatic leap.
"""

import math
import wave
import struct
import random
import os

OUTPUT_DIR_PLAYER = "e:/Trok/ChibiRPG_Project/game/assets/sounds/player"
OUTPUT_DIR_SOUNDS = "e:/Trok/ChibiRPG_Project/game/assets/sounds"
os.makedirs(OUTPUT_DIR_PLAYER, exist_ok=True)
os.makedirs(OUTPUT_DIR_SOUNDS, exist_ok=True)

def write_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        frames = bytearray()
        for s in samples:
            s_clamped = max(-1.0, min(1.0, s))
            frames.extend(struct.pack("<h", int(s_clamped * 32767)))
        w.writeframes(frames)
    print(f"Generated: {filename} ({len(samples)} samples)")

sr = 44100

# ==============================================================================
# 1. GLIDER WIND LOOP (glider_wind.wav)
# Seamless, velvety, airy mountain breeze with smooth pink/brownian lowpass
# ==============================================================================
dur_wind = 3.0
n_wind = int(dur_wind * sr)
raw_noise = [random.gauss(0, 1.0) for _ in range(n_wind)]

# Multi-stage low-pass filtering for silky soft air texture (cutoff ~ 450 Hz)
lp1 = 0.0
lp2 = 0.0
filtered_wind = []
alpha = 0.045 # Strong lowpass

for i in range(n_wind):
    lp1 += alpha * (raw_noise[i] - lp1)
    lp2 += alpha * (lp1 - lp2)
    t = float(i) / sr
    # Very gentle, undulating air current breath (0.35 Hz)
    breath = 0.85 + 0.15 * math.sin(2.0 * math.pi * 0.35 * t)
    filtered_wind.append(lp2 * breath * 0.35)

# Seamless loop crossfade (0.3s crossfade at boundaries)
fade_len = int(0.3 * sr)
glider_wind = list(filtered_wind)
for i in range(fade_len):
    frac = float(i) / fade_len
    # Blend end into start
    glider_wind[i] = (1.0 - frac) * filtered_wind[n_wind - fade_len + i] + frac * filtered_wind[i]
    glider_wind[n_wind - fade_len + i] = glider_wind[i]

write_wav(os.path.join(OUTPUT_DIR_SOUNDS, "glider_wind.wav"), glider_wind)

# ==============================================================================
# 2. GLIDER OPEN (glider_open.wav)
# Elegant, soft silk glider fabric flap with gentle aerodynamic whoosh
# ==============================================================================
dur_open = 0.36
n_open = int(dur_open * sr)
glider_open = []
lp_open = 0.0

for i in range(n_open):
    t = float(i) / sr
    env = math.exp(-t * 9.5) * (t / 0.04 if t < 0.04 else 1.0)
    # Silk flutter burst
    noise = random.gauss(0, 1.0)
    lp_open += 0.12 * (noise - lp_open)
    # Air swell
    whoosh = math.sin(2.0 * math.pi * (180.0 - t * 80.0) * t) * 0.45
    flutter = math.sin(2.0 * math.pi * 32.0 * t) * 0.25 * math.exp(-t * 14.0)
    sample = (lp_open * 0.55 + whoosh + flutter) * env * 0.48
    glider_open.append(sample)

write_wav(os.path.join(OUTPUT_DIR_SOUNDS, "glider_open.wav"), glider_open)

# ==============================================================================
# 3. WATER SWIM STROKE (water_swim_stroke.wav)
# Organic, gentle water paddle / displacement without harsh synthetic tone
# ==============================================================================
dur_stroke = 0.42
n_stroke = int(dur_stroke * sr)
swim_stroke = []
lp_water = 0.0

for i in range(n_stroke):
    t = float(i) / sr
    # Smooth natural swell and decay
    if t < 0.06:
        env = (t / 0.06) ** 1.5
    else:
        env = math.exp(-(t - 0.06) * 8.5)
    
    # Low fluid surge (warm 75-140 Hz body)
    fluid_surge = math.sin(2.0 * math.pi * (115.0 - t * 55.0) * t) * 0.55
    # Gentle bubbly texture (lowpass filtered noise around 280 Hz)
    noise = random.gauss(0, 1.0)
    lp_water += 0.065 * (noise - lp_water)
    # Soft droplet swirl
    droplet = math.sin(2.0 * math.pi * (240.0 + math.sin(t * 30.0) * 40.0) * t) * 0.18 * math.exp(-t * 12.0)
    
    sample = (fluid_surge + lp_water * 0.45 + droplet) * env * 0.38
    swim_stroke.append(sample)

write_wav(os.path.join(OUTPUT_DIR_PLAYER, "water_swim_stroke.wav"), swim_stroke)

# ==============================================================================
# 4. WATER SPLASH ENTER (water_splash_enter.wav)
# Soft aquatic entry plunge
# ==============================================================================
dur_enter = 0.48
n_enter = int(dur_enter * sr)
splash_enter = []
lp_ent = 0.0

for i in range(n_enter):
    t = float(i) / sr
    env = math.exp(-t * 8.0) * (t / 0.03 if t < 0.03 else 1.0)
    surge = math.sin(2.0 * math.pi * (120.0 - t * 65.0) * t) * 0.50
    noise = random.gauss(0, 1.0)
    lp_ent += 0.08 * (noise - lp_ent)
    bubble = math.sin(2.0 * math.pi * 320.0 * t) * 0.20 * math.exp(-t * 10.0)
    sample = (surge + lp_ent * 0.40 + bubble) * env * 0.45
    splash_enter.append(sample)

write_wav(os.path.join(OUTPUT_DIR_PLAYER, "water_splash_enter.wav"), splash_enter)

# ==============================================================================
# 5. WATER SPLASH JUMP (water_splash_jump.wav)
# Gentle leap out of water
# ==============================================================================
dur_jump = 0.32
n_jump = int(dur_jump * sr)
splash_jump = []
lp_jmp = 0.0

for i in range(n_jump):
    t = float(i) / sr
    env = math.exp(-t * 11.0) * (t / 0.02 if t < 0.02 else 1.0)
    surge = math.sin(2.0 * math.pi * (140.0 + t * 40.0) * t) * 0.45
    noise = random.gauss(0, 1.0)
    lp_jmp += 0.09 * (noise - lp_jmp)
    sample = (surge + lp_jmp * 0.35) * env * 0.42
    splash_jump.append(sample)

write_wav(os.path.join(OUTPUT_DIR_PLAYER, "water_splash_jump.wav"), splash_jump)

print("All soothing locomotion audio generated successfully!")
