import os
import asyncio
import edge_tts

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds/voice"
os.makedirs(OUTPUT_DIR, exist_ok=True)

VOICE_DATA = {
    # Ellen Joe - cool, calm, slightly sleepy maid
    "ellen_switch.mp3": ("Эллен на связи. Быстро покрошим их и по домам?", "ru-RU-SvetlanaNeural", "-4%", "-2Hz"),
    "ellen_vn_greet.mp3": ("Ха-ах... Чего тебе? Если ты из агентства, скажи, что я на обеденном перерыве.", "ru-RU-SvetlanaNeural", "-5%", "-3Hz"),
    "ellen_vn_accept.mp3": ("Ладно, помогу тебе. Только чур сверхурочные оплачиваешь леденцами!", "ru-RU-SvetlanaNeural", "+2%", "-1Hz"),
    "ellen_attack_1.mp3": ("Быстро и без шума.", "ru-RU-SvetlanaNeural", "+6%", "-2Hz"),
    "ellen_attack_2.mp3": ("Заморожу на кусочки!", "ru-RU-SvetlanaNeural", "+8%", "+1Hz"),
    "ellen_idle.mp3": ("Ха-ах... Опять сверхурочные? Я бы лучше поспала на диване в кафе...", "ru-RU-SvetlanaNeural", "-6%", "-3Hz"),
    
    # Hu Tao - cheerful, fiery, lively
    "ht_switch.mp3": ("Ху Тао здесь! Давайте зажжем этот вечер!", "ru-RU-SvetlanaNeural", "+8%", "+8Hz"),
}

async def generate():
    for fname, (text, voice, rate, pitch) in VOICE_DATA.items():
        out_path = os.path.join(OUTPUT_DIR, fname)
        comm = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
        await comm.save(out_path)
        print(f"Generated: {fname} -> {text}")

if __name__ == "__main__":
    asyncio.run(generate())
