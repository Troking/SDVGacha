import os
import re
import urllib.request
import time

VO_DIR = "game/assets/sounds/voice"
wiki_path = r"C:\Users\troki\.gemini\antigravity\brain\347d3171-74d4-4c12-8caf-29af6064aa17\.system_generated\steps\5410\content.md"

with open(wiki_path, "r", encoding="utf-8") as f:
    text = f.read()

matches = re.findall(r'(https://static\.wikia\.nocookie\.net/gensin-impact/images/[^\s\"\'<>]*(VO_JA_Hu_Tao_[^\s\"\'<>]+\.ogg)[^\s\"\'<>]*)', text)
url_map = {}
for full_url, name in matches:
    clean_name = name.split("?")[0]
    if clean_name not in url_map:
        url_map[clean_name] = full_url

BURST_TARGETS = {
    "ht_burst_1.ogg": "VO_JA_Hu_Tao_Elemental_Burst_01.ogg",
    "ht_burst_2.ogg": "VO_JA_Hu_Tao_Elemental_Burst_02.ogg",
    "ht_burst_3.ogg": "VO_JA_Hu_Tao_Elemental_Burst_03.ogg",
    "ht_light_atk_4.ogg": "VO_JA_Hu_Tao_Light_Attack_04.ogg",
    "ht_light_atk_5.ogg": "VO_JA_Hu_Tao_Light_Attack_05.ogg",
    "ht_mid_atk_2.ogg": "VO_JA_Hu_Tao_Mid_Attack_02.ogg",
    "ht_mid_atk_3.ogg": "VO_JA_Hu_Tao_Mid_Attack_03.ogg",
}

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://genshin-impact.fandom.com/wiki/Hu_Tao/Voice-Overs/Japanese',
    'Accept': '*/*',
}

for local_file, wiki_vo in BURST_TARGETS.items():
    if wiki_vo not in url_map:
        print(f"Not found: {wiki_vo}")
        continue
    url = url_map[wiki_vo]
    dest = os.path.join(VO_DIR, local_file)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp:
            data = resp.read()
            with open(dest, "wb") as out:
                out.write(data)
            print(f"Downloaded {local_file} ({len(data)} bytes) from {wiki_vo}")
        time.sleep(0.1)
    except Exception as e:
        print(f"Failed {local_file}: {e}")
