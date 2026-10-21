extends Node3D

@onready var character_root: Node3D = $CharacterRoot

var face_eye_mesh: MeshInstance3D = null
var eye_star_mesh: MeshInstance3D = null
var skeleton: Skeleton3D = null
var head_bone_idx: int = -1
var hips_bone_idx: int = -1
var hand_r_bone_idx: int = -1

var blink_shape_l_idx: int = -1
var blink_shape_r_idx: int = -1

var hair_materials: Array[ShaderMaterial] = []
var eye_materials: Array[ShaderMaterial] = []
var body_materials: Array[ShaderMaterial] = []

# Attachments
var headdress_node: Node3D = null
var tail_node: Node3D = null
var tail_material: ShaderMaterial = null
var weapon_node: Node3D = null

# Tail Sway Physics
var tail_sway_time: float = 0.0
var last_global_pos: Vector3 = Vector3.ZERO
var tail_inertia: float = 0.0
var current_tail_rot: Vector3 = Vector3.ZERO

# Blinking System (Ellen's cool, slightly sleepy half-lidded gaze)
var blink_timer: float = 3.5
var is_blinking: bool = false
var blink_time: float = 0.0
var blink_duration: float = 0.16

# Gaze Saccades
var gaze_timer: float = 2.5
var current_gaze: Vector2 = Vector2.ZERO
var target_gaze: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_priority = 10
	_setup_model_and_rig()
	_apply_ellen_cel_shading()
	_setup_attachments()
	_play_preview_idle()

	last_global_pos = global_position

func _setup_model_and_rig() -> void:
	skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	face_eye_mesh = find_child("Face_Eye", true, false) as MeshInstance3D
	eye_star_mesh = find_child("EyeStar", true, false) as MeshInstance3D
	if eye_star_mesh:
		eye_star_mesh.visible = false

	if face_eye_mesh and face_eye_mesh.mesh:
		blink_shape_l_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkB_L")
		blink_shape_r_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkB_R")
		if blink_shape_l_idx < 0:
			blink_shape_l_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkA_L")
		if blink_shape_r_idx < 0:
			blink_shape_r_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkA_R")

	if skeleton:
		head_bone_idx = skeleton.find_bone("head")
		hips_bone_idx = skeleton.find_bone("hips")
		hand_r_bone_idx = skeleton.find_bone("handslot.r")

func _setup_attachments() -> void:
	if not skeleton:
		return

	# 1. Maid Headdress & Shark Fin Clip on Head
	var head_att = BoneAttachment3D.new()
	head_att.name = "HeadAttachment"
	head_att.bone_name = "head"
	skeleton.add_child(head_att)

	var headdress_scene = load("res://assets/models/ellen_maid_headdress.glb")
	if headdress_scene:
		headdress_node = headdress_scene.instantiate() as Node3D
		# Fine-tune position relative to head bone
		headdress_node.position = Vector3(0, -1.22, 0.02)
		head_att.add_child(headdress_node)

	# 2. Ellen's Massive Shark Tail on Hips
	var hips_att = BoneAttachment3D.new()
	hips_att.name = "HipsAttachment"
	hips_att.bone_name = "hips"
	skeleton.add_child(hips_att)

	var tail_scene = load("res://assets/models/ellen_shark_tail.glb")
	if tail_scene:
		tail_node = tail_scene.instantiate() as Node3D
		tail_node.name = "SharkTail"
		# Position naturally at Ellen's sacrum (lower back)
		tail_node.position = Vector3(0.0, -0.04, -0.08)
		tail_node.rotation_degrees = Vector3.ZERO
		tail_node.scale = Vector3.ONE
		hips_att.add_child(tail_node)

		# Add cold frost particles to the caudal fin tip
		var frost = CPUParticles3D.new()
		frost.name = "TailFrost"
		frost.position = Vector3(0.0, -0.15, -1.30)
		frost.amount = 14
		frost.lifetime = 1.1
		frost.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		frost.emission_sphere_radius = 0.15
		frost.gravity = Vector3(0, 0.15, 0)
		frost.initial_velocity_min = 0.2
		frost.initial_velocity_max = 0.5
		frost.scale_amount_min = 0.6
		frost.scale_amount_max = 1.4

		var grad = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		grad.colors = PackedColorArray([
			Color(0.4, 0.9, 1.0, 0.8),
			Color(0.1, 0.5, 0.9, 0.5),
			Color(0.0, 0.2, 0.6, 0.0)
		])
		frost.color_ramp = grad

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
		tail_node.add_child(frost)

	# 3. Giant Shark Shears Weapon on Right Hand
	var hand_att = BoneAttachment3D.new()
	hand_att.name = "HandAttachment"
	hand_att.bone_name = "handslot.r"
	skeleton.add_child(hand_att)

	var weapon_scene = load("res://assets/models/ellen_shark_shears.glb")
	if weapon_scene:
		weapon_node = weapon_scene.instantiate() as Node3D
		weapon_node.name = "SharkShears"
		weapon_node.position = Vector3(0, 0.05, 0)
		weapon_node.rotation_degrees = Vector3(0, 90, 0)
		weapon_node.scale = Vector3(0.85, 0.85, 0.85)
		weapon_node.visible = false # Summoned during attacks
		hand_att.add_child(weapon_node)

