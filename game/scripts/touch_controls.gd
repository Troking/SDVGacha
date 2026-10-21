extends Control

# Touch Controls Overlay for Mobile / Smartphone / Web Gameplay
# High performance, multi-touch virtual joystick, action buttons, and camera orbit look.

@export var is_touch_enabled: bool = true:
	set(val):
		is_touch_enabled = val
		visible = is_touch_enabled

var player_ref: Node3D = null

# Multi-touch pointers
var joystick_touch_id: int = -1
var look_touch_id: int = -1

# Virtual Joystick Geometry
var joystick_base_pos: Vector2 = Vector2.ZERO
var joystick_curr_pos: Vector2 = Vector2.ZERO
var joystick_offset: Vector2 = Vector2.ZERO
const JOYSTICK_RADIUS: float = 78.0
const JOYSTICK_DEADZONE: float = 0.15
const JOYSTICK_DEFAULT_OFFSET: Vector2 = Vector2(170.0, -170.0) # from bottom-left
var joystick_is_active: bool = false

# Skill Cooldown tracking
var skill_cooldown_left: float = 0.0
var skill_max_cooldown: float = 6.0

# Action Button Definitions: [id, center_offset_from_bottom_right, radius, icon_label, action_name, touch_id, is_pressed, bg_color]
var touch_buttons: Array[Dictionary] = [
	{
		"id": "attack",
		"offset": Vector2(-130.0, -130.0),
		"radius": 52.0,
		"label": "⚔️",
		"sub": "АТАКА",
		"action": "attack",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.95, 0.45, 0.15, 0.65),
		"press_color": Color(1.0, 0.75, 0.2, 0.95),
		"border_color": Color(1.0, 0.9, 0.6, 0.9)
	},
	{
		"id": "jump",
		"offset": Vector2(-80.0, -260.0),
		"radius": 40.0,
		"label": "🦘",
		"sub": "ПРЫЖОК",
		"action": "jump",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.2, 0.55, 0.9, 0.65),
		"press_color": Color(0.4, 0.8, 1.0, 0.95),
		"border_color": Color(0.7, 0.9, 1.0, 0.9)
	},
	{
		"id": "dash",
		"offset": Vector2(-260.0, -110.0),
		"radius": 40.0,
		"label": "💨",
		"sub": "РЫВОК",
		"action": "dash",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.3, 0.8, 0.5, 0.65),
		"press_color": Color(0.5, 1.0, 0.7, 0.95),
		"border_color": Color(0.8, 1.0, 0.85, 0.9)
	},
	{
		"id": "skill",
		"offset": Vector2(-225.0, -225.0),
		"radius": 44.0,
		"label": "🔥",
		"sub": "НАВЫК",
		"action": "elemental_skill",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.9, 0.25, 0.2, 0.70),
		"press_color": Color(1.0, 0.45, 0.35, 0.95),
		"border_color": Color(1.0, 0.8, 0.7, 0.9)
	},
	{
		"id": "interact",
		"offset": Vector2(-315.0, -250.0),
		"radius": 38.0,
		"label": "💬 [F]",
		"sub": "ДЕЙСТВИЕ",
		"action": "interact",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.85, 0.7, 0.15, 0.65),
		"press_color": Color(1.0, 0.9, 0.3, 0.95),
		"border_color": Color(1.0, 0.95, 0.7, 0.9)
	},
	{
		"id": "potion",
		"offset": Vector2(-155.0, -325.0),
		"radius": 34.0,
		"label": "🧪 [Q]",
		"sub": "ЗЕЛЬЕ",
		"action": "use_potion",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.65, 0.2, 0.8, 0.65),
		"press_color": Color(0.85, 0.4, 1.0, 0.95),
		"border_color": Color(0.9, 0.7, 1.0, 0.9)
	},
	{
		"id": "lock",
		"offset": Vector2(-60.0, -370.0),
		"radius": 30.0,
		"label": "🎯",
		"sub": "ЦЕЛЬ",
		"action": "target_lock",
		"touch_id": -1,
		"is_pressed": false,
		"base_color": Color(0.3, 0.35, 0.5, 0.60),
		"press_color": Color(0.5, 0.6, 0.8, 0.95),
		"border_color": Color(0.8, 0.85, 1.0, 0.8)
	}
]

func _ready() -> void:
	# Keep on top of HUD
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_joystick_home()
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Auto-enable on mobile / touch platforms only
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	is_touch_enabled = is_mobile
	visible = is_mobile

func _on_viewport_resized() -> void:
	_update_joystick_home()
	queue_redraw()

func _update_joystick_home() -> void:
	var vp_size = get_viewport_rect().size
	joystick_base_pos = Vector2(JOYSTICK_DEFAULT_OFFSET.x, vp_size.y + JOYSTICK_DEFAULT_OFFSET.y)
	if not joystick_is_active:
		joystick_curr_pos = joystick_base_pos

