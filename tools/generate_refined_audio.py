"""
Refined Organic Sound Generator for Chibi RPG
Generates:
1. sword_slash_charged.wav: Heavy organic sword finisher cleave (aerodynamic edge slice, visceral physical thump, metallic beam resonance, stereo sweep, warm pyro swell).
2. jump.wav, jump_1.wav, jump_2.wav, jump_3.wav: Light, agile anime hop sounds (silky fabric flutter, delicate sole liftoff, zero cartoon boing).
"""

import os
import wave
import numpy as np

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds"
os.makedirs(OUTPUT_DIR, exist_ok=True)
SR = 44100

def write_stereo_wav(path, left, right):
    left = np.clip(left, -1.0, 1.0)
    right = np.clip(right, -1.0, 1.0)
    left_i16 = (left * 32767).astype(np.int16)
    right_i16 = (right * 32767).astype(np.int16)
    stereo = np.empty((len(left) * 2,), dtype=np.int16)
    stereo[0::2] = left_i16
    stereo[1::2] = right_i16
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(stereo.tobytes())
    print(f"Generated: {path}")

def generate_organic_sword_finisher():
    dur = 0.72
    n_samples = int(SR * dur)
    t = np.linspace(0, dur, n_samples, endpoint=False)
    np.random.seed(1337)

    # 1. Aerodynamic Blade Slicing Whoosh (Air cleave transient)
    # The blade accelerates through air: frequency envelope peaks fast then dissipates
    whoosh_t = np.clip(t / 0.18, 0.0, 1.0)
    whoosh_env = np.sin(whoosh_t * np.pi) * np.exp(-t * 8.5)
    
    # Pink-filtered aerodynamic turbulence
    white = np.random.randn(n_samples)
    b_filter = np.ones(18) / 18.0
    turb = np.convolve(white, b_filter, mode='same')
    
    # Edge bite (steel cutting air with high-speed friction)
    edge_bp = np.convolve(white, np.cos(2.0 * np.pi * 3200.0 * np.arange(-32, 32)/SR) * np.hanning(64), mode='same')
    blade_slice = (turb * 0.65 + edge_bp * 0.45) * whoosh_env

    # 2. Heavy Physical Cleave Thump (tactile chest resonance, non-linear body)
    thump_env = np.exp(-t / 0.065)
    f_thump = 72.0 * np.exp(-t * 6.0)
    thump_phase = 2.0 * np.pi * np.cumsum(f_thump) / SR
    # Non-linear saturation (fundamental + 2nd + 3rd harmonics for rich acoustic body)
    raw_thump = np.sin(thump_phase) + 0.45 * np.sin(2.0 * thump_phase) + 0.22 * np.sin(3.0 * thump_phase)
    saturated_thump = np.tanh(raw_thump * 1.5) * thump_env * 0.75

    # 3. Steel Singing Resonance (Euler-Bernoulli vibrating bar modal frequencies)
    # Steel blade modes: f1=820Hz, f2=2260Hz, f3=4430Hz, f4=7150Hz
    sing_env = np.exp(-t / 0.14)
    steel_sing = (
        0.35 * np.sin(2.0 * np.pi * 820.0 * t) * np.exp(-t / 0.18) +
        0.28 * np.sin(2.0 * np.pi * 2260.0 * t) * np.exp(-t / 0.12) +
        0.18 * np.sin(2.0 * np.pi * 4430.0 * t) * np.exp(-t / 0.08) +
        0.08 * np.sin(2.0 * np.pi * 7150.0 * t) * np.exp(-t / 0.05)
    )
    # Add subtle metallic phase detuning
    steel_sing_detuned = (
        0.35 * np.sin(2.0 * np.pi * 824.0 * t) * np.exp(-t / 0.18) +
        0.28 * np.sin(2.0 * np.pi * 2252.0 * t) * np.exp(-t / 0.12) +
        0.18 * np.sin(2.0 * np.pi * 4438.0 * t) * np.exp(-t / 0.08)
    )

    # 4. Warm Pyro Finisher Combustion Swell (fire bloom in blade's wake)
    fire_t = np.clip(t - 0.03, 0.0, dur)
    fire_env = (1.0 - np.exp(-fire_t * 30.0)) * np.exp(-fire_t * 6.0)
    low_fire = np.convolve(white, np.ones(36)/36.0, mode='same') * fire_env * 0.65
    ember_crackle = (np.random.rand(n_samples) > 0.985).astype(float) * np.random.uniform(0.1, 0.4, n_samples) * fire_env

    # 5. Dynamic Stereo Cleave Panning (sweeps across soundstage)
    # Pan moves from left to right as the 2H blade cleaves
    pan_progress = np.clip(t / 0.22, 0.0, 1.0)
    pan_l = np.cos(pan_progress * np.pi * 0.5)
    pan_r = np.sin(pan_progress * np.pi * 0.5)

    left = (
        blade_slice * (pan_l * 1.3) +
        saturated_thump * 0.85 +
        steel_sing * 0.70 +
        low_fire * 0.75 + ember_crackle * 0.4
    )
    right = (
        blade_slice * (pan_r * 1.3) +
        saturated_thump * 0.85 +
        steel_sing_detuned * 0.70 +
        low_fire * 0.80 + ember_crackle * 0.4
    )

    # Anti-click smooth fadeout
    fade = np.clip((dur - t) / 0.06, 0.0, 1.0)
    left *= fade
    right *= fade

    # Normalize to -0.6 dB
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)), 1e-5)
    left = (left / peak) * 0.93
    right = (right / peak) * 0.93

    write_stereo_wav(os.path.join(OUTPUT_DIR, "sword_slash_charged.wav"), left, right)

