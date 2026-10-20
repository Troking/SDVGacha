"""
High-fidelity Organic Monster Sound Synthesizer
Generates rich, juicy, squishy anime RPG sound effects:
- Slime: Hop/boing, alert bubble, charge tremor, attack slap, squelchy hurts, ultra-juicy death burst, and bouncy droplet splats
- Goblin: Mischievous growls, sprint charge, squeak hurt, and cartoon defeat thud
- Skeleton: Rattling bone clatter alert, hollow strike, and bone shatter collapse
"""
import os
import math
import wave
import struct
import random

MONSTER_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds/monsters"
os.makedirs(MONSTER_DIR, exist_ok=True)

def write_wav(filename, samples, sample_rate=44100):
    filepath = os.path.join(MONSTER_DIR, filename)
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono for crisp 3D spatial audio
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        # Normalize and soft-clip
        max_val = max(abs(s) for s in samples) if samples else 1.0
        scale = 0.92 / max(max_val, 0.001)
        
        raw_bytes = bytearray()
        for s in samples:
            val = s * scale
            # Soft tanh-like saturation curve
            val = val / (1.0 + abs(val) * 0.25)
            ival = int(max(-32767, min(32767, val * 32767)))
            raw_bytes.extend(struct.pack('<h', ival))
        
        wav_file.writeframes(raw_bytes)
    print(f"Generated: {filename} ({len(samples)/sample_rate:.2f}s)")

# -------------------------------------------------------------
# 1. SLIME SOUNDS: SQUISHY, JUICY, GELATINOUS & BOUNCY
# -------------------------------------------------------------

def gen_slime_hop():
    # Juicy cartoon rubbery boing / bloop with wet liquid sweep
    sr = 44100
    duration = 0.35
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        
        # Pitch envelope: quick drop then upward rubbery sweep (130 -> 360Hz)
        if t < 0.04:
            freq = 280.0 - (t / 0.04) * 150.0
        else:
            p = (t - 0.04) / (duration - 0.04)
            freq = 130.0 + 230.0 * (1.0 - math.exp(-p * 6.0))
            # subtle liquid FM wobble
            freq += math.sin(2.0 * math.pi * 32.0 * t) * 15.0 * math.exp(-p * 4.0)
            
        phase += 2.0 * math.pi * freq / sr
        
        # Primary squishy sine + warm 2nd harmonic
        osc = math.sin(phase) * 0.75 + math.sin(phase * 2.0) * 0.25
        
        # Initial wet suction transient
        wet_click = 0.0
        if t < 0.035:
            click_env = math.exp(-t * 180.0)
            wet_click = (math.sin(2.0 * math.pi * 1650.0 * t) * 0.6 + random.uniform(-0.4, 0.4)) * click_env * 0.45
            
        # Amplitude envelope: snappy attack, rounded body, soft decay
        amp = math.sin(min(1.0, t / 0.02) * math.pi * 0.5) * math.exp(-t * 9.5)
        samples.append((osc + wet_click) * amp)
    
    write_wav("slime_hop.wav", samples, sr)

def gen_slime_alert():
    # Cute, curious gelatinous bubble gurgle / bloop chirp
    sr = 44100
    duration = 0.42
    total = int(sr * duration)
    samples = []
    
    phase1 = 0.0
    phase2 = 0.0
    for i in range(total):
        t = i / float(sr)
        
        # Bubble 1 (0.00 - 0.18s)
        b1 = 0.0
        if t < 0.20:
            p1 = t / 0.20
            f1 = 320.0 + 380.0 * (p1 ** 0.6)
            phase1 += 2.0 * math.pi * f1 / sr
            env1 = math.sin(min(1.0, t / 0.015) * math.pi * 0.5) * math.exp(-t * 14.0)
            b1 = math.sin(phase1) * env1
            
        # Bubble 2 (0.12 - 0.40s) higher pitch chirp
        b2 = 0.0
        if t > 0.10:
            t2 = t - 0.10
            p2 = t2 / 0.30
            f2 = 480.0 + 440.0 * (p2 ** 0.5)
            phase2 += 2.0 * math.pi * f2 / sr
            env2 = math.sin(min(1.0, t2 / 0.015) * math.pi * 0.5) * math.exp(-t2 * 11.0)
            b2 = (math.sin(phase2) * 0.8 + math.sin(phase2 * 2.0) * 0.2) * env2
            
        samples.append(b1 * 0.7 + b2 * 0.85)
        
    write_wav("slime_alert.wav", samples, sr)

