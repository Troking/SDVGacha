extends Area3D
class_name NPCCompanion

@export var character_id: String = "ellen"
@export var character_name: String = "Эллен Джо"
@export var character_title: String = "Горничная • Victoria Housekeeping"

@onready var prompt_label: Label3D = $PromptLabel
@onready var visual_root: Node3D = $VisualRoot

var is_player_nearby: bool = false
var is_recruited: bool = false
var anim_player: AnimationPlayer = null
var tail_node: Node3D = null
var bob_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_ellen_visuals()
	_update_prompt()

func _setup_ellen_visuals() -> void:
	# Load rigged anime model
	var model_scene = load("res://assets/models/anime_heroine_rigged.glb")
	if model_scene:
		var model_inst = model_scene.instantiate() as Node3D
		visual_root.add_child(model_inst)

		# Find animation player
		var players = model_inst.find_children("*", "AnimationPlayer", true, false)
		if players.size() > 0:
			anim_player = players[0]
			if anim_player.has_animation("Idle"):
				var anim = anim_player.get_animation("Idle")
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
				anim_player.play("Idle")

		# Hide EyeStar highlight to avoid white polygon glare
		var star_m = model_inst.find_child("EyeStar", true, false)
		if star_m:
			star_m.visible = false

		# Apply Cel Shading with Ellen's maid colors
		var shader = load("res://scripts/genshin_cel_shader.gdshader")
		for child in model_inst.find_children("*", "MeshInstance3D", true, false):
			if child is MeshInstance3D and child.mesh:
				for s_idx in range(child.mesh.get_surface_count()):
					var toon = ShaderMaterial.new()
					toon.shader = shader
					var mat = child.get_active_material(s_idx)
					if mat is StandardMaterial3D and mat.albedo_texture:
						toon.set_shader_parameter("use_texture", true)
						toon.set_shader_parameter("albedo_texture", mat.albedo_texture)
						toon.set_shader_parameter("albedo_color", Color.WHITE)
					else:
						# Maid dress palette (black and dark slate with white apron)
						toon.set_shader_parameter("use_texture", false)
						toon.set_shader_parameter("albedo_color", Color(0.12, 0.12, 0.16))
					
					var lower_name = child.name.to_lower()
					if "face" in lower_name and not ("eye" in lower_name):
						toon.set_shader_parameter("is_face", true)
						toon.set_shader_parameter("shadow_threshold", 0.24)
						toon.set_shader_parameter("deep_shadow_threshold", 0.10)
						toon.set_shader_parameter("ambient_strength", 0.50)
						toon.set_shader_parameter("shadow_tint", Color(0.92, 0.82, 0.80))
					elif "eye" in lower_name or "brow" in lower_name:
						toon.set_shader_parameter("is_eye", true)
						toon.set_shader_parameter("shadow_threshold", 0.18)
						toon.set_shader_parameter("deep_shadow_threshold", 0.06)
						toon.set_shader_parameter("ambient_strength", 0.50)
					elif "hair" in lower_name:
						toon.set_shader_parameter("is_hair", true)
						toon.set_shader_parameter("hair_specular_power", 96.0)
						toon.set_shader_parameter("ambient_strength", 0.50)
					child.set_surface_override_material(s_idx, toon)

		# Attach Ellen's iconic Shark Tail to the skeleton hips / root
		var skels = model_inst.find_children("*", "Skeleton3D", true, false)
		if skels.size() > 0:
			var skel = skels[0] as Skeleton3D
			var hip_bone = "lowerbody"
			if skel.find_bone(hip_bone) == -1:
				hip_bone = "root"
			if skel.find_bone(hip_bone) != -1:
				var bone_attach = BoneAttachment3D.new()
				bone_attach.name = "SharkTailAttachment"
				bone_attach.bone_name = hip_bone
				skel.add_child(bone_attach)

				var tail_scene = load("res://assets/models/ellen_shark_tail.glb")
				if tail_scene:
					var tail_inst = tail_scene.instantiate() as Node3D
					tail_inst.name = "SharkTail"
					tail_inst.scale = Vector3(1.1, 1.1, 1.1)
					tail_inst.position = Vector3(0.0, 0.05, -0.05)
					tail_inst.rotation_degrees = Vector3(-15.0, 180.0, 0.0)
					bone_attach.add_child(tail_inst)
					tail_node = tail_inst

		# Add subtle ice / frost particle aura
		var frost = CPUParticles3D.new()
		frost.name = "FrostAura"
		frost.amount = 14
		frost.lifetime = 1.8
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		var p_mesh = SphereMesh.new()
		p_mesh.radius = 0.02
		p_mesh.height = 0.04
		p_mesh.material = mat
		frost.mesh = p_mesh
		frost.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		frost.emission_sphere_radius = 0.65
		frost.direction = Vector3(0, 1, 0)
		frost.gravity = Vector3(0, 0.15, 0)
		var grad = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
		grad.colors = PackedColorArray([Color(0.2, 0.8, 1.0, 0), Color(0.4, 0.9, 1.0, 0.8), Color(0.7, 0.95, 1.0, 0.6), Color(0.2, 0.7, 1.0, 0.0)])
		frost.color_ramp = grad
		visual_root.add_child(frost)

func _process(delta: float) -> void:
	bob_time += delta
	# Gentle shark tail sway
	if tail_node:
		tail_node.rotation_degrees.y = 180.0 + sin(bob_time * 2.2) * 12.0
		tail_node.rotation_degrees.z = cos(bob_time * 1.8) * 4.0

func _unhandled_input(event: InputEvent) -> void:
	if is_player_nearby and not is_recruited:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.is_pressed() and not event.is_echo() and event.keycode == KEY_F):
			get_viewport().set_input_as_handled()
			_trigger_dialogue()

func _trigger_dialogue() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Smoothly orient Ellen towards the player
	var dir_to_player = (player.global_position - global_position)
	dir_to_player.y = 0
	if dir_to_player.length() > 0.1:
		visual_root.rotation.y = atan2(dir_to_player.x, dir_to_player.z)

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
	if action == "recruit" and not is_recruited:
		is_recruited = true
		SoundSynth.play_voice_ellen_accept()
		
		var player = get_tree().get_first_node_in_group("player")
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
	if prompt_label:
		prompt_label.visible = is_player_nearby and not is_recruited
		prompt_label.text = "[F] Поговорить  |  Эллен Джо (Victoria Housekeeping)"
