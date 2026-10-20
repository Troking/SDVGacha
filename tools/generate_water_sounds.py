import math, wave, struct, random, os

os.makedirs("game/assets/sounds/player", exist_ok=True)

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

# 1. water_splash_enter.wav (Soft bubbly water plunge)
sr = 44100
dur = 0.55
n_samples = int(dur * sr)
splash_enter = []
for i in range(n_samples):
    t = float(i) / sr
    env = math.exp(-t * 8.5)
    # Low frequency surge + bubble pops + filtered white noise
    noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 14.0)
    surge = math.sin(2.0 * math.pi * (160.0 - t * 120.0) * t) * 0.6
    bubble = math.sin(2.0 * math.pi * (450.0 + math.sin(t * 80.0) * 150.0) * t) * 0.35 * math.exp(-t * 9.0)
    sample = (surge + bubble + noise * 0.4) * env * 0.75
    splash_enter.append(sample)
write_wav("game/assets/sounds/player/water_splash_enter.wav", splash_enter)

# 2. water_swim_stroke.wav (Gentle rhythmic water paddle stroke)
dur = 0.38
n_samples = int(dur * sr)
swim_stroke = []
for i in range(n_samples):
    t = float(i) / sr
    # Swell and fade
    env = (t / 0.08) if t < 0.08 else math.exp(-(t - 0.08) * 11.0)
    swish = (random.random() * 2.0 - 1.0) * math.sin(2.0 * math.pi * 120.0 * t) * 0.45
    ripple = math.sin(2.0 * math.pi * (220.0 - t * 80.0) * t) * 0.5
    sample = (swish + ripple) * env * 0.55
    swim_stroke.append(sample)
write_wav("game/assets/sounds/player/water_swim_stroke.wav", swim_stroke)

# 3. water_splash_jump.wav (Light water push-off on jumping out)
dur = 0.32
n_samples = int(dur * sr)
splash_jump = []
for i in range(n_samples):
    t = float(i) / sr
    env = math.exp(-t * 12.0)
    burst = (random.random() * 2.0 - 1.0) * 0.45
    whoosh = math.sin(2.0 * math.pi * (280.0 + t * 150.0) * t) * 0.5
    sample = (burst + whoosh) * env * 0.65
    splash_jump.append(sample)
write_wav("game/assets/sounds/player/water_splash_jump.wav", splash_jump)

print("Generated water sound effects.")
