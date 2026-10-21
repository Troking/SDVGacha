extends Area3D
class_name NPCCompanion

@export var character_id: String = "ellen"
@export var character_name: String = "Эллен Джо"
@export var character_title: String = "Victoria Housekeeping • Горничная"

@onready var prompt_label: Label3D = $PromptLabel
@onready var visual_root: Node3D = $VisualRoot

var is_player_nearby: bool = false
var is_recruited: bool = false
var anim_player: AnimationPlayer = null
var ellen_model_inst: Node3D = null
var bob_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_ellen_visuals()
	call_deferred("_check_initial_proximity")

func _check_initial_proximity() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if global_position.distance_to(player.global_position) <= 4.2:
			is_player_nearby = true
	_update_prompt()

func _setup_ellen_visuals() -> void:
	# Load authentic Ellen Joe model scene
	var model_scene = load("res://scenes/ellen_joe_model.tscn")
	if model_scene:
		ellen_model_inst = model_scene.instantiate() as Node3D
		visual_root.add_child(ellen_model_inst)

		var players = ellen_model_inst.find_children("*", "AnimationPlayer", true, false)
		if players.size() > 0:
			anim_player = players[0]
			if anim_player.has_animation("Idle"):
				var anim = anim_player.get_animation("Idle")
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
				anim_player.play("Idle")

	# Add soft icy frost particle aura around Ellen
	var frost = CPUParticles3D.new()
	frost.name = "FrostAura"
	frost.amount = 16
	frost.lifetime = 1.8
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.025
	p_mesh.height = 0.05
	p_mesh.material = mat
	frost.mesh = p_mesh
	frost.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	frost.emission_sphere_radius = 0.70
	frost.direction = Vector3(0, 1, 0)
	frost.gravity = Vector3(0, 0.15, 0)
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	grad.colors = PackedColorArray([
		Color(0.2, 0.8, 1.0, 0),
		Color(0.4, 0.9, 1.0, 0.8),
		Color(0.7, 0.95, 1.0, 0.6),
		Color(0.2, 0.7, 1.0, 0.0)
	])
	frost.color_ramp = grad
	visual_root.add_child(frost)

func _process(delta: float) -> void:
	bob_time += delta
	# Subtle floating bob
	visual_root.position.y = sin(bob_time * 1.8) * 0.025

	# Active real-time distance proximity tracking
	if not is_recruited:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var d = global_position.distance_to(player.global_position)
			var was_nearby = is_player_nearby
			is_player_nearby = (d <= 4.2)
			if is_player_nearby != was_nearby:
				_update_prompt()

func _input(event: InputEvent) -> void:
	if is_player_nearby and not is_recruited:
		var is_f_key = false
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			is_f_key = (event.physical_keycode == KEY_F or event.keycode == KEY_F or event.keycode == 0x410 or event.keycode == 0x430 or event.unicode == 1072 or event.unicode == 1040)
		if event.is_action_pressed("interact") or is_f_key:
			get_viewport().set_input_as_handled()
			_trigger_dialogue()
		elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			var player = get_tree().get_first_node_in_group("player")
			if player and not player.is_in_dialogue and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				get_viewport().set_input_as_handled()
				_trigger_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	_input(event)

func _trigger_dialogue() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Smoothly orient Ellen towards the player
	var dir_to_player = (player.global_position - global_position)
	dir_to_player.y = 0
	if dir_to_player.length() > 0.1:
		visual_root.rotation = Vector3.ZERO
		global_rotation.y = atan2(dir_to_player.x, dir_to_player.z)

	# Trigger cinematic camera focusing on Ellen's face
	if player.has_method("start_dialogue_camera"):
		player.start_dialogue_camera(self)

	var ui = get_tree().root.find_child("UI", true, false)
	if ui and ui.has_method("start_visual_novel_dialogue"):
		var speaker_info = {
			"id": character_id,
			"name": character_name,
			"title": character_title,
			"portrait": "res://assets/textures/ellen_joe_portrait.png"
		}
		var dialogue_data = {
			"lines": [
				"Ха-ах... Чего тебе? Если ты из агентства, скажи, что я на обеденном перерыве... Шучу. Чего надо?",
				"Снова незнакомый мир. Коляски нет, Ликаона нет... а меня опять заставляют работать сверхурочно? Ты выглядишь бодро. Не подбросишь до ближайшего кафе?"
			],
			"choices": [
				{
					"text": "«Эллен, присоединяйся к моему отряду! Вместе исследуем этот мир!»",
					"response": "Хм... Ладно, уговорил. С тобой хотя бы не скучно. Только чур сверхурочные оплачиваешь леденцами! И не заставляй меня бегать по утрам.",
					"action": "recruit"
				},
				{
					"text": "«Ты круто орудуешь ножницами. Поможешь мне в битвах?»",
					"response": "Быстро покрошим монстров и по домам? Договорились. Только не стой у меня на пути.",
					"action": "recruit"
				}
			]
		}
		ui.start_visual_novel_dialogue(speaker_info, dialogue_data, Callable(self, "_on_dialogue_finished"))
		SoundSynth.play_voice_ellen_greet()

func _on_dialogue_finished(action: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("end_dialogue_camera"):
		player.end_dialogue_camera()

	if action == "recruit" and not is_recruited:
		is_recruited = true
		SoundSynth.play_voice_ellen_accept()

		if player and player.has_method("recruit_party_member"):
			player.recruit_party_member("ellen")

		var ui = get_tree().root.find_child("UI", true, false)
		if ui and ui.has_method("show_party_recruit_banner"):
			ui.show_party_recruit_banner("Эллен Джо", "Victoria Housekeeping • 5★ Ледяной Клинок", "res://assets/textures/ellen_joe_portrait.png")

		# Vanish gracefully into the player's party
		var tw = create_tween()
		tw.tween_property(visual_root, "scale", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tw.finished
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		_update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		_update_prompt()

func _update_prompt() -> void:
	if not prompt_label:
		return
	if is_player_nearby and not is_recruited:
		prompt_label.visible = true
		prompt_label.text = "✦  [F] Поговорить с Эллен Джо  ✦"
	else:
		prompt_label.visible = false