def gen_slime_charge():
    # Deep bubbling gelatinous tremor / squish compression before strike
    sr = 44100
    duration = 0.65
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    bubble_phase = 0.0
    for i in range(total):
        t = i / float(sr)
        p = t / duration
        
        # Rising low fundamental (65Hz -> 145Hz)
        freq = 65.0 + 80.0 * (p ** 1.8)
        # Viscous bubbling modulation
        bubble_mod = math.sin(2.0 * math.pi * (14.0 + 26.0 * p) * t) * 18.0
        phase += 2.0 * math.pi * (freq + bubble_mod) / sr
        
        # Micro bubbly liquid clicks
        bubble_click = 0.0
        if random.random() < (0.12 + p * 0.35):
            bubble_click = random.uniform(-0.35, 0.35) * math.sin(t * 8000.0)
            
        osc = math.sin(phase) * 0.75 + math.sin(phase * 1.5) * 0.25
        # Swelling envelope
        env = (p ** 1.3) * (1.0 - math.exp(-(duration - t) * 16.0))
        samples.append((osc + bubble_click) * env)
        
    write_wav("slime_charge.wav", samples, sr)

def gen_slime_attack():
    # Snappy wet gelatinous whip slap + juicy splatter impact
    sr = 44100
    duration = 0.40
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        
        # 1. High wet whip crack transient (0.0 - 0.05s)
        crack = 0.0
        if t < 0.06:
            c_env = math.exp(-t * 120.0)
            crack = (math.sin(2.0 * math.pi * 1800.0 * t) * 0.5 + 
                     random.uniform(-0.6, 0.6)) * c_env * 0.85
                     
        # 2. Heavy low body thud (110Hz -> 60Hz)
        t_env = math.exp(-t * 16.0)
        t_freq = 140.0 - 80.0 * min(1.0, t * 15.0)
        phase += 2.0 * math.pi * t_freq / sr
        thud = math.sin(phase) * t_env * 0.75
        
        # 3. Wet liquid splash noise (band-limited)
        splash_env = math.exp(-t * 22.0) * min(1.0, t / 0.01)
        splash = random.uniform(-0.4, 0.4) * splash_env * 0.55
        
        samples.append(crack + thud + splash)
        
    write_wav("slime_attack.wav", samples, sr)

def gen_slime_hurt(index):
    # Wet squishy rubber deformation / crunchy pop
    sr = 44100
    duration = 0.26
    total = int(sr * duration)
    samples = []
    
    base_f = 220.0 if index == 1 else 175.0
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        
        # Fast descending squelch
        freq = base_f * math.exp(-t * 12.0) + math.sin(2.0 * math.pi * 45.0 * t) * 35.0 * math.exp(-t * 15.0)
        phase += 2.0 * math.pi * freq / sr
        
        osc = math.sin(phase) * 0.7 + math.sin(phase * 2.0) * 0.3
        
        # Wet squash click
        squash = 0.0
        if t < 0.04:
            s_env = math.exp(-t * 150.0)
            squash = (math.sin(2.0 * math.pi * 1400.0 * t) * 0.5 + random.uniform(-0.5, 0.5)) * s_env * 0.6
            
        env = math.exp(-t * 16.0)
        samples.append((osc + squash) * env)
        
    write_wav(f"slime_hurt_{index}.wav", samples, sr)

