extends CanvasLayer

@onready var player_hud: Control = $PlayerHUD
@onready var hints_panel: Control = $HintsPanel
@onready var character_sheet: Control = $CharacterSheet
@onready var close_btn: Button = $CharacterSheet/TopBar/CloseBtn
@onready var sheet_element_badge: Label = $CharacterSheet/TopBar/ElementTitleHBox/ElementBadge
@onready var sheet_role_badge: Label = $CharacterSheet/TopBar/ElementTitleHBox/RoleBadge
@onready var sheet_title_label: Label = $CharacterSheet/TopBar/ElementTitleHBox/Title

# HUD elements
@onready var hp_bar: ProgressBar = $PlayerHUD/BottomCenterHUD/BarsVBox/HPContainer/HPBar
@onready var hp_text: Label = $PlayerHUD/BottomCenterHUD/BarsVBox/HPContainer/HPText
@onready var exp_bar: ProgressBar = $PlayerHUD/BottomCenterHUD/BarsVBox/ExpContainer/ExpBar
@onready var exp_text: Label = $PlayerHUD/BottomCenterHUD/BarsVBox/ExpText
@onready var level_label: Label = $PlayerHUD/BottomCenterHUD/LevelLabel
@onready var attack_label: Label = $PlayerHUD/TopLeftProfile/Margin/HBox/VBox/AttackLabel
@onready var skill_badge_label: Label = $PlayerHUD/BottomRightSkills/SkillPanel/Margin/VBox/SkillBadgeLabel
@onready var hints_label: Label = $HintsPanel/Margin/HintsLabel

# Level up and Exp Popup elements
@onready var level_up_banner: Control = $LevelUpBanner
@onready var lvl_info_label: Label = $LevelUpBanner/Margin/VBox/LvlInfo
@onready var stats_boost_label: Label = $LevelUpBanner/Margin/VBox/StatsBoost
@onready var exp_popup_label: Label = $ExpPopupLabel
@onready var damage_flash: ColorRect = $DamageFlash

# Character Sheet elements
@onready var hero_name_label: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/HeroName
@onready var stars_label: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/StarsLabel
@onready var level_display_label: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/LevelHBox/LevelDisplay
@onready var stats_list_label: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/StatsList
@onready var equip_title: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/EquipTitle
@onready var equip_vbox: VBoxContainer = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/EquipVBox
@onready var weapon_slot: InventorySlot = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/EquipVBox/WeaponSlotContainer/WeaponSlot
@onready var shield_slot: InventorySlot = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/EquipVBox/ShieldSlotContainer/ShieldSlot
@onready var boots_slot: InventorySlot = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/EquipVBox/BootsSlotContainer/BootsSlot
@onready var inv_title: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/InvTitle
@onready var inv_grid: GridContainer = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/InvGrid
@onready var lore_box: Control = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/LoreBox
@onready var lore_label: Label = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox/LoreBox/LoreMargin/LoreLabel

@onready var tab_stats_panel: PanelContainer = $CharacterSheet/LeftNavColumn/TabCharacteristicsPanel
@onready var tab_equip_panel: PanelContainer = $CharacterSheet/LeftNavColumn/TabEquipmentPanel
@onready var tab_inv_panel: PanelContainer = $CharacterSheet/LeftNavColumn/TabInventoryPanel
@onready var tab_about_panel: PanelContainer = $CharacterSheet/LeftNavColumn/TabAboutPanel

@onready var backdrop_overlay: Control = $BackdropOverlay
@onready var preview_container: Control = $CharacterSheet/CenterShowcase/PreviewContainer
@onready var preview_3d = $CharacterSheet/CenterShowcase/PreviewContainer/SubViewport/CharacterPreview3D
@onready var magic_circle: TextureRect = $CharacterSheet/CenterShowcase/MagicCircle

var slot_scene: PackedScene = preload("res://scenes/inventory_slot.tscn")

var touch_controls: Control = null
var touch_toggle_btn: Button = null

var current_hp_val: int = 100
var max_hp_val: int = 100
var exp_val_val: int = 0
var exp_to_next_val: int = 50
var level_val: int = 1
var attack_val_val: int = 15

var is_animating_sheet: bool = false
var sheet_tween: Tween = null
var is_dragging_preview: bool = false
var exp_popup_tween: Tween = null
var banner_tween: Tween = null
var flash_tween: Tween = null

# Dynamic UI additions
var toast_container: VBoxContainer = null
var potion_btn_label: Label = null
var active_nav_tab: String = "stats" # "stats", "equip", "inventory", "about"
var inventory_filter: String = "all" # "all", "weapon", "shield", "boots", "potion"

var filter_btn_container: HBoxContainer = null
var item_inspector_card: PanelContainer = null
var inspector_name_label: Label = null
var inspector_stars_label: Label = null
var inspector_type_label: Label = null
var inspector_stat_label: Label = null
var inspector_diff_label: Label = null
var inspector_lore_label: Label = null
var inspector_action_btn: Button = null

var selected_slot_ref: InventorySlot = null
var selected_item_ref: Dictionary = {}
var nav_tabs_info: Array[Dictionary] = []
var voice_mode_btn: Button = null

# Party / Squad System UI
var party_hud_container: VBoxContainer = null
var party_slot_panels: Array[PanelContainer] = []
var active_squad_slot: int = 0

# Visual Novel Dialogue UI
var vn_root: Control = null
var vn_portrait: TextureRect = null
var vn_name_label: Label = null
var vn_title_label: Label = null
var vn_text_label: Label = null
var vn_choices_vbox: VBoxContainer = null
var vn_continue_label: Label = null
var vn_full_text: String = ""
var vn_current_char_idx: int = 0
var vn_typewriter_timer: float = 0.0
var vn_is_typing: bool = false
var vn_on_finish_callback: Callable
var vn_current_dialogue_data: Dictionary = {}
var vn_current_line_idx: int = 0
var vn_is_active: bool = false

# Recruit Celebration Banner
var recruit_banner: PanelContainer = null
var recruit_name_label: Label = null
var recruit_role_label: Label = null
var recruit_portrait: TextureRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AccessibilityManager.ui_visibility_toggled.connect(_on_ui_toggle)
	AccessibilityManager.high_contrast_toggled.connect(_on_contrast_toggle)
	
	if close_btn:
		close_btn.pivot_offset = Vector2(48, 21)
		close_btn.mouse_entered.connect(func():
			var tw = create_tween()
			tw.tween_property(close_btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			SoundSynth.play_ui_hover(self)
		)
		close_btn.mouse_exited.connect(func():
			var tw = create_tween()
			tw.tween_property(close_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		close_btn.pressed.connect(func():
			SoundSynth.play_ui_click(self)
			toggle_character_sheet()
		)

	if preview_container:
		preview_container.gui_input.connect(_on_preview_gui_input)

	hints_label.text = "Управление (ПК):\nWASD — Бег по направлению камеры  |  Мышь — Обзор (колёсико: Zoom)\n1–9 — Переключение отряда (1: Ху Тао  |  2: Эллен Джо)\nЛКМ — Серия из 4 ударов (зажатие 0.4с: Выпад с бабочками)\nПКМ — Рывок  |  E — Стихийный навык  |  C — Меню персонажа\nF — Взаимодействие (NPC Эллен Джо, Диалоги, Сундуки)\nU / F8 — Анти-застревание (Телепорт на твердую землю)\nQ / Z — Быстрое зелье исцеления  |  Пробел — Прыжок / Планер"

	_setup_hud_extensions()
	_setup_party_hud()
	_setup_visual_novel_ui()
	_setup_recruit_banner()
	_setup_nav_tabs()
	_setup_inventory_filter_bar()
	_setup_voice_mode_button()
	_setup_item_inspector_card()
	_expand_inventory_grid_slots()
	_setup_touch_controls()

	# Connect InventoryManager signals
	InventoryManager.inventory_updated.connect(_on_inventory_updated)
	InventoryManager.toast_notification.connect(_show_loot_toast)
	InventoryManager.equipment_changed.connect(_on_inventory_equipment_changed)

	# Initial refresh
	_refresh_inventory_grid()
	_switch_tab("stats")

func _process(delta: float) -> void:
	if character_sheet and character_sheet.visible and magic_circle:
		magic_circle.rotation += delta * 0.16
	if vn_is_typing:
		_update_typewriter(delta)
	if touch_controls and not touch_controls.player_ref:
		touch_controls.player_ref = get_tree().get_first_node_in_group("player")

# ==================== TOUCH CONTROLS FOR MOBILE ====================

func _setup_touch_controls() -> void:
	var touch_scene = preload("res://scenes/touch_controls.tscn")
	if touch_scene:
		touch_controls = touch_scene.instantiate()
		add_child(touch_controls)
		var p = get_tree().get_first_node_in_group("player")
		if p:
			touch_controls.player_ref = p

	_setup_touch_toggle_hud_button()

func _setup_touch_toggle_hud_button() -> void:
	if not player_hud:
		return
	touch_toggle_btn = Button.new()
	touch_toggle_btn.name = "TouchToggleBtn"
	touch_toggle_btn.text = "📱 Сенсор: ВКЛ"
	touch_toggle_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	touch_toggle_btn.offset_left = 280.0
	touch_toggle_btn.offset_top = 26.0
	touch_toggle_btn.offset_right = 430.0
	touch_toggle_btn.offset_bottom = 64.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18, 0.82)
	style.border_color = Color(0.9, 0.75, 0.35, 0.85)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	touch_toggle_btn.add_theme_stylebox_override("normal", style)
	touch_toggle_btn.add_theme_stylebox_override("hover", style)
	touch_toggle_btn.add_theme_stylebox_override("pressed", style)
	touch_toggle_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75, 1.0))
	touch_toggle_btn.add_theme_font_size_override("font_size", 14)

	touch_toggle_btn.pressed.connect(func():
		if touch_controls:
			touch_controls.is_touch_enabled = not touch_controls.is_touch_enabled
			touch_toggle_btn.text = "📱 Сенсор: " + ("ВКЛ" if touch_controls.is_touch_enabled else "ВЫКЛ")
			SoundSynth.play_ui_click(self)
	)
	player_hud.add_child(touch_toggle_btn)

