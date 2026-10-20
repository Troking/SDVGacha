extends Node3D

@onready var character_root: Node3D = $CharacterRoot

var face_eye_mesh: MeshInstance3D = null
var eye_star_mesh: MeshInstance3D = null
var skeleton: Skeleton3D = null
var head_bone_idx: int = -1

var blink_shape_l_idx: int = -1
var blink_shape_r_idx: int = -1

var hair_materials: Array[ShaderMaterial] = []
var eye_materials: Array[ShaderMaterial] = []

# Hair Physics Simulation
var last_global_pos: Vector3 = Vector3.ZERO
var last_rot_y: float = 0.0
var hair_inertia: Vector3 = Vector3.ZERO
var hair_target_inertia: Vector3 = Vector3.ZERO

# Blinking System (Organic Eyelid Motion)
var blink_timer: float = 2.8
var is_blinking: bool = false
var blink_time: float = 0.0
var blink_duration: float = 0.14
var is_double_blink: bool = false
var double_blink_queued: bool = false

# Looking Around / Gaze Saccades
var gaze_timer: float = 2.2
var current_gaze: Vector2 = Vector2.ZERO
var target_gaze: Vector2 = Vector2.ZERO
var head_offset_rot: Quaternion = Quaternion.IDENTITY

func _ready() -> void:
	# Run after AnimationPlayer (AnimationPlayer has priority 0 by default)
	process_priority = 10
	
	_apply_genshin_shading()
	_play_preview_idle()
	_setup_mesh_references()

	last_global_pos = global_position
	last_rot_y = global_rotation.y

func _setup_mesh_references() -> void:
	face_eye_mesh = find_child("Face_Eye", true, false) as MeshInstance3D
	eye_star_mesh = find_child("EyeStar", true, false) as MeshInstance3D
	if eye_star_mesh:
		eye_star_mesh.visible = false
	skeleton = find_child("Skeleton3D", true, false) as Skeleton3D

	if face_eye_mesh and face_eye_mesh.mesh:
		# Prefer WinkB (cute rounded curved eyelid blink), fallback to WinkA
		blink_shape_l_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkB_L")
		blink_shape_r_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkB_R")
		if blink_shape_l_idx < 0:
			blink_shape_l_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkA_L")
		if blink_shape_r_idx < 0:
			blink_shape_r_idx = face_eye_mesh.find_blend_shape_by_name("Eye_WinkA_R")

	if skeleton:
		head_bone_idx = skeleton.find_bone("head")

func _play_preview_idle() -> void:
	var anim_players = find_children("*", "AnimationPlayer", true, false)
	if anim_players.size() > 0:
		var ap = anim_players[0] as AnimationPlayer
		if ap.has_animation("Idle"):
			var anim = ap.get_animation("Idle")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			ap.play("Idle")

