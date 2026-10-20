"""
Generates high-fidelity organic chest opening sound effect (tactile wooden latch, heavy lid swing,
lush crystal bell fanfare, and gold coin shimmer).
"""
import os
import math
import wave
import struct
import random

SOUND_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds"
os.makedirs(SOUND_DIR, exist_ok=True)

def generate_organic_chest_open_sound():
    sample_rate = 44100
    duration = 1.30
    total_samples = int(sample_rate * duration)
    stereo_data = bytearray()

    # Bell notes (Genshin Major Pentatonic Sparkle)
    bell_notes = [
        (0.10, 523.25, 0.42),   # C5
        (0.18, 659.25, 0.45),   # E5
        (0.26, 783.99, 0.48),   # G5
        (0.35, 1046.50, 0.55),  # C6
        (0.44, 1318.51, 0.60),  # E6
        (0.53, 1567.98, 0.68),  # G6
    ]

    # Coin clink micro-transients
    coin_clinks = [
        (0.22, 2200.0), (0.28, 2850.0), (0.34, 1950.0),
        (0.41, 3100.0), (0.48, 2450.0), (0.56, 3350.0),
        (0.64, 2150.0), (0.72, 2900.0)
    ]

    for i in range(total_samples):
        t = i / float(sample_rate)

        # ----------------------------------------------------
        # 1. Tactile Wooden Box & Brass Latch Snap (0.00 - 0.12s)
        # ----------------------------------------------------
        latch_sound = 0.0
        if t < 0.12:
            # High metallic latch click
            click_env = math.exp(-t * 220.0)
            click_wave = (math.sin(2.0 * math.pi * 1850.0 * t) * 0.6 +
                          math.sin(2.0 * math.pi * 3200.0 * t) * 0.4) * click_env * 0.55

            # Hollow wooden chest resonance (low thump)
            wood_env = math.exp(-t * 45.0)
            wood_wave = math.sin(2.0 * math.pi * 195.0 * t) * wood_env * 0.65

            # Heavy lid friction whoosh
            whoosh_env = math.sin(min(1.0, t / 0.06) * math.pi) * math.exp(-t * 18.0)
            whoosh = random.uniform(-0.15, 0.15) * whoosh_env

            latch_sound = click_wave + wood_wave + whoosh

        # ----------------------------------------------------
        # 2. Celestial Crystal Bell Fanfare (0.10 - 1.25s)
        # ----------------------------------------------------
        bell_sum_l = 0.0
        bell_sum_r = 0.0
        for start_t, freq, amp in bell_notes:
            dt = t - start_t
            if dt >= 0.0:
                # Bell envelope: sharp strike, natural long acoustic ring
                strike = math.sin(min(1.0, dt / 0.008) * math.pi * 0.5)
                decay = math.exp(-dt * 3.4)
                env = strike * decay * amp

                # Natural bell harmonics (Fundamental + 2nd octave + 3rd fifth + inharmonic metallic strike)
                h1 = math.sin(2.0 * math.pi * freq * dt)
                h2 = math.sin(2.0 * math.pi * (freq * 2.002) * dt) * 0.35
                h3 = math.sin(2.0 * math.pi * (freq * 3.01) * dt) * 0.15
                h4 = math.sin(2.0 * math.pi * (freq * 4.15) * dt) * 0.08 * math.exp(-dt * 12.0) # Strike transient
                bell_sample = (h1 + h2 + h3 + h4) * env

                # Stereo chorus detuning
                detune_l = math.sin(2.0 * math.pi * (freq + 1.2) * dt) * env * 0.15
                detune_r = math.sin(2.0 * math.pi * (freq - 1.2) * dt) * env * 0.15

                bell_sum_l += bell_sample + detune_l
                bell_sum_r += bell_sample + detune_r

        # ----------------------------------------------------
        # 3. Gold Coin / Gem Clinks
        # ----------------------------------------------------
        coins_l = 0.0
        coins_r = 0.0
        for c_t, c_f in coin_clinks:
            dt = t - c_t
            if 0.0 <= dt < 0.035:
                c_env = math.exp(-dt * 160.0)
                c_wav = math.sin(2.0 * math.pi * c_f * dt) * c_env * 0.09
                coins_l += c_wav * (0.8 if c_f % 2 == 0 else 0.5)
                coins_r += c_wav * (0.5 if c_f % 2 == 0 else 0.8)

        # Master mix
        sample_l = latch_sound * 0.85 + bell_sum_l * 0.65 + coins_l
        sample_r = latch_sound * 0.85 + bell_sum_r * 0.65 + coins_r

        # Gentle soft limiting / saturation
        sample_l = math.tanh(sample_l * 1.1)
        sample_r = math.tanh(sample_r * 1.1)

        int_l = int(max(-32767, min(32767, sample_l * 32767)))
        int_r = int(max(-32767, min(32767, sample_r * 32767)))
        stereo_data.extend(struct.pack('<hh', int_l, int_r))

    out_file = os.path.join(SOUND_DIR, "chest_open.wav")
    with wave.open(out_file, 'wb') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(stereo_data)
    print("Saved organic chest_open.wav (44.1kHz Stereo)")

if __name__ == '__main__':
    generate_organic_chest_open_sound()
