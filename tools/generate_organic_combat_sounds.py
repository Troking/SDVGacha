"""
Generates high-fidelity, organic, Genshin Impact-style sound effects for:
1. flame_burst.wav       - Hu Tao's Elemental Skill (warm combustion bloom, swirling flame vortex, organic ember snaps, ethereal spirit chime)
2. sword_charge_ready.wav - Charged Attack Windup (tactile steel draw, inward fire suction, soft sacred temple bell chime)
3. sword_slash_charged.wav - Charged Attack Unleash (heavy blade air whip, visceral pyro thump, flame roar, singing steel resonance)
"""

import os
import wave
import numpy as np

OUTPUT_DIR = "game/assets/sounds"
SAMPLE_RATE = 44100

os.makedirs(OUTPUT_DIR, exist_ok=True)

def write_stereo_wav(filepath, left, right):
    # Ensure no NaN or inf
    left = np.nan_to_num(left)
    right = np.nan_to_num(right)
    
    # Peak normalization to -1.5 dBFS (~0.84)
    peak = max(np.max(np.abs(left)), np.max(np.abs(right)), 1e-4)
    target_peak = 0.84
    left = (left / peak) * target_peak
    right = (right / peak) * target_peak
    
    # Soft analog saturation to prevent any hard digital clipping
    left = np.tanh(left * 1.05) / 1.05
    right = np.tanh(right * 1.05) / 1.05
    
    left_int = (np.clip(left, -1.0, 1.0) * 32767.0).astype(np.int16)
    right_int = (np.clip(right, -1.0, 1.0) * 32767.0).astype(np.int16)
    
    stereo_interleaved = np.empty((len(left) * 2,), dtype=np.int16)
    stereo_interleaved[0::2] = left_int
    stereo_interleaved[1::2] = right_int
    
    with wave.open(filepath, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(stereo_interleaved.tobytes())
    print(f"Successfully generated: {filepath} ({len(left)/SAMPLE_RATE:.2f}s, peak={peak:.3f})")

def generate_colored_noise(n_samples, exponent=1.0):
    """
    exponent = 0.0 -> White noise
    exponent = 1.0 -> Pink noise (warm, natural air/fire)
    exponent = 2.0 -> Brown noise (deep, heavy rumble/air)
    """
    white = np.random.randn(n_samples)
    X = np.fft.rfft(white)
    freqs = np.fft.rfftfreq(n_samples, 1.0 / SAMPLE_RATE)
    freqs[0] = 1.0  # DC bin protection
    scale = 1.0 / (freqs ** (exponent / 2.0))
    scale[0] = 0.0
    colored = np.fft.irfft(X * scale, n=n_samples)
    max_val = np.max(np.abs(colored))
    if max_val > 1e-5:
        colored /= max_val
    return colored

def apply_svf(signal, cutoff_env, q=1.5, mode='lp'):
    """
    Time-varying State-Variable Filter (SVF)
    Provides smooth, acoustic analog-modeled resonance without digital distortion.
    """
    n = len(signal)
    out = np.zeros(n, dtype=np.float64)
    low = 0.0
    band = 0.0
    damp = 1.0 / max(0.2, q)
    
    # Pre-clamp cutoff frequencies safely within Nyquist
    cutoffs = np.clip(cutoff_env, 20.0, SAMPLE_RATE * 0.44)
    f_vals = 2.0 * np.sin(np.pi * cutoffs / SAMPLE_RATE)
    
    sig_64 = signal.astype(np.float64)
    for i in range(n):
        f = f_vals[i]
        low += f * band
        high = sig_64[i] - low - damp * band
        band += f * high
        
        if mode == 'lp':
            out[i] = low
        elif mode == 'bp':
            out[i] = band
        elif mode == 'hp':
            out[i] = high
            
    # Normalize output gain
    max_out = np.max(np.abs(out))
    if max_out > 1e-4:
        out = out / max_out
    return out

# ==============================================================================
# 1. ELEMENTAL SKILL SOUND: flame_burst.wav
# ==============================================================================
def create_flame_burst():
    duration = 1.15
    n_samples = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n_samples, endpoint=False)
    
    # Layer 1: Sub-bass Combustion Ignition Bloom (warm, visceral acoustic punch)
    sub_pitch = 68.0 * np.exp(-t * 5.5) + 36.0
    sub_phase = 2.0 * np.pi * np.cumsum(sub_pitch) / SAMPLE_RATE
    sub_env = (np.sin(np.clip(t / 0.04, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-t * 5.2)
    sub_impact = np.sin(sub_phase) * sub_env * 0.70
    
    # Layer 2: Swirling Flame Vortex Whoosh (organic, warm brown/pink air rush)
    brown = generate_colored_noise(n_samples, exponent=1.6)
    # Sweeping cutoff from 1100 Hz down to 260 Hz
    cutoff_sweep = 1100.0 * np.exp(-t * 3.5) + 260.0
    flame_whoosh = apply_svf(brown, cutoff_sweep, q=1.6, mode='lp')
    whoosh_env = (np.sin(np.clip(t / 0.08, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-t * 2.8)
    flame_whoosh *= whoosh_env * 0.65
    
    # Dynamic stereo panning to create the swirling vortex rotation
    pan_rate = 5.2 # Hz swirl
    pan_l = 0.5 + 0.4 * np.sin(2.0 * np.pi * pan_rate * t)
    pan_r = 0.5 + 0.4 * np.cos(2.0 * np.pi * pan_rate * t)
    
    vortex_l = flame_whoosh * pan_l
    vortex_r = flame_whoosh * pan_r
    
    # Layer 3: Organic Campfire / Butterfly Spark Snaps (micro-transients, not digital beeps)
    sparks_l = np.zeros(n_samples)
    sparks_r = np.zeros(n_samples)
    np.random.seed(42)
    n_sparks = 20
    spark_times = np.random.uniform(0.06, 0.70, n_sparks)
    for st in spark_times:
        idx = int(st * SAMPLE_RATE)
        spark_len = int(SAMPLE_RATE * 0.016) # 16ms micro-burst
        if idx + spark_len < n_samples:
            t_sp = np.linspace(0, 0.016, spark_len, endpoint=False)
            # High-pass acoustic snap
            snap_noise = np.random.randn(spark_len) * np.exp(-t_sp * 320.0)
            snap_l = snap_noise * np.random.uniform(0.3, 0.8)
            snap_r = snap_noise * np.random.uniform(0.3, 0.8)
            sparks_l[idx:idx+spark_len] += snap_l * 0.22
            sparks_r[idx:idx+spark_len] += snap_r * 0.22
            
    # Layer 4: Ethereal Butterfly Spirit Chime (Genshin pentatonic bell shimmer)
    # Pentatonic chords: G4 (392Hz), D5 (587.3Hz), G5 (784Hz)
    chime_env = (np.sin(np.clip((t - 0.03) / 0.06, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-(t - 0.03) * 3.8)
    chime_env = np.where(t >= 0.03, chime_env, 0.0)
    
    bell_l = (
        0.30 * np.sin(2.0 * np.pi * 392.0 * t) * np.exp(-t * 3.2) +
        0.22 * np.sin(2.0 * np.pi * 587.3 * t) * np.exp(-t * 5.0) +
        0.14 * np.sin(2.0 * np.pi * 784.0 * t) * np.exp(-t * 7.5)
    ) * chime_env
    
    bell_r = (
        0.30 * np.sin(2.0 * np.pi * 393.5 * t) * np.exp(-t * 3.2) +
        0.22 * np.sin(2.0 * np.pi * 585.8 * t) * np.exp(-t * 5.0) +
        0.14 * np.sin(2.0 * np.pi * 786.2 * t) * np.exp(-t * 7.5)
    ) * chime_env
    
    # Master assembly
    left = sub_impact * 0.85 + vortex_l + sparks_l + bell_l * 0.35
    right = sub_impact * 0.85 + vortex_r + sparks_r + bell_r * 0.35
    
    # Smooth fade out at the tail
    tail_fade = np.clip((duration - t) / 0.08, 0.0, 1.0)
    left *= tail_fade
    right *= tail_fade
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "flame_burst.wav"), left, right)

# ==============================================================================
# 2. CHARGED ATTACK HOLD SOUND: sword_charge_ready.wav
# ==============================================================================
def create_sword_charge_ready():
    duration = 0.46
    n_samples = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n_samples, endpoint=False)
    
    # Layer 1: Tactile Blade Scabbard Sheath Draw (0.0s to 0.26s)
    # Realistic acoustic sliding friction of steel
    pink = generate_colored_noise(n_samples, exponent=1.1)
    slide_cutoff = 1350.0 * np.exp(-t * 2.5) + 650.0
    slide_friction = apply_svf(pink, slide_cutoff, q=2.0, mode='bp')
    slide_env = (np.sin(np.clip(t / 0.04, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-t * 6.5)
    slide_l = slide_friction * slide_env * 0.55
    slide_r = slide_friction * slide_env * 0.50
    
    # Layer 2: Inward Gathering Fire Suction / Inhale (0.05s to 0.36s)
    # Warm air pulling inward toward the coiled heroine
    brown = generate_colored_noise(n_samples, exponent=1.7)
    vaccum_cutoff = 180.0 + 550.0 * (t / duration) ** 2.2
    vaccum_air = apply_svf(brown, vaccum_cutoff, q=1.2, mode='lp')
    # Exponential crescendo up to the ready threshold
    vaccum_env = (np.clip(t / 0.34, 0.0, 1.0) ** 2.4) * (1.0 - np.clip((t - 0.34) / 0.10, 0.0, 1.0))
    vaccum_l = vaccum_air * vaccum_env * 0.60
    vaccum_r = vaccum_air * vaccum_env * 0.65
    
    # Layer 3: Soft Sacred Readiness Chime (at readiness threshold t = 0.32s)
    # NO piercing sine beeps! A soft, resonant Japanese temple wind chime (Furin)
    chime_start = 0.31
    t_ch = np.maximum(0.0, t - chime_start)
    chime_gate = np.where(t >= chime_start, 1.0, 0.0)
    
    # Fundamental: A5 (880 Hz) and E6 (1318.5 Hz) - gentle, warm bell harmonics
    ch_f1 = 880.0
    ch_f2 = 1318.5
    # Natural physical bar overtones with rapid overtone damping
    ch_strike = np.sin(np.clip(t_ch / 0.008, 0.0, 1.0) * np.pi * 0.5)
    ch_decay1 = np.exp(-t_ch * 7.5)
    ch_decay2 = np.exp(-t_ch * 12.0)
    ch_decay_high = np.exp(-t_ch * 28.0)
    
    bell_l = (
        0.45 * np.sin(2.0 * np.pi * ch_f1 * t_ch) * ch_decay1 +
        0.25 * np.sin(2.0 * np.pi * ch_f2 * t_ch) * ch_decay2 +
        0.10 * np.sin(2.0 * np.pi * (ch_f1 * 2.76) * t_ch) * ch_decay_high
    ) * ch_strike * chime_gate
    
    bell_r = (
        0.45 * np.sin(2.0 * np.pi * (ch_f1 + 3.0) * t_ch) * ch_decay1 +
        0.25 * np.sin(2.0 * np.pi * (ch_f2 - 2.5) * t_ch) * ch_decay2 +
        0.10 * np.sin(2.0 * np.pi * (ch_f1 * 2.78) * t_ch) * ch_decay_high
    ) * ch_strike * chime_gate
    
    left = slide_l + vaccum_l + bell_l * 0.45
    right = slide_r + vaccum_r + bell_r * 0.45
    
    fade_tail = np.clip((duration - t) / 0.03, 0.0, 1.0)
    left *= fade_tail
    right *= fade_tail
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "sword_charge_ready.wav"), left, right)

# ==============================================================================
# 3. CHARGED ATTACK RELEASE SOUND: sword_slash_charged.wav
# ==============================================================================
def create_sword_slash_charged():
    duration = 0.65
    n_samples = int(SAMPLE_RATE * duration)
    t = np.linspace(0, duration, n_samples, endpoint=False)
    
    # Layer 1: Cinematic Heavy Blade Air Whip (0.0s to 0.18s)
    # Rapid displacement of air by the heavy edge
    pink = generate_colored_noise(n_samples, exponent=1.2)
    # Sweeping bandpass from 680 Hz down to 190 Hz
    whip_cutoff = 680.0 * np.exp(-t * 18.0) + 190.0
    blade_whip = apply_svf(pink, whip_cutoff, q=2.4, mode='bp')
    whip_env = (np.sin(np.clip(t / 0.02, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-t * 13.0)
    whip_l = blade_whip * whip_env * 0.70
    whip_r = blade_whip * whip_env * 0.70
    
    # Layer 2: Visceral Low-End Pyro Impact Thump (0.01s to 0.28s)
    # Deep acoustic chest punch (72 Hz down to 42 Hz)
    thump_pitch = 72.0 * np.exp(-t * 8.0) + 42.0
    thump_phase = 2.0 * np.pi * np.cumsum(thump_pitch) / SAMPLE_RATE
    thump_env = (np.sin(np.clip(t / 0.025, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-t * 9.5)
    thump_impact = np.sin(thump_phase) * thump_env * 0.75
    
    # Layer 3: Flaring Flame Combustion Roar (0.02s to 0.48s)
    # Warm, roaring fire wake trailing behind the sword
    brown = generate_colored_noise(n_samples, exponent=1.6)
    flame_cutoff = 480.0 * np.exp(-t * 4.0) + 210.0
    flame_body = apply_svf(brown, flame_cutoff, q=1.5, mode='lp')
    # Soft 6 Hz flame flutter
    flutter = 1.0 + 0.25 * np.sin(2.0 * np.pi * 6.0 * t)
    flame_env = (np.sin(np.clip((t - 0.02) / 0.05, 0.0, 1.0) * np.pi * 0.5) ** 2) * np.exp(-(t - 0.02) * 5.0)
    flame_env = np.where(t >= 0.02, flame_env, 0.0)
    flame_l = flame_body * flutter * flame_env * 0.65
    flame_r = flame_body * (2.0 - flutter) * flame_env * 0.65
    
    # Layer 4: Resonant Singing Steel Blade Ring (0.03s to 0.55s)
    # Physical acoustic vibration of the forged steel blade
    t_st = np.maximum(0.0, t - 0.02)
    steel_gate = np.where(t >= 0.02, 1.0, 0.0)
    # F#5 (740 Hz) and C#6 (1108 Hz)
    steel_f1 = 740.0
    steel_f2 = 1108.0
    steel_env1 = np.exp(-t_st * 6.5)
    steel_env2 = np.exp(-t_st * 16.0)
    
    steel_l = (
        0.35 * np.sin(2.0 * np.pi * steel_f1 * t_st) * steel_env1 +
        0.18 * np.sin(2.0 * np.pi * steel_f2 * t_st) * steel_env2
    ) * steel_gate
    
    steel_r = (
        0.35 * np.sin(2.0 * np.pi * (steel_f1 + 2.0) * t_st) * steel_env1 +
        0.18 * np.sin(2.0 * np.pi * (steel_f2 - 2.0) * t_st) * steel_env2
    ) * steel_gate
    
    left = whip_l + thump_impact * 0.80 + flame_l + steel_l * 0.38
    right = whip_r + thump_impact * 0.80 + flame_r + steel_r * 0.38
    
    tail_fade = np.clip((duration - t) / 0.06, 0.0, 1.0)
    left *= tail_fade
    right *= tail_fade
    
    write_stereo_wav(os.path.join(OUTPUT_DIR, "sword_slash_charged.wav"), left, right)

def main():
    print("Generating Organic Genshin-Grade Combat Audio...")
    create_flame_burst()
    create_sword_charge_ready()
    create_sword_slash_charged()
    print("All combat sounds generated successfully!")

if __name__ == "__main__":
    main()