func _apply_genshin_shading() -> void:
	var shader = load("res://scripts/genshin_cel_shader.gdshader")
	if not shader:
		return

	hair_materials.clear()
	eye_materials.clear()

	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.mesh:
			var lower_name = str(child.name).to_lower()
			for s_idx in range(child.mesh.get_surface_count()):
				var mat = child.get_active_material(s_idx)
				var mat_name = mat.resource_name.to_lower() if mat else ""
				var toon = ShaderMaterial.new()
				toon.shader = shader
				var is_transparent = false
				
				if mat is StandardMaterial3D:
					if mat.albedo_texture:
						toon.set_shader_parameter("use_texture", true)
						toon.set_shader_parameter("albedo_texture", mat.albedo_texture)
						toon.set_shader_parameter("albedo_color", Color.WHITE)
					else:
						toon.set_shader_parameter("use_texture", false)
						toon.set_shader_parameter("albedo_color", mat.albedo_color)
					if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
						is_transparent = true

				var is_hair_surf = ("hair" in lower_name) or ("hair" in mat_name) or (lower_name == "body" and s_idx == 0)
				var is_eye_surf = ("eye" in lower_name) or ("brow" in lower_name)
				var is_face_surf = ("face" in lower_name) and not is_eye_surf

				if is_hair_surf:
					toon.set_shader_parameter("is_hair", true)
					toon.set_shader_parameter("hair_specular_power", 96.0)
					toon.set_shader_parameter("hair_wind_strength", 1.0)
					toon.set_shader_parameter("shadow_threshold", 0.30)
					toon.set_shader_parameter("deep_shadow_threshold", 0.12)
					toon.set_shader_parameter("shadow_tint", Color(0.55, 0.42, 0.45, 1.0))
					toon.set_shader_parameter("deep_shadow_tint", Color(0.38, 0.28, 0.32, 1.0))
					hair_materials.append(toon)
				elif is_eye_surf:
					toon.set_shader_parameter("is_eye", true)
					toon.set_shader_parameter("shadow_threshold", 0.18)
					toon.set_shader_parameter("deep_shadow_threshold", 0.06)
					toon.set_shader_parameter("ambient_strength", 0.50)
					toon.set_shader_parameter("use_alpha_scissor", true)
					toon.set_shader_parameter("alpha_scissor_threshold", 0.25)
					eye_materials.append(toon)
				elif is_face_surf:
					toon.set_shader_parameter("is_face", true)
					toon.set_shader_parameter("shadow_threshold", 0.24)
					toon.set_shader_parameter("deep_shadow_threshold", 0.10)
					toon.set_shader_parameter("shadow_softness", 0.05)
					toon.set_shader_parameter("ambient_strength", 0.50)
					toon.set_shader_parameter("shadow_tint", Color(0.94, 0.82, 0.80, 1.0))
					toon.set_shader_parameter("deep_shadow_tint", Color(0.85, 0.70, 0.70, 1.0))
				elif "body" in lower_name or "body" in mat_name:
					toon.set_shader_parameter("shadow_threshold", 0.28)
					toon.set_shader_parameter("deep_shadow_threshold", 0.12)
					toon.set_shader_parameter("shadow_softness", 0.05)
					toon.set_shader_parameter("ambient_strength", 0.50)
					toon.set_shader_parameter("shadow_tint", Color(0.65, 0.60, 0.68, 1.0))
					toon.set_shader_parameter("deep_shadow_tint", Color(0.48, 0.44, 0.52, 1.0))

				child.set_surface_override_material(s_idx, toon)

func _process(delta: float) -> void:
	if delta <= 0.0:
		return

	_update_hair_physics(delta)
	_update_blinking(delta)
	_update_gaze_and_head(delta)

# ==================== 1. HAIR PHYSICS SIMULATION ====================

func _update_hair_physics(delta: float) -> void:
	if hair_materials.is_empty():
		return

	# Calculate linear movement delta in character's local coordinates
	var delta_pos = global_position - last_global_pos
	last_global_pos = global_position

	# Transform delta_pos into local space
	var inv_basis = global_transform.basis.inverse()
	var local_movement = inv_basis * delta_pos
	var current_velocity = local_movement / delta

	# Angular rotation delta
	var current_rot_y = global_rotation.y
	var delta_rot_y = wrapf(current_rot_y - last_rot_y, -PI, PI)
	last_rot_y = current_rot_y
	var angular_velocity = delta_rot_y / delta

	# Inertia targets:
	# Running forward: hair drags backwards (-Z) and floats slightly (+Y)
	# Jumping up: hair dips down (-Y), falling down: hair floats up (+Y)
	# Turning left/right: hair swings outward (opposite of turn)
	var target_x = clamp(-angular_velocity * 0.14 - current_velocity.x * 0.04, -0.28, 0.28)
	var target_y = clamp(current_velocity.y * -0.025, -0.15, 0.22)
	var target_z = clamp(current_velocity.z * 0.045, -0.32, 0.35)

	hair_target_inertia = Vector3(target_x, target_y, target_z)

	# Spring damping interpolation for natural elastic swaying
	hair_inertia = hair_inertia.lerp(hair_target_inertia, delta * 11.5)

	# Feed into hair shader materials
	for mat in hair_materials:
		if is_instance_valid(mat):
			mat.set_shader_parameter("hair_inertia", hair_inertia)

# ==================== 2. ORGANIC BLINKING SYSTEM ====================

