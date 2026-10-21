extends Node

## Global Damage Number Popup Manager
## Spawns Genshin-style floating combat numbers in 3D world space

const POPUP_SCENE = preload("res://scenes/damage_popup.tscn")

enum Type {
	PHYSICAL,
	PYRO,
	CRIT,
	PLAYER_HURT,
	HEAL,
	CRYO
}

func spawn_physical(parent: Node, pos: Vector3, amount: int) -> void:
	_spawn(parent, pos, amount, Type.PHYSICAL)

func spawn_pyro(parent: Node, pos: Vector3, amount: int) -> void:
	_spawn(parent, pos, amount, Type.PYRO)

func spawn_cryo(parent: Node, pos: Vector3, amount: int) -> void:
	_spawn(parent, pos, amount, Type.CRYO)

func spawn_crit(parent: Node, pos: Vector3, amount: int) -> void:
	_spawn(parent, pos, amount, Type.CRIT)

func spawn_player_hurt(parent: Node, pos: Vector3, amount: int) -> void:
	_spawn(parent, pos, amount, Type.PLAYER_HURT)

func spawn_heal(parent: Node, pos: Vector3, amount: int) -> void:
	_spawn(parent, pos, amount, Type.HEAL)

var _alt_drift: float = 1.0

func _spawn(parent: Node, pos: Vector3, amount: int, type: Type) -> void:
	if not is_instance_valid(parent):
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.current_scene:
			parent = tree.current_scene
		else:
			return

	var popup = POPUP_SCENE.instantiate()
	parent.add_child(popup)
	popup.global_position = pos + Vector3(randf_range(-0.15, 0.15), randf_range(0.85, 1.25), randf_range(-0.15, 0.15))

	var label: Label3D = popup.get_node_or_null("Label3D")
	if not label:
		return

	match type:
		Type.PHYSICAL:
			label.text = str(amount)
			label.modulate = Color(1.0, 0.95, 0.45, 1.0)
			label.font_size = 40
			label.outline_size = 9
			label.outline_modulate = Color(0.12, 0.06, 0.0, 0.95)
		Type.PYRO:
			label.text = "🔥 " + str(amount)
			label.modulate = Color(1.0, 0.48, 0.08, 1.0)
			label.font_size = 45
			label.outline_size = 11
			label.outline_modulate = Color(0.3, 0.02, 0.0, 0.95)
		Type.CRYO:
			label.text = "❄ " + str(amount)
			label.modulate = Color(0.35, 0.90, 1.0, 1.0)
			label.font_size = 46
			label.outline_size = 11
			label.outline_modulate = Color(0.02, 0.12, 0.28, 0.95)
		Type.CRIT:
			label.text = "💥 " + str(amount) + "!"
			label.modulate = Color(1.0, 0.2, 0.05, 1.0)
			label.font_size = 54
			label.outline_size = 13
			label.outline_modulate = Color(0.35, 0.0, 0.0, 1.0)
		Type.PLAYER_HURT:
			label.text = "-" + str(amount) + " 💔"
			label.modulate = Color(1.0, 0.2, 0.25, 1.0)
			label.font_size = 46
			label.outline_size = 11
			label.outline_modulate = Color(0.25, 0.0, 0.05, 1.0)
		Type.HEAL:
			label.text = "+" + str(amount) + " 💚"
			label.modulate = Color(0.25, 1.0, 0.4, 1.0)
			label.font_size = 42
			label.outline_size = 9
			label.outline_modulate = Color(0.0, 0.2, 0.05, 0.95)

	# Initial scale and alternating combo bounce trajectory
	popup.scale = Vector3(0.25, 0.25, 0.25)
	_alt_drift = -_alt_drift
	var drift_x = _alt_drift * randf_range(0.35, 0.75)
	var drift_z = randf_range(-0.25, 0.25)
	var rise_height = randf_range(1.15, 1.55)

	# Punchy pop animation
	var scale_tween = popup.create_tween()
	scale_tween.tween_property(popup, "scale", Vector3(1.35, 1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(popup, "scale", Vector3(1.0, 1.0, 1.0), 0.14)

	# Upward floating arc
	var move_tween = popup.create_tween()
	var target_pos = popup.global_position + Vector3(drift_x, rise_height, drift_z)
	move_tween.tween_property(popup, "global_position", target_pos, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade out
	var fade_tween = popup.create_tween()
	fade_tween.tween_interval(0.42)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.33).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	move_tween.finished.connect(func(): if is_instance_valid(popup): popup.queue_free())