# ==================== HUD EXTENSIONS ====================

func _setup_hud_extensions() -> void:
	# 1. Loot Toast Container on the right side of the screen
	toast_container = VBoxContainer.new()
	toast_container.name = "LootToastContainer"
	toast_container.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	toast_container.offset_left = -330.0
	toast_container.offset_right = -24.0
	toast_container.offset_top = 220.0
	toast_container.offset_bottom = -220.0
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_container.add_theme_constant_override("separation", 10)
	toast_container.alignment = BoxContainer.ALIGNMENT_CENTER
	player_hud.add_child(toast_container)

	# 2. Quick Potion HUD Pill in BottomRightSkills
	var skills_box = $PlayerHUD/BottomRightSkills as HBoxContainer
	if skills_box:
		var potion_pill = PanelContainer.new()
		potion_pill.name = "PotionPill"
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.07, 0.12, 0.78)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.9, 0.35, 0.45, 0.8)
		sb.corner_radius_top_left = 14
		sb.corner_radius_top_right = 14
		sb.corner_radius_bottom_right = 14
		sb.corner_radius_bottom_left = 14
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 6
		potion_pill.add_theme_stylebox_override("panel", sb)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 8)
		potion_pill.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(hbox)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.texture = InventoryManager.icons.get("potion_hp")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox)

		potion_btn_label = Label.new()
		potion_btn_label.text = "[Q] Зелье: x5"
		potion_btn_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55))
		potion_btn_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(potion_btn_label)

		var sub_hint = Label.new()
		sub_hint.text = "+45 HP"
		sub_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 0.8))
		sub_hint.add_theme_font_size_override("font_size", 11)
		vbox.add_child(sub_hint)

		potion_pill.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
				InventoryManager.use_quick_potion()
		)
		skills_box.add_child(potion_pill)
		skills_box.move_child(potion_pill, 0)

	_update_potion_pill()

func _update_potion_pill() -> void:
	if not potion_btn_label:
		return
	var count = InventoryManager.get_potion_count()
	potion_btn_label.text = "[Q] Зелье: x" + str(count)
	if count > 0:
		potion_btn_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55))
	else:
		potion_btn_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.55))

# ==================== LOOT TOAST FEED ====================

func _show_loot_toast(item_data: Dictionary) -> void:
	if not toast_container:
		return

	var toast = PanelContainer.new()
	var rarity = item_data.get("rarity", 0)
	var count = item_data.get("count", 1)
	var item_name = item_data.get("name", "Предмет")
	var tex = item_data.get("texture", null)

	var bg_colors = [
		Color(0.12, 0.14, 0.18, 0.90), # Common
		Color(0.10, 0.22, 0.28, 0.92), # Rare
		Color(0.24, 0.12, 0.32, 0.92), # Epic
		Color(0.35, 0.22, 0.08, 0.95)  # Legendary
	]
	var border_colors = [
		Color(0.45, 0.5, 0.6, 0.85),
		Color(0.3, 0.7, 0.9, 0.9),
		Color(0.75, 0.4, 0.95, 0.9),
		Color(1.0, 0.85, 0.3, 1.0)
	]
	var text_colors = [
		Color(0.9, 0.92, 0.96),
		Color(0.4, 0.85, 1.0),
		Color(0.85, 0.55, 1.0),
		Color(1.0, 0.9, 0.4)
	]
	var idx = clamp(rarity, 0, bg_colors.size() - 1)

	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_colors[idx]
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border_colors[idx]
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	toast.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 8)
	toast.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	if tex:
		var img = TextureRect.new()
		img.custom_minimum_size = Vector2(34, 34)
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(img)

	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = item_name
	name_lbl.add_theme_color_override("font_color", text_colors[idx])
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var sub_lbl = Label.new()
	var stars = ""
	for i in range(clamp(rarity + 2, 1, 5)): stars += "✦"
	sub_lbl.text = stars + "  +" + str(count)
	sub_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 0.85))
	sub_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(sub_lbl)

	toast.modulate.a = 0.0
	toast_container.add_child(toast)

	# Animation: slide in, hold, fade out
	var t = create_tween()
	t.tween_property(toast, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.4)
	t.tween_property(toast, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.finished.connect(func():
		if is_instance_valid(toast):
			toast.queue_free()
	)

# ==================== NAVIGATION TABS ====================

func _setup_nav_tabs() -> void:
	nav_tabs_info = [
		{
			"id": "stats",
			"panel": tab_stats_panel,
			"label": tab_stats_panel.get_node_or_null("Margin/TabCharacteristics") as Label,
			"title": "Характеристики"
		},
		{
			"id": "equip",
			"panel": tab_equip_panel,
			"label": tab_equip_panel.get_node_or_null("Margin/TabEquipment") as Label,
			"title": "Снаряжение"
		},
		{
			"id": "inventory",
			"panel": tab_inv_panel,
			"label": tab_inv_panel.get_node_or_null("Margin/TabInventory") as Label,
			"title": "Инвентарь"
		},
		{
			"id": "about",
			"panel": tab_about_panel,
			"label": tab_about_panel.get_node_or_null("Margin/TabAbout") as Label,
			"title": "О персонаже"
		}
	]

	for item in nav_tabs_info:
		var p: PanelContainer = item["panel"]
		if not p:
			continue
		var tab_id: String = item["id"]
		p.custom_minimum_size = Vector2(230, 52)
		p.pivot_offset = Vector2(115, 26)
		p.mouse_filter = Control.MOUSE_FILTER_STOP

		p.mouse_entered.connect(func():
			if active_nav_tab != tab_id:
				p.add_theme_stylebox_override("panel", _get_nav_style("hover"))
				var tw = create_tween()
				tw.tween_property(p, "scale", Vector2(1.03, 1.03), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				SoundSynth.play_ui_hover(self)
		)

		p.mouse_exited.connect(func():
			if active_nav_tab != tab_id:
				p.add_theme_stylebox_override("panel", _get_nav_style("normal"))
				var tw = create_tween()
				tw.tween_property(p, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)

		p.gui_input.connect(func(e):
			if _is_click(e):
				if active_nav_tab != tab_id:
					SoundSynth.play_ui_click(self)
					_switch_tab(tab_id)
		)

	_update_nav_tabs_visuals()

func _get_nav_style(state: String) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10

	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14

	match state:
		"active":
			sb.bg_color = Color(0.26, 0.16, 0.08, 0.98)
			sb.border_width_left = 5
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color(1.0, 0.88, 0.42, 1.0)
			sb.shadow_color = Color(1.0, 0.65, 0.15, 0.35)
			sb.shadow_size = 10
		"hover":
			sb.bg_color = Color(0.16, 0.14, 0.22, 0.95)
			sb.border_width_left = 3
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(1.0, 0.82, 0.45, 0.90)
			sb.shadow_color = Color(0, 0, 0, 0.45)
			sb.shadow_size = 6
		"normal", _:
			sb.bg_color = Color(0.08, 0.07, 0.13, 0.82)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.42, 0.40, 0.56, 0.55)
			sb.shadow_color = Color(0, 0, 0, 0.35)
			sb.shadow_size = 4
	return sb

func _update_nav_tabs_visuals() -> void:
	for item in nav_tabs_info:
		var p: PanelContainer = item["panel"]
		var lbl: Label = item["label"]
		var tab_id: String = item["id"]
		var title: String = item["title"]
		if not p:
			continue
		var is_active = (active_nav_tab == tab_id)
		p.scale = Vector2(1.0, 1.0)
		p.add_theme_stylebox_override("panel", _get_nav_style("active" if is_active else "normal"))
		if lbl:
			lbl.text = ("◆  " if is_active else "◇  ") + title
			lbl.add_theme_font_size_override("font_size", 17 if is_active else 16)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65) if is_active else Color(0.88, 0.90, 0.96, 0.85))

