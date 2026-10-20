import os
import asyncio
import edge_tts

OUTPUT_DIR = r"e:\Trok\ChibiRPG_Project\game\assets\sounds\voice"
os.makedirs(OUTPUT_DIR, exist_ok=True)

VOICE_DATA = {
    # Ellen Joe (Seiyuu Aoi Yuuki style: calm, cool, slightly sleepy maid)
    "ellen_vn_greet.mp3": (
        "はぁ…何の用？ヴィクトリア家政に用件なら、今は休憩時間…ま、話くらいは聞いてあげる。",
        "ja-JP-NanamiNeural", "-4%", "-4Hz"
    ),
    "ellen_vn_accept.mp3": (
        "わかった、一緒に行ってあげる。ただし、残業代はロリポップで払ってよね。",
        "ja-JP-NanamiNeural", "-2%", "-3Hz"
    ),
    "ellen_switch.mp3": (
        "エレン、出るよ。さっさと片付けて帰ろ。",
        "ja-JP-NanamiNeural", "-2%", "-3Hz"
    ),
    "ellen_attack_1.mp3": (
        "遅いよ！",
        "ja-JP-NanamiNeural", "+8%", "-1Hz"
    ),
    "ellen_attack_2.mp3": (
        "シャーク・バイト！",
        "ja-JP-NanamiNeural", "+10%", "+0Hz"
    ),
    "ellen_idle.mp3": (
        "ふぁ〜あ…眠い…少しサボらせてくれない？",
        "ja-JP-NanamiNeural", "-6%", "-4Hz"
    ),

    # Heroine / Player dialogue voice reactions (Hu Tao cheerful style)
    "heroine_dialogue_start.mp3": (
        "ねえねえ、ちょっといい？",
        "ja-JP-NanamiNeural", "+6%", "+6Hz"
    ),
    "heroine_choice_recruit.mp3": (
        "うん！一緒に行こう、頼りにしてるよ！",
        "ja-JP-NanamiNeural", "+8%", "+7Hz"
    ),
    "heroine_choice_battle.mp3": (
        "やった！よろしく頼むね！",
        "ja-JP-NanamiNeural", "+10%", "+8Hz"
    ),
}

async def generate():
    for fname, (text, voice, rate, pitch) in VOICE_DATA.items():
        out_path = os.path.join(OUTPUT_DIR, fname)
        comm = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
        await comm.save(out_path)
        print(f"Generated: {fname}")

if __name__ == "__main__":
    asyncio.run(generate())
