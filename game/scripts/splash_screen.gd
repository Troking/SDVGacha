extends CanvasLayer

signal started()

var is_starting: bool = false
var prompt_tween: Tween = null
var bg_tween: Tween = null
var active_modal: Control = null

@onready var root_control: Control = $RootControl
@onready var bg_texture: TextureRect = $RootControl/Background

var embers_left: CPUParticles2D = null
var snow_right: CPUParticles2D = null
var start_button: Button = null
var start_prompt_label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	root_control.modulate.a = 0.0

	# Ensure mouse is visible and interactive on title screen
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	_clear_scene_placeholders()
	_setup_background_and_particles()
	_setup_top_header()
	_setup_center_bottom_cta()

	# Smooth cinematic fade-in
	var in_tween = create_tween()
	in_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	in_tween.tween_property(root_control, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_start_bg_breathing()
	_start_cta_pulse()

	AccessibilityManager.speak("SDV Gacha. Добро пожаловать. Нажмите Войти в мир для начала игры.", true, false)

func _clear_scene_placeholders() -> void:
	# Clean up any static scene nodes so everything is built cleanly
	var old_center = root_control.get_node_or_null("CenterContainer")
	if old_center:
		old_center.queue_free()
	var old_embers = root_control.get_node_or_null("Embers")
	if old_embers:
		old_embers.queue_free()

func _setup_background_and_particles() -> void:
	if not bg_texture:
		bg_texture = TextureRect.new()
		bg_texture.name = "Background"
		bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		root_control.add_child(bg_texture)

	var cover_tex = load("res://assets/textures/game_cover.png")
	if cover_tex:
		bg_texture.texture = cover_tex
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# Soft dark vignette overlay
	var vignette = TextureRect.new()
	vignette.name = "VignetteOverlay"
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vig_tex = load("res://assets/textures/menu_vignette.png")
	if vig_tex:
		vignette.texture = vig_tex
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vignette.modulate = Color(0.08, 0.04, 0.04, 0.45)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(vignette)

	# 1. Left Side: Hu Tao's Fiery Embers
	embers_left = CPUParticles2D.new()
	embers_left.name = "EmbersLeft"
	embers_left.position = Vector2(380, 1080)
	embers_left.amount = 32
	embers_left.lifetime = 4.2
	embers_left.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers_left.emission_rect_extents = Vector2(360, 20)
	embers_left.direction = Vector2(0.2, -1.0)
	embers_left.spread = 25.0
	embers_left.gravity = Vector2(0, -20)
	embers_left.initial_velocity_min = 45.0
	embers_left.initial_velocity_max = 110.0
	embers_left.scale_amount_min = 2.5
	embers_left.scale_amount_max = 5.5
	var grad_fire = Gradient.new()
	grad_fire.colors = PackedColorArray([
		Color(1.0, 0.95, 0.4, 0.0),
		Color(1.0, 0.65, 0.15, 0.9),
		Color(1.0, 0.25, 0.05, 0.65),
		Color(0.2, 0.02, 0.02, 0.0)
	])
	embers_left.color_ramp = grad_fire
	root_control.add_child(embers_left)

	# 2. Right Side: Ellen Joe's Cryo Snowflakes
	snow_right = CPUParticles2D.new()
	snow_right.name = "SnowflakesRight"
	snow_right.position = Vector2(1540, 1080)
	snow_right.amount = 32
	snow_right.lifetime = 4.5
	snow_right.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow_right.emission_rect_extents = Vector2(360, 20)
	snow_right.direction = Vector2(-0.2, -1.0)
	snow_right.spread = 25.0
	snow_right.gravity = Vector2(0, -18)
	snow_right.initial_velocity_min = 40.0
	snow_right.initial_velocity_max = 100.0
	snow_right.scale_amount_min = 2.5
	snow_right.scale_amount_max = 5.0
	var grad_ice = Gradient.new()
	grad_ice.colors = PackedColorArray([
		Color(0.8, 0.95, 1.0, 0.0),
		Color(0.4, 0.9, 1.0, 0.95),
		Color(0.1, 0.5, 0.95, 0.6),
		Color(0.02, 0.1, 0.3, 0.0)
	])
	snow_right.color_ramp = grad_ice
	root_control.add_child(snow_right)

func _setup_top_header() -> void:
	var top_bar = MarginContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.add_theme_constant_override("margin_left", 28)
	top_bar.add_theme_constant_override("margin_right", 28)
	top_bar.add_theme_constant_override("margin_top", 22)
	root_control.add_child(top_bar)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_child(hbox)

	# Left Header: Game Logo & Badges
	var brand_box = VBoxContainer.new()
	brand_box.add_theme_constant_override("separation", 4)
	hbox.add_child(brand_box)

	var title_lbl = Label.new()
	title_lbl.text = "✦  SDV GACHA  ✦"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.2, 0.05, 0.02, 0.9))
	title_lbl.add_theme_constant_override("shadow_offset_x", 2)
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	brand_box.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "ANIME ACTION RPG • HU TAO & ELLEN JOE"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.50, 0.9))
	brand_box.add_child(sub_lbl)

	# Status Pills
	var pills_row = HBoxContainer.new()
	pills_row.add_theme_constant_override("separation", 8)
	brand_box.add_child(pills_row)

	_add_status_pill(pills_row, "🟢 Селестия • Онлайн", Color(0.2, 0.85, 0.4))
	_add_status_pill(pills_row, "v1.3.0 WebGL", Color(0.4, 0.8, 1.0))
	_add_status_pill(pills_row, "🔊 Сэйю (JA/RU)", Color(1.0, 0.75, 0.3))

	# Middle Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Right Utility Buttons Bar
	var nav_bar = HBoxContainer.new()
	nav_bar.add_theme_constant_override("separation", 10)
	hbox.add_child(nav_bar)

	_create_nav_button(nav_bar, "⌨️ Управление", _open_controls_modal)
	_create_nav_button(nav_bar, "👥 Героини", _open_squad_modal)
	_create_nav_button(nav_bar, "⚙️ Настройки", _open_settings_modal)
	_create_nav_button(nav_bar, "⛶ Экран", _toggle_fullscreen)