func _is_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT

func _switch_tab(tab_name: String) -> void:
	active_nav_tab = tab_name
	_update_nav_tabs_visuals()

	# Configure RightInfoPanel sections visibility based on active tab
	match tab_name:
		"stats":
			stats_list_label.visible = true
			equip_title.visible = false
			equip_vbox.visible = false
			inv_title.visible = false
			if filter_btn_container: filter_btn_container.visible = false
			inv_grid.visible = false
			if item_inspector_card: item_inspector_card.visible = false
			if voice_mode_btn: voice_mode_btn.visible = false
			lore_box.visible = false
			update_character_sheet_text()

		"equip":
			stats_list_label.visible = false
			equip_title.visible = true
			equip_vbox.visible = true
			inv_title.visible = false
			if filter_btn_container: filter_btn_container.visible = false
			inv_grid.visible = false
			if item_inspector_card: item_inspector_card.visible = true
			if voice_mode_btn: voice_mode_btn.visible = false
			lore_box.visible = false
			_select_slot(weapon_slot, InventoryManager.equipped.get("weapon", {}))

		"inventory":
			stats_list_label.visible = false
			equip_title.visible = false
			equip_vbox.visible = false
			inv_title.visible = true
			if filter_btn_container: filter_btn_container.visible = true
			inv_grid.visible = true
			if item_inspector_card: item_inspector_card.visible = true
			if voice_mode_btn: voice_mode_btn.visible = false
			lore_box.visible = false
			_refresh_inventory_grid()

		"about":
			stats_list_label.visible = false
			equip_title.visible = false
			equip_vbox.visible = false
			inv_title.visible = false
			if filter_btn_container: filter_btn_container.visible = false
			inv_grid.visible = false
			if item_inspector_card: item_inspector_card.visible = false
			lore_box.visible = true
			if voice_mode_btn:
				voice_mode_btn.visible = true
				_update_voice_button_text()
			lore_label.text = "«Ху Тао — 77-я управляющая ритуального бюро «Ваншэн». Повелительница пламени, оберегающая границу между мирами живых и духов.\n\nВ бою орудует стремительным одноручным мечом, совершая молниеносные выпады вперед, а её стихийный навык высвобождает огненный вихрь и мистических пламенных бабочек, рассекающих строй недругов.»"

# ==================== VOICE MODE SELECTOR ====================

func _setup_voice_mode_button() -> void:
	var right_vbox = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox as VBoxContainer
	if not right_vbox:
		return

	voice_mode_btn = Button.new()
	voice_mode_btn.name = "VoiceModeButton"
	voice_mode_btn.custom_minimum_size = Vector2(0, 44)
	voice_mode_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	voice_mode_btn.focus_mode = Control.FOCUS_ALL
	_update_voice_button_text()

	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.20, 0.12, 0.08, 0.95)
	sb_norm.border_width_left = 2
	sb_norm.border_width_top = 2
	sb_norm.border_width_right = 2
	sb_norm.border_width_bottom = 2
	sb_norm.border_color = Color(1.0, 0.78, 0.35, 1.0)
	sb_norm.corner_radius_top_left = 8
	sb_norm.corner_radius_top_right = 8
	sb_norm.corner_radius_bottom_right = 8
	sb_norm.corner_radius_bottom_left = 8
	sb_norm.shadow_color = Color(1.0, 0.6, 0.1, 0.3)
	sb_norm.shadow_size = 4

	var sb_hov = sb_norm.duplicate()
	sb_hov.bg_color = Color(0.30, 0.18, 0.10, 0.98)
	sb_hov.border_color = Color(1.0, 0.92, 0.55, 1.0)

	voice_mode_btn.add_theme_stylebox_override("normal", sb_norm)
	voice_mode_btn.add_theme_stylebox_override("hover", sb_hov)
	voice_mode_btn.add_theme_stylebox_override("pressed", sb_hov)
	voice_mode_btn.add_theme_stylebox_override("focus", sb_hov)
	voice_mode_btn.add_theme_font_size_override("font_size", 14)
	voice_mode_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))

	voice_mode_btn.mouse_entered.connect(func():
		SoundSynth.play_ui_hover(self)
	)
	voice_mode_btn.pressed.connect(func():
		SoundSynth.play_ui_click(self)
		var new_name = SoundSynth.cycle_voice_mode()
		_update_voice_button_text()
		SoundSynth.play_voice_finisher(self)
		AccessibilityManager.speak("Озвучка: " + new_name)
	)

	right_vbox.add_child(voice_mode_btn)
	voice_mode_btn.visible = false

func _update_voice_button_text() -> void:
	if voice_mode_btn:
		voice_mode_btn.text = "🎙 Режим голоса: " + SoundSynth.get_voice_mode_name() + "  [Клавиша V]"

# ==================== INVENTORY & INSPECTOR ====================

func _setup_inventory_filter_bar() -> void:
	var right_vbox = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox as VBoxContainer
	if not right_vbox:
		return

	filter_btn_container = HBoxContainer.new()
	filter_btn_container.name = "FilterBar"
	filter_btn_container.add_theme_constant_override("separation", 8)

	var filters = [
		{"id": "all", "label": "✦ Все"},
		{"id": "weapon", "label": "⚔ Оружие"},
		{"id": "shield", "label": "🛡 Броня"},
		{"id": "boots", "label": "👟 Обувь"},
		{"id": "potion", "label": "🧪 Зелья"}
	]

	for f in filters:
		var btn = Button.new()
		btn.text = f["label"]
		btn.custom_minimum_size = Vector2(88, 38)
		btn.pivot_offset = Vector2(44, 19)
		btn.add_theme_font_size_override("font_size", 14)
		var fid = f["id"]
		btn.set_meta("filter_id", fid)

		btn.mouse_entered.connect(func():
			if inventory_filter != fid:
				var tw = create_tween()
				tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			SoundSynth.play_ui_hover(self)
		)
		btn.mouse_exited.connect(func():
			var tw = create_tween()
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		btn.pressed.connect(func():
			SoundSynth.play_ui_click(self)
			inventory_filter = fid
			_update_filter_buttons_style()
			_refresh_inventory_grid()
		)
		filter_btn_container.add_child(btn)

	var grid_idx = inv_grid.get_index()
	right_vbox.add_child(filter_btn_container)
	right_vbox.move_child(filter_btn_container, grid_idx)

	_update_filter_buttons_style()

func _update_filter_buttons_style() -> void:
	if not filter_btn_container:
		return
	for btn in filter_btn_container.get_children():
		if btn is Button:
			var fid = btn.get_meta("filter_id", "")
			var is_active = (inventory_filter == fid)

			var sb_norm = StyleBoxFlat.new()
			sb_norm.bg_color = Color(0.28, 0.18, 0.08, 0.96) if is_active else Color(0.08, 0.09, 0.15, 0.88)
			sb_norm.border_width_left = 1
			sb_norm.border_width_top = 1
			sb_norm.border_width_right = 1
			sb_norm.border_width_bottom = 3 if is_active else 1
			sb_norm.border_color = Color(1.0, 0.86, 0.40, 1.0) if is_active else Color(0.35, 0.38, 0.52, 0.70)
			sb_norm.corner_radius_top_left = 8
			sb_norm.corner_radius_top_right = 8
			sb_norm.corner_radius_bottom_right = 8
			sb_norm.corner_radius_bottom_left = 8
			sb_norm.shadow_color = Color(1.0, 0.65, 0.1, 0.25) if is_active else Color(0, 0, 0, 0.3)
			sb_norm.shadow_size = 6 if is_active else 3

			var sb_hov = sb_norm.duplicate()
			sb_hov.bg_color = Color(0.34, 0.22, 0.10, 0.98) if is_active else Color(0.16, 0.15, 0.24, 0.95)
			sb_hov.border_color = Color(1.0, 0.92, 0.55, 1.0) if is_active else Color(0.9, 0.75, 0.40, 0.95)

			btn.add_theme_stylebox_override("normal", sb_norm)
			btn.add_theme_stylebox_override("hover", sb_hov)
			btn.add_theme_stylebox_override("pressed", sb_hov)
			btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.65) if is_active else Color(0.88, 0.90, 0.96))

