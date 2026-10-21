#!/usr/bin/env python3
"""
Injects a high-visibility fullscreen button and automatic orientation handler
into the exported Godot Web index.html.
"""

import sys
from pathlib import Path

def inject(index_path: Path) -> None:
    if not index_path.exists():
        print(f"Error: {index_path} not found")
        sys.exit(1)

    html = index_path.read_text(encoding="utf-8")

    fs_widget = """
<!-- Interactive Fullscreen Launcher Bar -->
<style>
#web-fullscreen-btn {
	position: fixed;
	top: 14px;
	right: 14px;
	z-index: 9999999;
	background: linear-gradient(135deg, rgba(22, 18, 32, 0.94), rgba(42, 22, 14, 0.96));
	color: #ffe082;
	border: 2px solid #ffd54f;
	padding: 10px 22px;
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
	font-size: 15px;
	font-weight: 700;
	border-radius: 14px;
	cursor: pointer;
	box-shadow: 0 4px 20px rgba(0, 0, 0, 0.65), 0 0 14px rgba(255, 180, 0, 0.45);
	transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
	letter-spacing: 0.5px;
	display: flex;
	align-items: center;
	gap: 8px;
	backdrop-filter: blur(8px);
}
#web-fullscreen-btn:hover {
	transform: scale(1.06);
	background: linear-gradient(135deg, rgba(42, 28, 56, 0.98), rgba(68, 32, 18, 0.98));
	border-color: #ffffff;
	color: #ffffff;
	box-shadow: 0 6px 26px rgba(255, 190, 0, 0.7);
}
</style>
<button id="web-fullscreen-btn" onclick="toggleWebFullscreen()">⛶ НА ВЕСЬ ЭКРАН</button>
<script>
function toggleWebFullscreen() {
	var btn = document.getElementById('web-fullscreen-btn');
	if (!document.fullscreenElement) {
		document.documentElement.requestFullscreen().then(function() {
			if (btn) btn.innerHTML = '🗗 ОКОННЫЙ РЕЖИМ';
		}).catch(function(err) {});
	} else {
		if (document.exitFullscreen) {
			document.exitFullscreen().then(function() {
				if (btn) btn.innerHTML = '⛶ НА ВЕСЬ ЭКРАН';
			});
		}
	}
}
document.addEventListener('fullscreenchange', function() {
	var btn = document.getElementById('web-fullscreen-btn');
	if (!btn) return;
	if (document.fullscreenElement) {
		btn.innerHTML = '🗗 ОКОННЫЙ РЕЖИМ';
	} else {
		btn.innerHTML = '⛶ НА ВЕСЬ ЭКРАН';
	}
});
</script>
"""

    if "</body>" in html and "#web-fullscreen-btn" not in html:
        html = html.replace("</body>", fs_widget + "\n</body>")
        index_path.write_text(html, encoding="utf-8")
        print(f"Successfully injected fullscreen button into {index_path}")
    else:
        print("Fullscreen button already present or </body> not found.")

if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/web/index.html")
    inject(target)