func _add_status_pill(parent: HBoxContainer, text: String, accent: Color) -> void:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.75)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)

	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", accent)
	p.add_child(l)
	parent.add_child(p)

func _create_nav_button(parent: HBoxContainer, label: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE

	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.10, 0.15, 0.82)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = Color(0.4, 0.45, 0.55, 0.6)
	sb_normal.corner_radius_top_left = 8
	sb_normal.corner_radius_top_right = 8
	sb_normal.corner_radius_bottom_left = 8
	sb_normal.corner_radius_bottom_right = 8
	sb_normal.content_margin_left = 14
	sb_normal.content_margin_right = 14
	sb_normal.content_margin_top = 8
	sb_normal.content_margin_bottom = 8

	var sb_hover = sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.18, 0.18, 0.28, 0.95)
	sb_hover.border_color = Color(1.0, 0.85, 0.4, 0.9)
	sb_hover.shadow_color = Color(1.0, 0.7, 0.2, 0.3)
	sb_hover.shadow_size = 4

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.65))
	btn.add_theme_font_size_override("font_size", 13)

	btn.mouse_entered.connect(func(): SoundSynth.play_ui_hover(self))
	btn.pressed.connect(func():
		SoundSynth.play_ui_click(self)
		callback.call()
	)
	parent.add_child(btn)
	return btn

