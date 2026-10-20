extends Node3D

@onready var character_rotator: Node3D = $CharacterRotator
@onready var particles: CPUParticles3D = $ElementalParticles
@onready var camera_node: Camera3D = $Camera3D

var anim_player: AnimationPlayer = null
var current_char_id: String = "hutao"
var current_model_inst: Node3D = null

var idle_action_timer: float = 4.0
var is_performing_special: bool = false
var special_animations: Array[String] = ["Cheer", "Spellcast_Raise", "Use_Item", "Interact"]

var base_y: float = 0.0

# Genshin Zoom Parameters
var target_zoom: float = 2.35
var min_zoom: float = 1.10 # Close-up view of face, eyes, and hair
var max_zoom: float = 3.30 # Full length view with pedestal

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_y = character_rotator.position.y
	_setup_character_animation()
	_apply_genshin_cel_shading()

func set_preview_character(char_id: String) -> void:
	if char_id == current_char_id and current_model_inst:
		return
	current_char_id = char_id

	# Clear previous model
	for child in character_rotator.get_children():
		child.queue_free()

	var scene_path = "res://scenes/chibi_heroine_model.tscn"
	if char_id == "ellen":
		scene_path = "res://scenes/ellen_joe_model.tscn"

	var sc = load(scene_path)
	if sc:
		current_model_inst = sc.instantiate() as Node3D
		character_rotator.add_child(current_model_inst)

	# Update elemental aura particles
	if particles:
		var grad = Gradient.new()
		if char_id == "ellen":
			grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
			grad.colors = PackedColorArray([
				Color(0.3, 0.85, 1.0, 0.9),
				Color(0.1, 0.55, 0.95, 0.75),
				Color(0.05, 0.25, 0.6, 0.4),
				Color(0.0, 0.1, 0.3, 0.0)
			])
		else:
			grad.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 0.85, 1.0])
			grad.colors = PackedColorArray([
				Color(1.0, 0.95, 0.3, 0.95),
				Color(1.0, 0.55, 0.1, 0.9),
				Color(0.9, 0.18, 0.05, 0.75),
				Color(0.45, 0.08, 0.02, 0.4),
				Color(0.2, 0.02, 0.02, 0.0)
			])
		particles.color_ramp = grad

	_setup_character_animation()
	_apply_genshin_cel_shading()

func _setup_character_animation() -> void:
	var players = character_rotator.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		anim_player = players[0]
		if anim_player.has_animation("Idle"):
			var anim = anim_player.get_animation("Idle")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play("Idle")
		if not anim_player.animation_finished.is_connected(_on_animation_finished):
			anim_player.animation_finished.connect(_on_animation_finished)

func _apply_genshin_cel_shading() -> void:
	var shader = load("res://scripts/genshin_cel_shader.gdshader")
	if not shader:
		return

	# Hide EyeStar highlight to reveal authentic iris without white polygon glare
	var star_mesh = character_rotator.find_child("EyeStar", true, false)
	if star_mesh:
		star_mesh.visible = false

	# Apply cel-shader to all mesh instances inside the preview model
	for child in character_rotator.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.mesh:
			var lower_name = str(child.name).to_lower()
			for surface_idx in range(child.mesh.get_surface_count()):
				var mat = child.get_active_material(surface_idx)
				var toon_mat = ShaderMaterial.new()
				toon_mat.shader = shader
				if mat is StandardMaterial3D:
					if mat.albedo_texture:
						toon_mat.set_shader_parameter("use_texture", true)
						toon_mat.set_shader_parameter("albedo_texture", mat.albedo_texture)
						toon_mat.set_shader_parameter("albedo_color", Color.WHITE)
					else:
						toon_mat.set_shader_parameter("use_texture", false)
						toon_mat.set_shader_parameter("albedo_color", mat.albedo_color)
				elif mat is ShaderMaterial:
					continue

				var mat_name = mat.resource_name.to_lower() if mat else ""
				var is_hair = ("hair" in lower_name) or ("hair" in mat_name) or (lower_name == "body" and surface_idx == 0)
				var is_eye = ("brow" in lower_name) or ("eye" in lower_name)
				var is_face = ("face" in lower_name) and not is_eye

				if is_hair:
					toon_mat.set_shader_parameter("is_hair", true)
					toon_mat.set_shader_parameter("hair_specular_power", 96.0)
					toon_mat.set_shader_parameter("ambient_strength", 0.48)
					toon_mat.set_shader_parameter("shadow_threshold", 0.32)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.14)
				elif is_eye:
					toon_mat.set_shader_parameter("is_eye", true)
					toon_mat.set_shader_parameter("shadow_threshold", 0.18)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.06)
					toon_mat.set_shader_parameter("ambient_strength", 0.50)
					toon_mat.set_shader_parameter("use_alpha_scissor", true)
					toon_mat.set_shader_parameter("alpha_scissor_threshold", 0.25)
				elif is_face:
					toon_mat.set_shader_parameter("is_face", true)
					toon_mat.set_shader_parameter("shadow_threshold", 0.22)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.08)
					toon_mat.set_shader_parameter("shadow_softness", 0.06)
					toon_mat.set_shader_parameter("ambient_strength", 0.52)
					toon_mat.set_shader_parameter("shadow_tint", Color(0.95, 0.84, 0.82, 1.0))
				else:
					toon_mat.set_shader_parameter("shadow_threshold", 0.28)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.12)

				child.set_surface_override_material(surface_idx, toon_mat)

func _process(delta: float) -> void:
	# Gentle breathing / floating bob
	var t = Time.get_ticks_msec() * 0.002
	character_rotator.position.y = base_y + sin(t) * 0.012

	# Smooth camera zoom and dynamic vertical framing
	if camera_node:
		camera_node.position.z = lerp(camera_node.position.z, target_zoom, delta * 10.0)
		var t_zoom = inverse_lerp(min_zoom, max_zoom, camera_node.position.z)
		var target_y = lerp(1.14, 0.88, t_zoom)
		camera_node.position.y = lerp(camera_node.position.y, target_y, delta * 10.0)

	# Periodic cute idle reaction in character sheet
	idle_action_timer -= delta
	if idle_action_timer <= 0.0:
		perform_special_idle_action()

func handle_zoom(direction: float) -> void:
	target_zoom = clamp(target_zoom + direction * 0.25, min_zoom, max_zoom)

func handle_drag(relative_x: float) -> void:
	character_rotator.rotation.y += relative_x * 0.01

func perform_special_idle_action() -> void:
	idle_action_timer = randf_range(8.0, 14.0)

	if anim_player:
		var anim_name = special_animations[randi() % special_animations.size()]
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name, 0.25)

	var synth = get_tree().root.get_node_or_null("SoundSynth")
	if synth:
		if current_char_id == "ellen":
			synth.play_voice_ellen_greet()
		else:
			if randf() < 0.4:
				synth.play_voice_pyro_idle(self)
			else:
				synth.play_voice_menu_idle(self)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != "Idle":
		if anim_player and anim_player.has_animation("Idle"):
			anim_player.play("Idle", 0.35)
		is_performing_special = false

func reset_preview() -> void:
	is_performing_special = false
	idle_action_timer = randf_range(4.0, 8.0)
	target_zoom = 2.35
	if character_rotator:
		character_rotator.rotation.y = 0.0
	if camera_node:
		camera_node.position.z = 2.35
		camera_node.position.y = 0.9
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle", 0.2)