func _setup_item_inspector_card() -> void:
	var right_vbox = $CharacterSheet/RightInfoPanel/Scroll/Margin/VBox as VBoxContainer
	if not right_vbox:
		return

	item_inspector_card = PanelContainer.new()
	item_inspector_card.name = "ItemInspectorCard"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.11, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.85, 0.72, 0.38, 0.90)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 10
	item_inspector_card.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	item_inspector_card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	inspector_name_label = Label.new()
	inspector_name_label.text = "Выберите предмет"
	inspector_name_label.add_theme_font_size_override("font_size", 19)
	inspector_name_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	vbox.add_child(inspector_name_label)

	var sub_hbox = HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(sub_hbox)

	inspector_stars_label = Label.new()
	inspector_stars_label.text = "✦✦✦✦"
	inspector_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	inspector_stars_label.add_theme_font_size_override("font_size", 16)
	sub_hbox.add_child(inspector_stars_label)

	inspector_type_label = Label.new()
	inspector_type_label.text = "[ Одноручный меч ]"
	inspector_type_label.add_theme_color_override("font_color", Color(0.70, 0.85, 1.0))
	inspector_type_label.add_theme_font_size_override("font_size", 14)
	sub_hbox.add_child(inspector_type_label)

	inspector_stat_label = Label.new()
	inspector_stat_label.text = "⚔ Сила атаки: +18"
	inspector_stat_label.add_theme_font_size_override("font_size", 16)
	inspector_stat_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
	vbox.add_child(inspector_stat_label)

	inspector_diff_label = Label.new()
	inspector_diff_label.text = "▲ +8 к Силе Атаки (Улучшение!)"
	inspector_diff_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.50))
	inspector_diff_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(inspector_diff_label)

	inspector_lore_label = Label.new()
	inspector_lore_label.text = "Описание предмета."
	inspector_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_lore_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.96, 0.90))
	inspector_lore_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(inspector_lore_label)

	inspector_action_btn = Button.new()
	inspector_action_btn.text = "Экипировать"
	inspector_action_btn.custom_minimum_size = Vector2(0, 46)
	inspector_action_btn.pivot_offset = Vector2(180, 23)
	inspector_action_btn.add_theme_font_size_override("font_size", 16)

	inspector_action_btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(inspector_action_btn, "scale", Vector2(1.025, 1.025), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		SoundSynth.play_ui_hover(self)
	)
	inspector_action_btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(inspector_action_btn, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	inspector_action_btn.pressed.connect(_on_inspector_action_pressed)
	vbox.add_child(inspector_action_btn)

	var hint_lbl = Label.new()
	hint_lbl.text = "Совет: ПКМ или Двойной клик по слоту для быстрого действия"
	hint_lbl.add_theme_color_override("font_color", Color(0.70, 0.72, 0.85, 0.75))
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_lbl)

	right_vbox.add_child(item_inspector_card)

func _expand_inventory_grid_slots() -> void:
	# Ensure grid has MAX_BAG_SLOTS (36) slots
	while inv_grid.get_child_count() < InventoryManager.MAX_BAG_SLOTS:
		var slot = slot_scene.instantiate() as InventorySlot
		inv_grid.add_child(slot)

	# Connect all slots
	var all_slots = [weapon_slot, shield_slot, boots_slot]
	all_slots.append_array(inv_grid.get_children())
	for s in all_slots:
		if s is InventorySlot:
			if not s.slot_selected.is_connected(_on_slot_selected):
				s.slot_selected.connect(_on_slot_selected)
			if not s.slot_activated.is_connected(_on_slot_activated):
				s.slot_activated.connect(_on_slot_activated)

func _refresh_inventory_grid() -> void:
	if not is_inside_tree():
		return

	# Update equipment slots
	weapon_slot.set_item(InventoryManager.equipped.get("weapon", {}), true)
	weapon_slot.slot_index = -1
	shield_slot.set_item(InventoryManager.equipped.get("shield", {}), true)
	shield_slot.slot_index = -1
	boots_slot.set_item(InventoryManager.equipped.get("boots", {}), true)
	boots_slot.slot_index = -1

	# Filter items in bag
	var filtered_items: Array[Dictionary] = []
	for i in range(InventoryManager.bag_items.size()):
		var it = InventoryManager.bag_items[i]
		var type = it.get("type", "")
		var matches = false
		if inventory_filter == "all":
			matches = true
		elif inventory_filter == "weapon" and type == "weapon":
			matches = true
		elif inventory_filter == "shield" and type == "shield":
			matches = true
		elif inventory_filter == "boots" and type == "boots":
			matches = true
		elif inventory_filter == "potion" and type in ["potion", "material"]:
			matches = true

		if matches:
			var entry = it.duplicate(true)
			entry["_bag_index"] = i
			filtered_items.append(entry)

	# Update grid slots
	var slots = inv_grid.get_children()
	for i in range(slots.size()):
		var s = slots[i] as InventorySlot
		if not s:
			continue
		if i < filtered_items.size():
			var it = filtered_items[i]
			s.slot_index = it.get("_bag_index", -1)
			s.set_item(it)
		else:
			s.slot_index = -1
			s.clear_item()

	inv_title.text = "── Инвентарь (Рюкзак: " + str(InventoryManager.bag_items.size()) + " / " + str(InventoryManager.MAX_BAG_SLOTS) + ") ──"
	_update_potion_pill()

# ==================== SELECTION & ACTION ====================

func _on_slot_selected(slot: InventorySlot, item_data: Dictionary) -> void:
	_select_slot(slot, item_data)