func _setup_center_bottom_cta() -> void:
	var bottom_container = VBoxContainer.new()
	bottom_container.name = "BottomCTA"
	bottom_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_container.offset_top = -180.0
	bottom_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_container.add_theme_constant_override("separation", 12)
	root_control.add_child(bottom_container)

	# Center HBox to align button in middle
	var c_hbox = HBoxContainer.new()
	c_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_container.add_child(c_hbox)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "✦   ВОЙТИ В МИР   ✦"
	start_button.custom_minimum_size = Vector2(340, 58)
	start_button.focus_mode = Control.FOCUS_NONE

	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.12, 0.08, 0.06, 0.88)
	sb_btn.border_width_left = 2
	sb_btn.border_width_top = 2
	sb_btn.border_width_right = 2
	sb_btn.border_width_bottom = 2
	sb_btn.border_color = Color(1.0, 0.82, 0.35, 1.0)
	sb_btn.corner_radius_top_left = 12
	sb_btn.corner_radius_top_right = 12
	sb_btn.corner_radius_bottom_left = 12
	sb_btn.corner_radius_bottom_right = 12
	sb_btn.shadow_color = Color(1.0, 0.55, 0.1, 0.45)
	sb_btn.shadow_size = 8

	var sb_btn_hover = sb_btn.duplicate() as StyleBoxFlat
	sb_btn_hover.bg_color = Color(0.25, 0.14, 0.08, 0.95)
	sb_btn_hover.border_color = Color(1.0, 0.95, 0.65, 1.0)
	sb_btn_hover.shadow_size = 14
	sb_btn_hover.shadow_color = Color(1.0, 0.65, 0.15, 0.65)

	start_button.add_theme_stylebox_override("normal", sb_btn)
	start_button.add_theme_stylebox_override("hover", sb_btn_hover)
	start_button.add_theme_stylebox_override("pressed", sb_btn_hover)
	start_button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	start_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	start_button.add_theme_font_size_override("font_size", 20)

	start_button.mouse_entered.connect(func():
		SoundSynth.play_ui_hover(self)
		var t = start_button.create_tween()
		t.tween_property(start_button, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	start_button.mouse_exited.connect(func():
		var t = start_button.create_tween()
		t.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	start_button.pressed.connect(start_game)
	start_button.pivot_offset = Vector2(170, 29)
	c_hbox.add_child(start_button)

	# Keyboard/Touch Prompt Subtitle
	start_prompt_label = Label.new()
	start_prompt_label.name = "PromptLabel"
	start_prompt_label.text = "[ КЛИКНИТЕ ИЛИ НАЖМИТЕ ENTER / ПРОБЕЛ ]"
	start_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_prompt_label.add_theme_font_size_override("font_size", 13)
	start_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 0.85))
	start_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	start_prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	start_prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	bottom_container.add_child(start_prompt_label)

func _start_bg_breathing() -> void:
	if not bg_texture:
		return
	bg_texture.pivot_offset = Vector2(960, 540)
	bg_tween = create_tween().set_loops()
	bg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bg_tween.tween_property(bg_texture, "scale", Vector2(1.03, 1.03), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bg_tween.tween_property(bg_texture, "scale", Vector2(1.0, 1.0), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_cta_pulse() -> void:
	if not start_prompt_label:
		return
	prompt_tween = create_tween().set_loops()
	prompt_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	prompt_tween.tween_property(start_prompt_label, "modulate:a", 0.45, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	prompt_tween.tween_property(start_prompt_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if is_starting:
		return

	# If a modal is open, Escape closes it
	if active_modal and event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		_close_active_modal()
		return

	# If modal is open, don't start the game with clicks/keys
	if active_modal:
		return

	var is_trigger = false
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			is_trigger = true
	elif event is InputEventJoypadButton and event.is_pressed():
		is_trigger = true
	elif event is InputEventScreenTouch and event.is_pressed():
		is_trigger = true

	if is_trigger:
		start_game()

func start_game() -> void:
	if is_starting or active_modal:
		return
	is_starting = true

	if prompt_tween: prompt_tween.kill()
	if bg_tween: bg_tween.kill()

	# Audio feedback
	SoundSynth.play_level_up_fanfare(self)
	SoundSynth.play_voice_menu_close(self)

	# Button flash punch
	if start_button:
		var flash_tween = create_tween()
		flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		flash_tween.tween_property(start_button, "scale", Vector2(1.12, 1.12), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		flash_tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.16)
		start_button.release_focus()

	# Release any UI focus immediately so Godot Viewport retains direct canvas key events
	get_viewport().gui_release_focus()
	if root_control:
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Unpause the game world & signal main scene
	get_tree().paused = false
	started.emit()

	# Smooth cinematic fade out
	var out_tween = create_tween()
	out_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out_tween.tween_property(root_control, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_callback(queue_free)

# ==================== MODALS (PRACTICAL UTILITY) ====================

func _open_controls_modal() -> void:
	_close_active_modal()
	SoundSynth.play_voice_menu_open(self)

	var modal = _create_modal_frame("⌨️ РУКОВОДСТВО ПО УПРАВЛЕНИЮ", Vector2(720, 500))
	var content_vbox = modal.get_node("Margin/VBox/Content") as VBoxContainer

	var columns_hbox = HBoxContainer.new()
	columns_hbox.add_theme_constant_override("separation", 24)
	content_vbox.add_child(columns_hbox)

	# PC Column
	var pc_col = VBoxContainer.new()
	pc_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(pc_col)

	var pc_title = Label.new()
	pc_title.text = "🎮 ПК (Клавиатура и мышь)"
	pc_title.add_theme_font_size_override("font_size", 15)
	pc_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	pc_col.add_child(pc_title)

	var pc_keys = [
		{"k": "W, A, S, D", "d": "Движение и авто-спринт"},
		{"k": "ЛКМ (Клик)", "d": "Серия из 4 ударов комбо"},
		{"k": "ЛКМ (Удержание)", "d": "Заряженный вихревой удар"},
		{"k": "E", "d": "Элементальный навык (Вихрь)"},
		{"k": "Shift", "d": "Быстрый рывок уклонения"},
		{"k": "Пробел", "d": "Прыжок / Карабкание по скалам"},
		{"k": "1 / 2", "d": "Смена: Ху Тао 🔥 / Эллен ❄️"},
		{"k": "F", "d": "Действие (сундуки, NPC Эллен)"},
		{"k": "C", "d": "Окно персонажа и инвентарь"},
		{"k": "Tab", "d": "Автоприцел на монстров"}
	]
	for item in pc_keys:
		_add_key_row(pc_col, item["k"], item["d"])

	# Mobile Column
	var mob_col = VBoxContainer.new()
	mob_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns_hbox.add_child(mob_col)

	var mob_title = Label.new()
	mob_title.text = "📱 Сенсорный экран (Тач)"
	mob_title.add_theme_font_size_override("font_size", 15)
	mob_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	mob_col.add_child(mob_title)

	var mob_keys = [
		{"k": "Виртуальный стик", "d": "Свободное перемещение"},
		{"k": "Кнопка ⚔️", "d": "Атака и комбо-серии"},
		{"k": "Кнопка 🔥/❄️", "d": "Навык с индикатором отката"},
		{"k": "Кнопка 🦘", "d": "Прыжок и прыжки в воде"},
		{"k": "Кнопка 💨", "d": "Уклонение и рывок"},
		{"k": "Кнопка 💬 [F]", "d": "Взаимодействие с миром"},
		{"k": "Слоты 1 / 2 (вверху)", "d": "Мгновенная смена отряда"}
	]
	for item in mob_keys:
		_add_key_row(mob_col, item["k"], item["d"])

func _open_settings_modal() -> void:
	_close_active_modal()
	SoundSynth.play_voice_menu_open(self)

	var modal = _create_modal_frame("⚙️ НАСТРОЙКИ И ДОСТУПНОСТЬ", Vector2(560, 420))
	var content_vbox = modal.get_node("Margin/VBox/Content") as VBoxContainer

	# High Contrast Toggle
	_add_setting_toggle(content_vbox, "👁 Режим высокой контрастности:", "ВКЛ" if AccessibilityManager.high_contrast else "ВЫКЛ", func(btn: Button):
		AccessibilityManager.toggle_high_contrast()
		btn.text = "ВКЛ" if AccessibilityManager.high_contrast else "ВЫКЛ"
	)

	# Screen Reader TTS Toggle
	_add_setting_toggle(content_vbox, "📢 Диктор озвучки (TTS):", "ВКЛ" if AccessibilityManager.tts_enabled else "ВЫКЛ", func(btn: Button):
		AccessibilityManager.toggle_tts()
		btn.text = "ВКЛ" if AccessibilityManager.tts_enabled else "ВЫКЛ"
	)

	# Fullscreen Toggle
	_add_setting_toggle(content_vbox, "⛶ Полноэкранный режим:", "ПЕРЕКЛЮЧИТЬ", func(_btn: Button):
		_toggle_fullscreen()
	)

	# Language hint
	var lang_hint = Label.new()
	lang_hint.text = "Язык озвучки героинь: Японский сэйю (JP Seiyuu) • Текст: Русский"
	lang_hint.add_theme_font_size_override("font_size", 12)
	lang_hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	content_vbox.add_child(lang_hint)

func _open_squad_modal() -> void:
	_close_active_modal()
	SoundSynth.play_voice_menu_open(self)

	var modal = _create_modal_frame("👥 ГЕРОИНИ ОТРЯДА", Vector2(740, 480))
	var content_vbox = modal.get_node("Margin/VBox/Content") as VBoxContainer

	var cards_hbox = HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 20)
	content_vbox.add_child(cards_hbox)

	# Card 1: Hu Tao
	_create_character_card(cards_hbox, "🔥 Ху Тао", "5★ Пиро • Главный урон", "res://assets/textures/player_portrait.png", Color(1.0, 0.55, 0.15), [
		"Оружие: Одноручный церемониальный меч",
		"Стихия: Пиро (Огонь)",
		"Навык: «Огненный Вихрь» — притягивает врагов в огненный смерч с периодическим уроном.",
		"Сейю: Чистая аутентичная озвучка с эмоциональными репликами при ударах и прыжках."
	])

	# Card 2: Ellen Joe
	_create_character_card(cards_hbox, "❄️ Эллен Джо", "5★ Крио • Скоростной штурмовик", "res://assets/textures/ellen_joe_portrait.png", Color(0.35, 0.88, 1.0), [
		"Оружие: Гигантские акульи механические ножницы",
		"Стихия: Крио (Лед)",
		"Навык: «Морозный Шквал» — круговой рывок с призывом метели и ледяной заморозкой.",
		"Хвост: Живой физический акулий хвост с гидродинамической волной при движении."
	])

func _create_character_card(parent: HBoxContainer, name_text: String, role_text: String, portrait_path: String, col: Color, features: Array) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.90)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(col.r, col.g, col.b, 0.75)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	# Portrait + Title Header
	var th_box = HBoxContainer.new()
	th_box.add_theme_constant_override("separation", 12)
	vb.add_child(th_box)

	var port = TextureRect.new()
	port.custom_minimum_size = Vector2(56, 56)
	var tex = load(portrait_path)
	if tex: port.texture = tex
	port.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	port.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	th_box.add_child(port)

	var text_vb = VBoxContainer.new()
	th_box.add_child(text_vb)

	var nl = Label.new()
	nl.text = name_text
	nl.add_theme_font_size_override("font_size", 16)
	nl.add_theme_color_override("font_color", col)
	text_vb.add_child(nl)

	var rl = Label.new()
	rl.text = role_text
	rl.add_theme_font_size_override("font_size", 11)
	rl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	text_vb.add_child(rl)

	var sep = HSeparator.new()
	vb.add_child(sep)

	for feat in features:
		var fl = Label.new()
		fl.text = "• " + feat
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl.add_theme_font_size_override("font_size", 11)
		fl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95, 0.9))
		vb.add_child(fl)

	parent.add_child(panel)

func _create_modal_frame(title: String, frame_size: Vector2) -> Control:
	var overlay = Control.new()
	overlay.name = "ModalOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(overlay)
	active_modal = overlay

	# Dim background
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	overlay.add_child(dim)
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.is_pressed():
			_close_active_modal()
	)

	# Dialog Card
	var card = PanelContainer.new()
	card.custom_minimum_size = frame_size
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -frame_size.x * 0.5
	card.offset_top = -frame_size.y * 0.5
	card.offset_right = frame_size.x * 0.5
	card.offset_bottom = frame_size.y * 0.5

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.82, 0.35, 1.0)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 18
	card.add_theme_stylebox_override("panel", sb)
	overlay.add_child(card)

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Header HBox
	var h_hbox = HBoxContainer.new()
	vbox.add_child(h_hbox)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	h_hbox.add_child(title_lbl)

	var h_sp = Control.new()
	h_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_hbox.add_child(h_sp)

	var close_btn = Button.new()
	close_btn.text = "✖"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_close_active_modal)
	h_hbox.add_child(close_btn)

	var content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	# Bottom close button
	var bot_btn = Button.new()
	bot_btn.text = "Закрыть [Esc]"
	bot_btn.focus_mode = Control.FOCUS_NONE
	bot_btn.custom_minimum_size = Vector2(160, 36)
	bot_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bot_btn.pressed.connect(_close_active_modal)
	vbox.add_child(bot_btn)

	# Pop-in animation
	card.scale = Vector2(0.92, 0.92)
	card.pivot_offset = frame_size * 0.5
	var tw = card.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return card

func _close_active_modal() -> void:
	if active_modal:
		SoundSynth.play_voice_menu_close(self)
		active_modal.queue_free()
		active_modal = null

func _add_key_row(parent: VBoxContainer, key: String, desc: String) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)

	var k_lbl = Label.new()
	k_lbl.text = key
	k_lbl.custom_minimum_size = Vector2(120, 0)
	k_lbl.add_theme_font_size_override("font_size", 12)
	k_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	row.add_child(k_lbl)

	var d_lbl = Label.new()
	d_lbl.text = "— " + desc
	d_lbl.add_theme_font_size_override("font_size", 12)
	d_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.9))
	row.add_child(d_lbl)

func _add_setting_toggle(parent: VBoxContainer, title: String, btn_text: String, callback: Callable) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)

	var l = Label.new()
	l.text = title
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	row.add_child(l)

	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(120, 32)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		SoundSynth.play_ui_click(self)
		callback.call(btn)
	)
	row.add_child(btn)

func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
