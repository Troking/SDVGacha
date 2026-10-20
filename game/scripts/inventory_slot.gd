extends Panel
class_name InventorySlot

signal item_equipped(slot_type: String, item_data: Dictionary)
signal item_unequipped(slot_type: String, item_data: Dictionary)
signal slot_selected(slot: InventorySlot, item_data: Dictionary)
signal slot_activated(slot: InventorySlot, item_data: Dictionary)

@export var slot_type: String = "general" # "general", "weapon", "shield", "boots"
var slot_index: int = -1 # Index in bag_items (-1 for equipment slot)
var item_data: Dictionary = {}
var is_equipped: bool = false
var is_selected: bool = false

@onready var icon_rect: TextureRect = get_node_or_null("Icon")
@onready var stars_label: Label = get_node_or_null("StarsLabel")
@onready var level_label: Label = get_node_or_null("LevelLabel")
@onready var equipped_badge: TextureRect = get_node_or_null("EquippedBadge")
@onready var selection_border: ReferenceRect = get_node_or_null("SelectionBorder")
@onready var label: Label = get_node_or_null("Label")

var count_label: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(82, 86)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_ensure_count_label()
	update_view()

func _on_mouse_entered() -> void:
	pivot_offset = size / 2.0
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.05, 1.05), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	SoundSynth.play_ui_hover(self)

func _on_mouse_exited() -> void:
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _ensure_count_label() -> void:
	if not count_label:
		count_label = get_node_or_null("CountLabel")
		if not count_label:
			count_label = Label.new()
			count_label.name = "CountLabel"
			count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_label.offset_left = -42.0
			count_label.offset_top = -22.0
			count_label.offset_right = -4.0
			count_label.offset_bottom = -2.0
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_label.add_theme_font_size_override("font_size", 13)
			count_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
			count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
			count_label.add_theme_constant_override("shadow_offset_x", 1)
			count_label.add_theme_constant_override("shadow_offset_y", 1)
			add_child(count_label)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		SoundSynth.play_ui_click(self)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				slot_activated.emit(self, item_data)
			else:
				slot_selected.emit(self, item_data)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_activated.emit(self, item_data)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_border:
		selection_border.visible = selected
		if selected:
			selection_border.border_color = Color(1.0, 0.9, 0.35, 1.0)
			selection_border.border_width = 2.5

func set_item(data: Dictionary, equipped: bool = false) -> void:
	item_data = data
	is_equipped = equipped or (slot_type != "general" and not data.is_empty())
	update_view()

func clear_item() -> void:
	item_data = {}
	is_equipped = false
	update_view()

func has_item() -> bool:
	return not item_data.is_empty()