def generate_refined_jump(seed, filename, pitch_mult=1.0):
    np.random.seed(seed)
    dur = 0.18
    n_samples = int(SR * dur)
    t = np.linspace(0, dur, n_samples, endpoint=False)

    # 1. Delicate, crisp shoe-sole liftoff (clean micro-friction, 12ms dry tap, NO low pitch-bend)
    tap_env = np.exp(-t / 0.014)
    tap_noise = np.random.randn(n_samples)
    # Bandpass around 1200 - 2400 Hz for tactile sole friction
    k_size = 48
    k_t = np.arange(-k_size//2, k_size//2)
    bp_tap = np.cos(2.0 * np.pi * (1600.0 * pitch_mult) * k_t / SR) * np.hanning(k_size)
    sole_tap = np.convolve(tap_noise, bp_tap, mode='same') * tap_env * 0.55

    # 2. Silky anime dress/coat flutter (gentle cloth rustle)
    cloth_env = (1.0 - np.exp(-t / 0.012)) * np.exp(-t / 0.065)
    flutter_mod = 1.0 + 0.35 * np.sin(2.0 * np.pi * 42.0 * t)
    bp_cloth = np.cos(2.0 * np.pi * (2800.0 * pitch_mult) * k_t / SR) * np.hanning(k_size)
    cloth = np.convolve(tap_noise * flutter_mod, bp_cloth, mode='same') * cloth_env * 0.50

    # 3. Soft airy leap whoosh (delicate updraft)
    whoosh_env = (1.0 - np.exp(-t / 0.020)) * np.exp(-t / 0.080)
    bp_whoosh = np.cos(2.0 * np.pi * 650.0 * k_t / SR) * np.hanning(k_size)
    whoosh = np.convolve(tap_noise, bp_whoosh, mode='same') * whoosh_env * 0.42

    # Subtle stereo width
    left = sole_tap * 0.95 + cloth * 0.90 + whoosh * 0.85
    right = sole_tap * 0.85 + cloth * 1.05 + whoosh * 0.85

    # Fade out
    fade = np.clip((dur - t) / 0.03, 0.0, 1.0)
    left *= fade
    right *= fade

    peak = max(np.max(np.abs(left)), np.max(np.abs(right)), 1e-5)
    left = (left / peak) * 0.85
    right = (right / peak) * 0.85

    write_stereo_wav(os.path.join(OUTPUT_DIR, filename), left, right)

if __name__ == "__main__":
    generate_organic_sword_finisher()
    generate_refined_jump(101, "jump_1.wav", pitch_mult=1.05)
    generate_refined_jump(202, "jump_2.wav", pitch_mult=0.96)
    generate_refined_jump(303, "jump_3.wav", pitch_mult=1.0)
    generate_refined_jump(404, "jump.wav", pitch_mult=1.02)
    print("All refined sounds generated successfully!")