func _select_slot(slot: InventorySlot, item_data: Dictionary) -> void:
	selected_slot_ref = slot
	selected_item_ref = item_data

	# Clear selection highlight across all slots
	var all_slots = [weapon_slot, shield_slot, boots_slot]
	all_slots.append_array(inv_grid.get_children())
	for s in all_slots:
		if s is InventorySlot:
			s.set_selected(s == slot)

	if not item_inspector_card or item_data.is_empty():
		if item_inspector_card:
			inspector_name_label.text = "Слот пуст"
			inspector_stars_label.text = ""
			inspector_type_label.text = ""
			inspector_stat_label.text = "Выберите предмет из рюкзака"
			inspector_diff_label.text = ""
			inspector_lore_label.text = ""
			inspector_action_btn.visible = false
		return

	inspector_action_btn.visible = true
	var item_name = item_data.get("name", "Предмет")
	var item_type = item_data.get("type", "weapon")
	var bonus = item_data.get("bonus", 0)
	var rarity = item_data.get("rarity", 0)
	var lore = item_data.get("desc", "")

	inspector_name_label.text = item_name

	var stars = ""
	for i in range(clamp(rarity + 2, 1, 5)): stars += "✦"
	inspector_stars_label.text = stars

	var type_ru = "Одноручный меч" if item_type == "weapon" else ("Броня / Щит" if item_type == "shield" else ("Обувь" if item_type == "boots" else ("Зелье исцеления" if item_type == "potion" else "Материал")))
	inspector_type_label.text = "[ " + type_ru + " ]"

	var stat_name = item_data.get("stat_name", "Бонус")
	inspector_stat_label.text = "✦ " + stat_name + ": +" + str(bonus)
	inspector_lore_label.text = lore

	# Stat comparison with equipped gear
	var is_in_equip_slot = slot.slot_type != "general"
	if is_in_equip_slot:
		inspector_diff_label.text = "✅ Текущее снаряжение"
		inspector_diff_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		inspector_action_btn.text = "Снять снаряжение"
	elif item_type in ["weapon", "shield", "boots"]:
		var current_eq = InventoryManager.equipped.get(item_type, {})
		var cur_bonus = current_eq.get("bonus", 0) if not current_eq.is_empty() else 0
		var diff = bonus - cur_bonus
		if diff > 0:
			inspector_diff_label.text = "▲ +" + str(diff) + " к " + stat_name + " (Улучшение!)"
			inspector_diff_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
		elif diff < 0:
			inspector_diff_label.text = "▼ " + str(diff) + " к " + stat_name
			inspector_diff_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.35))
		else:
			inspector_diff_label.text = "= Равные характеристики"
			inspector_diff_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		inspector_action_btn.text = "Экипировать"
	elif item_type == "potion":
		inspector_diff_label.text = "Восстановит " + str(bonus) + " HP герою"
		inspector_diff_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.65))
		inspector_action_btn.text = "Использовать зелье"
	elif item_type == "material":
		inspector_diff_label.text = "Дарует +" + str(bonus) + " опыта персонажу"
		inspector_diff_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		inspector_action_btn.text = "Использовать кристалл"

	# High contrast dynamic styling for action button
	var btn_sb = StyleBoxFlat.new()
	btn_sb.corner_radius_top_left = 8
	btn_sb.corner_radius_top_right = 8
	btn_sb.corner_radius_bottom_right = 8
	btn_sb.corner_radius_bottom_left = 8
	btn_sb.border_width_left = 2
	btn_sb.border_width_top = 2
	btn_sb.border_width_right = 2
	btn_sb.border_width_bottom = 2
	btn_sb.shadow_size = 6

	if is_in_equip_slot:
		btn_sb.bg_color = Color(0.28, 0.08, 0.12, 0.95)
		btn_sb.border_color = Color(1.0, 0.45, 0.45, 1.0)
		btn_sb.shadow_color = Color(0.8, 0.2, 0.2, 0.35)
		inspector_action_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.95))
	elif item_type == "potion":
		btn_sb.bg_color = Color(0.08, 0.26, 0.16, 0.95)
		btn_sb.border_color = Color(0.40, 0.95, 0.60, 1.0)
		btn_sb.shadow_color = Color(0.2, 0.8, 0.4, 0.35)
		inspector_action_btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	else:
		btn_sb.bg_color = Color(0.30, 0.18, 0.08, 0.95)
		btn_sb.border_color = Color(1.0, 0.85, 0.35, 1.0)
		btn_sb.shadow_color = Color(1.0, 0.65, 0.1, 0.35)
		inspector_action_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))

	var btn_hov = btn_sb.duplicate()
	btn_hov.bg_color = btn_sb.bg_color.lightened(0.15)
	inspector_action_btn.add_theme_stylebox_override("normal", btn_sb)
	inspector_action_btn.add_theme_stylebox_override("hover", btn_hov)
	inspector_action_btn.add_theme_stylebox_override("pressed", btn_sb)

func _on_slot_activated(slot: InventorySlot, item_data: Dictionary) -> void:
	if item_data.is_empty():
		return
	_select_slot(slot, item_data)
	_on_inspector_action_pressed()

func _on_inspector_action_pressed() -> void:
	if not selected_slot_ref or selected_item_ref.is_empty():
		return

	SoundSynth.play_ui_equip(self)

	if selected_slot_ref.slot_type != "general":
		# Unequip
		InventoryManager.unequip_slot(selected_slot_ref.slot_type)
	else:
		# Use or Equip
		if selected_slot_ref.slot_index >= 0:
			InventoryManager.use_item_at(selected_slot_ref.slot_index)

	_refresh_inventory_grid()
	update_character_sheet_text()

# ==================== SIGNALS & EVENT HANDLERS ====================

func _on_inventory_updated() -> void:
	_refresh_inventory_grid()
	update_character_sheet_text()

func _on_inventory_equipment_changed(_slot_name: String, _item_data: Dictionary) -> void:
	_refresh_inventory_grid()
	update_character_sheet_text()

func toggle_character_sheet() -> void:
	if is_animating_sheet:
		return
	if not character_sheet.visible:
		open_character_sheet()
	else:
		close_character_sheet()

