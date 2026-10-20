"""
Generates natural, expressive, lively Russian voice lines for Hu Tao.
No artificial pitch-shifting (which caused the metallic robotic distortion).
Using lively anime intonation, expressive punctuation, and natural human delivery.
"""
import os
import asyncio
import edge_tts

OUTPUT_DIR = "game/assets/sounds/voice"
os.makedirs(OUTPUT_DIR, exist_ok=True)

SPOKEN_DATA = {
    # 1. Finisher & Charged Attack Shouts
    "ru_finisher_1.mp3": "Бабочки, летите!",
    "ru_finisher_2.mp3": "С огоньком!",
    "ru_finisher_3.mp3": "Время для шоу!",

    # 2. Elemental Skill (Pyro Burst)
    "ru_pyro_skill_1.mp3": "Вспыхни ярче!",
    "ru_pyro_skill_2.mp3": "Пламя, за мной!",
    "ru_pyro_skill_3.mp3": "Жарче, еще жарче!",

    # 3. Gliding Lines
    "ru_glider_1.mp3": "Лечу-у-у, прямо как бабочка!",
    "ru_glider_2.mp3": "Ух ты, какой простор открывается!",
    "ru_glider_3.mp3": "Ветер, неси меня выше!",

    # 4. Playful Idle Chatter (Hu Tao's mischievous character)
    "ru_idle_1.mp3": "Хи-хи-хи! Солнышко греет, бабочки летают... Красота!",
    "ru_idle_2.mp3": "Один хиличурл заболел, а второй смотрел... Хи-хи!",
    "ru_idle_3.mp3": "Ку-ку! Чего стоим? Пошли скорее за приключениями!",
    "ru_idle_4.mp3": "Хи-хи, скучно на месте топтаться! Погнали исследовать мир!",
    "ru_idle_5.mp3": "Ой, смотри, какой приятный ветерок! Самое время прогуляться!",

    # 5. Pyro Idle
    "ru_pyro_idle_1.mp3": "Огоньки так весело пляшут прямо на кончиках пальцев!",
    "ru_pyro_idle_2.mp3": "Хи-хи, щекотно! Пламя само рвется в бой!",

    # 6. Menu & Level Up
    "ru_lvlup.mp3": "Хи-хи! Директор бюро Ваншэн снова на высоте!",
    "ru_menu_open.mp3": "Та-да-а! Чего изволите?",
    "ru_menu_close.mp3": "В путь-дорогу!",
    "ru_menu_idle_1.mp3": "Хм-м, примерим новые артефакты?",
    "ru_menu_idle_2.mp3": "Огоньки горят, мечи звенят!",
    "ru_menu_idle_3.mp3": "Хи-хи, не тормози, нас ждут сокровища!",
    "ru_menu_idle_4.mp3": "Ой, сколько тут интересного снаряжения!",
    "ru_menu_idle_5.mp3": "Ну что, готова зажечь этот мир?",
}

async def generate_file(filename, text):
    target = os.path.join(OUTPUT_DIR, filename)
    # Using natural Svetlana with natural pitch and slight brisk pace (+5%) for youthful anime cadence
    comm = edge_tts.Communicate(text, "ru-RU-SvetlanaNeural", rate="+6%")
    await comm.save(target)
    print(f"Generated: {filename} -> '{text}'")

async def main():
    print(f"Generating {len(SPOKEN_DATA)} natural Russian voice lines...")
    tasks = []
    for filename, text in SPOKEN_DATA.items():
        tasks.append(generate_file(filename, text))
    await asyncio.gather(*tasks)
    print("All Russian spoken lines generated successfully without pitch distortion!")

if __name__ == "__main__":
    asyncio.run(main())
