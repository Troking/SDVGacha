"""
Organic Jump Sound Generator for Chibi RPG (Genshin Impact / Anime ARPG style)
Synthesizes multi-layered organic jump audio:
- Layer 1: Ground push-off (boot compression & tactile low thump 80-140 Hz)
- Layer 2: Silky fabric & gothic coat rustle (fluttering cloth bandpass 2200-4000 Hz)
- Layer 3: Airy wind whoosh (aerodynamic lift 400-800 Hz)
- Layer 4: Delicate pyro ember sparkle (whisper-soft shimmer 5000-8000 Hz)
Generates multiple organic variations to eliminate repetitive audio fatigue.
"""
import os
import wave
import numpy as np

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds"
os.makedirs(OUTPUT_DIR, exist_ok=True)

SR = 44100

def synthesize_jump(seed=42, dur=0.22, thump_freq=110, thump_decay=0.028, cloth_center=2600, whoosh_weight=0.45, ember_weight=0.25):
    np.random.seed(seed)
    n_samples = int(SR * dur)
    t = np.linspace(0, dur, n_samples, endpoint=False)

    # 1. Physical boot push-off (ground contact impulse)
    f_inst = thump_freq * (1.0 + 0.65 * np.exp(-t / 0.018))
    phase = 2.0 * np.pi * np.cumsum(f_inst) / SR
    boot_sine = np.sin(phase) * np.exp(-t / thump_decay)

    noise_raw = np.random.randn(n_samples)
    low_noise = np.convolve(noise_raw, np.ones(28)/28, mode='same')
    boot_punch = low_noise * np.exp(-t / (thump_decay * 0.75)) * 0.6
    boot = boot_sine * 0.85 + boot_punch * 0.45

    # 2. Silky coat / cloth rustle
    flutter_freq = 36.0 + (seed % 10) * 1.5
    flutter = 1.0 + 0.32 * np.sin(2.0 * np.pi * flutter_freq * t)
    
    kernel_size = 64
    k_t = np.arange(-kernel_size // 2, kernel_size // 2)
    bp_cloth = np.cos(2.0 * np.pi * cloth_center * k_t / SR) * np.hanning(kernel_size)
    cloth_noise = np.convolve(noise_raw * flutter, bp_cloth, mode='same')
    env_cloth = (1.0 - np.exp(-t / 0.010)) * np.exp(-t / 0.085)
    cloth = cloth_noise * env_cloth * 0.38

    # 3. Aerodynamic wind whoosh
    bp_whoosh = np.cos(2.0 * np.pi * 540.0 * k_t / SR) * np.hanning(kernel_size)
    whoosh_noise = np.convolve(noise_raw, bp_whoosh, mode='same')
    env_whoosh = (1.0 - np.exp(-t / 0.022)) * np.exp(-t / 0.11)
    whoosh = whoosh_noise * env_whoosh * whoosh_weight

    # 4. Subtle pyro ember shimmer
    bp_ember = np.cos(2.0 * np.pi * 6800.0 * k_t / SR) * np.hanning(kernel_size)
    ember_noise = np.convolve(noise_raw, bp_ember, mode='same')
    env_ember = (1.0 - np.exp(-t / 0.018)) * np.exp(-t / 0.075)
    ember = ember_noise * env_ember * ember_weight

    # Layer blending
    combined = boot * 0.62 + cloth * 0.58 + whoosh * 0.42 + ember * 0.28

    # Anti-click envelope
    fade_in = np.clip(t / 0.003, 0.0, 1.0)
    fade_out = np.clip((dur - t) / 0.035, 0.0, 1.0)
    combined = combined * fade_in * fade_out

    # Peak normalization to -1.2 dB (~0.87)
    peak = np.abs(combined).max()
    if peak > 1e-5:
        combined = combined * (0.87 / peak)

    return (combined * 32767).astype(np.int16)

def save_wav(filename, samples):
    with wave.open(filename, 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(samples.tobytes())
    print(f"Saved: {filename} ({len(samples)} samples, {len(samples)/SR:.3f}s)")

def main():
    # Variation 1: Crisp & energetic (Standard heroic leap)
    v1 = synthesize_jump(seed=101, dur=0.22, thump_freq=118, thump_decay=0.026, cloth_center=2700, whoosh_weight=0.44)
    save_wav(os.path.join(OUTPUT_DIR, "jump_1.wav"), v1)

    # Variation 2: Light & nimble (Breezy silk flutter)
    v2 = synthesize_jump(seed=202, dur=0.20, thump_freq=126, thump_decay=0.022, cloth_center=3100, whoosh_weight=0.38)
    save_wav(os.path.join(OUTPUT_DIR, "jump_2.wav"), v2)

    # Variation 3: Dynamic & athletic (Firm boot compression + wind lift)
    v3 = synthesize_jump(seed=303, dur=0.24, thump_freq=104, thump_decay=0.032, cloth_center=2400, whoosh_weight=0.50)
    save_wav(os.path.join(OUTPUT_DIR, "jump_3.wav"), v3)

    # Master fallback: jump.wav (Balanced take)
    master = synthesize_jump(seed=404, dur=0.22, thump_freq=112, thump_decay=0.028, cloth_center=2600, whoosh_weight=0.45)
    save_wav(os.path.join(OUTPUT_DIR, "jump.wav"), master)

    print("All organic jump sounds generated successfully!")

if __name__ == '__main__':
    main()