func open_character_sheet() -> void:
	is_animating_sheet = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if player_hud:
		player_hud.visible = false
	if hints_panel:
		hints_panel.visible = false
	if touch_controls:
		touch_controls.visible = false

	_refresh_inventory_grid()
	update_character_sheet_text()

	if preview_3d and preview_3d.has_method("reset_preview"):
		preview_3d.reset_preview()

	if magic_circle:
		magic_circle.rotation = 0.0

	backdrop_overlay.visible = true
	backdrop_overlay.modulate.a = 0.0
	backdrop_overlay.move_to_front()
	character_sheet.visible = true
	character_sheet.modulate.a = 0.0
	character_sheet.move_to_front()
	character_sheet.pivot_offset = Vector2(960, 540)
	character_sheet.scale = Vector2(0.96, 0.96)

	if sheet_tween: sheet_tween.kill()
	sheet_tween = create_tween().set_parallel(true)
	sheet_tween.tween_property(backdrop_overlay, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sheet_tween.tween_property(character_sheet, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sheet_tween.tween_property(character_sheet, "scale", Vector2(1.0, 1.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	SoundSynth.play_voice_menu_open(self)
	AccessibilityManager.speak_after_voice("Окно персонажа", 0.25)

	await sheet_tween.finished
	is_animating_sheet = false

func close_character_sheet() -> void:
	is_animating_sheet = true
	SoundSynth.play_voice_menu_close(self)
	if not SoundSynth.is_voice_playing():
		AccessibilityManager.speak("Закрыто")

	if sheet_tween: sheet_tween.kill()
	sheet_tween = create_tween().set_parallel(true)
	sheet_tween.tween_property(backdrop_overlay, "modulate:a", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sheet_tween.tween_property(character_sheet, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sheet_tween.tween_property(character_sheet, "scale", Vector2(0.96, 0.96), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await sheet_tween.finished
	character_sheet.visible = false
	backdrop_overlay.visible = false
	if player_hud and AccessibilityManager.ui_visible:
		player_hud.visible = true
	if hints_panel and AccessibilityManager.ui_visible:
		hints_panel.visible = true
	if touch_controls and touch_controls.is_touch_enabled and AccessibilityManager.ui_visible:
		touch_controls.visible = true

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_animating_sheet = false

func _on_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging_preview = event.is_pressed()
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if preview_3d and preview_3d.has_method("handle_zoom"):
				preview_3d.handle_zoom(-1.0)
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if preview_3d and preview_3d.has_method("handle_zoom"):
				preview_3d.handle_zoom(1.0)
	elif event is InputEventMouseMotion and is_dragging_preview:
		if preview_3d and preview_3d.has_method("handle_drag"):
			preview_3d.handle_drag(event.relative.x)

func _input(event: InputEvent) -> void:
	if vn_is_active:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			_advance_vn()
			get_viewport().set_input_as_handled()
			return
		elif event is InputEventKey and event.is_pressed() and not event.is_echo() and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			_advance_vn()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("open_character_sheet"):
		toggle_character_sheet()
	elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if character_sheet.visible and not is_animating_sheet:
			close_character_sheet()
			get_viewport().set_input_as_handled()

func update_stats(hp: int, max_hp: int, exp_val: int, exp_to_next: int, level: int, attack_val: int) -> void:
	current_hp_val = hp
	max_hp_val = max_hp
	exp_val_val = exp_val
	exp_to_next_val = exp_to_next
	level_val = level
	attack_val_val = attack_val

	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_text.text = str(hp) + " / " + str(max_hp)
	level_label.text = "Ур. " + str(level)
	attack_label.text = "⚔ Сила атаки: " + str(attack_val)

	if exp_bar:
		exp_bar.max_value = exp_to_next
		var exp_tween = create_tween()
		exp_tween.tween_property(exp_bar, "value", float(exp_val), 0.25)
	if exp_text:
		var pct = int((float(exp_val) / float(max(1, exp_to_next))) * 100.0)
		exp_text.text = str(exp_val) + " / " + str(exp_to_next) + " XP (" + str(pct) + "%)"

	var fill = hp_bar.get_theme_stylebox("fill")
	if fill is StyleBoxFlat:
		var ratio = float(hp) / float(max_hp)
		if ratio > 0.5:
			fill.bg_color = Color(0.35, 0.88, 0.42)
		elif ratio > 0.25:
			fill.bg_color = Color(0.95, 0.75, 0.1)
		else:
			fill.bg_color = Color(0.95, 0.2, 0.2)

	update_character_sheet_text()

func update_character_sheet_text() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var active_char = "hutao"
	if player and "current_character_id" in player:
		active_char = player.current_character_id

	if preview_3d and preview_3d.has_method("set_preview_character"):
		preview_3d.set_preview_character(active_char)

	if active_char == "ellen":
		if hero_name_label:
			hero_name_label.text = "Эллен Джо"
		if sheet_title_label:
			sheet_title_label.text = "✦  Эллен Джо (Ellen Joe)  ✦"
		if sheet_element_badge:
			sheet_element_badge.text = "❄️"
			sheet_element_badge.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
		if sheet_role_badge:
			sheet_role_badge.text = "  [ Victoria Housekeeping • Горничная • Крио • 5★ ]"
			sheet_role_badge.add_theme_color_override("font_color", Color(0.65, 0.90, 1.0, 0.9))
		if stars_label:
			stars_label.text = "★ ★ ★ ★ ★"
		if level_display_label:
			level_display_label.text = "УРОВЕНЬ  " + str(level_val) + " / 90   ✦   ФАЗА 6 (МАКС.)"
		if stats_list_label:
			var def_bonus = InventoryManager.get_defense_bonus()
			var def_val = 16 + def_bonus
			var spd_bonus = InventoryManager.get_speed_bonus()
			var spd_val = 7.4 + spd_bonus
			var atk_bonus = InventoryManager.get_attack_bonus()
			var atk_val = 28 + atk_bonus
			var lines: Array[String] = []
			lines.append("  ❤️  Макс. HP:                15,480  (+3,240)")
			lines.append("  ⚔️  Сила Атаки:             %d  (+%d)" % [atk_val, 45 + atk_bonus])
			lines.append("  🛡️  Защита:                 %d  (+%d)" % [def_val, 20 + def_bonus])
			lines.append("  ⚡  Скорость бега:          %.1f м/с  (+15%%)" % spd_val)
			lines.append("  ❄️  Бонус Крио-урона:       +24.0%")
			lines.append("  🎯  Крит. шанс:             68.4%")
			lines.append("  💥  Крит. урон:             194.2%")
			lines.append("  ⚡  Восст. энергии:         135.0%")
			lines.append("  ✨  Опыт героя:             %d / %d XP" % [exp_val_val, exp_to_next_val])
			stats_list_label.text = "\n".join(lines)
	else:
		if hero_name_label:
			hero_name_label.text = "Ху Тао"
		if sheet_title_label:
			sheet_title_label.text = "✦  Ху Тао (Hu Tao)  ✦"
		if sheet_element_badge:
			sheet_element_badge.text = "🔥"
			sheet_element_badge.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
		if sheet_role_badge:
			sheet_role_badge.text = "  [ 77-я Управляющая бюро «Ваншэн» • Пиро • 5★ ]"
			sheet_role_badge.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35, 0.85))
		if stars_label:
			stars_label.text = "★ ★ ★ ★ ★"
		if level_display_label:
			level_display_label.text = "УРОВЕНЬ  " + str(level_val) + " / 90   ✦   ФАЗА 6 (МАКС.)"
		if stats_list_label:
			var def_bonus = InventoryManager.get_defense_bonus()
			var def_val = 10 + def_bonus
			var spd_bonus = InventoryManager.get_speed_bonus()
			var spd_val = 7.0 + spd_bonus
			var atk_bonus = InventoryManager.get_attack_bonus()
			var atk_val = 15 + atk_bonus
			var lines: Array[String] = []
			lines.append("  ❤️  Макс. HP:                %d" % max_hp_val)
			if atk_bonus > 0:
				lines.append("  ⚔️  Сила Атаки:             %d  (+%d)" % [atk_val, atk_bonus])
			else:
				lines.append("  ⚔️  Сила Атаки:             %d" % atk_val)
			if def_bonus > 0:
				lines.append("  🛡️  Защита:                 %d  (+%d)" % [def_val, def_bonus])
			else:
				lines.append("  🛡️  Защита:                 %d" % def_val)
			lines.append("  ⚡  Скорость бега:          %.1f м/с" % spd_val)
			lines.append("  🔥  Бонус Пиро-урона:       +15.0%")
			lines.append("  🎯  Крит. шанс:             52.8%")
			lines.append("  💥  Крит. урон:             168.4%")
			lines.append("  ⚡  Восст. энергии:         120.0%")
			lines.append("  ✨  Опыт героя:             %d / %d XP" % [exp_val_val, exp_to_next_val])
			stats_list_label.text = "\n".join(lines)

func show_exp_gain(amount: int) -> void:
	if not exp_popup_label:
		return
	exp_popup_label.text = "+" + str(amount) + " ОПЫТА ✨"
	exp_popup_label.visible = true
	exp_popup_label.position.y = 560.0
	exp_popup_label.modulate.a = 1.0
	exp_popup_label.scale = Vector2(0.8, 0.8)

	if exp_popup_tween: exp_popup_tween.kill()
	exp_popup_tween = create_tween().set_parallel(true)
	exp_popup_tween.tween_property(exp_popup_label, "position:y", 490.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	exp_popup_tween.tween_property(exp_popup_label, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	exp_popup_tween.tween_property(exp_popup_label, "modulate:a", 0.0, 0.4).set_delay(0.6)

	await exp_popup_tween.finished
	exp_popup_label.visible = false

func show_level_up_banner(new_lvl: int, new_hp: int, new_atk: int) -> void:
	if not level_up_banner:
		return
	lvl_info_label.text = "✦ УРОВЕНЬ " + str(new_lvl) + " ДОСТИГНУТ! ✦"
	stats_boost_label.text = "Макс. Здоровье: " + str(new_hp) + " (+20)   |   Сила атаки: " + str(new_atk) + " (+5)"
	level_up_banner.visible = true
	level_up_banner.modulate.a = 0.0
	level_up_banner.pivot_offset = level_up_banner.size * 0.5
	level_up_banner.scale = Vector2(0.65, 0.65)

	if damage_flash:
		damage_flash.color = Color(1.0, 0.88, 0.45, 0.28)
		var ft = create_tween()
		ft.tween_property(damage_flash, "color:a", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if banner_tween: banner_tween.kill()
	banner_tween = create_tween()
	banner_tween.set_parallel(true)
	banner_tween.tween_property(level_up_banner, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	banner_tween.tween_property(level_up_banner, "scale", Vector2(1.08, 1.08), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await banner_tween.finished
	await get_tree().create_timer(1.8).timeout

	var fade_out = create_tween()
	fade_out.tween_property(level_up_banner, "modulate:a", 0.0, 0.35)
	await fade_out.finished
	level_up_banner.visible = false

func trigger_damage_flash() -> void:
	if not damage_flash:
		return
	if flash_tween: flash_tween.kill()
	damage_flash.color = Color(1.0, 0.05, 0.05, 0.28)
	flash_tween = create_tween()
	flash_tween.tween_property(damage_flash, "color:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_ui_toggle(is_visible: bool) -> void:
	player_hud.visible = is_visible
	hints_panel.visible = is_visible
	if not is_visible:
		character_sheet.visible = false

func _on_contrast_toggle(active: bool) -> void:
	var mod = Color(1.3, 1.3, 1.3) if active else Color(1.0, 1.0, 1.0)
	player_hud.modulate = mod
	hints_panel.modulate = mod
	character_sheet.modulate = mod

func update_skill_cooldown(remaining: float, total: float) -> void:
	if touch_controls and touch_controls.has_method("update_skill_cooldown"):
		touch_controls.update_skill_cooldown(remaining, total)
	if not skill_badge_label:
		return
	if remaining <= 0.05:
		skill_badge_label.text = "✦ [E] Пламя: ГОТОВ"
		skill_badge_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
	else:
		skill_badge_label.text = "✦ [E] " + str(snapped(remaining, 0.1)) + "с"
		skill_badge_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.65))

# ==================== SQUAD & PARTY HUD ====================

func _setup_party_hud() -> void:
	party_hud_container = VBoxContainer.new()
	party_hud_container.name = "PartyHUDContainer"
	party_hud_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	party_hud_container.offset_left = -190.0
	party_hud_container.offset_top = 180.0
	party_hud_container.offset_right = -24.0
	party_hud_container.offset_bottom = 340.0
	party_hud_container.add_theme_constant_override("separation", 10)
	player_hud.add_child(party_hud_container)

	var squad_slots_data = [
		{"num": "1", "icon": "🔥", "name": "Ху Тао", "element": "Пиро", "color": Color(1.0, 0.65, 0.2)},
		{"num": "2", "icon": "❄️", "name": "Эллен Джо", "element": "Лед", "color": Color(0.3, 0.85, 1.0)}
	]

	for i in range(squad_slots_data.size()):
		var s_data = squad_slots_data[i]
		var panel = PanelContainer.new()
		panel.name = "PartySlot_" + str(i)
		panel.custom_minimum_size = Vector2(166, 46)
		panel.mouse_filter = Control.MOUSE_FILTER_PASS

		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.08, 0.14, 0.82)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_right = 10
		sb.corner_radius_bottom_left = 10
		if i == 0:
			sb.border_width_left = 3
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(1.0, 0.85, 0.35, 1.0)
			sb.shadow_color = Color(1.0, 0.6, 0.1, 0.3)
			sb.shadow_size = 6
		else:
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.4, 0.4, 0.5, 0.45)
		panel.add_theme_stylebox_override("panel", sb)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 6)
		panel.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		margin.add_child(hbox)

		var key_lbl = Label.new()
		key_lbl.text = "[" + s_data["num"] + "]"
		key_lbl.add_theme_font_size_override("font_size", 14)
		key_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		hbox.add_child(key_lbl)

		var icon_lbl = Label.new()
		icon_lbl.text = s_data["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 16)
		hbox.add_child(icon_lbl)

		var name_lbl = Label.new()
		name_lbl.text = s_data["name"]
		name_lbl.name = "SlotNameLabel"
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
		hbox.add_child(name_lbl)

		var slot_idx = i
		panel.gui_input.connect(func(event: InputEvent):
			if (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.is_pressed()):
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("switch_party_member"):
					player.switch_party_member(slot_idx)
		)

		party_hud_container.add_child(panel)
		party_slot_panels.append(panel)

		# Slot 1 (Ellen Joe) is initially hidden until recruited in the game!
		if i == 1:
			panel.visible = false

func on_party_switched(char_id: String, slot_idx: int) -> void:
	active_squad_slot = slot_idx
	# Update active slot styling
	for i in range(party_slot_panels.size()):
		var p = party_slot_panels[i]
		var sb = p.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if i == slot_idx:
			sb.border_width_left = 3
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(1.0, 0.85, 0.35, 1.0)
			sb.shadow_color = Color(1.0, 0.6, 0.1, 0.35)
			sb.shadow_size = 6
		else:
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.4, 0.4, 0.5, 0.45)
			sb.shadow_size = 0
		p.add_theme_stylebox_override("panel", sb)

	# Update top-left profile
	var portrait = $PlayerHUD/TopLeftProfile/Margin/HBox/Portrait as TextureRect
	var name_lbl = $PlayerHUD/TopLeftProfile/Margin/HBox/VBox/NameLabel as Label
	var atk_lbl = $PlayerHUD/TopLeftProfile/Margin/HBox/VBox/AttackLabel as Label
	if char_id == "ellen":
		if portrait:
			var tex = load("res://assets/textures/ellen_joe_portrait.png")
			if tex: portrait.texture = tex
		if name_lbl:
			name_lbl.text = "❄️ Эллен Джо"
			name_lbl.add_theme_color_override("font_color", Color(0.65, 0.92, 1.0))
		if atk_lbl:
			atk_lbl.text = "⚔ Сила атаки: 20 (Лед)"
			atk_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		if skill_badge_label:
			skill_badge_label.text = "✦ [E] Морозный Шквал: ГОТОВ"
			skill_badge_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	else:
		if portrait:
			var tex = load("res://assets/textures/player_portrait.png")
			if tex: portrait.texture = tex
		if name_lbl:
			name_lbl.text = "🔥 Ху Тао"
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85))
		if atk_lbl:
			atk_lbl.text = "⚔ Сила атаки: 15 (Пиро)"
			atk_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
		if skill_badge_label:
			skill_badge_label.text = "✦ [E] Пламя: ГОТОВ"
			skill_badge_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))

func on_party_member_recruited(char_id: String) -> void:
	if char_id == "ellen" and party_slot_panels.size() > 1:
		var slot2 = party_slot_panels[1]
		slot2.visible = true
		slot2.scale = Vector2(0.5, 0.5)
		slot2.pivot_offset = slot2.size * 0.5
		var tw = create_tween()
		tw.tween_property(slot2, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ==================== VISUAL NOVEL CUTSCENE DIALOGUE ====================

func _setup_visual_novel_ui() -> void:
	vn_root = Control.new()
	vn_root.name = "VNDialogueOverlay"
	vn_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	vn_root.mouse_filter = Control.MOUSE_FILTER_STOP
	vn_root.visible = false
	add_child(vn_root)

	# 1. Top Cinematic Widescreen Letterbox Bar
	var top_bar = ColorRect.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 64.0
	top_bar.color = Color(0.04, 0.04, 0.06, 0.95)
	vn_root.add_child(top_bar)

	# 2. Bottom Dialogue Container with frosted dark background
	var bot_box = PanelContainer.new()
	bot_box.name = "DialogBox"
	bot_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_box.offset_left = 80.0
	bot_box.offset_top = -295.0
	bot_box.offset_right = -80.0
	bot_box.offset_bottom = -26.0

	var sb_dialog = StyleBoxFlat.new()
	sb_dialog.bg_color = Color(0.04, 0.05, 0.09, 0.96)
	sb_dialog.border_width_left = 3
	sb_dialog.border_width_top = 3
	sb_dialog.border_width_right = 3
	sb_dialog.border_width_bottom = 3
	sb_dialog.border_color = Color(1.0, 0.84, 0.42, 0.92)
	sb_dialog.corner_radius_top_left = 18
	sb_dialog.corner_radius_top_right = 18
	sb_dialog.corner_radius_bottom_right = 18
	sb_dialog.corner_radius_bottom_left = 18
	sb_dialog.shadow_color = Color(0, 0, 0, 0.6)
	sb_dialog.shadow_size = 16
	bot_box.add_theme_stylebox_override("panel", sb_dialog)
	vn_root.add_child(bot_box)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	bot_box.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)

	# Speaker Portrait on left side of dialog box
	vn_portrait = TextureRect.new()
	vn_portrait.name = "VNPortrait"
	vn_portrait.custom_minimum_size = Vector2(195, 195)
	vn_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vn_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(vn_portrait)

	# Right VBox for Nameplate, Text, Choices
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 10)
	hbox.add_child(text_vbox)

	# Nameplate HBox
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 12)
	text_vbox.add_child(name_hbox)

	vn_name_label = Label.new()
	vn_name_label.text = "Эллен Джо"
	vn_name_label.add_theme_font_size_override("font_size", 28)
	vn_name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	name_hbox.add_child(vn_name_label)

	vn_title_label = Label.new()
	vn_title_label.text = "[ Victoria Housekeeping • Горничная ]"
	vn_title_label.add_theme_font_size_override("font_size", 16)
	vn_title_label.add_theme_color_override("font_color", Color(0.35, 0.88, 1.0, 0.90))
	name_hbox.add_child(vn_title_label)

	# Dialogue Text Label (supports typewriter effect)
	vn_text_label = Label.new()
	vn_text_label.name = "DialogueText"
	vn_text_label.add_theme_font_size_override("font_size", 25)
	vn_text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vn_text_label.add_theme_constant_override("line_spacing", 8)
	vn_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vn_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(vn_text_label)

	# Choices Container
	vn_choices_vbox = VBoxContainer.new()
	vn_choices_vbox.name = "ChoicesVBox"
	vn_choices_vbox.add_theme_constant_override("separation", 8)
	vn_choices_vbox.visible = false
	text_vbox.add_child(vn_choices_vbox)

	# Continue Hint
	vn_continue_label = Label.new()
	vn_continue_label.text = "✦  [ Кликните ЛКМ или нажмите ПРОБЕЛ для продолжения ]  ✦"
	vn_continue_label.add_theme_font_size_override("font_size", 15)
	vn_continue_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40, 0.85))
	vn_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text_vbox.add_child(vn_continue_label)

	vn_root.gui_input.connect(_on_vn_gui_input)