func _apply_ellen_cel_shading() -> void:
	var shader = load("res://scripts/genshin_cel_shader.gdshader")
	if not shader:
		return

	hair_materials.clear()
	eye_materials.clear()
	body_materials.clear()

	var hair_tex = load("res://assets/textures/ellen_hair_diffuse.png")
	var body_tex = load("res://assets/textures/ellen_body_diffuse.png")
	var face_tex = load("res://assets/textures/ellen_face_diffuse.png")

	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.mesh:
			var lower_name = str(child.name).to_lower()
			for s_idx in range(child.mesh.get_surface_count()):
				var mat = child.get_active_material(s_idx)
				var mat_name = mat.resource_name.to_lower() if mat else ""
				var toon = ShaderMaterial.new()
				toon.shader = shader

				var is_hair_surf = ("hair" in lower_name) or ("hair" in mat_name) or (lower_name == "body" and s_idx == 0)
				var is_eye_surf = ("eye" in lower_name) or ("brow" in lower_name)
				var is_face_surf = ("face" in lower_name) and not is_eye_surf
				var is_body_surf = ("body" in lower_name or "body" in mat_name) and s_idx == 1

				if is_hair_surf:
					toon.set_shader_parameter("use_texture", true)
					toon.set_shader_parameter("albedo_texture", hair_tex)
					toon.set_shader_parameter("albedo_color", Color.WHITE)
					toon.set_shader_parameter("is_hair", true)
					toon.set_shader_parameter("hair_specular_power", 96.0)
					toon.set_shader_parameter("shadow_threshold", 0.32)
					toon.set_shader_parameter("deep_shadow_threshold", 0.14)
					toon.set_shader_parameter("shadow_tint", Color(0.20, 0.15, 0.22, 1.0))
					toon.set_shader_parameter("deep_shadow_tint", Color(0.12, 0.08, 0.14, 1.0))
					toon.set_shader_parameter("use_alpha_scissor", true)
					toon.set_shader_parameter("alpha_scissor_threshold", 0.5)
					hair_materials.append(toon)
				elif is_eye_surf:
					toon.set_shader_parameter("use_texture", true)
					toon.set_shader_parameter("albedo_texture", face_tex)
					toon.set_shader_parameter("albedo_color", Color.WHITE)
					toon.set_shader_parameter("is_eye", true)
					toon.set_shader_parameter("shadow_threshold", 0.18)
					toon.set_shader_parameter("deep_shadow_threshold", 0.06)
					toon.set_shader_parameter("use_alpha_scissor", true)
					toon.set_shader_parameter("alpha_scissor_threshold", 0.25)
					eye_materials.append(toon)
				elif is_face_surf:
					toon.set_shader_parameter("use_texture", true)
					toon.set_shader_parameter("albedo_texture", face_tex)
					toon.set_shader_parameter("albedo_color", Color.WHITE)
					toon.set_shader_parameter("is_face", true)
					toon.set_shader_parameter("shadow_threshold", 0.22)
					toon.set_shader_parameter("deep_shadow_threshold", 0.08)
					toon.set_shader_parameter("shadow_tint", Color(0.95, 0.84, 0.82, 1.0))
				elif is_body_surf:
					toon.set_shader_parameter("use_texture", true)
					toon.set_shader_parameter("albedo_texture", body_tex)
					toon.set_shader_parameter("albedo_color", Color.WHITE)
					toon.set_shader_parameter("shadow_threshold", 0.30)
					toon.set_shader_parameter("deep_shadow_threshold", 0.14)
					body_materials.append(toon)
				else:
					if mat is StandardMaterial3D and mat.albedo_texture:
						toon.set_shader_parameter("use_texture", true)
						toon.set_shader_parameter("albedo_texture", mat.albedo_texture)
					toon.set_shader_parameter("albedo_color", Color.WHITE)

				child.set_surface_override_material(s_idx, toon)

