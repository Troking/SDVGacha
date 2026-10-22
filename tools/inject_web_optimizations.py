#!/usr/bin/env python3
"""
⚡ WEB OPTIMIZATIONS & FAST-LOAD ENHANCER (MOBILE & PC)
Features:
1. Direct event-driven progress hook into Godot engine onProgress (zero polling, zero WebKit lag)
2. Mobile & desktop responsive layout (fits landscape smartphones, portrait, and desktop 4K)
3. Portrait orientation helper for smartphones
4. Clean removal of conflicting preloads that cause duplicate downloads on mobile Safari
"""

import sys
from pathlib import Path

def inject(index_path: Path) -> None:
    if not index_path.exists():
        print(f"Error: {index_path} not found")
        sys.exit(1)

    html = index_path.read_text(encoding="utf-8")

    # Remove any old preload tags that caused CORS mismatch / duplicate 65MB downloads on mobile
    if '<link rel="preload" href="index.wasm"' in html:
        import re
        html = re.sub(r'\s*<!-- Fast-load HTTP/2 parallel resource preloading -->\s*', '\n', html)
        html = re.sub(r'\s*<link rel="preload" href="index\.wasm"[^>]*>', '', html)
        html = re.sub(r'\s*<link rel="preload" href="index\.pck"[^>]*>', '', html)

    # Hook directly into Godot's onProgress callback
    target_onprogress = """statusProgress.value = current;
					statusProgress.max = total;"""
    replacement_onprogress = """statusProgress.value = current;
					statusProgress.max = total;
					if (window.updateCustomProgress) {
						window.updateCustomProgress(current, total);
					}"""
    if target_onprogress in html and "window.updateCustomProgress" not in html:
        html = html.replace(target_onprogress, replacement_onprogress, 1)

    # Modern Anime Loading Screen (Responsive for mobile landscape, portrait, and PC)
    enhancement = """
<!-- ==================== SDVGACHA WEB ENHANCEMENTS ==================== -->
<style>
/* Anime Loading Screen Overhaul */
#status {
	position: absolute;
	left: 0;
	top: 0;
	right: 0;
	bottom: 0;
	background: radial-gradient(circle at center, #181528 0%, #08060f 100%);
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
	color: #ffffff;
	text-align: center;
	padding: 12px;
	box-sizing: border-box;
	overflow: hidden;
	z-index: 99999;
}
#status[style*="display: none"] {
	display: none !important;
}
#status-splash {
	max-height: 180px;
	max-width: 82%;
	object-fit: contain;
	border-radius: 14px;
	box-shadow: 0 6px 24px rgba(0, 0, 0, 0.6), 0 0 16px rgba(255, 180, 0, 0.25);
	margin-bottom: 16px;
}
#status-progress {
	display: none !important; /* Replaced by custom anime progress bar */
}
#custom-loading-card {
	display: flex;
	flex-direction: column;
	align-items: center;
	width: min(480px, 92vw);
}
.loading-title {
	font-size: clamp(16px, 4vw, 22px);
	font-weight: 800;
	color: #ffd54f;
	letter-spacing: 1px;
	margin-bottom: 4px;
	text-shadow: 0 0 12px rgba(255, 213, 79, 0.5);
}
.loading-sub {
	font-size: clamp(10px, 2.5vw, 12px);
	color: #90a4ae;
	margin-bottom: 12px;
	letter-spacing: 0.5px;
}
.progress-bar-shell {
	width: 100%;
	height: 14px;
	background: rgba(255, 255, 255, 0.08);
	border: 1.5px solid rgba(255, 213, 79, 0.6);
	border-radius: 10px;
	overflow: hidden;
	box-shadow: 0 2px 8px rgba(0, 0, 0, 0.5), inset 0 1px 3px rgba(0, 0, 0, 0.6);
	position: relative;
}
.progress-bar-fill {
	height: 100%;
	width: 0%;
	background: linear-gradient(90deg, #ff5722 0%, #ffd54f 50%, #40c4ff 100%);
	border-radius: 8px;
	box-shadow: 0 0 14px rgba(255, 213, 79, 0.85);
	transition: width 0.1s ease-out;
}
.loading-status-text {
	margin-top: 10px;
	font-size: clamp(12px, 3vw, 14px);
	font-weight: 700;
	color: #ffe082;
	letter-spacing: 0.5px;
}
.loading-tip {
	margin-top: 14px;
	font-size: 11px;
	color: #78909c;
	font-style: italic;
	line-height: 1.3;
	max-width: 420px;
	background: rgba(255, 255, 255, 0.04);
	padding: 6px 14px;
	border-radius: 8px;
	border: 1px solid rgba(255, 255, 255, 0.06);
}
.loading-portrait-hint {
	display: none;
	margin-top: 12px;
	font-size: 12px;
	color: #81d4fa;
	background: rgba(3, 169, 244, 0.12);
	border: 1px solid rgba(129, 212, 250, 0.35);
	padding: 6px 14px;
	border-radius: 8px;
	animation: pulse-hint 2s infinite ease-in-out;
}
@media (orientation: portrait) {
	.loading-portrait-hint {
		display: block;
	}
}
@keyframes pulse-hint {
	0%, 100% { opacity: 0.7; transform: scale(1); }
	50% { opacity: 1; transform: scale(1.02); }
}

/* Mobile Landscape & Compact Viewport Optimization */
@media (max-height: 480px) {
	#status {
		padding: 6px;
	}
	#status-splash {
		max-height: 64px !important;
		margin-bottom: 6px !important;
	}
	.loading-title {
		font-size: 15px !important;
		margin-bottom: 2px !important;
	}
	.loading-sub {
		display: none !important;
	}
	.progress-bar-shell {
		height: 10px !important;
	}
	.loading-status-text {
		margin-top: 6px !important;
		font-size: 11px !important;
	}
	.loading-tip {
		display: none !important;
	}
	.loading-portrait-hint {
		display: none !important;
	}
}
</style>

<script>
// Direct fast callback invoked by Godot's onProgress
window.updateCustomProgress = function(current, total) {
	var fill = document.getElementById('custom-progress-fill');
	var txt = document.getElementById('custom-status-text');
	if (total > 0) {
		var pct = Math.min(100, Math.floor((current / total) * 100));
		var curMB = (current / (1024 * 1024)).toFixed(1);
		var totMB = (total / (1024 * 1024)).toFixed(1);
		if (fill) fill.style.width = pct + '%';
		if (txt) txt.innerText = 'Загрузка: ' + pct + '% (' + curMB + ' / ' + totMB + ' МБ)';
	}
};

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
		<div class="loading-status-text" id="custom-status-text">Инициализация игрового мира...</div>
		<div class="loading-portrait-hint">📱 Поверните смартфон горизонтально для лучшего обзора</div>
		<div class="loading-tip" id="custom-tip">💡 Совет: Переключайтесь между Ху Тао [1] и Эллен [2] прямо во время боя!</div>
	`;
	status.appendChild(card);

	var tips = [
		"💡 Совет: Переключайтесь между Ху Тао [1] и Эллен [2] прямо во время боя!",
		"💡 Совет: Зажмите кнопку атаки для мощного заряженного вихревого удара!",
		"💡 Совет: Подойдите к Эллен Джо и нажмите кнопку действия, чтобы пригласить в отряд!",
		"💡 Совет: Вся Японская школа и крупные постройки разрушаются по частям и ярусам!",
		"💡 Совет: Кнопка зелья мгновенно восстанавливает здоровье."
	];
	var tipIdx = 0;
	setInterval(function() {
		tipIdx = (tipIdx + 1) % tips.length;
		var tipElem = document.getElementById('custom-tip');
		if (tipElem) tipElem.innerText = tips[tipIdx];
	}, 4000);
});
</script>
"""

    # If enhancements already present, replace them; otherwise insert before </body>
    if "<!-- ==================== SDVGACHA WEB ENHANCEMENTS" in html:
        import re
        html = re.sub(r'<!-- ==================== SDVGACHA WEB ENHANCEMENTS.*?</body>', enhancement + '\n</body>', html, flags=re.DOTALL)
    elif "</body>" in html:
        html = html.replace("</body>", enhancement + "\n</body>")

    index_path.write_text(html, encoding="utf-8")
    print(f"Successfully injected responsive mobile & PC web optimizations into {index_path}")

if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/web/index.html")
    inject(target)