func start_visual_novel_dialogue(speaker_info: Dictionary, dialogue_data: Dictionary, on_finish: Callable) -> void:
	vn_current_dialogue_data = dialogue_data
	vn_on_finish_callback = on_finish
	vn_current_line_idx = 0
	vn_is_active = true

	# Set speaker identity
	vn_name_label.text = speaker_info.get("name", "Эллен Джо")
	vn_title_label.text = "[ " + speaker_info.get("title", "") + " ]"
	var p_path = speaker_info.get("portrait", "res://assets/textures/ellen_joe_portrait.png")
	var tex = load(p_path)
	if tex:
		vn_portrait.texture = tex

	# Hide HUD and touch controls during cutscene
	player_hud.visible = false
	hints_panel.visible = false
	if touch_controls:
		touch_controls.visible = false
	vn_root.move_to_front()

	# Show VN Root with smooth fade
	vn_root.visible = true
	vn_root.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(vn_root, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_show_vn_line(0)

func _show_vn_line(idx: int) -> void:
	var lines = vn_current_dialogue_data.get("lines", []) as Array
	if idx >= lines.size():
		_show_vn_choices()
		return

	vn_full_text = lines[idx]
	vn_current_char_idx = 0
	vn_typewriter_timer = 0.0
	vn_is_typing = true
	vn_text_label.text = ""
	vn_choices_vbox.visible = false
	vn_continue_label.visible = false

func _update_typewriter(delta: float) -> void:
	vn_typewriter_timer += delta
	if vn_typewriter_timer >= 0.022:
		vn_typewriter_timer = 0.0
		if vn_current_char_idx < vn_full_text.length():
			vn_current_char_idx += 1
			vn_text_label.text = vn_full_text.substr(0, vn_current_char_idx)
		else:
			vn_is_typing = false
			vn_continue_label.visible = true

func _show_vn_choices() -> void:
	vn_is_typing = false
	vn_continue_label.visible = false
	vn_choices_vbox.visible = true

	for c in vn_choices_vbox.get_children():
		c.queue_free()

	var choices = vn_current_dialogue_data.get("choices", []) as Array
	for c_data in choices:
		var btn = Button.new()
		btn.text = c_data.get("text", "")
		btn.custom_minimum_size = Vector2(0, 52)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.20, 0.96)
		sb.border_width_left = 3
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.35, 0.88, 1.0, 1.0)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_right = 10
		sb.corner_radius_bottom_left = 10
		btn.add_theme_stylebox_override("normal", sb)

		var sb_hov = sb.duplicate() as StyleBoxFlat
		sb_hov.bg_color = Color(0.18, 0.24, 0.38, 1.0)
		sb_hov.border_color = Color(0.7, 0.98, 1.0, 1.0)
		btn.add_theme_stylebox_override("hover", sb_hov)
		btn.add_theme_stylebox_override("pressed", sb_hov)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))

		var chosen = c_data
		btn.pressed.connect(func():
			SoundSynth.play_ui_click(self)
			_on_choice_selected(chosen)
		)
		btn.mouse_entered.connect(func():
			SoundSynth.play_ui_hover(self)
		)
		vn_choices_vbox.add_child(btn)

