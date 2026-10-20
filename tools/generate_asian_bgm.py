import math
import wave
import struct
import os

sample_rate = 44100
bpm = 68.0
beat_duration = 60.0 / bpm
total_beats = 64 # ~56.4 seconds, 16 bars of 4/4
total_seconds = total_beats * beat_duration
total_samples = int(total_seconds * sample_rate)

# Asian Pentatonic Scale (D - F - G - A - C in various octaves, very peaceful Genshin/Liyue style)
# D3, F3, G3, A3, C4, D4, F4, G4, A4, C5, D5
FREQ = {
    "D2": 73.42, "A2": 110.00,
    "D3": 146.83, "F3": 174.61, "G3": 196.00, "A3": 220.00, "C4": 261.63,
    "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "C5": 523.25,
    "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.00, "C6": 1046.50
}

left_channel = [0.0] * total_samples
right_channel = [0.0] * total_samples

def add_sample(t_idx, l_val, r_val):
    if 0 <= t_idx < total_samples:
        left_channel[t_idx] += l_val
        right_channel[t_idx] += r_val
    elif t_idx >= total_samples:
        # Wrap around for seamless looping!
        wrap_idx = t_idx % total_samples
        left_channel[wrap_idx] += l_val
        right_channel[wrap_idx] += r_val

# 1. Warm Ambient Drone Pad (Gentle meditative root D and fifth A)
print("Synthesizing ambient drone pads...")
for i in range(total_samples):
    t = float(i) / sample_rate
    # Slow undulating swells
    swell1 = 0.5 + 0.5 * math.sin(2.0 * math.pi * t / (total_seconds * 0.25))
    swell2 = 0.5 + 0.5 * math.cos(2.0 * math.pi * t / (total_seconds * 0.5))
    
    # D2 + A2 + D3 warm chord with soft harmonics
    s1 = math.sin(2.0 * math.pi * FREQ["D2"] * t) * 0.08
    s2 = math.sin(2.0 * math.pi * FREQ["A2"] * t) * 0.05
    s3 = math.sin(2.0 * math.pi * FREQ["D3"] * t) * 0.04
    s4 = math.sin(2.0 * math.pi * FREQ["A3"] * t) * 0.02
    
    pad = (s1 + s2 + s3 + s4) * (0.6 + 0.4 * swell1)
    # Stereo panning motion
    pan = 0.5 + 0.15 * math.sin(2.0 * math.pi * 0.05 * t)
    left_channel[i] += pad * (1.0 - pan)
    right_channel[i] += pad * pan

# 2. Guzheng / Koto Plucked Notes (Sharp attack, ringing metallic-wooden decay, rich vibrato)
def play_guzheng(beat, note_freq, vel=0.25, pan=0.4):
    start_time = beat * beat_duration
    start_sample = int(start_time * sample_rate)
    duration = 4.2 # long ringing decay
    note_samples = int(duration * sample_rate)
    
    for i in range(note_samples):
        t = float(i) / sample_rate
        # Pluck envelope: rapid 8ms attack, exponential decay
        if t < 0.008:
            env = t / 0.008
        else:
            env = math.exp(-(t - 0.008) * 1.8)
        
        if env < 0.0001:
            break
            
        # Subtle pitch vibrato (characteristic of Guzheng string pressing)
        vibrato = math.sin(2.0 * math.pi * 4.8 * t) * (1.0 - math.exp(-t * 2.0)) * 3.5
        f = note_freq + vibrato
        
        # Plucked timbre: fundamental + odd/even harmonics + string buzz
        wave_val = (
            math.sin(2.0 * math.pi * f * t) * 0.60 +
            math.sin(2.0 * math.pi * f * 2.0 * t) * 0.28 * math.exp(-t * 3.0) +
            math.sin(2.0 * math.pi * f * 3.0 * t) * 0.16 * math.exp(-t * 5.0) +
            math.sin(2.0 * math.pi * f * 4.0 * t) * 0.08 * math.exp(-t * 7.0)
        )
        sample = wave_val * env * vel
        add_sample(start_sample + i, sample * (1.0 - pan), sample * pan)

