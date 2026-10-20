"""
Generates moderate, pleasant, high-quality anime RPG UI sound effects:
1. ui_hover.wav  - Gentle, velvety paper/glass tick / optical shimmer (subtle, non-fatiguing, pleasant on sweep)
2. ui_click.wav  - Crisp, tactile, satisfying crystal/wooden tab switch click
3. ui_equip.wav  - Satisfying metallic armor/weapon latch click
"""
import os
import wave
import numpy as np

OUTPUT_DIR = "game/assets/sounds/ui"
os.makedirs(OUTPUT_DIR, exist_ok=True)
SAMPLE_RATE = 44100

def write_stereo_wav(filepath, left, right):
    left = np.nan_to_num(left)
    right = np.nan_to_num(right)
    
    # Soft limiter & peak normalization
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)), 1e-4)
    target_peak = 0.82
    left = (left / peak) * target_peak
    right = (right / peak) * target_peak
    
    left = np.tanh(left * 1.05) / 1.05
    right = np.tanh(right * 1.05) / 1.05
    
    left_int = (np.clip(left, -1.0, 1.0) * 32767.0).astype(np.int16)
    right_int = (np.clip(right, -1.0, 1.0) * 32767.0).astype(np.int16)
    
    stereo = np.empty((len(left) * 2,), dtype=np.int16)
    stereo[0::2] = left_int
    stereo[1::2] = right_int
    
    with wave.open(filepath, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(stereo.tobytes())
    print(f"Generated: {filepath} ({len(left)/SAMPLE_RATE*1000:.1f}ms)")

def create_ui_hover():
    # Extremely soft, gentle optical shimmer / paper tick (~28ms)
    duration = 0.035
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    
    # Soft high-pass transient (gentle felt mallet on crystal glass)
    # Fundamental around 1850 Hz decaying in 18ms
    f0 = 1850.0
    f1 = 3700.0
    env = np.exp(-t * 160.0) * np.sin(np.clip(t / 0.003, 0.0, 1.0) * np.pi * 0.5)
    
    tone = (
        0.55 * np.sin(2.0 * np.pi * f0 * t) +
        0.25 * np.sin(2.0 * np.pi * f1 * t)
    ) * env
    
    # Very subtle airy shimmer
    noise = np.random.randn(n) * np.exp(-t * 220.0) * 0.15
    
    left = (tone + noise) * 0.45
    # Haas micro-delay for stereo air
    delay = int(SAMPLE_RATE * 0.0004)
    right = np.zeros_like(left)
    right[delay:] = left[:-delay] * 0.95
    right[:delay] = left[:delay] * 0.95
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "ui_hover.wav"), left, right)

def create_ui_click():
    # Crisp, satisfying tactile Genshin tab switch click (~55ms)
    duration = 0.065
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    
    # Acoustic wood/crystal body: fast 420 Hz thump + 1240 Hz crystal ping
    thump = np.sin(2.0 * np.pi * (420.0 * np.exp(-t * 60.0)) * t) * np.exp(-t * 90.0) * 0.65
    ping = (
        0.45 * np.sin(2.0 * np.pi * 1240.0 * t) * np.exp(-t * 70.0) +
        0.20 * np.sin(2.0 * np.pi * 2480.0 * t) * np.exp(-t * 140.0)
    )
    
    snap = np.random.randn(n) * np.exp(-t * 350.0) * 0.35
    
    left = thump + ping + snap
    delay = int(SAMPLE_RATE * 0.0003)
    right = np.zeros_like(left)
    right[delay:] = left[:-delay]
    right[:delay] = left[:delay]
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "ui_click.wav"), left, right)

def create_ui_equip():
    # Tactile gear latch / armor snap (~75ms)
    duration = 0.085
    n = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n, endpoint=False)
    
    # Dual transient: click + resonant metallic latch
    t_cl1 = t
    t_cl2 = np.maximum(0.0, t - 0.016)
    
    click1 = np.sin(2.0 * np.pi * 650.0 * t_cl1) * np.exp(-t_cl1 * 120.0)
    click2 = (
        0.6 * np.sin(2.0 * np.pi * 920.0 * t_cl2) +
        0.3 * np.sin(2.0 * np.pi * 1840.0 * t_cl2)
    ) * np.exp(-t_cl2 * 65.0) * np.where(t >= 0.016, 1.0, 0.0)
    
    scrape = np.random.randn(n) * np.exp(-t * 140.0) * 0.25
    
    left = click1 * 0.5 + click2 * 0.7 + scrape * 0.2
    right = click1 * 0.45 + click2 * 0.75 + scrape * 0.2
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "ui_equip.wav"), left, right)

def main():
    print("Generating moderate, elegant UI sounds...")
    create_ui_hover()
    create_ui_click()
    create_ui_equip()
    print("UI sounds generated successfully!")

if __name__ == "__main__":
    main()