func _play_preview_idle() -> void:
	var anim_players = find_children("*", "AnimationPlayer", true, false)
	if anim_players.size() > 0:
		var ap = anim_players[0] as AnimationPlayer
		if ap.has_animation("Idle"):
			var anim = ap.get_animation("Idle")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			ap.play("Idle")

func _process(delta: float) -> void:
	tail_sway_time += delta
	_update_shark_tail(delta)
	_update_blinking(delta)

func _update_shark_tail(delta: float) -> void:
	if not tail_node:
		return

	# Movement tracking
	var move_delta = (global_position - last_global_pos)
	last_global_pos = global_position
	var move_speed = move_delta.length() / max(delta, 0.001)
	tail_inertia = lerp(tail_inertia, move_speed, delta * 4.5)

	# Lateral inertia from turning and strafing
	var right = global_transform.basis.x
	var lat_accel = right.dot(move_delta) / max(delta, 0.001)

	# Smooth canonical predatory shark tail secondary physics:
	# Idle: slow, heavy, breathing sway
	# Motion: hydrodynamic fluid undulating wave lagging behind player rotation
	var is_moving = tail_inertia > 0.35
	var sway_freq = 1.35 if not is_moving else (2.0 + clamp(tail_inertia * 0.4, 0.0, 2.5))
	var sway_amp = 3.6 if not is_moving else clamp(4.0 + tail_inertia * 1.5, 4.0, 11.0)

	var sway_yaw = sin(tail_sway_time * sway_freq) * sway_amp
	var sway_roll = cos(tail_sway_time * (sway_freq * 0.85)) * (sway_amp * 0.28)
	var sway_pitch = sin(tail_sway_time * (sway_freq * 1.6)) * (1.2 if not is_moving else 2.2)

	# Centrifugal/lateral turn lag
	var turn_lag = clamp(-lat_accel * 3.5, -15.0, 15.0)

	# Forward motion causes the heavy tail to streamline behind (-Y resting droop decreases)
	var stream_lift = clamp(tail_inertia * 1.0, 0.0, 4.5)
	var target_pitch = -3.0 + stream_lift + sway_pitch
	var target_yaw = turn_lag + sway_yaw
	var target_roll = sway_roll

	var target_rot = Vector3(target_pitch, target_yaw, target_roll)
	current_tail_rot = current_tail_rot.lerp(target_rot, delta * 9.0)
	tail_node.rotation_degrees = current_tail_rot

func _update_blinking(delta: float) -> void:
	if not face_eye_mesh or blink_shape_l_idx < 0:
		return

	if not is_blinking:
		blink_timer -= delta
		if blink_timer <= 0.0:
			is_blinking = true
			blink_time = 0.0
			blink_duration = randf_range(0.13, 0.18)
	else:
		blink_time += delta
		var p = blink_time / blink_duration
		var w = 0.0
		if p <= 0.45:
			w = sin((p / 0.45) * (PI * 0.5))
		elif p <= 0.55:
			w = 1.0
		elif p <= 1.0:
			w = cos(((p - 0.55) / 0.45) * (PI * 0.5))
		else:
			is_blinking = false
			blink_timer = randf_range(3.0, 6.0)

		face_eye_mesh.set_blend_shape_value(blink_shape_l_idx, w)
		face_eye_mesh.set_blend_shape_value(blink_shape_r_idx, w)

func summon_weapon() -> void:
	if weapon_node:
		weapon_node.visible = true
		weapon_node.scale = Vector3(0.1, 0.1, 0.1)
		var tw = create_tween()
		tw.tween_property(weapon_node, "scale", Vector3(0.85, 0.85, 0.85), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func dissolve_weapon() -> void:
	if weapon_node and weapon_node.visible:
		var tw = create_tween()
		tw.tween_property(weapon_node, "scale", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if weapon_node:
				weapon_node.visible = false
		)