# 3. Shakuhachi / Xiao Bamboo Flute (Breathy airy onset, warm resonant tone, organic pitch bend)
def play_flute(beat, note_freq, duration_beats, vel=0.22, pan=0.55):
    start_time = beat * beat_duration
    start_sample = int(start_time * sample_rate)
    duration = duration_beats * beat_duration
    note_samples = int(duration * sample_rate)
    
    for i in range(note_samples):
        t = float(i) / sample_rate
        # Flute envelope: gentle 0.12s swell, sustain, soft release
        rel_len = 0.25
        if t < 0.12:
            env = 0.5 - 0.5 * math.cos(math.pi * t / 0.12)
        elif t > duration - rel_len:
            env = 0.5 + 0.5 * math.cos(math.pi * (t - (duration - rel_len)) / rel_len)
        else:
            env = 1.0
            
        # Subtle breath noise + graceful vibrato
        vibrato = math.sin(2.0 * math.pi * 5.2 * t) * (1.0 - math.exp(-t * 1.5)) * 4.2
        # Initial graceful breath pitch slide (portamento)
        pitch_slide = math.exp(-t * 12.0) * -8.0
        f = note_freq + vibrato + pitch_slide
        
        # Flute waveform: soft hollow sine + 2nd/3rd harmonics + breath air
        phase = 2.0 * math.pi * f * t
        pure_tone = (
            math.sin(phase) * 0.70 +
            math.sin(phase * 2.0) * 0.18 +
            math.sin(phase * 3.0) * 0.08
        )
        # Pinkish breath noise
        breath = (math.sin(t * 18420.0) * math.sin(t * 7200.0)) * 0.04
        
        sample = (pure_tone + breath) * env * vel
        add_sample(start_sample + i, sample * (1.0 - pan), sample * pan)

# 4. Compose serene Asian Fantasy Melody & Arpeggios (64 beats)
print("Composing Guzheng and Flute melodies...")

# Guzheng cascading peaceful arpeggios
guzheng_pattern = [
    # Bar 1-4 (D minor pentatonic dawn)
    (0.0, "D4", 0.28, 0.35), (1.0, "F4", 0.20, 0.40), (2.0, "A4", 0.24, 0.45), (3.0, "D5", 0.28, 0.38),
    (4.0, "C5", 0.22, 0.60), (5.5, "A4", 0.18, 0.55), (6.0, "G4", 0.20, 0.50), (7.0, "F4", 0.18, 0.45),
    (8.0, "G4", 0.24, 0.40), (9.0, "A4", 0.22, 0.42), (10.0, "C5", 0.25, 0.45), (11.0, "D5", 0.30, 0.35),
    (12.0, "A4", 0.26, 0.50), (14.0, "F4", 0.20, 0.55), (15.0, "D4", 0.28, 0.40),
    
    # Bar 5-8 (Floating over the river)
    (16.0, "F4", 0.22, 0.35), (17.5, "G4", 0.18, 0.40), (18.0, "A4", 0.24, 0.48), (19.0, "C5", 0.22, 0.55),
    (20.0, "D5", 0.30, 0.38), (21.5, "F5", 0.22, 0.42), (22.0, "D5", 0.25, 0.45), (23.0, "C5", 0.20, 0.50),
    (24.0, "A4", 0.24, 0.55), (25.0, "G4", 0.20, 0.50), (26.0, "F4", 0.22, 0.45), (27.0, "G4", 0.24, 0.42),
    (28.0, "A4", 0.28, 0.40), (30.0, "D4", 0.32, 0.35),
    
    # Bar 9-12 (Ascending the mountain shrine)
    (32.0, "D4", 0.26, 0.40), (33.0, "A4", 0.22, 0.45), (34.0, "D5", 0.28, 0.38), (35.0, "F5", 0.26, 0.42),
    (36.0, "G5", 0.28, 0.50), (37.5, "F5", 0.22, 0.48), (38.0, "D5", 0.25, 0.45), (39.0, "C5", 0.22, 0.52),
    (40.0, "D5", 0.30, 0.40), (41.0, "C5", 0.22, 0.45), (42.0, "A4", 0.24, 0.50), (43.0, "G4", 0.20, 0.55),
    (44.0, "F4", 0.24, 0.48), (45.5, "G4", 0.20, 0.45), (46.0, "A4", 0.26, 0.42), (47.0, "C5", 0.22, 0.40),
    
    # Bar 13-16 (Resolution & Sakura petals drifting)
    (48.0, "D5", 0.30, 0.38), (50.0, "A4", 0.24, 0.45), (51.0, "F4", 0.20, 0.50), (52.0, "G4", 0.22, 0.48),
    (54.0, "F4", 0.20, 0.45), (55.0, "D4", 0.25, 0.40), (56.0, "A3", 0.26, 0.35), (58.0, "D4", 0.30, 0.38),
    (60.0, "F4", 0.22, 0.42), (61.5, "A4", 0.20, 0.45), (62.0, "D5", 0.28, 0.40)
]