func _update_blinking(delta: float) -> void:
	if not face_eye_mesh or blink_shape_l_idx < 0:
		return

	if not is_blinking:
		blink_timer -= delta
		if blink_timer <= 0.0:
			_start_blink()
	else:
		blink_time += delta
		var progress = blink_time / blink_duration
		
		# Smooth cosine curve: 0 -> 1 -> 0
		var blink_weight = 0.0
		if progress <= 0.45:
			# Fast, organic eyelid snap shut
			blink_weight = sin((progress / 0.45) * (PI * 0.5))
		elif progress <= 0.55:
			# Brief microscopic hold
			blink_weight = 1.0
		elif progress <= 1.0:
			# Slightly slower, gentler reopen
			var p_open = (progress - 0.55) / 0.45
			blink_weight = cos(p_open * (PI * 0.5))
		else:
			blink_weight = 0.0
			is_blinking = false
			if double_blink_queued:
				double_blink_queued = false
				blink_timer = randf_range(0.08, 0.16) # Immediate second blink
			else:
				blink_timer = randf_range(2.6, 5.2)

		# Apply blend shape weight to eyelids
		face_eye_mesh.set_blend_shape_value(blink_shape_l_idx, blink_weight)
		face_eye_mesh.set_blend_shape_value(blink_shape_r_idx, blink_weight)

		# EyeStar is hidden to keep natural authentic Hu Tao plum blossom pupils
		if eye_star_mesh:
			eye_star_mesh.visible = false

func _start_blink() -> void:
	is_blinking = true
	blink_time = 0.0
	blink_duration = randf_range(0.12, 0.16)
	# 18% chance of charming double-blink
	double_blink_queued = (randf() < 0.18)

# ==================== 3. LOOKING AROUND & HEAD RIG ====================

func _update_gaze_and_head(delta: float) -> void:
	# Periodic saccade target selection (looking around curiously)
	gaze_timer -= delta
	if gaze_timer <= 0.0:
		gaze_timer = randf_range(1.8, 4.2)
		var rand_choice = randf()
		if rand_choice < 0.35:
			# Look straight ahead
			target_gaze = Vector2.ZERO
		elif rand_choice < 0.55:
			# Glance left
			target_gaze = Vector2(randf_range(-0.85, -0.40), randf_range(-0.15, 0.20))
		elif rand_choice < 0.75:
			# Glance right
			target_gaze = Vector2(randf_range(0.40, 0.85), randf_range(-0.15, 0.20))
		elif rand_choice < 0.88:
			# Look slightly up / curious glance
			target_gaze = Vector2(randf_range(-0.3, 0.3), randf_range(0.45, 0.85))
		else:
			# Look down thoughtfully
			target_gaze = Vector2(randf_range(-0.3, 0.3), randf_range(-0.65, -0.30))

	# Fast, snappy eye saccade movement
	current_gaze = current_gaze.lerp(target_gaze, delta * 12.0)

	# Update eye shader offset
	for mat in eye_materials:
		if is_instance_valid(mat):
			mat.set_shader_parameter("eye_gaze_offset", current_gaze)

	# Procedural organic Head Bone tracking & breathing micro-tilt
	if skeleton and head_bone_idx >= 0:
		# Subtle head turn and tilt matching gaze
		var target_yaw = clamp(current_gaze.x * deg_to_rad(18.0), deg_to_rad(-16.0), deg_to_rad(16.0))
		var target_pitch = clamp(-current_gaze.y * deg_to_rad(11.0), deg_to_rad(-10.0), deg_to_rad(12.0))
		# Cute anime side-tilt (curiosity roll)
		var target_roll = clamp(current_gaze.x * deg_to_rad(-4.5), deg_to_rad(-4.0), deg_to_rad(4.0))

		# Add subtle breathing cycle oscillation
		var breath = sin(Time.get_ticks_msec() * 0.0022) * deg_to_rad(1.2)
		target_pitch += breath

		var target_quat = Quaternion.from_euler(Vector3(target_pitch, target_yaw, target_roll))
		head_offset_rot = head_offset_rot.slerp(target_quat, delta * 4.5)

		# Blend smoothly on top of active AnimationPlayer pose
		var anim_rot = skeleton.get_bone_pose_rotation(head_bone_idx)
		skeleton.set_bone_pose_rotation(head_bone_idx, anim_rot * head_offset_rot)
