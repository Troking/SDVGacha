"""
Hu Tao Russian Voice & Vocalization Generator using Edge-TTS
Generates:
- Tired anime climbing sighs and exertion breaths ("Уф-ф...", "Ха-а...", "Ох-х...")
- Light nimble dash & dodge effort breaths ("Ха!", "Хуп!", "Хэ!")
- Light jump hop vocalizations ("Хоп!", "Ха!", "Ап!")
- Landing exertion breaths ("Ух!", "Оп!")
- Crisp anime attack effort grunts & battle shouts
- Rare playful idle lines
"""
import os
import asyncio
import edge_tts

OUTPUT_DIR = "e:/Trok/ChibiRPG_Project/game/assets/sounds/voice"
os.makedirs(OUTPUT_DIR, exist_ok=True)

VOICE_DATA = {
    # 1. Climbing Tired Anime Sighs & Exertion Breaths (Natural, tired, soft)
    "ru_climb_1.mp3": ("Уф-ф...", "+27Hz", "-6%"),
    "ru_climb_2.mp3": ("Ха-а...", "+29Hz", "-4%"),
    "ru_climb_3.mp3": ("Хмпф...", "+28Hz", "+2%"),
    "ru_climb_4.mp3": ("Ох-х...", "+26Hz", "-5%"),

    # 2. Dash & Dodge Nimble Breaths
    "ru_dash_1.mp3": ("Ха!", "+35Hz", "+24%"),
    "ru_dash_2.mp3": ("Хуп!", "+36Hz", "+25%"),
    "ru_dash_3.mp3": ("Хэ!", "+34Hz", "+22%"),

    # 3. Jump Effort Breaths
    "ru_jump_1.mp3": ("Хоп!", "+36Hz", "+22%"),
    "ru_jump_2.mp3": ("Ха!", "+35Hz", "+22%"),
    "ru_jump_3.mp3": ("Ап!", "+37Hz", "+20%"),

    # 4. Landing Impact Breaths
    "ru_land_1.mp3": ("Ух!", "+28Hz", "+10%"),
    "ru_land_2.mp3": ("Оп!", "+32Hz", "+14%"),

    # 5. Combat Normal Attack Effort Sounds (Hits 1-3)
    "ru_atk_1.mp3": ("Ха!", "+35Hz", "+25%"),
    "ru_atk_2.mp3": ("Ся!", "+37Hz", "+25%"),
    "ru_atk_3.mp3": ("Хэй!", "+36Hz", "+22%"),
    "ru_atk_4.mp3": ("То!", "+34Hz", "+24%"),

    # 6. Finisher & Charged Attack Shouts
    "ru_finisher_1.mp3": ("Бабочки, летите!", "+35Hz", "+16%"),
    "ru_finisher_2.mp3": ("С огоньком!", "+36Hz", "+16%"),
    "ru_finisher_3.mp3": ("Время для шоу!", "+34Hz", "+18%"),

    # 7. Elemental Skill (Pyro Burst)
    "ru_pyro_skill_1.mp3": ("Вспыхни ярче!", "+36Hz", "+16%"),
    "ru_pyro_skill_2.mp3": ("Пламя, за мной!", "+35Hz", "+15%"),
    "ru_pyro_skill_3.mp3": ("Жарче, еще жарче!", "+37Hz", "+18%"),

    # 8. Gliding Voices
    "ru_glider_1.mp3": ("Лечу-у-у, как бабочка!", "+35Hz", "+14%"),
    "ru_glider_2.mp3": ("Ух ты, какой простор!", "+34Hz", "+15%"),
    "ru_glider_3.mp3": ("Ветер, неси меня выше!", "+35Hz", "+15%"),

    # 9. Hurt / Damage Reactions
    "ru_hurt_1.mp3": ("Ай!", "+38Hz", "+24%"),
    "ru_hurt_2.mp3": ("Ой-ёй!", "+36Hz", "+20%"),
    "ru_hurt_3.mp3": ("Ох!", "+32Hz", "+18%"),

    # 10. Idle Lines (Hu Tao playful, mischievous chatter)
    "ru_idle_1.mp3": ("Хи-хи-хи! Солнышко греет, бабочки летают... Красота~", "+33Hz", "+12%"),
    "ru_idle_2.mp3": ("Один хиличурл заболел, а второй смотрел... Хи-хи!", "+34Hz", "+13%"),
    "ru_idle_3.mp3": ("Ку-ку! Чего стоим? Пошли скорее!", "+35Hz", "+15%"),
    "ru_idle_4.mp3": ("Хи-хи, скучно на месте топтаться! Погнали исследовать мир!", "+34Hz", "+14%"),
    "ru_idle_5.mp3": ("Ой, смотри, какой ветерок! Самое время погулять!", "+33Hz", "+13%"),

    # 11. Pyro Idle
    "ru_pyro_idle_1.mp3": ("Огоньки так весело пляшут прямо на кончиках пальцев!", "+34Hz", "+13%"),
    "ru_pyro_idle_2.mp3": ("Хи-хи, щекотно! Пламя само рвется в бой!", "+35Hz", "+14%"),

    # 12. Menu & Level Up
    "ru_lvlup.mp3": ("Хи-хи! Директор бюро снова на высоте!", "+35Hz", "+15%"),
    "ru_menu_open.mp3": ("Та-да-а! Чего изволите?", "+36Hz", "+16%"),
    "ru_menu_close.mp3": ("В путь-дорогу!", "+35Hz", "+16%"),
    "ru_menu_idle_1.mp3": ("Хм-м, примерим новые артефакты?", "+33Hz", "+12%"),
    "ru_menu_idle_2.mp3": ("Огоньки горят, мечи звенят!", "+34Hz", "+14%"),
    "ru_menu_idle_3.mp3": ("Хи-хи, не тормози, нас ждут сокровища!", "+35Hz", "+15%"),
    "ru_menu_idle_4.mp3": ("Ой, сколько тут интересного снаряжения!", "+33Hz", "+13%"),
    "ru_menu_idle_5.mp3": ("Ну что, готова зажечь этот мир?", "+35Hz", "+14%"),
}

async def generate_file(filename, text, pitch, rate):
    target = os.path.join(OUTPUT_DIR, filename)
    comm = edge_tts.Communicate(text, "ru-RU-SvetlanaNeural", pitch=pitch, rate=rate)
    await comm.save(target)
    print(f"Generated: {filename} -> {text}")

async def main():
    print(f"Generating {len(VOICE_DATA)} voice and vocalization files...")
    tasks = []
    for filename, (text, pitch, rate) in VOICE_DATA.items():
        tasks.append(generate_file(filename, text, pitch, rate))
    await asyncio.gather(*tasks)
    print("All vocalizations and voice lines generated successfully!")

if __name__ == '__main__':
    asyncio.run(main())
