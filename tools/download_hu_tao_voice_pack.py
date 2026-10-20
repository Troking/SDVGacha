import os
import re
import urllib.request
import time

VO_DIR = "game/assets/sounds/voice"
os.makedirs(VO_DIR, exist_ok=True)

# Parse wiki content for exact URLs
wiki_path = r"C:\Users\troki\.gemini\antigravity\brain\347d3171-74d4-4c12-8caf-29af6064aa17\.system_generated\steps\5410\content.md"
with open(wiki_path, "r", encoding="utf-8") as f:
    text = f.read()

matches = re.findall(r'(https://static\.wikia\.nocookie\.net/gensin-impact/images/[^\s\"\'<>]*(VO_JA_Hu_Tao_[^\s\"\'<>]+\.ogg)[^\s\"\'<>]*)', text)

url_map = {}
for full_url, name in matches:
    clean_name = name.split('?')[0]
    if clean_name not in url_map:
        url_map[clean_name] = full_url

# Map to target files for ChibiRPG
TARGETS = {
    # Climbing sighs & tired exertion breaths (Authentic Rie Takahashi performance)
    "ht_climb_1.ogg": "VO_JA_Hu_Tao_Climbing_01.ogg",
    "ht_climb_2.ogg": "VO_JA_Hu_Tao_Climbing_02.ogg",
    "ht_climb_3.ogg": "VO_JA_Hu_Tao_Climbing_03.ogg",
    "ht_climb_4.ogg": "VO_JA_Hu_Tao_Climbing_04.ogg",

    # Jump hops
    "ht_jump_1.ogg": "VO_JA_Hu_Tao_Jumping_01.ogg",
    "ht_jump_2.ogg": "VO_JA_Hu_Tao_Jumping_02.ogg",
    "ht_jump_3.ogg": "VO_JA_Hu_Tao_Jumping_03.ogg",
    "ht_jump_4.ogg": "VO_JA_Hu_Tao_Jumping_04.ogg",
    "ht_jump_5.ogg": "VO_JA_Hu_Tao_Jumping_05.ogg",

    # Dash / sprint start breaths
    "ht_dash_1.ogg": "VO_JA_Hu_Tao_Sprint_Start_01.ogg",
    "ht_dash_2.ogg": "VO_JA_Hu_Tao_Sprint_Start_02.ogg",
    "ht_dash_3.ogg": "VO_JA_Hu_Tao_Sprint_Start_03.ogg",

    # Landing
    "ht_land_1.ogg": "VO_JA_Hu_Tao_Jumping_02.ogg",
    "ht_land_2.ogg": "VO_JA_Hu_Tao_Jumping_03.ogg",

    # Normal attack combo effort sounds
    "ht_atk_1.ogg": "VO_JA_Hu_Tao_Light_Attack_01.ogg",
    "ht_atk_2.ogg": "VO_JA_Hu_Tao_Light_Attack_02.ogg",
    "ht_atk_3.ogg": "VO_JA_Hu_Tao_Light_Attack_03.ogg",
    "ht_atk_4.ogg": "VO_JA_Hu_Tao_Mid_Attack_01.ogg",

    # Finisher & Charged Attack
    "ht_finisher_1.ogg": "VO_JA_Hu_Tao_Heavy_Attack_01.ogg",
    "ht_finisher_2.ogg": "VO_JA_Hu_Tao_Heavy_Attack_02.ogg",
    "ht_finisher_3.ogg": "VO_JA_Hu_Tao_Heavy_Attack_03.ogg",

    # Elemental Skill (Pyro Burst)
    "ht_pyro_skill_1.ogg": "VO_JA_Hu_Tao_Elemental_Skill_1_01.ogg",
    "ht_pyro_skill_2.ogg": "VO_JA_Hu_Tao_Elemental_Skill_1_02.ogg",
    "ht_pyro_skill_3.ogg": "VO_JA_Hu_Tao_Elemental_Skill_1_03.ogg",

    # Glider deploying
    "ht_glider_1.ogg": "VO_JA_Hu_Tao_Deploying_Wind_Glider_01.ogg",
    "ht_glider_2.ogg": "VO_JA_Hu_Tao_Deploying_Wind_Glider_02.ogg",
    "ht_glider_3.ogg": "VO_JA_Hu_Tao_Deploying_Wind_Glider_03.ogg",

    # Hurt reactions
    "ht_hurt_1.ogg": "VO_JA_Hu_Tao_Light_Hit_Taken_01.ogg",
    "ht_hurt_2.ogg": "VO_JA_Hu_Tao_Light_Hit_Taken_02.ogg",
    "ht_hurt_3.ogg": "VO_JA_Hu_Tao_Light_Hit_Taken_03.ogg",
    "ht_hurt_4.ogg": "VO_JA_Hu_Tao_Heavy_Hit_Taken_01.ogg",

    # Opening chest
    "ht_chest_1.ogg": "VO_JA_Hu_Tao_Opening_Treasure_Chest_01.ogg",
    "ht_chest_2.ogg": "VO_JA_Hu_Tao_Opening_Treasure_Chest_02.ogg",
    "ht_chest_3.ogg": "VO_JA_Hu_Tao_Opening_Treasure_Chest_03.ogg",

    # Idle / Chats (Authentic Hu Tao personality)
    "ht_idle_1.ogg": "VO_JA_Hu_Tao_Chat_-_Wangsheng_Funeral_Parlor.ogg",
    "ht_idle_2.ogg": "VO_JA_Hu_Tao_Chat_-_Customers.ogg",
    "ht_idle_3.ogg": "VO_JA_Hu_Tao_Chat_-_Taking_a_Break.ogg",
    "ht_idle_4.ogg": "VO_JA_Hu_Tao_Standby_01.ogg",
    "ht_idle_5.ogg": "VO_JA_Hu_Tao_Standby_02.ogg",
}

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://genshin-impact.fandom.com/wiki/Hu_Tao/Voice-Overs/Japanese',
    'Accept': '*/*',
}

print(f"Starting download of {len(TARGETS)} authentic Hu Tao voice clips...")
success = 0
for local_file, wiki_vo in TARGETS.items():
    if wiki_vo not in url_map:
        print(f"Warning: {wiki_vo} not found in url_map")
        continue
    url = url_map[wiki_vo]
    dest = os.path.join(VO_DIR, local_file)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp:
            data = resp.read()
            with open(dest, "wb") as out:
                out.write(data)
            print(f"[{success+1}/{len(TARGETS)}] Downloaded {local_file} ({len(data)} bytes) <- {wiki_vo}")
            success += 1
        time.sleep(0.1) # Be gentle to CDN
    except Exception as e:
        print(f"Failed {local_file}: {e}")

print(f"Completed: {success}/{len(TARGETS)} authentic Hu Tao voice lines downloaded successfully!")