func update_view() -> void:
	if not is_inside_tree():
		return

	_ensure_count_label()

	if has_item():
		if icon_rect:
			icon_rect.texture = item_data.get("texture", null)
			icon_rect.visible = true

		var r = item_data.get("rarity", 0)
		var stars_count = clamp(r + 2, 1, 5) # 0->2, 1->3, 2->4, 3->5
		var star_str = ""
		for i in range(stars_count):
			star_str += "✦"

		if stars_label:
			stars_label.text = star_str
			stars_label.visible = true

		if level_label:
			var lvl_str = "Ур. 90" if r >= 2 else "Ур. 70"
			if item_data.get("type") in ["potion", "material"]:
				lvl_str = ""
			level_label.text = lvl_str
			level_label.visible = lvl_str != ""

		if equipped_badge:
			equipped_badge.visible = is_equipped or (slot_type != "general")

		# Item stack count label
		var count = item_data.get("count", 1)
		if count_label:
			if count > 1:
				count_label.text = "x" + str(count)
				count_label.visible = true
			else:
				count_label.visible = false

		# Genshin High-Contrast Rarity Background Colors (Deep rich gradients)
		var colors = [
			Color(0.20, 0.22, 0.28, 0.98), # 1-star (slate)
			Color(0.12, 0.34, 0.24, 0.98), # 2-star (emerald)
			Color(0.12, 0.28, 0.48, 0.98), # 3-star (azure)
			Color(0.32, 0.18, 0.48, 0.98), # 4-star (violet)
			Color(0.55, 0.32, 0.10, 0.98)  # 5-star (radiant amber gold)
		]
		var border_colors = [
			Color(0.55, 0.60, 0.72, 0.9),
			Color(0.35, 0.78, 0.55, 0.9),
			Color(0.35, 0.70, 0.98, 0.9),
			Color(0.80, 0.50, 0.98, 0.95),
			Color(1.0, 0.85, 0.30, 1.0)
		]
		var idx = clamp(r, 0, colors.size() - 1)
		var sb = StyleBoxFlat.new()
		sb.bg_color = colors[idx]
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 2
		sb.border_color = border_colors[idx]
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_right = 8
		sb.corner_radius_bottom_left = 8
		add_theme_stylebox_override("panel", sb)

		if label:
			label.visible = false
	else:
		if icon_rect:
			icon_rect.texture = null
		if stars_label:
			stars_label.visible = false
		if level_label:
			level_label.visible = false
		if equipped_badge:
			equipped_badge.visible = false
		if count_label:
			count_label.visible = false

		var sb_empty = StyleBoxFlat.new()
		sb_empty.bg_color = Color(0.08, 0.08, 0.13, 0.85)
		sb_empty.border_width_left = 1
		sb_empty.border_width_top = 1
		sb_empty.border_width_right = 1
		sb_empty.border_width_bottom = 1
		sb_empty.border_color = Color(0.38, 0.35, 0.50, 0.75)
		sb_empty.corner_radius_top_left = 8
		sb_empty.corner_radius_top_right = 8
		sb_empty.corner_radius_bottom_right = 8
		sb_empty.corner_radius_bottom_left = 8
		add_theme_stylebox_override("panel", sb_empty)

		if label:
			var slot_names = {
				"weapon": "Оружие",
				"shield": "Щит",
				"boots": "Обувь"
			}
			label.text = slot_names.get(slot_type, "")
			label.visible = slot_type != "general"

# Drag and Drop support
func _get_drag_data(_at_position: Vector2):
	if not has_item():
		return null
	var preview = TextureRect.new()
	preview.texture = icon_rect.texture if icon_rect else null
	preview.custom_minimum_size = Vector2(64, 64)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	return {"source_slot": self, "item_data": item_data}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not (data is Dictionary and data.has("item_data")):
		return false
	var incoming_item = data["item_data"]
	var incoming_type = incoming_item.get("type", "general")
	if slot_type == "general":
		return true
	return slot_type == incoming_type

func _drop_data(_at_position: Vector2, data) -> void:
	var source_slot = data.get("source_slot") as InventorySlot
	var incoming_item = data.get("item_data") as Dictionary

	if not source_slot or source_slot == self:
		return

	# Handle equipment slots vs bag slots
	if slot_type != "general" and source_slot.slot_type == "general":
		# Equipping from bag
		if source_slot.slot_index >= 0:
			InventoryManager.equip_item_at(source_slot.slot_index)
	elif slot_type == "general" and source_slot.slot_type != "general":
		# Unequipping to bag
		InventoryManager.unequip_slot(source_slot.slot_type)
	elif slot_type != "general" and source_slot.slot_type != "general":
		# Cannot drag between weapon and boots
		pass
	else:
		# Drag within bag slots
		if source_slot.slot_index >= 0 and slot_index >= 0:
			var tmp = InventoryManager.bag_items[source_slot.slot_index]
			InventoryManager.bag_items[source_slot.slot_index] = InventoryManager.bag_items[slot_index]
			InventoryManager.bag_items[slot_index] = tmp
			InventoryManager.inventory_updated.emit()