func _process(delta: float) -> void:
	if not is_touch_enabled:
		return
	if skill_cooldown_left > 0.0:
		skill_cooldown_left = max(0.0, skill_cooldown_left - delta)
		queue_redraw()

func update_skill_cooldown(current: float, max_cd: float) -> void:
	skill_cooldown_left = current
	skill_max_cooldown = max_cd
	queue_redraw()

func set_character_element(char_id: String) -> void:
	for btn in touch_buttons:
		if btn["id"] == "skill":
			if char_id == "ellen":
				btn["label"] = "❄️"
				btn["base_color"] = Color(0.15, 0.55, 0.85, 0.75)
				btn["press_color"] = Color(0.35, 0.85, 1.0, 0.95)
				btn["border_color"] = Color(0.7, 0.95, 1.0, 0.9)
			else:
				btn["label"] = "🔥"
				btn["base_color"] = Color(0.9, 0.25, 0.2, 0.70)
				btn["press_color"] = Color(1.0, 0.45, 0.35, 0.95)
				btn["border_color"] = Color(1.0, 0.8, 0.7, 0.9)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_touch_enabled:
		return

	var vp_size = get_viewport_rect().size

	# Handle Screen Touch (Press / Release)
	if event is InputEventScreenTouch:
		if event.is_pressed():
			_handle_touch_down(event.index, event.position, vp_size)
		else:
			_handle_touch_up(event.index)
		queue_redraw()

	# Handle Screen Drag (Move)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position, event.relative, vp_size)
		queue_redraw()

func _handle_touch_down(pointer_id: int, pos: Vector2, vp_size: Vector2) -> void:
	# 1. Check Action Buttons (Priority)
	for btn in touch_buttons:
		var btn_center = Vector2(vp_size.x + btn["offset"].x, vp_size.y + btn["offset"].y)
		if pos.distance_to(btn_center) <= btn["radius"] * 1.25:
			btn["touch_id"] = pointer_id
			btn["is_pressed"] = true
			_trigger_action_press(btn["action"])
			return

	# 2. Check Virtual Joystick Area (Left 45% of screen, bottom 60%)
	if pos.x < vp_size.x * 0.48 and pos.y > vp_size.y * 0.35:
		if joystick_touch_id == -1:
			joystick_touch_id = pointer_id
			joystick_is_active = true
			# Dynamic anchor to initial touch position for extreme tactile comfort
			joystick_base_pos = pos
			joystick_curr_pos = pos
			joystick_offset = Vector2.ZERO
			_update_movement_from_joystick()
			return

	# 3. Touch Look Area (Right 55% of screen)
	if pos.x >= vp_size.x * 0.48:
		if look_touch_id == -1:
			look_touch_id = pointer_id

func _handle_touch_up(pointer_id: int) -> void:
	# Release Action Button
	for btn in touch_buttons:
		if btn["touch_id"] == pointer_id:
			btn["touch_id"] = -1
			btn["is_pressed"] = false
			_trigger_action_release(btn["action"])

	# Release Joystick
	if joystick_touch_id == pointer_id:
		joystick_touch_id = -1
		joystick_is_active = false
		joystick_offset = Vector2.ZERO
		_update_joystick_home()
		_release_movement_actions()

	# Release Look
	if look_touch_id == pointer_id:
		look_touch_id = -1

func _handle_touch_drag(pointer_id: int, pos: Vector2, relative: Vector2, vp_size: Vector2) -> void:
	# Joystick Drag
	if pointer_id == joystick_touch_id:
		var delta_pos = pos - joystick_base_pos
		var dist = delta_pos.length()
		if dist > JOYSTICK_RADIUS:
			delta_pos = delta_pos.normalized() * JOYSTICK_RADIUS
		joystick_curr_pos = joystick_base_pos + delta_pos
		joystick_offset = delta_pos / JOYSTICK_RADIUS
		_update_movement_from_joystick()
		return

	# Camera Look Drag
	if pointer_id == look_touch_id:
		if player_ref and player_ref.has_method("rotate_camera_touch"):
			player_ref.rotate_camera_touch(relative)
		return

	# Track action button slide off/on
	for btn in touch_buttons:
		if btn["touch_id"] == pointer_id:
			var btn_center = Vector2(vp_size.x + btn["offset"].x, vp_size.y + btn["offset"].y)
			var is_inside = pos.distance_to(btn_center) <= btn["radius"] * 1.4
			if is_inside != btn["is_pressed"]:
				btn["is_pressed"] = is_inside
				if is_inside:
					_trigger_action_press(btn["action"])
				else:
					_trigger_action_release(btn["action"])

