import re

p = r"C:\Users\troki\.gemini\antigravity\brain\347d3171-74d4-4c12-8caf-29af6064aa17\.system_generated\steps\5410\content.md"
with open(p, "r", encoding="utf-8") as f:
    text = f.read()

matches = re.findall(r"(https://static\.wikia\.nocookie\.net/gensin-impact/images/[^\s\"\'<>]*(VO_[^\s\"\'<>]+\.ogg)[^\s\"\'<>]*)", text)
print(f"Total matches: {len(matches)}")
categories = set()
for url, name in matches:
    clean = name.split("?")[0]
    categories.add(clean)

for c in sorted(list(categories)):
    if any(k in c for k in ["Attack", "Skill", "Burst", "Standby", "Chat", "Chest", "Climb", "Jump", "Fallen", "Damage", "Hit", "Wind", "Sprint"]):
        print(c)