func _on_choice_selected(choice_data: Dictionary) -> void:
	vn_choices_vbox.visible = false
	var resp = choice_data.get("response", "")
	vn_full_text = resp
	vn_current_char_idx = 0
	vn_typewriter_timer = 0.0
	vn_is_typing = true
	vn_text_label.text = ""

	var action = choice_data.get("action", "")
	vn_current_dialogue_data["pending_action"] = action

func _on_vn_gui_input(event: InputEvent) -> void:
	if not vn_is_active:
		return
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_vn()

func _advance_vn() -> void:
	if vn_is_typing:
		# Fast forward typewriter
		vn_is_typing = false
		vn_text_label.text = vn_full_text
		vn_continue_label.visible = true
		return

	if vn_choices_vbox.visible:
		return

	if "pending_action" in vn_current_dialogue_data:
		var act = vn_current_dialogue_data["pending_action"]
		_close_visual_novel()
		if vn_on_finish_callback.is_valid():
			vn_on_finish_callback.call(act)
		return

	vn_current_line_idx += 1
	var lines = vn_current_dialogue_data.get("lines", []) as Array
	if vn_current_line_idx < lines.size():
		_show_vn_line(vn_current_line_idx)
	else:
		var choices = vn_current_dialogue_data.get("choices", []) as Array
		if choices.size() > 0:
			_show_vn_choices()
		else:
			_close_visual_novel()
			if vn_on_finish_callback.is_valid():
				vn_on_finish_callback.call("")

func _close_visual_novel() -> void:
	vn_is_active = false
	var tw = create_tween()
	tw.tween_property(vn_root, "modulate:a", 0.0, 0.20)
	await tw.finished
	vn_root.visible = false

	if AccessibilityManager.ui_visible:
		player_hud.visible = true
		hints_panel.visible = true
		if touch_controls and touch_controls.is_touch_enabled:
			touch_controls.visible = true

# ==================== RECRUIT CELEBRATION BANNER ====================

func _setup_recruit_banner() -> void:
	recruit_banner = PanelContainer.new()
	recruit_banner.name = "PartyRecruitBanner"
	recruit_banner.set_anchors_preset(Control.PRESET_CENTER)
	recruit_banner.offset_left = -320.0
	recruit_banner.offset_top = -120.0
	recruit_banner.offset_right = 320.0
	recruit_banner.offset_bottom = 120.0
	recruit_banner.visible = false

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.14, 0.96)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(1.0, 0.85, 0.35, 1.0)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 16
	sb.corner_radius_bottom_left = 16
	sb.shadow_color = Color(1.0, 0.7, 0.15, 0.45)
	sb.shadow_size = 18
	recruit_banner.add_theme_stylebox_override("panel", sb)
	add_child(recruit_banner)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	recruit_banner.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	recruit_portrait = TextureRect.new()
	recruit_portrait.custom_minimum_size = Vector2(100, 100)
	recruit_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	recruit_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(recruit_portrait)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)

	var cheer_lbl = Label.new()
	cheer_lbl.text = "✦ НОВЫЙ СОЮЗНИК В ОТРЯДЕ! ✦"
	cheer_lbl.add_theme_font_size_override("font_size", 18)
	cheer_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(cheer_lbl)

	recruit_name_label = Label.new()
	recruit_name_label.text = "Эллен Джо"
	recruit_name_label.add_theme_font_size_override("font_size", 24)
	recruit_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(recruit_name_label)

	recruit_role_label = Label.new()
	recruit_role_label.text = "Victoria Housekeeping • 5★ Ледяной Клинок"
	recruit_role_label.add_theme_font_size_override("font_size", 14)
	recruit_role_label.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	vbox.add_child(recruit_role_label)

	var hint_lbl = Label.new()
	hint_lbl.text = "Нажмите [2] для выбора Эллен Джо, [1] для возврата к Ху Тао"
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55, 0.85))
	vbox.add_child(hint_lbl)

func show_party_recruit_banner(c_name: String, c_role: String, portrait_p: String) -> void:
	if not recruit_banner:
		return
	recruit_name_label.text = c_name
	recruit_role_label.text = c_role
	var tex = load(portrait_p)
	if tex:
		recruit_portrait.texture = tex

	recruit_banner.visible = true
	recruit_banner.modulate.a = 0.0
	recruit_banner.pivot_offset = recruit_banner.size * 0.5
	recruit_banner.scale = Vector2(0.7, 0.7)

	SoundSynth.play_level_up_fanfare(self)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(recruit_banner, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(recruit_banner, "scale", Vector2(1.05, 1.05), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tw.finished
	await get_tree().create_timer(3.2).timeout

	var fade = create_tween()
	fade.tween_property(recruit_banner, "modulate:a", 0.0, 0.35)
	await fade.finished
	recruit_banner.visible = false
