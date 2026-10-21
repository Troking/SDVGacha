#!/usr/bin/env python3
"""
⚡ WEB OPTIMIZATIONS & FAST-LOAD ENHANCER
Injects:
1. Parallel fetch preloading for index.wasm & index.pck
2. High-visibility full-screen launcher button
3. Anime-styled loading screen with exact percentage, MB counter, and dynamic tips
4. Robust display: none handling when Godot initialization finishes
"""

import sys
from pathlib import Path

def inject(index_path: Path) -> None:
    if not index_path.exists():
        print(f"Error: {index_path} not found")
        sys.exit(1)

    html = index_path.read_text(encoding="utf-8")

    # 1. Preload hints in <head> for maximum parallel download speed over HTTP/2
    preload_tags = """
		<!-- Fast-load HTTP/2 parallel resource preloading -->
		<link rel="preload" href="index.wasm" as="fetch" type="application/wasm" crossorigin="anonymous">
		<link rel="preload" href="index.pck" as="fetch" crossorigin="anonymous">
"""
    if "</head>" in html and "index.wasm" not in html.split("</head>")[0]:
        html = html.replace("</head>", preload_tags + "\n\t</head>", 1)

    # 2. Modern Anime Loading Screen & Fullscreen Button
    enhancement = """
<!-- ==================== SDVGACHA WEB ENHANCEMENTS ==================== -->
<style>
/* Fullscreen Toggle Floating Widget */
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
	font-size: 14px;
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
	transform: scale(1.05);
	background: linear-gradient(135deg, rgba(42, 28, 56, 0.98), rgba(68, 32, 18, 0.98));
	border-color: #ffffff;
	color: #ffffff;
	box-shadow: 0 6px 26px rgba(255, 190, 0, 0.7);
}

/* Anime Loading Screen Overhaul */
#status {
	background: radial-gradient(circle at center, #181528 0%, #08060f 100%);
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
	color: #ffffff;
	text-align: center;
}
#status[style*="display: none"] {
	display: none !important;
}
#status-splash {
	max-height: 220px !important;
	max-width: 85% !important;
	border-radius: 16px;
	box-shadow: 0 8px 32px rgba(0, 0, 0, 0.7), 0 0 20px rgba(255, 180, 0, 0.25);
	margin-bottom: 24px !important;
}
#status-progress {
	display: none !important; /* Replaced by custom anime progress bar */
}
#custom-loading-card {
	display: flex;
	flex-direction: column;
	align-items: center;
	width: min(520px, 86vw);
}
.loading-title {
	font-size: 24px;
	font-weight: 800;
	color: #ffd54f;
	letter-spacing: 1.5px;
	margin-bottom: 6px;
	text-shadow: 0 0 16px rgba(255, 213, 79, 0.6);
}
.loading-sub {
	font-size: 13px;
	color: #90a4ae;
	margin-bottom: 18px;
	letter-spacing: 0.5px;
}
.progress-bar-shell {
	width: 100%;
	height: 16px;
	background: rgba(255, 255, 255, 0.08);
	border: 1.5px solid rgba(255, 213, 79, 0.6);
	border-radius: 12px;
	overflow: hidden;
	box-shadow: 0 2px 10px rgba(0, 0, 0, 0.5), inset 0 1px 3px rgba(0, 0, 0, 0.6);
	position: relative;
}
.progress-bar-fill {
	height: 100%;
	width: 0%;
	background: linear-gradient(90deg, #ff5722 0%, #ffd54f 50%, #40c4ff 100%);
	border-radius: 10px;
	box-shadow: 0 0 16px rgba(255, 213, 79, 0.85);
	transition: width 0.12s ease-out;
}
.loading-status-text {
	margin-top: 14px;
	font-size: 15px;
	font-weight: 700;
	color: #ffe082;
	letter-spacing: 0.6px;
}
.loading-tip {
	margin-top: 22px;
	font-size: 12px;
	color: #78909c;
	font-style: italic;
	line-height: 1.4;
	max-width: 440px;
	background: rgba(255, 255, 255, 0.04);
	padding: 8px 16px;
	border-radius: 8px;
	border: 1px solid rgba(255, 255, 255, 0.06);
}
</style>

<button id="web-fullscreen-btn" onclick="toggleWebFullscreen()">⛶ НА ВЕСЬ ЭКРАН</button>

<script>
// Fullscreen Toggle
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

// Setup Anime Loading Card
window.addEventListener('DOMContentLoaded', function() {
	var status = document.getElementById('status');
	if (!status) return;

	// Watch for Godot hiding the status screen
	var hideObserver = new MutationObserver(function() {
		if (status.style.display === 'none') {
			status.style.setProperty('display', 'none', 'important');
		}
	});
	hideObserver.observe(status, { attributes: true, attributeFilter: ['style'] });

	var card = document.createElement('div');
	card.id = 'custom-loading-card';
	card.innerHTML = `
		<div class="loading-title">🌟 SDV GACHA • ЗАГРУЗКА 🌟</div>
		<div class="loading-sub">3D Anime Action-RPG • WebGL Engine</div>
		<div class="progress-bar-shell">
			<div class="progress-bar-fill" id="custom-progress-fill"></div>
		</div>
		<div class="loading-status-text" id="custom-status-text">Инициализация WebAssembly...</div>
		<div class="loading-tip" id="custom-tip">💡 Совет: Переключайтесь между Ху Тао [1] и Эллен [2] прямо во время боя!</div>
	`;
	status.appendChild(card);

	var tips = [
		"💡 Совет: Переключайтесь между Ху Тао [1] и Эллен [2] прямо во время боя!",
		"💡 Совет: Зажмите ЛКМ для мощного заряженного вихревого удара!",
		"💡 Совет: Подойдите к Эллен Джо и нажмите [F], чтобы пригласить ее в отряд!",
		"💡 Совет: Вся Японская школа и крупные постройки разрушаются по частям и секциям!",
		"💡 Совет: Кнопка [Q] мгновенно восстанавливает здоровье исцеляющим зельем."
	];
	var tipIdx = 0;
	setInterval(function() {
		tipIdx = (tipIdx + 1) % tips.length;
		var tipElem = document.getElementById('custom-tip');
		if (tipElem) tipElem.innerText = tips[tipIdx];
	}, 4000);

	// Observe and poll standard Godot progress updates
	var defaultProgress = document.getElementById('status-progress');
	var fill = document.getElementById('custom-progress-fill');
	var txt = document.getElementById('custom-status-text');

	function updateCustomProgress() {
		if (!defaultProgress) return;
		var val = parseFloat(defaultProgress.value) || 0;
		var max = parseFloat(defaultProgress.max) || 0;
		if (max > 0) {
			var pct = Math.min(100, Math.floor((val / max) * 100));
			var curMB = (val / (1024 * 1024)).toFixed(1);
			var totMB = (max / (1024 * 1024)).toFixed(1);
			if (fill) fill.style.width = pct + '%';
			if (txt) txt.innerText = 'Загрузка игрового мира: ' + pct + '% (' + curMB + ' / ' + totMB + ' МБ)';
		}
	}

	var pollInterval = setInterval(updateCustomProgress, 50);

	if (defaultProgress) {
		var observer = new MutationObserver(updateCustomProgress);
		observer.observe(defaultProgress, { attributes: true });
	}
});
</script>
"""

    if "</body>" in html and "#web-fullscreen-btn" not in html:
        html = html.replace("</body>", enhancement + "\n</body>")
        index_path.write_text(html, encoding="utf-8")
        print(f"Successfully injected web optimizations into {index_path}")
    else:
        print("Web optimizations already present.")

if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/web/index.html")
    inject(target)
