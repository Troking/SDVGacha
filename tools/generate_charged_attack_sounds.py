"""
Generates organic, anime-style Genshin-grade sound effects for the charged attack:
1. sword_charge_ready.wav - Crisp blade pull, rising airy energy vortex, and sparkling crystal glint.
2. sword_slash_charged.wav - Powerful organic blade whip, warm combustion roar, sub-bass crunch, and steel resonance.
"""

import os
import wave
import numpy as np

OUTPUT_DIR = "game/assets/sounds"
SAMPLE_RATE = 44100

def write_stereo_wav(filepath, left, right):
    left = np.clip(left, -1.0, 1.0)
    right = np.clip(right, -1.0, 1.0)
    left_int = (left * 32767.0).astype(np.int16)
    right_int = (right * 32767.0).astype(np.int16)
    
    stereo_interleaved = np.empty((len(left) * 2,), dtype=np.int16)
    stereo_interleaved[0::2] = left_int
    stereo_interleaved[1::2] = right_int
    
    with wave.open(filepath, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(stereo_interleaved.tobytes())
    print(f"Generated {filepath} ({len(left)/SAMPLE_RATE:.2f}s)")

def generate_charge_windup():
    duration = 0.50
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    
    # Layer 1: Inward energy vortex (air suction with rising frequency)
    noise = np.random.uniform(-1.0, 1.0, len(t))
    # Smooth moving average to simulate bandpassed acoustic air
    window_size = 18
    smooth_noise = np.convolve(noise, np.ones(window_size)/window_size, mode='same')
    
    # Rising cutoff envelope & crescendo
    vortex_env = (t / duration) ** 1.8
    pitch_mod = 1.0 + 3.0 * (t / duration) ** 2.0
    air_layer_l = smooth_noise * vortex_env * 0.42 * np.sin(2.0 * np.pi * 320.0 * pitch_mod * t)
    air_layer_r = smooth_noise * vortex_env * 0.42 * np.cos(2.0 * np.pi * 335.0 * pitch_mod * t)
    
    # Layer 2: Steel blade resonance (metallic gleam building up)
    steel_f1 = 2093.0 # C7
    steel_f2 = 3136.0 # G7
    steel_f3 = 4186.0 # C8
    vibrato = np.sin(2.0 * np.pi * 7.5 * t) * 12.0
    steel_env = (t / duration) ** 2.2
    
    steel_l = (
        0.35 * np.sin(2.0 * np.pi * (steel_f1 + vibrato) * t) +
        0.20 * np.sin(2.0 * np.pi * (steel_f2 + vibrato * 1.5) * t) +
        0.12 * np.sin(2.0 * np.pi * (steel_f3) * t)
    ) * steel_env
    
    steel_r = (
        0.35 * np.sin(2.0 * np.pi * (steel_f1 * 1.004 + vibrato) * t) +
        0.20 * np.sin(2.0 * np.pi * (steel_f2 * 0.996 + vibrato * 1.5) * t) +
        0.12 * np.sin(2.0 * np.pi * (steel_f3 * 1.002) * t)
    ) * steel_env
    
    # Layer 3: Brilliant crystal glint chime accent at readiness threshold (t = 0.32s)
    chime_start = 0.30
    chime_idx = int(chime_start * SAMPLE_RATE)
    chime_len = len(t) - chime_idx
    t_chime = np.linspace(0, duration - chime_start, chime_len, endpoint=False)
    chime_env = np.exp(-t_chime * 16.0)
    
    chime_bell_l = (
        0.55 * np.sin(2.0 * np.pi * 2637.0 * t_chime) + # E7
        0.35 * np.sin(2.0 * np.pi * 3951.0 * t_chime) + # B7
        0.25 * np.sin(2.0 * np.pi * 5274.0 * t_chime)   # E8
    ) * chime_env
    
    chime_bell_r = (
        0.55 * np.sin(2.0 * np.pi * 2642.0 * t_chime) +
        0.35 * np.sin(2.0 * np.pi * 3940.0 * t_chime) +
        0.25 * np.sin(2.0 * np.pi * 5285.0 * t_chime)
    ) * chime_env
    
    left = air_layer_l + steel_l
    right = air_layer_r + steel_r
    left[chime_idx:] += chime_bell_l
    right[chime_idx:] += chime_bell_r
    
    # Master volume envelope
    fade_in = np.clip(t / 0.04, 0.0, 1.0)
    left *= fade_in
    right *= fade_in
    
    # Normalize
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)), 1e-4)
    left = (left / peak) * 0.88
    right = (right / peak) * 0.88
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "sword_charge_ready.wav"), left, right)

def generate_charged_slash():
    duration = 0.65
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    
    # Layer 1: Razor-sharp blade slice whip transient (0 to 0.18s)
    t_whip = np.clip(t / 0.16, 0.0, 1.0)
    whip_pitch = 3800.0 * np.exp(-t * 22.0) + 380.0
    whip_env = np.exp(-t * 14.0)
    whip_noise = np.random.uniform(-0.8, 0.8, len(t)) * whip_env
    whip_l = (np.sin(2.0 * np.pi * whip_pitch * t) * 0.6 + whip_noise * 0.5) * whip_env
    whip_r = (np.cos(2.0 * np.pi * (whip_pitch * 1.02) * t) * 0.6 + whip_noise * 0.5) * whip_env
    
    # Layer 2: Organic flame combustion roar (warm, airy rush)
    fire_t = np.clip(t - 0.02, 0.0, duration)
    fire_env = np.exp(-fire_t * 6.5) * (1.0 - np.exp(-fire_t * 40.0))
    # Lowpass flame body
    noise = np.random.uniform(-1.0, 1.0, len(t))
    w_fire = 24
    fire_body = np.convolve(noise, np.ones(w_fire)/w_fire, mode='same')
    flame_l = fire_body * fire_env * 0.75 * np.sin(2.0 * np.pi * 210.0 * t)
    flame_r = fire_body * fire_env * 0.75 * np.cos(2.0 * np.pi * 225.0 * t)
    
    # Layer 3: Tactile sub-bass impact body (78 Hz punch)
    sub_env = np.exp(-t * 9.0)
    sub_pitch = 78.0 * np.exp(-t * 8.0)
    sub_l = np.sin(2.0 * np.pi * sub_pitch * t) * sub_env * 0.65
    sub_r = np.sin(2.0 * np.pi * (sub_pitch * 0.98) * t) * sub_env * 0.65
    
    # Layer 4: Steel harmonic ring decay
    ring_env = np.exp(-t * 4.5)
    ring_l = (
        0.30 * np.sin(2.0 * np.pi * 1760.0 * t) +
        0.18 * np.sin(2.0 * np.pi * 3520.0 * t) +
        0.08 * np.sin(2.0 * np.pi * 5280.0 * t)
    ) * ring_env
    ring_r = (
        0.30 * np.sin(2.0 * np.pi * 1764.0 * t) +
        0.18 * np.sin(2.0 * np.pi * 3512.0 * t) +
        0.08 * np.sin(2.0 * np.pi * 5290.0 * t)
    ) * ring_env
    
    left = whip_l + flame_l + sub_l + ring_l
    right = whip_r + flame_r + sub_r + ring_r
    
    # Normalize
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)), 1e-4)
    left = (left / peak) * 0.95
    right = (right / peak) * 0.95
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "sword_slash_charged.wav"), left, right)

if __name__ == "__main__":
    generate_charge_windup()
    generate_charged_slash()
    print("Charged attack audio assets generated successfully!")