func _update_movement_from_joystick() -> void:
	var len_val = joystick_offset.length()
	if len_val < JOYSTICK_DEADZONE:
		_release_movement_actions()
		return

	var dir = joystick_offset.normalized()
	var strength = clamp((len_val - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE), 0.0, 1.0)

	# Analog Direction Mapping
	if dir.y < -0.2:
		Input.action_press("move_forward", -dir.y * strength)
		Input.action_release("move_back")
	elif dir.y > 0.2:
		Input.action_press("move_back", dir.y * strength)
		Input.action_release("move_forward")
	else:
		Input.action_release("move_forward")
		Input.action_release("move_back")

	if dir.x < -0.2:
		Input.action_press("move_left", -dir.x * strength)
		Input.action_release("move_right")
	elif dir.x > 0.2:
		Input.action_press("move_right", dir.x * strength)
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

func _release_movement_actions() -> void:
	if not Input.is_physical_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_UP):
		Input.action_release("move_forward")
	if not Input.is_physical_key_pressed(KEY_S) and not Input.is_key_pressed(KEY_DOWN):
		Input.action_release("move_back")
	if not Input.is_physical_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_LEFT):
		Input.action_release("move_left")
	if not Input.is_physical_key_pressed(KEY_D) and not Input.is_key_pressed(KEY_RIGHT):
		Input.action_release("move_right")

func _trigger_action_press(action: String) -> void:
	Input.action_press(action, 1.0)

func _trigger_action_release(action: String) -> void:
	Input.action_release(action)

func _draw() -> void:
	if not is_touch_enabled:
		return

	var vp_size = get_viewport_rect().size

	# 1. Draw Virtual Joystick
	_draw_joystick()

	# 2. Draw Action Buttons
	var default_font = ThemeDB.fallback_font
	for btn in touch_buttons:
		var center = Vector2(vp_size.x + btn["offset"].x, vp_size.y + btn["offset"].y)
		var rad = btn["radius"]
		var is_p = btn["is_pressed"]
		var bg_col = btn["press_color"] if is_p else btn["base_color"]
		var border_col = btn["border_color"]

		# Outer Glow
		if is_p:
			draw_circle(center, rad + 6.0, Color(border_col.r, border_col.g, border_col.b, 0.40))

		# Button Circle
		draw_circle(center, rad, bg_col)
		# Border Ring
		draw_arc(center, rad, 0.0, TAU, 36, border_col, 2.5, true)

		# Skill Cooldown Overlay
		if btn["id"] == "skill" and skill_cooldown_left > 0.0:
			var ratio = clamp(skill_cooldown_left / skill_max_cooldown, 0.0, 1.0)
			draw_arc(center, rad - 3.0, -PI/2.0, -PI/2.0 + ratio * TAU, 32, Color(1, 0.9, 0.2, 0.95), 4.0, true)
			# Dimmer overlay
			draw_circle(center, rad - 2.0, Color(0, 0, 0, 0.55))
			var cd_str = str(snapped(skill_cooldown_left, 0.1))
			draw_string(default_font, center + Vector2(-14, 6), cd_str, HORIZONTAL_ALIGNMENT_CENTER, 36, 18, Color(1, 1, 1, 1))
		else:
			# Emoji / Label
			var icon_str = btn["label"]
			var font_sz = 24 if btn["radius"] >= 45.0 else 18
			var str_offset = Vector2(-rad * 0.45, font_sz * 0.35)
			draw_string(default_font, center + str_offset, icon_str, HORIZONTAL_ALIGNMENT_CENTER, rad * 0.9, font_sz, Color(1, 1, 1, 0.95))

		# Subtitle hint (Russian key prompt)
		var sub_font_sz = 10
		var sub_str = btn["sub"]
		draw_string(default_font, center + Vector2(-rad, rad + 14.0), sub_str, HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, sub_font_sz, Color(1, 1, 1, 0.65))

func _draw_joystick() -> void:
	# Base Outer Ring
	var base_col = Color(0.12, 0.14, 0.20, 0.45 if not joystick_is_active else 0.65)
	var ring_col = Color(0.85, 0.65, 0.25, 0.55 if not joystick_is_active else 0.90)
	draw_circle(joystick_base_pos, JOYSTICK_RADIUS, base_col)
	draw_arc(joystick_base_pos, JOYSTICK_RADIUS, 0.0, TAU, 40, ring_col, 2.0, true)
	draw_arc(joystick_base_pos, JOYSTICK_RADIUS * 0.45, 0.0, TAU, 24, Color(ring_col.r, ring_col.g, ring_col.b, 0.25), 1.0, true)

	# Active Drag Line
	if joystick_is_active and joystick_offset.length() > 0.05:
		draw_line(joystick_base_pos, joystick_curr_pos, Color(1.0, 0.85, 0.35, 0.65), 2.5, true)

	# Inner Thumb Knob
	var knob_rad = 32.0
	var knob_col = Color(0.95, 0.85, 0.45, 0.75 if not joystick_is_active else 0.95)
	var knob_border = Color(1.0, 1.0, 1.0, 0.90)
	draw_circle(joystick_curr_pos, knob_rad, knob_col)
	draw_arc(joystick_curr_pos, knob_rad, 0.0, TAU, 28, knob_border, 2.0, true)