def gen_slime_die():
    # ULTRA-JUICY MULTI-LAYER SLIME BURST:
    # 1. Low bass punch (75Hz)
    # 2. Resonant rubber balloon pop (480Hz)
    # 3. Juicy wet droplet splatter shower
    # 4. Melodic cute bubble fizzle out
    sr = 44100
    duration = 0.62
    total = int(sr * duration)
    samples = []
    
    bass_phase = 0.0
    pop_phase = 0.0
    
    # 6 micro-splatter droplet transients
    droplets = [
        (0.04, 1800.0, 0.55),
        (0.08, 2400.0, 0.45),
        (0.13, 1450.0, 0.60),
        (0.19, 2900.0, 0.40),
        (0.26, 2100.0, 0.35),
        (0.34, 1600.0, 0.25)
    ]
    
    for i in range(total):
        t = i / float(sr)
        
        # Layer 1: Bass Punch (thump of ruptured pressurized jelly)
        b_freq = 95.0 - 40.0 * min(1.0, t * 12.0)
        bass_phase += 2.0 * math.pi * b_freq / sr
        bass = math.sin(bass_phase) * math.exp(-t * 12.0) * 0.95
        
        # Layer 2: Elastic Pop Snap (0.00 - 0.08s)
        pop_env = math.exp(-t * 45.0)
        p_freq = 520.0 - 280.0 * min(1.0, t * 25.0)
        pop_phase += 2.0 * math.pi * p_freq / sr
        pop = (math.sin(pop_phase) * 0.8 + math.sin(pop_phase * 2.0) * 0.3) * pop_env * 0.85
        
        # Layer 3: Wet liquid spray splatter (bursting goop)
        spray_env = math.exp(-t * 14.0) * min(1.0, t / 0.02)
        spray = random.uniform(-0.55, 0.55) * spray_env * 0.70
        
        # Layer 4: Micro droplet plops
        drops = 0.0
        for d_t, d_f, d_amp in droplets:
            if t >= d_t and t < d_t + 0.04:
                dt = t - d_t
                d_env = math.exp(-dt * 160.0)
                drops += math.sin(2.0 * math.pi * (d_f - dt * 4000.0) * dt) * d_env * d_amp
                
        # Total composite
        s = bass + pop + spray + drops
        samples.append(s)
        
    write_wav("slime_die.wav", samples, sr)

def gen_slime_splat(index):
    # Cute miniature wet jelly plop when pieces bounce on the ground
    sr = 44100
    duration = 0.18
    total = int(sr * duration)
    samples = []
    
    freq_start = 550.0 if index == 1 else 420.0
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        
        freq = freq_start * math.exp(-t * 22.0) + 90.0
        phase += 2.0 * math.pi * freq / sr
        
        # Soft plop click
        click = 0.0
        if t < 0.02:
            click = random.uniform(-0.4, 0.4) * math.exp(-t * 220.0)
            
        osc = math.sin(phase) * 0.85 + math.sin(phase * 2.0) * 0.2
        env = math.exp(-t * 24.0)
        samples.append((osc + click) * env * 0.85)
        
    write_wav(f"slime_splat_{index}.wav", samples, sr)

# -------------------------------------------------------------
# 2. GOBLIN SOUNDS: GRITTY, MISCHIEVOUS & CRUNCHY
# -------------------------------------------------------------

def gen_goblin_alert():
    # Mischievous raspy goblin chortle / guttural snarl
    sr = 44100
    duration = 0.45
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        
        # Guttural pitch with gravelly vibrato
        f = 160.0 + 80.0 * math.sin(2.0 * math.pi * 38.0 * t) + 60.0 * (t / duration)
        phase += 2.0 * math.pi * f / sr
        
        # Raspy buzz
        buzz = (math.sin(phase) + 0.5 * math.sin(phase * 3.0) + 0.3 * random.uniform(-1, 1))
        # Leather / armor rattle
        rattle = random.uniform(-0.25, 0.25) * math.exp(-t * 8.0)
        env = math.sin(min(1.0, t / 0.04) * math.pi * 0.5) * math.exp(-t * 6.5)
        samples.append((buzz * 0.7 + rattle) * env)
        
    write_wav("goblin_alert.wav", samples, sr)

def gen_goblin_charge():
    # Aggressive running sprint snarl
    sr = 44100
    duration = 0.55
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        p = t / duration
        f = 140.0 + 130.0 * (p ** 1.4) + 40.0 * math.sin(2.0 * math.pi * 45.0 * t)
        phase += 2.0 * math.pi * f / sr
        buzz = math.sin(phase) + 0.4 * math.sin(phase * 2.5) + 0.35 * random.uniform(-1, 1)
        env = (p ** 1.1) * (1.0 - math.exp(-(duration - t) * 15.0))
        samples.append(buzz * env * 0.8)
        
    write_wav("goblin_charge.wav", samples, sr)

def gen_goblin_hurt():
    # Expressive high pitched goblin yelp / squeak
    sr = 44100
    duration = 0.28
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    for i in range(total):
        t = i / float(sr)
        f = 380.0 * math.exp(-t * 7.0) + 50.0 * math.sin(2.0 * math.pi * 60.0 * t)
        phase += 2.0 * math.pi * f / sr
        osc = math.sin(phase) + 0.3 * math.sin(phase * 2.0)
        impact = random.uniform(-0.4, 0.4) * math.exp(-t * 80.0)
        env = math.exp(-t * 14.0)
        samples.append((osc * 0.7 + impact) * env)
        
    write_wav("goblin_hurt.wav", samples, sr)

