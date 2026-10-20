"""
Youthful & Mischievous Hu Tao Russian Voice Generator
Generates cute, playful, fast-paced anime girl voice lines using Edge-TTS
with pitch and rate tuned to sound like a 16-year-old anime prankster,
completely eliminating mature/40yo phrasing and delivery.
"""
import os
import asyncio
import edge_tts

OUTPUT_DIR = "game/assets/sounds/voice"
os.makedirs(OUTPUT_DIR, exist_ok=True)

VOICE_DATA = {
    # 1. Finisher & Charged Attack Shouts (Playful, cheeky, combat banter)
    "ru_finisher_1.mp3": ("Бабочки, в пляс! Хи-хи!", "+36Hz", "+20%"),
    "ru_finisher_2.mp3": ("Ой-ёй, горячо будет!", "+35Hz", "+18%"),
    "ru_finisher_3.mp3": ("Проводим с почестями~!", "+34Hz", "+18%"),

    # 2. Elemental Skill (Pyro Burst)
    "ru_pyro_skill_1.mp3": ("Огоньки, кружитесь!", "+36Hz", "+20%"),
    "ru_pyro_skill_2.mp3": ("Опаньки! Зажигаем!", "+37Hz", "+22%"),
    "ru_pyro_skill_3.mp3": ("Бабочки порхают! Хи-хи!", "+36Hz", "+20%"),

    # 3. Gliding Voices
    "ru_glider_1.mp3": ("У-и-и-и! Прямо как бабочка!", "+36Hz", "+18%"),
    "ru_glider_2.mp3": ("Ух ты-ы! Какой простор, красота!", "+34Hz", "+16%"),
    "ru_glider_3.mp3": ("Ветерок, неси меня к облачкам~!", "+35Hz", "+18%"),

    # 4. Idle Lines (Hu Tao playful, eccentric, teasing banter)
    "ru_idle_1.mp3": ("Хи-хи-хи! Солнышко греет, гробики сохнут... Ой, то есть цветочки цветут~!", "+33Hz", "+14%"),
    "ru_idle_2.mp3": ("Хиличурл заболел, а второй на него смотрел... Хи-хи, забавная песенка!", "+34Hz", "+15%"),
    "ru_idle_3.mp3": ("Ку-ку! Чего застыл? Ску-у-чно же стоять, пошли скорее!", "+35Hz", "+18%"),
    "ru_idle_4.mp3": ("Хи-хи, клиенты сами себя не найдут! Погнали искать приключения!", "+35Hz", "+18%"),
    "ru_idle_5.mp3": ("Ой, ветерок такой свежий! Самое то пошалить~!", "+34Hz", "+16%"),

    # 5. Pyro Idle
    "ru_pyro_idle_1.mp3": ("Ой, огонёк пляшет прямо на ладошке! Хи-хи, щекотно!", "+35Hz", "+16%"),
    "ru_pyro_idle_2.mp3": ("Хи-хи, пламя не терпит покоя! Пора задать жару!", "+36Hz", "+18%"),

    # 6. Menu & Level Up
    "ru_lvlup.mp3": ("Та-да-ам! Директор бюро становится ещё сильнее!", "+36Hz", "+18%"),
    "ru_menu_open.mp3": ("Та-да-ам! Что у нас тут новенького?", "+37Hz", "+18%"),
    "ru_menu_close.mp3": ("Хи-хи, побежали навстречу ветру!", "+36Hz", "+20%"),
    "ru_menu_idle_1.mp3": ("Хм-м... А эта штучка мне к лицу? Хи-хи!", "+34Hz", "+16%"),
    "ru_menu_idle_2.mp3": ("Ой, блестит как новенькое сокровище!", "+35Hz", "+18%"),
    "ru_menu_idle_3.mp3": ("Не зевай, директор бюро не любит ждать!", "+35Hz", "+18%"),
    "ru_menu_idle_4.mp3": ("Ого, сколько кармашков! Что бы такое надеть?", "+34Hz", "+16%"),
    "ru_menu_idle_5.mp3": ("Хи-хи, директор одобряет этот выбор!", "+35Hz", "+18%"),
}

async def generate_file(filename, text, pitch, rate):
    target = os.path.join(OUTPUT_DIR, filename)
    comm = edge_tts.Communicate(text, "ru-RU-SvetlanaNeural", pitch=pitch, rate=rate)
    await comm.save(target)
    print(f"Generated: {filename} ({pitch}, {rate}) -> '{text}'")

async def main():
    print(f"Generating {len(VOICE_DATA)} youthful Hu Tao Russian voice lines...")
    tasks = []
    for filename, (text, pitch, rate) in VOICE_DATA.items():
        tasks.append(generate_file(filename, text, pitch, rate))
    await asyncio.gather(*tasks)
    print("All youthful Hu Tao voice lines generated successfully!")

if __name__ == "__main__":
    asyncio.run(main())