for beat, note, vel, pan in guzheng_pattern:
    play_guzheng(beat, FREQ[note], vel, pan)

# Shakuhachi Bamboo Flute expressive phrases
flute_melody = [
    # Phrase 1: Dawning call
    (2.0, "A4", 3.5, 0.20, 0.55),
    (6.0, "D5", 4.0, 0.24, 0.52),
    (10.5, "C5", 2.0, 0.18, 0.58),
    (13.0, "A4", 3.0, 0.22, 0.54),
    
    # Phrase 2: Flowing breeze
    (18.0, "D5", 3.0, 0.23, 0.52),
    (21.5, "F5", 2.5, 0.22, 0.48),
    (24.5, "D5", 2.0, 0.19, 0.52),
    (27.0, "C5", 2.5, 0.18, 0.55),
    (30.0, "A4", 3.5, 0.22, 0.54),
    
    # Phrase 3: Sacred mountain peak
    (34.0, "F5", 3.0, 0.24, 0.48),
    (37.5, "G5", 2.5, 0.25, 0.50),
    (40.5, "F5", 1.5, 0.20, 0.52),
    (42.5, "D5", 3.5, 0.24, 0.54),
    (46.5, "C5", 2.5, 0.18, 0.56),
    
    # Phrase 4: Gentle peaceful sunset rest
    (50.0, "A4", 3.5, 0.22, 0.52),
    (54.0, "F4", 3.0, 0.19, 0.55),
    (58.0, "D4", 4.5, 0.25, 0.50)
]

for beat, note, dur, vel, pan in flute_melody:
    play_flute(beat, FREQ[note], dur, vel, pan)

# 5. Distant Temple Bell / Wind Chime (Crystal peaceful harmonic pings at bar boundaries)
def play_temple_bell(beat, note_freq, vel=0.18):
    start_sample = int(beat * beat_duration * sample_rate)
    duration = 5.5
    bell_samples = int(duration * sample_rate)
    
    for i in range(bell_samples):
        t = float(i) / sample_rate
        env = math.exp(-t * 0.8)
        if env < 0.0001:
            break
        # Bell non-harmonic metallic ratios (sweet Asian chime)
        bell_val = (
            math.sin(2.0 * math.pi * note_freq * t) * 0.45 +
            math.sin(2.0 * math.pi * note_freq * 2.76 * t) * 0.25 * math.exp(-t * 1.5) +
            math.sin(2.0 * math.pi * note_freq * 5.40 * t) * 0.15 * math.exp(-t * 2.8)
        )
        sample = bell_val * env * vel
        add_sample(start_sample + i, sample * 0.5, sample * 0.5)

chime_beats = [0.0, 16.0, 32.0, 48.0]
for b in chime_beats:
    play_temple_bell(b, FREQ["A4"], 0.15)
    play_temple_bell(b + 0.15, FREQ["D5"], 0.12)

# Normalize and export to 16-bit stereo WAV
print("Normalizing audio and exporting...")
max_amp = max(max(abs(x) for x in left_channel), max(abs(y) for y in right_channel))
if max_amp > 0.001:
    target_peak = 0.88 # -1.1 dB headroom
    scale = target_peak / max_amp
    left_channel = [x * scale for x in left_channel]
    right_channel = [y * scale for y in right_channel]

out_dir = "game/assets/sounds/bgm"
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "asian_fantasy_peace.wav")

with wave.open(out_path, "wb") as wav:
    wav.setnchannels(2)
    wav.setsampwidth(2)
    wav.setframerate(sample_rate)
    frames = bytearray()
    for l, r in zip(left_channel, right_channel):
        l_clamped = max(-1.0, min(1.0, l))
        r_clamped = max(-1.0, min(1.0, r))
        l_int = int(l_clamped * 32767)
        r_int = int(r_clamped * 32767)
        frames.extend(struct.pack("<hh", l_int, r_int))
    wav.writeframes(frames)

print(f"Generated {out_path} ({total_seconds:.2f}s, {len(frames)} bytes)")