def gen_goblin_die():
    # Cartoon defeat yelp + heavy comic thud
    sr = 44100
    duration = 0.65
    total = int(sr * duration)
    samples = []
    
    phase = 0.0
    thud_phase = 0.0
    for i in range(total):
        t = i / float(sr)
        
        # High squeal falling (0.0 - 0.28s)
        squeal = 0.0
        if t < 0.32:
            f = 460.0 - (t / 0.32) * 320.0
            phase += 2.0 * math.pi * f / sr
            squeal = (math.sin(phase) + 0.3 * math.sin(phase * 2.0)) * math.exp(-t * 10.0) * 0.75
            
        # Heavy cartoon dirt thud (0.18 - 0.60s)
        thud = 0.0
        if t > 0.16:
            dt = t - 0.16
            tf = 95.0 * math.exp(-dt * 15.0)
            thud_phase += 2.0 * math.pi * tf / sr
            t_impact = random.uniform(-0.5, 0.5) * math.exp(-dt * 70.0)
            thud = (math.sin(thud_phase) * 0.8 + t_impact) * math.exp(-dt * 9.0) * 0.85
            
        samples.append(squeal + thud)
        
    write_wav("goblin_die.wav", samples, sr)

# -------------------------------------------------------------
# 3. SKELETON SOUNDS: HOLLOW BONE CLATTER & SHATTER
# -------------------------------------------------------------

def gen_skeleton_alert():
    # Dry, hollow wooden-bone clatter & jaw rattle
    sr = 44100
    duration = 0.45
    total = int(sr * duration)
    samples = []
    
    # 4 distinct bone clack pulses
    clacks = [0.03, 0.11, 0.19, 0.28]
    for i in range(total):
        t = i / float(sr)
        s = 0.0
        for ct in clacks:
            if t >= ct and t < ct + 0.07:
                dt = t - ct
                # Hollow resonance at 820Hz + 1450Hz
                wood1 = math.sin(2.0 * math.pi * 820.0 * dt) * 0.6
                wood2 = math.sin(2.0 * math.pi * 1450.0 * dt) * 0.4
                noise = random.uniform(-0.3, 0.3)
                env = math.exp(-dt * 65.0)
                s += (wood1 + wood2 + noise) * env * 0.75
        samples.append(s)
        
    write_wav("skel_alert.wav", samples, sr)

def gen_skeleton_die():
    # Dramatic bone collapse: initial shatter strike + shower of tumbling hollow bones
    sr = 44100
    duration = 0.75
    total = int(sr * duration)
    samples = []
    
    # Cascading bone impacts
    bone_impacts = [
        (0.00, 1100.0, 0.90),
        (0.05, 780.0, 0.80),
        (0.12, 1350.0, 0.65),
        (0.18, 620.0, 0.75),
        (0.25, 950.0, 0.60),
        (0.32, 1400.0, 0.50),
        (0.41, 800.0, 0.45),
        (0.52, 1150.0, 0.35)
    ]
    
    for i in range(total):
        t = i / float(sr)
        s = 0.0
        for bt, bf, bamp in bone_impacts:
            if t >= bt and t < bt + 0.09:
                dt = t - bt
                bone_res = (math.sin(2.0 * math.pi * bf * dt) * 0.65 +
                            math.sin(2.0 * math.pi * (bf * 1.8) * dt) * 0.35)
                bone_click = random.uniform(-0.4, 0.4) * math.exp(-dt * 120.0)
                env = math.exp(-dt * 45.0)
                s += (bone_res + bone_click) * env * bamp
                
        # Low hollow collapse dust
        dust = random.uniform(-0.15, 0.15) * math.exp(-t * 6.0)
        samples.append(s + dust)
        
    write_wav("skel_die.wav", samples, sr)

def main():
    print("Generating pristine organic monster sounds...")
    # Slime
    gen_slime_hop()
    gen_slime_alert()
    gen_slime_charge()
    gen_slime_attack()
    gen_slime_hurt(1)
    gen_slime_hurt(2)
    gen_slime_die()
    gen_slime_splat(1)
    gen_slime_splat(2)
    
    # Goblin
    gen_goblin_alert()
    gen_goblin_charge()
    gen_goblin_hurt()
    gen_goblin_die()
    
    # Skeleton
    gen_skeleton_alert()
    gen_skeleton_die()
    print("All monster sound effects generated successfully!")

if __name__ == "__main__":
    main()
