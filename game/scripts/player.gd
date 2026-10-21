extends CharacterBody3D
class_name ChibiPlayer

const TEX_MAGIC_CIRCLE = preload("res://assets/textures/magic_circle_pyro.png")
const TEX_PYRO_BUTTERFLY = preload("res://assets/textures/fx_pyro_butterfly.png")
const TEX_CRYO_SNOWFLAKE = preload("res://assets/textures/fx_cryo_snowflake.png")
const TEX_ASCENSION_RING = preload("res://assets/textures/fx_ascension_ring.png")
const TEX_LIGHT_SHAFT = preload("res://assets/textures/fx_light_shaft.png")
const TEX_CELESTIAL_SPARKLE = preload("res://assets/textures/fx_celestial_sparkle.png")

signal stats_changed(hp: int, max_hp: int, exp_val: int, exp_to_next: int, level: int, attack_val: int)
signal level_up_event(new_level: int, new_hp: int, new_atk: int)
signal exp_gained_event(amount: int)
signal skill_cooldown_updated(remaining: float, total: float)
signal message_logged(text: String)

@export var speed: float = 7.0
@export var rotation_speed: float = 12.0
@export var mouse_sensitivity: float = 0.003
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.22
@export var jump_velocity: float = 8.5

# Camera zoom
@export var min_zoom: float = 2.0
@export var max_zoom: float = 9.0
@export var zoom_step: float = 0.5

var max_hp: int = 100
var current_hp: int = 100
var level: int = 1
var current_exp: int = 0
var exp_to_next: int = 50
var attack_power: int = 15

var locked_target: Node3D = null
var is_attacking: bool = false
var can_attack: bool = true

# Combo & Charged Attack System
var combo_stage: int = 0 # 0, 1, 2 = light strikes, 3 = heavy finisher
var combo_reset_timer: float = 0.0
const COMBO_WINDOW: float = 1.05

var is_attack_pressed: bool = false
var attack_press_time: float = 0.0
var has_unleashed_charged_in_press: bool = false
var is_charging_attack: bool = false
const CHARGE_HOLD_THRESHOLD: float = 0.20
const MAX_CHARGE_DURATION: float = 0.42
var charge_fx_root: Node3D = null

# Dash state
var is_dashing: bool = false
var can_dash: bool = true
var is_invulnerable: bool = false
var dash_direction: Vector3 = Vector3.ZERO
var dash_cooldown: float = 0.8

# Elemental Skill State (E Key)
var can_use_skill: bool = true
var skill_cooldown: float = 6.0
var skill_cooldown_timer: float = 0.0
var is_casting_skill: bool = false
var skill_can_cancel: bool = false

# Death & low hp state
var is_dead: bool = false
var last_low_hp_alert_time: float = -999.0

# Camera pitch limits
var camera_pitch: float = -0.30
var min_pitch: float = deg_to_rad(-75.0)
var max_pitch: float = deg_to_rad(30.0)

# Genshin Climbing State
var is_climbing: bool = false
var climb_speed: float = 3.6
var climb_normal: Vector3 = Vector3.ZERO
var climb_voice_timer: float = 0.0
var climb_cooldown: float = 0.0
var wall_loss_timer: float = 0.0

# Genshin Wind Glider State
var is_gliding: bool = false
var glider_node: Node3D = null
var glider_wind_player: AudioStreamPlayer3D = null
var glider_particles_l: CPUParticles3D = null
var glider_particles_r: CPUParticles3D = null
var air_time: float = 0.0
var can_reopen_glider: bool = true
var glide_forward_speed: float = 8.8
var glide_fall_speed: float = 2.1
var glider_tween: Tween = null

# Swimming State
var is_swimming: bool = false
var water_surface_y: float = -0.45
var swim_speed: float = 4.8
var swim_fast_speed: float = 7.4
var swim_stroke_timer: float = 0.0
var swim_ripple_timer: float = 0.0
var has_snapped_ground: bool = false

# Movement animation variables
var move_anim_time: float = 0.0

# State sound timers
var step_timer: float = 0.0
var idle_voice_timer: float = 240.0 # Periodic cute idle hums while standing (very rare, 225-390s)
var run_breath_timer: float = 0.0

var anim_player: AnimationPlayer = null
var current_anim: String = ""
var attack_anim_index: int = 0

@onready var visual_mesh: Node3D = $Visual
@onready var anime_model: Node3D = $Visual/AnimeModel
@onready var arm_pivot: Node3D = $Visual/ArmPivot
@onready var attack_area: Area3D = $AttackArea
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_node: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var is_game_active: bool = true
var attack_stuck_watchdog: float = 0.0

# Genshin Weapon Summon & Dissolve System
var weapon_node: Node3D = null
var weapon_dissolve_timer: float = 0.0
var is_weapon_summoned: bool = false
var weapon_tween: Tween = null
const WEAPON_SUMMON_SCALE: Vector3 = Vector3(0.75, 0.75, 0.75)
const WEAPON_IDLE_DISSOLVE_DELAY: float = 2.4

# Squad & Party System (Hotkeys 1-9 & Ellen Joe)
signal party_switched(char_id: String, slot_idx: int)
signal party_member_recruited(char_id: String)

var party_members: Array[String] = ["hutao"]
var active_party_index: int = 0
var current_character_id: String = "hutao"
var ellen_model_node: Node3D = null
var ellen_tail_node: Node3D = null
var current_element: String = "PYRO"

# Dialogue Camera System
var is_in_dialogue: bool = false
var dialogue_saved_pivot_rot: Vector3 = Vector3.ZERO
var dialogue_saved_spring_len: float = 4.5
var dialogue_cam_tween: Tween = null
var biome_check_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	camera_pivot.rotation.x = camera_pitch
	emit_stats()
	AccessibilityManager.high_contrast_toggled.connect(_on_contrast_changed)
	_apply_visual_contrast(AccessibilityManager.high_contrast)
	_setup_genshin_cel_shading()
	_setup_animation_player()
	_attach_weapon_to_hand()
	_setup_glider()
	_setup_genshin_camera()
	visual_mesh.rotation.y = PI

	InventoryManager.equipment_changed.connect(func(_s, _d): _recalculate_equipment_stats())
	_recalculate_equipment_stats()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	SoundSynth.set_active_heroine(current_character_id)
	call_deferred("_snap_to_ground_on_start")

func activate_game_controls() -> void:
	is_game_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_animation_player() -> void:
	if not anime_model:
		return
	var players = anime_model.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		anim_player = players[0]
		var loop_anims = ["Idle", "Running_A", "Walking_A", "Jump_Idle", "Interact"]
		for a_name in loop_anims:
			if anim_player.has_animation(a_name):
				var anim = anim_player.get_animation(a_name)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
		play_anim("Idle")

func _attach_weapon_to_hand() -> void:
	if not anime_model or not arm_pivot:
		return
	var skels = anime_model.find_children("*", "Skeleton3D", true, false)
	if skels.size() > 0:
		var skel = skels[0] as Skeleton3D
		var hand_bone = "handslot.r"
		if skel.find_bone(hand_bone) == -1:
			hand_bone = "hand.r"
		if skel.find_bone(hand_bone) != -1:
			var bone_attach = BoneAttachment3D.new()
			bone_attach.name = "WeaponSlotRight"
			bone_attach.bone_name = hand_bone
			skel.add_child(bone_attach)
			arm_pivot.reparent(bone_attach)
			arm_pivot.transform = Transform3D.IDENTITY

			# Remove temporary box mesh and replace with genuine 3D Knight Sword model
			var old_sword = arm_pivot.get_node_or_null("Sword")
			if old_sword:
				old_sword.queue_free()

			var sword_scene = load("res://assets/models/sword_1h.glb")
			if sword_scene:
				var sword_inst = sword_scene.instantiate()
				sword_inst.name = "Sword"
				# In handslot.r local space:
				# Initially dissolved (hidden); summoned seamlessly on attack
				sword_inst.scale = Vector3.ZERO
				sword_inst.visible = false
				# Align sword hilt with palm, blade pointing along the forward attack vector
				sword_inst.position = Vector3(0.0, 0.04, -0.05)
				sword_inst.rotation_degrees = Vector3(90.0, 0.0, 0.0)

				# Add subtle flame aura to the sword
				var flame_aura = CPUParticles3D.new()
				flame_aura.name = "FlameAura"
				flame_aura.amount = 16
				flame_aura.lifetime = 0.35
				var mat = StandardMaterial3D.new()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mat.vertex_color_use_as_albedo = true
				var p_mesh = SphereMesh.new()
				p_mesh.radius = 0.02
				p_mesh.height = 0.04
				p_mesh.material = mat
				flame_aura.mesh = p_mesh
				flame_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
				flame_aura.emission_box_extents = Vector3(0.05, 0.05, 0.35)
				flame_aura.direction = Vector3(0, 1, 0)
				flame_aura.gravity = Vector3(0, 0.8, 0)
				var grad = Gradient.new()
				grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
				grad.colors = PackedColorArray([Color(1, 0.95, 0.4, 0.9), Color(1, 0.5, 0.1, 0.8), Color(0.9, 0.15, 0.05, 0.5), Color(0.2, 0.02, 0.02, 0.0)])
				flame_aura.color_ramp = grad
				sword_inst.add_child(flame_aura)

				arm_pivot.add_child(sword_inst)
				weapon_node = sword_inst
				is_weapon_summoned = false
				weapon_dissolve_timer = 0.0

func summon_weapon() -> void:
	if current_character_id == "ellen" and ellen_model_node and ellen_model_node.has_method("summon_weapon"):
		ellen_model_node.summon_weapon()
		return
	if not weapon_node or not is_instance_valid(weapon_node):
		return
	weapon_dissolve_timer = WEAPON_IDLE_DISSOLVE_DELAY
	if is_weapon_summoned and weapon_node.visible and weapon_node.scale.is_equal_approx(WEAPON_SUMMON_SCALE):
		return
	is_weapon_summoned = true
	weapon_node.visible = true
	if weapon_tween and weapon_tween.is_valid():
		weapon_tween.kill()
	weapon_tween = create_tween()
	weapon_tween.tween_property(weapon_node, "scale", WEAPON_SUMMON_SCALE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func dissolve_weapon() -> void:
	if current_character_id == "ellen" and ellen_model_node and ellen_model_node.has_method("dissolve_weapon"):
		ellen_model_node.dissolve_weapon()
		return
	if not weapon_node or not is_instance_valid(weapon_node) or not is_weapon_summoned:
		return
	is_weapon_summoned = false
	if weapon_tween and weapon_tween.is_valid():
		weapon_tween.kill()
	weapon_tween = create_tween()
	weapon_tween.tween_property(weapon_node, "scale", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	weapon_tween.tween_callback(func():
		if weapon_node and is_instance_valid(weapon_node) and not is_weapon_summoned:
			weapon_node.visible = false
	)

func _update_weapon_visibility(delta: float) -> void:
	if not is_weapon_summoned:
		return
	if is_attacking or is_charging_attack or is_casting_skill:
		weapon_dissolve_timer = WEAPON_IDLE_DISSOLVE_DELAY
		return
	weapon_dissolve_timer -= delta
	if weapon_dissolve_timer <= 0.0:
		dissolve_weapon()

func _update_current_biome(delta: float) -> void:
	biome_check_timer += delta
	if biome_check_timer < 0.35:
		return
	biome_check_timer = 0.0

	var pos = global_position
	var biome = "asian"
	if pos.z < -65.0 and pos.x < -20.0:
		biome = "blight"
	elif pos.z > 65.0 and pos.x > 15.0:
		biome = "cyber"
	elif pos.x >= 10.0 and pos.x <= 50.0 and pos.z >= -60.0 and pos.z <= -20.0:
		biome = "school"

	SoundSynth.update_biome_bgm(biome)

func play_anim(anim_name: String, blend: float = 0.15) -> void:
	if not anim_player or not anim_player.has_animation(anim_name):
		return
	if current_anim != anim_name:
		current_anim = anim_name
		anim_player.play(anim_name, blend)

func _setup_genshin_cel_shading() -> void:
	var shader = load("res://scripts/genshin_cel_shader.gdshader")
	if not shader or not anime_model:
		return

	# Hide EyeStar highlight to reveal authentic plum blossom iris
	var star_mesh = anime_model.find_child("EyeStar", true, false)
	if star_mesh:
		star_mesh.visible = false

	# Apply cel-shader to all mesh instances inside the anime model
	for child in anime_model.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.mesh:
			for surface_idx in range(child.mesh.get_surface_count()):
				var mat = child.get_active_material(surface_idx)
				var toon_mat = ShaderMaterial.new()
				toon_mat.shader = shader
				var is_transparent = false
				if mat is StandardMaterial3D:
					if mat.albedo_texture:
						toon_mat.set_shader_parameter("use_texture", true)
						toon_mat.set_shader_parameter("albedo_texture", mat.albedo_texture)
						toon_mat.set_shader_parameter("albedo_color", Color.WHITE)
					else:
						toon_mat.set_shader_parameter("use_texture", false)
						toon_mat.set_shader_parameter("albedo_color", mat.albedo_color)
					if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
						is_transparent = true

				var lower_name = str(child.name).to_lower()
				var mat_name = mat.resource_name.to_lower() if mat else ""
				var is_hair = ("hair" in lower_name) or ("hair" in mat_name) or (lower_name == "body" and surface_idx == 0)
				var is_eye = ("brow" in lower_name) or ("eye" in lower_name)
				var is_face = ("face" in lower_name) and not is_eye

				if is_hair:
					toon_mat.set_shader_parameter("is_hair", true)
					toon_mat.set_shader_parameter("hair_specular_power", 96.0)
					toon_mat.set_shader_parameter("ambient_strength", 0.50)
					toon_mat.set_shader_parameter("shadow_threshold", 0.30)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.12)
					toon_mat.set_shader_parameter("shadow_tint", Color(0.55, 0.42, 0.45, 1.0))
					toon_mat.set_shader_parameter("deep_shadow_tint", Color(0.38, 0.28, 0.32, 1.0))
				elif is_eye:
					toon_mat.set_shader_parameter("is_eye", true)
					toon_mat.set_shader_parameter("shadow_threshold", 0.18)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.06)
					toon_mat.set_shader_parameter("ambient_strength", 0.50)
					toon_mat.set_shader_parameter("use_alpha_scissor", true)
					toon_mat.set_shader_parameter("alpha_scissor_threshold", 0.25)
				elif is_face:
					toon_mat.set_shader_parameter("is_face", true)
					toon_mat.set_shader_parameter("shadow_threshold", 0.24)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.10)
					toon_mat.set_shader_parameter("shadow_softness", 0.05)
					toon_mat.set_shader_parameter("ambient_strength", 0.50)
					toon_mat.set_shader_parameter("shadow_tint", Color(0.94, 0.82, 0.80, 1.0))
					toon_mat.set_shader_parameter("deep_shadow_tint", Color(0.85, 0.70, 0.70, 1.0))
				elif "body" in lower_name or "body" in mat_name:
					toon_mat.set_shader_parameter("shadow_threshold", 0.44)
					toon_mat.set_shader_parameter("deep_shadow_threshold", 0.18)
					toon_mat.set_shader_parameter("ambient_strength", 0.50)
					toon_mat.set_shader_parameter("shadow_tint", Color(0.68, 0.62, 0.72, 1.0))
					toon_mat.set_shader_parameter("deep_shadow_tint", Color(0.50, 0.45, 0.56, 1.0))

				child.set_surface_override_material(surface_idx, toon_mat)

func _setup_genshin_camera() -> void:
	if spring_arm and camera_node:
		spring_arm.spring_length = 3.2
		camera_node.position = Vector3.ZERO
		camera_node.h_offset = 0.35 # Over-the-shoulder right
		camera_node.v_offset = 0.12 # Eye-level framing

func _setup_glider() -> void:
	var glider_scene = load("res://assets/models/glider_wings.glb")
	if not glider_scene or not visual_mesh:
		return

	glider_node = glider_scene.instantiate()
	glider_node.name = "GliderWings"
	# Positioned on the heroine's upper back
	glider_node.position = Vector3(0.0, 0.86, 0.12)
	glider_node.rotation_degrees = Vector3(-10.0, 0.0, 0.0)
	glider_node.scale = Vector3(0.85, 0.85, 0.85)
	glider_node.visible = false
	visual_mesh.add_child(glider_node)

	# Wind trail ribbons on wingtips
	glider_particles_l = _create_wing_trail(Vector3(-1.55, 0.15, 0.55))
	glider_particles_r = _create_wing_trail(Vector3(1.55, 0.15, 0.55))
	glider_node.add_child(glider_particles_l)
	glider_node.add_child(glider_particles_r)

	# 3D Wind loop audio (gentle, unobtrusive ambient breeze)
	glider_wind_player = AudioStreamPlayer3D.new()
	glider_wind_player.name = "GliderWindLoop"
	glider_wind_player.stream = SoundSynth.glider_wind_stream
	glider_wind_player.volume_db = -22.0
	glider_wind_player.autoplay = false
	glider_node.add_child(glider_wind_player)

func _create_wing_trail(pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.position = pos
	p.amount = 18
	p.lifetime = 0.4
	p.emitting = false

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true

	var sphere = SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	sphere.material = mat
	p.mesh = sphere

	p.direction = Vector3(0, 0, 1)
	p.spread = 15.0
	p.gravity = Vector3(0, -0.2, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.0

	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.8, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.95, 0.7, 0.8),
		Color(1.0, 0.6, 0.2, 0.6),
		Color(0.8, 0.2, 0.05, 0.3),
		Color(0.2, 0.05, 0.0, 0.0)
	])
	p.color_ramp = grad
	return p

func start_gliding() -> void:
	if is_gliding or is_dead or is_climbing or is_on_floor():
		return
	is_gliding = true
	can_reopen_glider = false

	if glider_node:
		glider_node.visible = true
		glider_node.scale = Vector3(0.15, 0.15, 0.15)
		if glider_tween: glider_tween.kill()
		glider_tween = create_tween()
		glider_tween.tween_property(glider_node, "scale", Vector3(0.85, 0.85, 0.85), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if glider_particles_l: glider_particles_l.emitting = true
	if glider_particles_r: glider_particles_r.emitting = true
	if glider_wind_player:
		glider_wind_player.volume_db = -38.0
		if not glider_wind_player.playing:
			glider_wind_player.play()
		var wt = create_tween()
		wt.tween_property(glider_wind_player, "volume_db", -22.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Soften downward plunge on opening
	if velocity.y < -2.0:
		velocity.y = -2.0

	SoundSynth.play_glider_open(self)
	if randf() < 0.15:
		SoundSynth.play_voice_glider(self)
	play_anim("Jump_Idle", 0.15)

func cancel_gliding() -> void:
	if not is_gliding:
		return
	is_gliding = false
	can_reopen_glider = false

	if glider_node:
		if glider_tween: glider_tween.kill()
		glider_tween = create_tween()
		glider_tween.tween_property(glider_node, "scale", Vector3(0.1, 0.1, 0.1), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		glider_tween.tween_callback(func(): if glider_node: glider_node.visible = false)

	if glider_particles_l: glider_particles_l.emitting = false
	if glider_particles_r: glider_particles_r.emitting = false
	if glider_wind_player and glider_wind_player.playing:
		var wt = create_tween()
		wt.tween_property(glider_wind_player, "volume_db", -45.0, 0.20)
		wt.tween_callback(func(): if glider_wind_player: glider_wind_player.stop())

	play_anim("Jump_Idle", 0.1)

func stop_gliding_landing() -> void:
	if not is_gliding:
		return
	is_gliding = false
	can_reopen_glider = true

	if glider_node:
		glider_node.visible = false
	if glider_particles_l: glider_particles_l.emitting = false
	if glider_particles_r: glider_particles_r.emitting = false
	if glider_wind_player and glider_wind_player.playing:
		var wt = create_tween()
		wt.tween_property(glider_wind_player, "volume_db", -45.0, 0.18)
		wt.tween_callback(func(): if glider_wind_player: glider_wind_player.stop())

	SoundSynth.play_step_run(self)
	play_anim("Jump_Land", 0.1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var key_code = 0
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		key_code = event.physical_keycode if event.physical_keycode != 0 else event.keycode

	if key_code == KEY_V or key_code == 0x41C: # English V or Russian М
		var mode_name = SoundSynth.cycle_voice_mode()
		SoundSynth.play_voice_finisher(self)
		AccessibilityManager.speak("Озвучка: " + mode_name)

	# Squad / Party Switching (Hotkeys 1-9)
	if key_code >= KEY_1 and key_code <= KEY_9:
		var slot_idx = key_code - KEY_1
		switch_party_member(slot_idx)
	elif key_code == KEY_U or key_code == KEY_F8 or key_code == 0x413: # Russian Г
		_rescue_from_void()

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch = clamp(camera_pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		camera_pivot.rotation.x = camera_pitch

	if event is InputEventScreenDrag:
		rotate_camera_touch(event.relative)

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - zoom_step, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + zoom_step, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()

func rotate_camera_touch(relative_delta: Vector2) -> void:
	if not camera_pivot or is_in_dialogue:
		return
	camera_pivot.rotate_y(-relative_delta.x * mouse_sensitivity * 1.25)
	camera_pitch = clamp(camera_pitch - relative_delta.y * mouse_sensitivity * 1.25, min_pitch, max_pitch)
	camera_pivot.rotation.x = camera_pitch

func _physics_process(delta: float) -> void:
	if is_in_dialogue:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Initial ground snap ensure
	if not has_snapped_ground:
		_snap_to_ground_on_start()

	# Void fall-off safety & auto-rescue
	if global_position.y < -12.0 or abs(global_position.x) > 130.0 or abs(global_position.z) > 130.0:
		_rescue_from_void()

	# Mountain geometry & underground anti-clip safety guard
	var ground_y = AsianWorldBuilder.get_terrain_height(global_position.x, global_position.z)
	if not is_swimming and global_position.y < ground_y - 0.75:
		global_position.y = ground_y + 0.25
		velocity.y = maxf(velocity.y, 0.0)

	# Dynamic Multi-Biome BGM updater
	_update_current_biome(delta)

	# Attack stuck safety watchdog (prevents animation/await from ever locking player)
	if is_attacking:
		attack_stuck_watchdog += delta
		if attack_stuck_watchdog >= 0.75:
			is_attacking = false
			can_attack = true
			attack_stuck_watchdog = 0.0
			if anim_player: anim_player.speed_scale = 1.0
	else:
		attack_stuck_watchdog = 0.0

	# Skill cooldown timer
	if not can_use_skill:
		skill_cooldown_timer -= delta
		skill_cooldown_updated.emit(max(0.0, skill_cooldown_timer), skill_cooldown)
		if skill_cooldown_timer <= 0.0:
			can_use_skill = true
			if current_character_id == "ellen" or current_element == "ICE":
				AccessibilityManager.speak("Ледяной вихрь готов")
			else:
				AccessibilityManager.speak("Пламя готово")

	# Combo decay timer (resets combo chain if idle for > COMBO_WINDOW)
	if combo_stage > 0 and not is_attacking:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_stage = 0

	# Genshin weapon dematerialize/summon timer
	_update_weapon_visibility(delta)

	# Charged Attack Hold & Auto-Release Detection
	if is_attack_pressed and not is_dead and not is_climbing and not is_dashing and not is_swimming:
		attack_press_time += delta
		if not is_charging_attack and not has_unleashed_charged_in_press:
			if attack_press_time >= CHARGE_HOLD_THRESHOLD and can_attack:
				is_charging_attack = true
				_start_charging_attack()
		elif is_charging_attack and not has_unleashed_charged_in_press:
			if attack_press_time >= MAX_CHARGE_DURATION:
				# Automatic strike! Player cannot be stuck holding forever
				has_unleashed_charged_in_press = true
				_release_charged_attack()
	else:
		if is_charging_attack:
			_release_charged_attack()

	# Floor touchdown and reset
	if is_on_floor():
		if air_time > 0.65 and not is_dashing and not is_climbing and not is_dead and not is_swimming:
			# Soft landing impact breath ("Ух!", "Оп!")
			if randf() < 0.40:
				SoundSynth.play_voice_land(self)
		air_time = 0.0
		can_reopen_glider = true
		if is_gliding:
			stop_gliding_landing()

	# Gravity & Gliding Aerodynamics
	if not is_on_floor() and not is_climbing and not is_swimming:
		if is_gliding:
			velocity.y = move_toward(velocity.y, -glide_fall_speed, 14.0 * delta)
		else:
			velocity.y -= 14.0 * delta

	if is_dead:
		velocity.x = 0
		velocity.z = 0
		play_anim("Death_A", 0.1)
		move_and_slide()
		return

	# Handle Dash Movement
	if is_dashing:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		move_and_slide()
		return

	# Read Input relative to camera orientation
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1
	if Input.is_action_pressed("move_back"): input_dir.y += 1
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1
	input_dir = input_dir.normalized()

	var cam_forward = -camera_pivot.global_transform.basis.z
	var cam_right = camera_pivot.global_transform.basis.x
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_dir = (cam_forward * (-input_dir.y) + cam_right * input_dir.x).normalized()

	# Water & Swimming System (Strictly confined to actual river channel)
	var x_riv = sin(global_position.z * 0.025) * 3.0
	var d_riv = abs(global_position.x - x_riv)
	var in_water_zone = d_riv <= 5.5 and abs(global_position.z) <= 85.0 and global_position.y <= (water_surface_y + 0.10)
	if in_water_zone:
		if not is_swimming:
			_enter_water()
	else:
		if is_swimming and (is_on_floor() or global_position.y > (water_surface_y + 0.05) or d_riv > 6.0):
			_exit_water()

	if is_swimming:
		_process_swimming(delta, move_dir, input_dir)
		return

	# GENSHIN CLIMBING LOGIC
	if climb_cooldown > 0.0:
		climb_cooldown -= delta

	var space_state = get_world_3d().direct_space_state
	var chest_pos = global_position + Vector3(0, 0.7, 0)
	var check_dir = visual_mesh.global_transform.basis.z
	if move_dir.length() > 0.1:
		check_dir = move_dir
	var fwd_query = PhysicsRayQueryParameters3D.create(chest_pos, chest_pos + check_dir * 0.85)
	fwd_query.exclude = [get_rid()]
	var fwd_hit = space_state.intersect_ray(fwd_query)

	# Enter climbing ONLY when genuinely mid-air and pushing toward a steep wall, or jumping into a wall
	if not is_climbing and climb_cooldown <= 0.0 and not is_dashing and not is_attacking and not is_dead and not is_swimming:
		var can_latch = false
		var wall_norm = Vector3.ZERO
		# Never latch from normal ground walking! Must be mid-air (air_time > 0.15 or pressing jump)
		if not is_on_floor() and (air_time > 0.15 or Input.is_action_pressed("jump")):
			if is_on_wall():
				wall_norm = get_wall_normal()
				var pushing_into_wall = move_dir.dot(-wall_norm) > 0.25
				can_latch = pushing_into_wall or Input.is_action_pressed("jump")
			elif not fwd_hit.is_empty():
				wall_norm = fwd_hit.normal
				var pushing_into_wall = move_dir.dot(-wall_norm) > 0.25
				can_latch = pushing_into_wall or Input.is_action_pressed("jump")

		# Wall must be steep (nearly vertical, abs(wall_norm.y) < 0.35)
		if can_latch and abs(wall_norm.y) < 0.35:
			# Verify ground is not right under feet (< 0.75m)
			var f_query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), global_position + Vector3(0, -0.75, 0))
			f_query.exclude = [get_rid()]
			var floor_chk = space_state.intersect_ray(f_query)
			if floor_chk.is_empty():
				is_climbing = true
				climb_normal = wall_norm
				wall_loss_timer = 0.0
				climb_voice_timer = 0.0

	if is_climbing:
		# Dismount if touching the floor
		if is_on_floor():
			is_climbing = false
			climb_cooldown = 0.35

		# Dismount if pulling away from the wall
		if move_dir.length() > 0.1 and move_dir.dot(climb_normal) > 0.25:
			is_climbing = false
			climb_cooldown = 0.4
			velocity = climb_normal * 2.5

		# Drop off wall with dash
		if Input.is_action_just_pressed("dash"):
			is_climbing = false
			climb_cooldown = 0.4
			velocity = climb_normal * 3.0

		# Check if wall is still in front of character
		var wall_query = PhysicsRayQueryParameters3D.create(chest_pos, chest_pos - climb_normal * 0.95)
		wall_query.exclude = [get_rid()]
		var wall_hit = space_state.intersect_ray(wall_query)
		if not wall_hit.is_empty():
			climb_normal = wall_hit.normal
			wall_loss_timer = 0.0
		else:
			wall_loss_timer += delta
			if wall_loss_timer > 0.25:
				is_climbing = false
				climb_cooldown = 0.35

		# Genshin Ledge Vault (reaching top of wall/pillar/ledge)
		var head_pos = global_position + Vector3(0, 1.45, 0)
		var ledge_query = PhysicsRayQueryParameters3D.create(head_pos, head_pos - climb_normal * 0.95)
		ledge_query.exclude = [get_rid()]
		var ledge_hit = space_state.intersect_ray(ledge_query)

		if is_climbing and input_dir.y < -0.1 and ledge_hit.is_empty() and not wall_hit.is_empty():
			is_climbing = false
			climb_cooldown = 0.4
			velocity = -climb_normal * 4.0 + Vector3.UP * 5.2
			SoundSynth.play_jump(self)
			play_anim("Jump_Start", 0.05)
			AccessibilityManager.speak("Взобралась!")
			move_and_slide()
			return

		# Jump off wall backwards
		if is_climbing and Input.is_action_just_pressed("jump"):
			is_climbing = false
			climb_cooldown = 0.4
			velocity = climb_normal * 6.0 + Vector3.UP * 6.5
			SoundSynth.play_jump(self)
			if randf() < 0.30:
				SoundSynth.play_voice_jump(self)
			play_anim("Jump_Start", 0.05)
			move_and_slide()
			return

		if is_climbing:
			# Orient heroine facing directly into the wall
			var wall_face_angle = atan2(-climb_normal.x, -climb_normal.z)
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, wall_face_angle, 15.0 * delta)
			visual_mesh.rotation.z = 0.0

			# 2D Climbing Locomotion along the wall plane
			var wall_tangent = climb_normal.cross(Vector3.UP).normalized()
			var climb_up = -input_dir.y
			velocity.y = climb_up * climb_speed
			velocity.x = wall_tangent.x * input_dir.x * (climb_speed * 0.75)
			velocity.z = wall_tangent.z * input_dir.x * (climb_speed * 0.75)

			# Stick force directed into wall to maintain continuous contact
			velocity += -climb_normal * 2.2

			play_anim("Interact", 0.15)

			# Periodic climbing exertion tired sigh ("Уф-ф...", "Ха-а...") only while actively moving on the wall
			if input_dir.length() > 0.1:
				climb_voice_timer += delta
				if climb_voice_timer >= 5.0:
					climb_voice_timer = 0.0
					SoundSynth.play_voice_climb(self)
			else:
				climb_voice_timer = max(0.0, climb_voice_timer - delta * 0.5)

			move_and_slide()
			return

	# Floor or Air Locomotion
	if not is_on_floor():
		if is_gliding:
			play_anim("Jump_Idle", 0.15)
			# Gliding forward flight and responsive turn banking
			if move_dir.length() > 0.1:
				var target_vx = move_dir.x * glide_forward_speed
				var target_vz = move_dir.z * glide_forward_speed
				velocity.x = move_toward(velocity.x, target_vx, 18.0 * delta)
				velocity.z = move_toward(velocity.z, target_vz, 18.0 * delta)
				var target_rot = atan2(move_dir.x, move_dir.z)
				visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rot, 7.5 * delta)
				var angle_diff = wrapf(target_rot - visual_mesh.rotation.y, -PI, PI)
				var target_bank = clamp(-angle_diff * 0.45, deg_to_rad(-16.0), deg_to_rad(16.0))
				visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, target_bank, 8.0 * delta)
			else:
				var fwd = visual_mesh.global_transform.basis.z
				velocity.x = move_toward(velocity.x, fwd.x * glide_forward_speed * 0.7, 8.0 * delta)
				velocity.z = move_toward(velocity.z, fwd.z * glide_forward_speed * 0.7, 8.0 * delta)
				visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, 0.0, 6.0 * delta)
		else:
			air_time += delta
			visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, 0.0, 8.0 * delta)
			if not is_attacking:
				if velocity.y > 0.5:
					play_anim("Jump_Start", 0.1)
				else:
					play_anim("Jump_Idle", 0.15)
			# Air control with slight drag
			var target_vx = move_dir.x * speed
			var target_vz = move_dir.z * speed
			velocity.x = move_toward(velocity.x, target_vx, 18.0 * delta)
			velocity.z = move_toward(velocity.z, target_vz, 18.0 * delta)

			# Auto-deploy ONLY when falling from significant cliff height (height > 6.5m)
			if can_reopen_glider and velocity.y < -6.5 and air_time > 0.6 and not is_attacking and not is_dashing and not is_climbing and not is_dead:
				var ground_query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 6.5)
				ground_query.exclude = [get_rid()]
				var ground_hit = space_state.intersect_ray(ground_query)
				if ground_hit.is_empty():
					start_gliding()
	elif is_casting_skill:
		if skill_can_cancel and move_dir.length() > 0.1:
			is_casting_skill = false
			skill_can_cancel = false
		else:
			# Smooth deceleration into casting stance with solid footing
			var decel = 32.0
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)
			velocity.z = move_toward(velocity.z, 0.0, decel * delta)
			visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, 0.0, 10.0 * delta)
			step_timer = 0.0
	elif move_dir.length() > 0.1 and not is_attacking:
		# Realistic ground acceleration with tactile weight (no instant float/snap)
		var accel = 38.0
		var target_vx = move_dir.x * speed
		var target_vz = move_dir.z * speed
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)
		velocity.z = move_toward(velocity.z, target_vz, accel * delta)

		# Face direction of movement smoothly
		var target_rotation = atan2(move_dir.x, move_dir.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rotation, rotation_speed * delta)

		# Genshin Impact Turn-Banking (subtle lean into curves while sprinting)
		var angle_diff = wrapf(target_rotation - visual_mesh.rotation.y, -PI, PI)
		var target_bank = clamp(-angle_diff * 0.28, deg_to_rad(-8.0), deg_to_rad(8.0))
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, target_bank, 8.0 * delta)

		var is_running = speed >= 7.0
		if is_running:
			play_anim("Running_A", 0.15)
		else:
			play_anim("Walking_A", 0.15)

		var step_interval = 0.28 if is_running else 0.45
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			if is_running:
				SoundSynth.play_step_run(self)
			else:
				SoundSynth.play_step_walk(self)

		# Reset idle timer when moving (5x less frequent: ~3.75 - 6.5 minutes)
		idle_voice_timer = randf_range(225.0, 390.0)
	elif not is_attacking and not is_charging_attack:
		# Ground friction / deceleration with weight
		var decel = 42.0
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, 0.0, 10.0 * delta)
		step_timer = 0.0
		play_anim("Idle", 0.2)

		# Very rare, gentle vocal reaction when standing still (idle 5x less frequent)
		if is_on_floor() and not is_dead:
			idle_voice_timer -= delta
			if idle_voice_timer <= 0.0:
				idle_voice_timer = randf_range(225.0, 390.0)
				if randf() < 0.5:
					SoundSynth.play_voice_idle(self)

	# Dynamic Camera FOV & Distance (Genshin Action Framing)
	if camera_node and spring_arm:
		var target_fov = 70.0
		var target_dist = 3.2
		if is_dashing:
			target_fov = 78.0
			target_dist = 3.7
		elif is_gliding:
			target_fov = 77.0
			target_dist = 4.2
		elif is_attacking or is_charging_attack or is_casting_skill:
			target_fov = 68.0
			target_dist = 2.8
		elif speed >= 7.0 and move_dir.length() > 0.1:
			target_fov = 74.0
			target_dist = 3.5

		camera_node.fov = lerp(camera_node.fov, target_fov, 5.0 * delta)
		spring_arm.spring_length = lerp(spring_arm.spring_length, target_dist, 5.0 * delta)

	# Jump Action on Space & Glider Toggle
	if Input.is_action_just_pressed("jump") and not is_dashing and not is_climbing and not is_dead:
		if is_on_floor():
			if is_attacking:
				is_attacking = false
				can_attack = true
			velocity.y = jump_velocity
			SoundSynth.play_jump(self)
			if randf() < 0.28:
				SoundSynth.play_voice_jump(self)
			play_anim("Jump_Start", 0.05)
		else:
			# Mid-air Space press: Toggle glider on / off!
			if is_gliding:
				cancel_gliding()
			else:
				# Require altitude higher than normal jump height (> 4.2m) to deploy glider
				var ground_query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 4.2)
				ground_query.exclude = [get_rid()]
				var ground_hit = space_state.intersect_ray(ground_query)
				if ground_hit.is_empty():
					start_gliding()

	move_and_slide()

	# Only face locked target when idle or attacking (never override run direction to walk backwards)
	if locked_target and is_instance_valid(locked_target) and (move_dir.length() <= 0.1 or is_attacking):
		var look_pos = locked_target.global_position
		look_pos.y = global_position.y
		var dir_to_target = (look_pos - global_position).normalized()
		if dir_to_target.length() > 0.01:
			var target_rot = atan2(dir_to_target.x, dir_to_target.z)
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rot, 12.0 * delta)

func _rescue_from_void() -> void:
	if is_gliding:
		stop_gliding_landing()
	is_climbing = false
	is_swimming = false
	is_dashing = false
	velocity = Vector3.ZERO
	# Return to solid ground at city avenue promenade
	global_position = Vector3(18.0, 3.4, -6.0)
	has_snapped_ground = false
	_snap_to_ground_on_start()
	SoundSynth.play_dash(self)
	AccessibilityManager.speak("Возврат на твердую поверхность.")

# ==================== SQUAD & PARTY MANAGEMENT ====================

func recruit_party_member(char_id: String) -> void:
	if not char_id in party_members:
		party_members.append(char_id)
		party_member_recruited.emit(char_id)
		AccessibilityManager.speak("В отряд вступила Эллен Джо! Нажмите 2 для переключения.")

func switch_party_member(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= party_members.size():
		return
	if slot_idx == active_party_index:
		return

	active_party_index = slot_idx
	var target_char = party_members[slot_idx]
	current_character_id = target_char

	# 1. Elemental switch burst VFX
	_spawn_character_switch_vfx(target_char)

	# 2. Distinct character switch voiceline
	SoundSynth.play_voice_character_switch(target_char)

	# 3. Apply character visuals, tail, weapon, and element
	_apply_active_character(target_char)

	party_switched.emit(target_char, slot_idx)

func _apply_active_character(char_id: String) -> void:
	SoundSynth.set_active_heroine(char_id)
	if char_id == "ellen":
		current_element = "ICE"
		if anime_model:
			anime_model.visible = false
		if not ellen_model_node:
			var em_scene = load("res://scenes/ellen_joe_model.tscn")
			if em_scene:
				ellen_model_node = em_scene.instantiate() as Node3D
				visual_mesh.add_child(ellen_model_node)
		if ellen_model_node:
			ellen_model_node.visible = true
			var players = ellen_model_node.find_children("*", "AnimationPlayer", true, false)
			if players.size() > 0:
				anim_player = players[0]
				current_anim = ""
				play_anim("Idle", 0.2)
		_equip_character_weapon("res://assets/models/ellen_shark_shears.glb", Color(0.2, 0.85, 1.0))
		AccessibilityManager.speak("Эллен Джо выбрана.")
	else:
		current_element = "PYRO"
		if ellen_model_node:
			ellen_model_node.visible = false
		if anime_model:
			anime_model.visible = true
			var players = anime_model.find_children("*", "AnimationPlayer", true, false)
			if players.size() > 0:
				anim_player = players[0]
				current_anim = ""
				play_anim("Idle", 0.2)
		_equip_character_weapon("res://assets/models/sword_1h.glb", Color(1.0, 0.55, 0.1))
		AccessibilityManager.speak("Ху Тао выбрана.")

func start_dialogue_camera(target_node: Node3D) -> void:
	is_in_dialogue = true
	is_game_active = false
	velocity = Vector3.ZERO
	is_attacking = false
	is_charging_attack = false
	is_dashing = false
	play_anim("Idle", 0.2)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if not camera_pivot or not spring_arm or not target_node:
		return

	# Hide player mesh during dialogue so it NEVER obstructs the NPC
	if visual_mesh:
		visual_mesh.visible = false

	dialogue_saved_pivot_rot = camera_pivot.rotation
	dialogue_saved_spring_len = spring_arm.spring_length

	# Frame NPC's bust (head, torso, maid outfit down to hips) in a crisp 3/4 cinematic portrait
	var target_focus = target_node.global_position + Vector3(0, 0.95, 0)
	var npc_fwd = -target_node.global_transform.basis.z
	var npc_right = target_node.global_transform.basis.x
	if npc_fwd.length_squared() < 0.1:
		npc_fwd = Vector3(0, 0, 1)
		npc_right = Vector3(1, 0, 0)
	else:
		npc_fwd = npc_fwd.normalized()
		npc_right = npc_right.normalized()

	# Position camera in front of NPC with a gentle 3/4 angle
	var cam_pos = target_focus + (npc_fwd * 1.65) + (npc_right * 0.40) + Vector3(0, 0.12, 0)

	spring_arm.collision_mask = 0 # Prevent clipping into nearby objects
	spring_arm.spring_length = 0.0

	if camera_node:
		camera_node.h_offset = 0.0
		camera_node.v_offset = 0.0

	camera_pivot.top_level = true
	camera_pivot.global_position = cam_pos
	camera_pivot.look_at(target_focus, Vector3.UP)

func end_dialogue_camera() -> void:
	if not is_in_dialogue:
		return

	if visual_mesh:
		visual_mesh.visible = true

	spring_arm.collision_mask = 1

	if camera_node:
		camera_node.h_offset = 0.35
		camera_node.v_offset = 0.12

	camera_pivot.top_level = false
	camera_pivot.position = Vector3(0, 1.25, 0)
	camera_pivot.rotation = dialogue_saved_pivot_rot
	spring_arm.spring_length = dialogue_saved_spring_len

	is_in_dialogue = false
	is_game_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _equip_character_weapon(weapon_path: String, aura_color: Color) -> void:
	if not arm_pivot:
		return
	var old_sword = arm_pivot.get_node_or_null("Sword")
	if old_sword:
		old_sword.queue_free()

	var w_scene = load(weapon_path)
	if w_scene:
		var w_inst = w_scene.instantiate() as Node3D
		w_inst.name = "Sword"
		w_inst.scale = Vector3.ZERO
		w_inst.visible = false
		w_inst.position = Vector3(0.0, 0.04, -0.05)
		w_inst.rotation_degrees = Vector3(90.0, 0.0, 0.0)

		# Add elemental aura to weapon
		var aura = CPUParticles3D.new()
		aura.name = "FlameAura"
		aura.amount = 16
		aura.lifetime = 0.35
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		var p_mesh = SphereMesh.new()
		p_mesh.radius = 0.02
		p_mesh.height = 0.04
		p_mesh.material = mat
		aura.mesh = p_mesh
		aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		aura.emission_box_extents = Vector3(0.05, 0.05, 0.35)
		aura.direction = Vector3(0, 1, 0)
		aura.gravity = Vector3(0, 0.8, 0)
		var grad = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
		grad.colors = PackedColorArray([Color(aura_color.r, aura_color.g, aura_color.b, 0.9), Color(aura_color.r * 0.8, aura_color.g * 0.8, aura_color.b, 0.7), Color(aura_color.r * 0.4, aura_color.g * 0.4, aura_color.b, 0.4), Color(0, 0, 0, 0)])
		aura.color_ramp = grad
		w_inst.add_child(aura)

		arm_pivot.add_child(w_inst)
		weapon_node = w_inst
		is_weapon_summoned = false
		weapon_dissolve_timer = 0.0

func _spawn_character_switch_vfx(target_char: String) -> void:
	var burst = CPUParticles3D.new()
	burst.amount = 36
	burst.lifetime = 0.55
	burst.one_shot = true
	burst.explosiveness = 0.92
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.04
	p_mesh.height = 0.08
	p_mesh.material = mat
	burst.mesh = p_mesh
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 0.65
	burst.direction = Vector3(0, 1, 0)
	burst.spread = 180.0
	burst.initial_velocity_min = 4.0
	burst.initial_velocity_max = 7.0

	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	if target_char == "ellen":
		grad.colors = PackedColorArray([Color(0.2, 0.9, 1.0, 1.0), Color(0.5, 0.95, 1.0, 0.9), Color(0.8, 1.0, 1.0, 0.5), Color(0.1, 0.5, 0.8, 0.0)])
	else:
		grad.colors = PackedColorArray([Color(1.0, 0.95, 0.4, 1.0), Color(1.0, 0.55, 0.1, 0.9), Color(0.9, 0.15, 0.05, 0.5), Color(0.2, 0.02, 0.02, 0.0)])
	burst.color_ramp = grad
	add_child(burst)
	burst.restart()
	get_tree().create_timer(0.7).timeout.connect(func(): if is_instance_valid(burst): burst.queue_free())

func _snap_to_ground_on_start() -> void:
	if has_snapped_ground:
		return
	var space = get_world_3d().direct_space_state
	var from_pos = global_position + Vector3(0, 5.0, 0)
	var to_pos = global_position + Vector3(0, -20.0, 0)
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [get_rid()]
	var hit = space.intersect_ray(query)
	if not hit.is_empty():
		global_position.y = hit.position.y + 0.05
		velocity = Vector3.ZERO
		has_snapped_ground = true

func _enter_water() -> void:
	if is_swimming:
		return
	is_swimming = true
	is_climbing = false
	is_charging_attack = false
	if is_gliding:
		stop_gliding_landing()
	velocity.y = max(velocity.y * 0.25, -2.5)
	SoundSynth.play_water_splash_enter(self)
	_spawn_water_splash_vfx(global_position)
	if randf() < 0.15:
		SoundSynth.play_voice_water_splash(self)

func _exit_water() -> void:
	if not is_swimming:
		return
	is_swimming = false
	visual_mesh.rotation.x = 0.0
	visual_mesh.rotation.z = 0.0

func _process_swimming(delta: float, move_dir: Vector3, _input_dir: Vector2) -> void:
	# Dampen vertical velocity and smoothly float at water surface
	var target_y = water_surface_y - 0.72
	var y_diff = target_y - global_position.y
	velocity.y = move_toward(velocity.y, y_diff * 9.0, 24.0 * delta)

	var is_sprint = Input.is_action_pressed("dash")
	var target_speed = swim_fast_speed if is_sprint else swim_speed

	if move_dir.length() > 0.1:
		var target_vx = move_dir.x * target_speed
		var target_vz = move_dir.z * target_speed
		velocity.x = move_toward(velocity.x, target_vx, 20.0 * delta)
		velocity.z = move_toward(velocity.z, target_vz, 20.0 * delta)

		var target_rot = atan2(move_dir.x, move_dir.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rot, 10.0 * delta)
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, deg_to_rad(-18.0), 8.0 * delta)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, 0.0, 8.0 * delta)

		play_anim("Running_A" if is_sprint else "Walking_A", 0.2)
		if anim_player:
			anim_player.speed_scale = 0.85 if not is_sprint else 1.25

		swim_stroke_timer += delta
		var stroke_rate = 0.65 if is_sprint else 0.95
		if swim_stroke_timer >= stroke_rate:
			swim_stroke_timer = 0.0
			SoundSynth.play_water_swim_stroke(self)

		swim_ripple_timer += delta
		if swim_ripple_timer >= 0.28:
			swim_ripple_timer = 0.0
			_spawn_water_ripple(global_position)
	else:
		var decel = 16.0
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)
		visual_mesh.rotation.x = lerp_angle(visual_mesh.rotation.x, 0.0, 6.0 * delta)
		visual_mesh.rotation.z = lerp_angle(visual_mesh.rotation.z, 0.0, 6.0 * delta)
		play_anim("Idle", 0.25)
		if anim_player:
			anim_player.speed_scale = 1.0

		swim_ripple_timer += delta
		if swim_ripple_timer >= 0.8:
			swim_ripple_timer = 0.0
			_spawn_water_ripple(global_position)

	# Water jump / Shore climb leap
	if Input.is_action_just_pressed("jump"):
		var space_state = get_world_3d().direct_space_state
		var check_dir = visual_mesh.global_transform.basis.z
		if move_dir.length() > 0.1:
			check_dir = move_dir
		var bank_query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), global_position + Vector3(0, 0.4, 0) + check_dir * 1.6)
		bank_query.exclude = [get_rid()]
		var bank_hit = space_state.intersect_ray(bank_query)
		if not bank_hit.is_empty():
			velocity = check_dir * 5.8 + Vector3.UP * 7.2
			_exit_water()
			SoundSynth.play_water_splash_jump(self)
			play_anim("Jump_Start", 0.05)
		else:
			velocity.y = 5.2
			SoundSynth.play_water_splash_jump(self)
			_spawn_water_splash_vfx(global_position)

	move_and_slide()

func _spawn_water_ripple(pos: Vector3) -> void:
	var ripple = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.25
	torus.outer_radius = 0.42
	torus.rings = 16
	torus.ring_segments = 6
	ripple.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.95, 1.0, 0.65)
	ripple.material_override = mat

	ripple.position = Vector3(pos.x, water_surface_y + 0.02, pos.z)
	get_parent().add_child(ripple)

	var tween = ripple.create_tween().set_parallel(true)
	tween.tween_property(ripple, "scale", Vector3(2.8, 1.0, 2.8), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ripple.queue_free)

func _spawn_water_splash_vfx(pos: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.position = Vector3(pos.x, water_surface_y + 0.05, pos.z)
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 24
	p.lifetime = 0.6
	p.direction = Vector3(0, 1, 0)
	p.spread = 45.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -9.8, 0)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.9, 0.96, 1.0, 0.8)
	var sphere = SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	sphere.material = mat
	p.mesh = sphere

	get_parent().add_child(p)
	p.restart()
	var t = p.create_tween()
	t.tween_interval(0.8)
	t.tween_callback(p.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_dialogue:
		return

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
			if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var key_code = 0
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		key_code = event.physical_keycode if event.physical_keycode != 0 else event.keycode

	if event.is_action_pressed("attack"):
		is_attack_pressed = true
		attack_press_time = 0.0
		has_unleashed_charged_in_press = false
	elif event.is_action_released("attack"):
		if is_charging_attack:
			_release_charged_attack()
		elif attack_press_time < CHARGE_HOLD_THRESHOLD and not has_unleashed_charged_in_press:
			perform_attack()
		is_attack_pressed = false
		attack_press_time = 0.0
		has_unleashed_charged_in_press = false
	elif event.is_action_pressed("dash"):
		perform_dash()
	elif event.is_action_pressed("elemental_skill") or key_code == KEY_E or key_code == 0x443: # Russian 'У'
		perform_elemental_skill()
	elif event.is_action_pressed("target_lock"):
		toggle_target_lock()
	elif event.is_action_pressed("use_potion") or key_code == KEY_Q or key_code == KEY_Z or key_code == 0x419 or key_code == 0x44F: # Russian 'Й' / 'Я'
		InventoryManager.use_quick_potion()

func perform_elemental_skill() -> void:
	if not can_use_skill or is_dead or is_climbing or is_dashing or is_casting_skill or is_swimming:
		return

	if is_gliding:
		cancel_gliding()

	can_use_skill = false
	is_casting_skill = true
	summon_weapon()
	skill_can_cancel = false
	skill_cooldown_timer = skill_cooldown

	if current_character_id == "ellen" or current_element == "ICE":
		_perform_cryo_skill_ellen()
	else:
		_perform_pyro_skill_hutao()

func _perform_cryo_skill_ellen() -> void:
	# Ellen's Signature Cryo Skill: "Frost Shredder" (Ледяной Акулий Вихрь)
	play_anim("2H_Melee_Attack_Spin", 0.04)
	if anim_player:
		anim_player.speed_scale = 1.35

	# Ellen Japanese battle shout & frost whoosh
	SoundSynth.play_voice_cryo_skill(self)
	SoundSynth.play_frost_whoosh(self)

	# Forward icy torpedo lunge
	var fwd = visual_mesh.global_transform.basis.z
	velocity += fwd * 7.5

	# Icy blade slash ring
	_spawn_sword_slash_arc(Color(0.25, 0.90, 1.0, 0.95), 3.2, 0.35)

	# Anticipation dynamic squash & stretch
	var spin_tween = create_tween()
	spin_tween.tween_property(visual_mesh, "scale", Vector3(1.15, 0.90, 1.15), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	spin_tween.tween_property(visual_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Strike sync at midpoint of spin (t = 0.20s)
	await get_tree().create_timer(0.20).timeout
	if is_dead or not is_casting_skill:
		return

	# Cryo burst & glacier shatter audio
	SoundSynth.play_cryo_burst(self)
	SoundSynth.play_ice_shatter(self)

	# Camera impact kick
	if camera_node:
		var cam_tween = create_tween()
		cam_tween.tween_property(camera_node, "fov", camera_node.fov + 4.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		cam_tween.tween_property(camera_node, "fov", 70.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Deal direct Cryo spin damage to nearby enemies & destructibles
	var spin_dmg = int(attack_power * 1.85)
	var bodies = attack_area.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(spin_dmg, false, true, true)
			if b.has_method("apply_hitstop"):
				b.apply_hitstop(0.08)
			_spawn_flame_hit_sparks(b.global_position, 1.5, true)
		else:
			var d_prop = _find_destructible(b)
			if d_prop and not d_prop.is_destroyed:
				d_prop.take_damage(spin_dmg, false, true, global_position)
				_spawn_flame_hit_sparks(d_prop.global_position + Vector3(0, 1.0, 0), 1.3, true)

	for a in attack_area.get_overlapping_areas():
		var d_prop = _find_destructible(a)
		if d_prop and not d_prop.is_destroyed:
			d_prop.take_damage(spin_dmg, false, true, global_position)
			_spawn_flame_hit_sparks(d_prop.global_position + Vector3(0, 1.0, 0), 1.3, true)

	# Spawn Cryo Vortex in front of Ellen
	var cryo_vortex_scene = preload("res://scenes/cryo_vortex.tscn")
	if cryo_vortex_scene:
		var vortex = cryo_vortex_scene.instantiate()
		var spawn_pos = global_position + visual_mesh.global_transform.basis.z * 3.0
		spawn_pos.y = global_position.y
		get_parent().add_child(vortex)
		vortex.global_position = spawn_pos

	# Open early cancel window (t = 0.20s -> 0.45s)
	await get_tree().create_timer(0.25).timeout
	if is_dead or not is_casting_skill:
		return
	skill_can_cancel = true

	# Follow through to resting stance (t = 0.45s -> 0.70s)
	await get_tree().create_timer(0.25).timeout
	if is_casting_skill and not is_dead and not is_climbing and not is_dashing:
		is_casting_skill = false
		skill_can_cancel = false
		if anim_player:
			anim_player.speed_scale = 1.0
		play_anim("Idle", 0.20)

func _perform_pyro_skill_hutao() -> void:
	# Phase 1: Dynamic cast animation & gathering flame energy (t = 0.00s - 0.24s)
	play_anim("Spellcast_Shoot", 0.08)
	if anim_player:
		anim_player.speed_scale = 1.0

	# Hu Tao voice shout as she gathers the fire
	SoundSynth.play_voice_pyro_skill(self)

	# Anticipation compression
	var prep_tween = create_tween()
	prep_tween.tween_property(visual_mesh, "scale", Vector3(0.96, 1.05, 0.96), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Exact keyframe strike sync (t = 0.24s): hand reaches apex forward extension!
	await get_tree().create_timer(0.24).timeout
	if is_dead or not is_casting_skill:
		return

	# Phase 2: Explosive flame release & Vortex eruption (t = 0.24s)
	SoundSynth.play_flame_burst(self)

	# Fiery power impulse on character model
	var burst_tween = create_tween()
	burst_tween.tween_property(visual_mesh, "scale", Vector3(1.14, 0.92, 1.14), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(visual_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Camera impact punch
	if camera_node:
		var cam_tween = create_tween()
		cam_tween.tween_property(camera_node, "fov", camera_node.fov + 4.5, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		cam_tween.tween_property(camera_node, "fov", 70.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Spawn Pyro Vortex in front of heroine
	var vortex_scene = preload("res://scenes/pyro_vortex.tscn")
	if vortex_scene:
		var vortex = vortex_scene.instantiate()
		var spawn_pos = global_position + visual_mesh.global_transform.basis.z * 2.8
		spawn_pos.y = global_position.y
		get_parent().add_child(vortex)
		vortex.global_position = spawn_pos

	# Phase 3: Post-burst hold & open early cancel window (t = 0.24s -> 0.50s)
	await get_tree().create_timer(0.26).timeout
	if is_dead or not is_casting_skill:
		return
	skill_can_cancel = true

	# Phase 4: Full animation follow-through to resting stance (t = 0.50s -> 0.88s)
	# Remaining duration of Spellcast_Shoot: 0.38s (total 0.88s)
	await get_tree().create_timer(0.38).timeout
	if is_casting_skill and not is_dead and not is_climbing and not is_dashing:
		is_casting_skill = false
		skill_can_cancel = false
		if anim_player:
			anim_player.speed_scale = 1.0
		# Seamless, natural blend into Idle
		play_anim("Idle", 0.22)

func perform_dash() -> void:
	if not can_dash or is_dashing or is_dead or is_swimming:
		return

	if is_gliding:
		cancel_gliding()

	# Genshin Animation Cancelling: Dash instantly interrupts sword attack or skill recovery
	if is_attacking:
		is_attacking = false
		can_attack = true
	if is_casting_skill:
		is_casting_skill = false
		skill_can_cancel = false

	can_dash = false
	is_dashing = true
	is_invulnerable = true

	var cam_forward = -camera_pivot.global_transform.basis.z
	var cam_right = camera_pivot.global_transform.basis.x
	cam_forward.y = 0
	cam_right.y = 0

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1
	if Input.is_action_pressed("move_back"): input_dir.y += 1
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1

	if input_dir.length() > 0.1:
		input_dir = input_dir.normalized()
		dash_direction = (cam_forward * (-input_dir.y) + cam_right * input_dir.x).normalized()
	else:
		dash_direction = cam_forward.normalized()

	visual_mesh.rotation.y = atan2(dash_direction.x, dash_direction.z)
	SoundSynth.play_dash(self)
	if randf() < 0.32:
		SoundSynth.play_voice_dash(self)
	play_anim("Dodge_Forward", 0.05)

	# I-Frame invulnerability window (0.22s)
	get_tree().create_timer(0.22).timeout.connect(func(): is_invulnerable = false)

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func _start_charging_attack() -> void:
	summon_weapon()
	# Anime coiled iaido charge stance
	play_anim("1H_Melee_Attack_Chop", 0.05)
	if anim_player:
		anim_player.speed_scale = 0.20 # Coils tightly into ready stance
	SoundSynth.play_charge_hum(self) # Crisp metallic blade pull + rising suction + crystal chime

	# Create charge VFX root
	if charge_fx_root and is_instance_valid(charge_fx_root):
		charge_fx_root.queue_free()
	charge_fx_root = Node3D.new()
	charge_fx_root.name = "ChargeVFX"
	visual_mesh.add_child(charge_fx_root)

	# 1. Subtle glowing crimson-gold ground seal under feet
	var rune = MeshInstance3D.new()
	var r_mesh = QuadMesh.new()
	r_mesh.size = Vector2(2.4, 2.4)
	r_mesh.orientation = QuadMesh.FACE_Y
	var r_mat = StandardMaterial3D.new()
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_texture = TEX_MAGIC_CIRCLE
	r_mat.albedo_color = Color(1.0, 0.45, 0.1, 0.0)
	rune.mesh = r_mesh
	rune.material_override = r_mat
	rune.position = Vector3(0, 0.04, 0)
	charge_fx_root.add_child(rune)

	var rt = rune.create_tween()
	rt.tween_property(r_mat, "albedo_color:a", 0.75, 0.18)

	# 2. Inward suction embers spiraling into the blade
	var p = CPUParticles3D.new()
	p.name = "InwardEmbers"
	p.amount = 24
	p.lifetime = 0.32
	var p_mat = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.035
	p_mesh.height = 0.07
	p_mesh.material = p_mat
	p.mesh = p_mesh
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.1
	p.gravity = Vector3(0, 0.5, 0)
	p.radial_accel_min = -7.0 # Pulls sharply inward!
	p.radial_accel_max = -4.5
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.95, 0.45, 1.0), Color(1.0, 0.35, 0.05, 0.8), Color(0.3, 0.02, 0.02, 0.0)])
	p.color_ramp = grad
	charge_fx_root.add_child(p)
	p.position = Vector3(0.35, 0.7, 0.2)

	# 3. Crystal Gleam Flare Star on sword tip that flashes at readiness
	var flare = MeshInstance3D.new()
	var fl_mesh = QuadMesh.new()
	fl_mesh.size = Vector2(0.2, 0.2)
	var fl_mat = StandardMaterial3D.new()
	fl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fl_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fl_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fl_mat.albedo_color = Color(1.0, 0.95, 0.7, 0.0)
	flare.mesh = fl_mesh
	flare.material_override = fl_mat
	charge_fx_root.add_child(flare)
	flare.position = Vector3(0.35, 1.15, 0.25)
	var ft = flare.create_tween()
	ft.tween_property(fl_mat, "albedo_color:a", 1.0, 0.18)
	ft.parallel().tween_property(flare, "scale", Vector3(3.2, 3.2, 3.2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Anticipation subtle body squash
	var st = create_tween()
	st.tween_property(visual_mesh, "scale", Vector3(1.06, 0.94, 1.06), 0.12)

func _find_destructible(node: Node) -> DestructibleProp:
	if not node:
		return null
	if node.has_meta("destructible_parent"):
		var p = node.get_meta("destructible_parent")
		if p is DestructibleProp and is_instance_valid(p):
			return p
	var curr = node
	var depth = 0
	while curr and depth < 10:
		depth += 1
		if curr is DestructibleProp:
			return curr
		if curr.has_meta("destructible_parent"):
			var p = curr.get_meta("destructible_parent")
			if p is DestructibleProp and is_instance_valid(p):
				return p
		curr = curr.get_parent()
	return null

func _get_prop_material(d_prop: DestructibleProp) -> String:
	if not d_prop:
		return "wood"
	match d_prop.prop_type:
		DestructibleProp.PropType.LANTERN, DestructibleProp.PropType.TOMB, DestructibleProp.PropType.RUIN, DestructibleProp.PropType.KARST_SPIRE:
			return "stone"
		DestructibleProp.PropType.BONE_SPIRE:
			return "bone"
		DestructibleProp.PropType.CYBER_TOWER, DestructibleProp.PropType.CYBER_LAMP:
			return "cyber"
		DestructibleProp.PropType.SHOP, DestructibleProp.PropType.PAVILION, DestructibleProp.PropType.PAGODA, DestructibleProp.PropType.BRIDGE, DestructibleProp.PropType.SHRINE:
			return "building"
		_:
			return "wood"

func _release_charged_attack() -> void:
	is_charging_attack = false
	if anim_player:
		anim_player.speed_scale = 1.0

	# Clean up charging VFX
	if charge_fx_root and is_instance_valid(charge_fx_root):
		charge_fx_root.queue_free()
		charge_fx_root = null

	if is_dead or is_dashing or is_climbing or not can_attack or is_attacking:
		return

	is_attacking = true
	can_attack = false
	summon_weapon()

	# High damage charged attack (2.5x base damage)
	var charged_power = int(attack_power * 2.5)
	var is_cryo_char = (current_character_id == "ellen" or current_element == "ICE")

	# Sound & voice
	if is_cryo_char:
		SoundSynth.play_sword_charged(self)
		SoundSynth.play_ice_shatter(self)
		SoundSynth.play_voice_finisher(self)
	else:
		SoundSynth.play_sword_charged(self)
		SoundSynth.play_voice_finisher(self)

	# Animation: high-speed 2H anime sweeping slice
	play_anim("2H_Melee_Attack_Slice", 0.02)
	if anim_player:
		anim_player.speed_scale = 1.35

	# Smooth forward lunge (steps forward into the strike)
	var fwd = visual_mesh.global_transform.basis.z
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_vec.length() > 0.1:
		var cam_fwd = -camera_pivot.global_transform.basis.z
		var cam_rt = camera_pivot.global_transform.basis.x
		cam_fwd.y = 0; cam_rt.y = 0
		fwd = (cam_fwd * (-input_vec.y) + cam_rt * input_vec.x).normalized()
		visual_mesh.rotation.y = atan2(fwd.x, fwd.z)
	elif locked_target and is_instance_valid(locked_target):
		var target_dir = (locked_target.global_position - global_position)
		target_dir.y = 0
		if target_dir.length() > 0.1:
			fwd = target_dir.normalized()
			visual_mesh.rotation.y = atan2(fwd.x, fwd.z)

	velocity = fwd * 12.5

	# Body stretch spring into release
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(0.92, 1.15, 0.92), 0.08)
	tween.tween_property(visual_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.18)

	# Wide sweeping crescent slash ribbon
	var slash_col = Color(0.25, 0.90, 1.0, 0.95) if is_cryo_char else Color(1.0, 0.42, 0.08, 0.95)
	_spawn_sword_slash_arc(slash_col, 3.4, 0.28)

	# Signature Burst along slash trail: Snowflakes for Ellen, Butterflies for Hu Tao
	_spawn_charged_butterfly_burst(global_position + fwd * 1.5 + Vector3(0, 0.8, 0), is_cryo_char)

	# Multi-target hit detection with forward cleave & knockback
	var bodies = attack_area.get_overlapping_bodies()
	var hit_count = 0
	var hit_destructibles: Array[DestructibleProp] = []
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(charged_power, not is_cryo_char, true, is_cryo_char)
			if b.has_method("apply_hitstop"):
				b.apply_hitstop(0.08)
			hit_count += 1
			_spawn_flame_hit_sparks(b.global_position, 1.8, is_cryo_char)
			if b is CharacterBody3D:
				var push_dir = fwd * 0.85 + (b.global_position - global_position).normalized() * 0.35
				push_dir.y = 0.35
				b.velocity += push_dir.normalized() * 10.0
		else:
			var d_prop = _find_destructible(b)
			if d_prop and not d_prop.is_destroyed and not d_prop in hit_destructibles:
				hit_destructibles.append(d_prop)
				d_prop.take_damage(charged_power, true, true, global_position)
				hit_count += 1
				_spawn_flame_hit_sparks(d_prop.global_position + Vector3(0, 1.2, 0), 1.8, is_cryo_char)

	for a in attack_area.get_overlapping_areas():
		var d_prop = _find_destructible(a)
		if d_prop and not d_prop.is_destroyed and not d_prop in hit_destructibles:
			hit_destructibles.append(d_prop)
			d_prop.take_damage(charged_power, true, true, global_position)
			hit_count += 1
			_spawn_flame_hit_sparks(d_prop.global_position + Vector3(0, 1.2, 0), 1.8, is_cryo_char)

	var fwd_sweep_center = global_position + fwd * 2.2 + Vector3(0, 1.0, 0)
	for d in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(d) and d is DestructibleProp and not d.is_destroyed and not d in hit_destructibles:
			if fwd_sweep_center.distance_to(d.global_position) <= 4.8:
				hit_destructibles.append(d)
				d.take_damage(charged_power, true, true, global_position)
				hit_count += 1
				_spawn_flame_hit_sparks(d.global_position + Vector3(0, 1.2, 0), 1.8, is_cryo_char)

	if hit_count > 0:
		SoundSynth.play_juicy_hit(self)
		_apply_hit_impact(0.06, 0.15)

	combo_stage = 0
	combo_reset_timer = 0.0

	await get_tree().create_timer(0.38).timeout
	if anim_player:
		anim_player.speed_scale = 1.0
	is_attacking = false
	await get_tree().create_timer(0.08).timeout
	can_attack = true
	if not is_dead and not is_climbing and not is_charging_attack:
		play_anim("Idle", 0.18)

func _spawn_charged_butterfly_burst(pos: Vector3, is_cryo: bool = false) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = CPUParticles3D.new()
	p.name = "ChargedParticles"
	var p_mat = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_texture = TEX_CRYO_SNOWFLAKE if is_cryo else TEX_PYRO_BUTTERFLY
	p_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p_mat.vertex_color_use_as_albedo = true

	var p_mesh = QuadMesh.new()
	p_mesh.size = Vector2(0.45, 0.45)
	p_mesh.material = p_mat
	p.mesh = p_mesh
	p.amount = 14
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.85
	p.direction = Vector3(0, 1, 0)
	p.spread = 75.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	var grad = Gradient.new()
	if is_cryo:
		grad.colors = PackedColorArray([Color(0.8, 0.95, 1.0, 1.0), Color(0.2, 0.75, 1.0, 0.85), Color(0.05, 0.2, 0.8, 0.0)])
	else:
		grad.colors = PackedColorArray([Color(1.0, 0.95, 0.6, 1.0), Color(1.0, 0.35, 0.05, 0.85), Color(0.3, 0.02, 0.02, 0.0)])
	p.color_ramp = grad

	tree.current_scene.add_child(p)
	p.global_position = pos
	p.emitting = true
	tree.create_timer(0.7).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func perform_attack() -> void:
	if is_casting_skill:
		if skill_can_cancel:
			is_casting_skill = false
			skill_can_cancel = false
		else:
			return

	if not can_attack or is_attacking or is_dashing or is_dead or is_charging_attack or has_unleashed_charged_in_press or is_swimming:
		return

	if is_gliding:
		cancel_gliding()

	is_attacking = true
	can_attack = false
	summon_weapon()

	# Character-specific combo animation chains:
	# Hu Tao: agile 1H crimson rapier strikes ending in 2H overhead slice
	# Ellen Joe: predatory heavy mechanical shark shears (scissors) combo with spins & glacial cleaves
	var is_cryo_char = (current_character_id == "ellen" or current_element == "ICE")

	var combo_data_hutao = [
		{"anim": "1H_Melee_Attack_Slice_Diagonal", "mult": 1.0, "duration": 0.26, "lunge": 2.5, "radius": 2.0, "color": Color(1.0, 0.85, 0.4, 0.85)},
		{"anim": "1H_Melee_Attack_Chop", "mult": 1.1, "duration": 0.28, "lunge": 3.0, "radius": 2.1, "color": Color(1.0, 0.65, 0.2, 0.88)},
		{"anim": "1H_Melee_Attack_Slice_Horizontal", "mult": 1.25, "duration": 0.32, "lunge": 3.5, "radius": 2.3, "color": Color(1.0, 0.45, 0.1, 0.92)},
		{"anim": "2H_Melee_Attack_Slice", "mult": 2.0, "duration": 0.45, "lunge": 5.5, "radius": 2.8, "color": Color(1.0, 0.25, 0.05, 0.98)}
	]
	var combo_data_ellen = [
		{"anim": "Dualwield_Melee_Attack_Slice", "mult": 1.15, "duration": 0.24, "lunge": 3.2, "radius": 2.3, "color": Color(0.35, 0.90, 1.0, 0.90)},
		{"anim": "2H_Melee_Attack_Chop", "mult": 1.30, "duration": 0.27, "lunge": 3.5, "radius": 2.4, "color": Color(0.20, 0.85, 1.0, 0.92)},
		{"anim": "2H_Melee_Attack_Spin", "mult": 1.55, "duration": 0.33, "lunge": 4.4, "radius": 2.7, "color": Color(0.15, 0.75, 1.0, 0.95)},
		{"anim": "2H_Melee_Attack_Slice", "mult": 2.30, "duration": 0.44, "lunge": 6.2, "radius": 3.2, "color": Color(0.65, 0.98, 1.0, 1.0)}
	]

	var combo_data = combo_data_ellen if is_cryo_char else combo_data_hutao
	var current_combo = combo_data[combo_stage]
	var dmg = int(attack_power * current_combo["mult"])

	# Sound & Voice
	if is_cryo_char:
		if combo_stage == 3:
			SoundSynth.play_sword_heavy(self)
			SoundSynth.play_ice_shatter(self)
			if randf() < 0.65:
				SoundSynth.play_voice_finisher(self)
		else:
			SoundSynth.play_frost_whoosh(self)
			if randf() < 0.35:
				SoundSynth.play_voice_attack(self)
	else:
		if combo_stage == 3:
			# 4th hit: Heavy finisher boom & roar + signature shout
			SoundSynth.play_sword_heavy(self)
			if randf() < 0.50:
				SoundSynth.play_voice_finisher(self)
		else:
			SoundSynth.play_sword_combo(self, combo_stage)
			if randf() < 0.22:
				SoundSynth.play_voice_attack(self)

	# Play Animation
	play_anim(current_combo["anim"], 0.04)

	# Tactile forward attack lunge (steps forward into the strike like Genshin characters)
	var fwd = visual_mesh.global_transform.basis.z
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_vec.length() > 0.1:
		var cam_fwd = -camera_pivot.global_transform.basis.z
		var cam_rt = camera_pivot.global_transform.basis.x
		cam_fwd.y = 0; cam_rt.y = 0
		fwd = (cam_fwd * (-input_vec.y) + cam_rt * input_vec.x).normalized()
		visual_mesh.rotation.y = atan2(fwd.x, fwd.z)
	elif locked_target and is_instance_valid(locked_target):
		var target_dir = (locked_target.global_position - global_position)
		target_dir.y = 0
		if target_dir.length() > 0.1:
			fwd = target_dir.normalized()
			visual_mesh.rotation.y = atan2(fwd.x, fwd.z)

	velocity += fwd * current_combo["lunge"]

	# Blade slash visual arc
	var arc_col: Color = current_combo["color"]
	if is_cryo_char:
		var cryo_colors = [
			Color(0.4, 0.92, 1.0, 0.88),
			Color(0.2, 0.85, 1.0, 0.92),
			Color(0.15, 0.75, 1.0, 0.95),
			Color(0.65, 0.98, 1.0, 1.0)
		]
		arc_col = cryo_colors[combo_stage]

	_spawn_sword_slash_arc(arc_col, current_combo["radius"], current_combo["duration"] * 0.7)

	# Hit detection with fiery impact sparks
	var bodies = attack_area.get_overlapping_bodies()
	var hit_any = false
	var hit_destructibles: Array[DestructibleProp] = []
	var hit_material = "flesh"
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			var is_pyro_finisher = (not is_cryo_char and combo_stage == 3)
			b.take_damage(dmg, is_pyro_finisher, combo_stage == 3, is_cryo_char)
			if b.has_method("apply_hitstop"):
				var enemy_stop = 0.06 if combo_stage == 3 else 0.04
				b.apply_hitstop(enemy_stop)
			hit_any = true
			var spark_scale = 1.4 if combo_stage == 3 else 1.0
			_spawn_flame_hit_sparks(b.global_position, spark_scale, is_cryo_char)
			# Heavy 4th hit knocks back enemies!
			if combo_stage == 3 and b is CharacterBody3D:
				var push_dir = (b.global_position - global_position).normalized()
				push_dir.y = 0.25
				b.velocity += push_dir * 6.5
			# Determine enemy material
			if "monster_type" in b:
				if b.monster_type == ChibiEnemy.MonsterType.SLIME:
					hit_material = "slime"
				elif b.monster_type == ChibiEnemy.MonsterType.SKELETON:
					hit_material = "bone"
				else:
					hit_material = "flesh"
			elif "slime" in b.name.to_lower():
				hit_material = "slime"
			elif "skel" in b.name.to_lower():
				hit_material = "bone"
			elif "cyber" in b.name.to_lower() or "mech" in b.name.to_lower():
				hit_material = "cyber"
		else:
			var d_prop = _find_destructible(b)
			if d_prop and not d_prop.is_destroyed and not d_prop in hit_destructibles:
				hit_destructibles.append(d_prop)
				d_prop.take_damage(dmg, false, combo_stage == 3, global_position)
				hit_any = true
				_spawn_flame_hit_sparks(d_prop.global_position + Vector3(0, 1.0, 0), 1.2 if combo_stage == 3 else 0.9, is_cryo_char)
				hit_material = _get_prop_material(d_prop)

	# Also check dedicated DestructibleHurtbox Area3D overlaps
	for a in attack_area.get_overlapping_areas():
		var d_prop = _find_destructible(a)
		if d_prop and not d_prop.is_destroyed and not d_prop in hit_destructibles:
			hit_destructibles.append(d_prop)
			d_prop.take_damage(dmg, false, combo_stage == 3, global_position)
			hit_any = true
			_spawn_flame_hit_sparks(d_prop.global_position + Vector3(0, 1.0, 0), 1.2 if combo_stage == 3 else 0.9, is_cryo_char)
			hit_material = _get_prop_material(d_prop)

	# Forward sweeping arc for large spires, mausoleums and mountain structures
	var fwd_sweep_center = global_position + visual_mesh.global_transform.basis.z * 1.8 + Vector3(0, 1.0, 0)
	for d in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(d) and d is DestructibleProp and not d.is_destroyed and not d in hit_destructibles:
			if fwd_sweep_center.distance_to(d.global_position) <= 4.2:
				hit_destructibles.append(d)
				d.take_damage(dmg, false, combo_stage == 3, global_position)
				hit_any = true
				_spawn_flame_hit_sparks(d.global_position + Vector3(0, 1.0, 0), 1.2 if combo_stage == 3 else 0.9, is_cryo_char)
				hit_material = _get_prop_material(d)

	if hit_any:
		SoundSynth.play_material_hit(self, hit_material)
		var shake_str = 0.10 if combo_stage == 3 else 0.05
		var stop_dur = 0.05 if combo_stage == 3 else 0.03
		_apply_hit_impact(stop_dur, shake_str)

	# Advance combo index or loop around
	if combo_stage >= 3:
		combo_stage = 0
		combo_reset_timer = 0.0
	else:
		combo_stage += 1
		combo_reset_timer = COMBO_WINDOW

	await get_tree().create_timer(current_combo["duration"]).timeout
	is_attacking = false
	await get_tree().create_timer(0.06).timeout
	can_attack = true

func _apply_hit_impact(hitstop_duration: float = 0.04, shake_amount: float = 0.06) -> void:
	# Local animation hitstop (frame freeze for weapon weight without freezing world/audio)
	if anim_player:
		anim_player.speed_scale = 0.02
		get_tree().create_timer(hitstop_duration, false).timeout.connect(func():
			if is_instance_valid(anim_player):
				anim_player.speed_scale = 1.0
		)

	# Punchy directional camera shake on offsets
	if camera_node:
		var ct = create_tween()
		var orig_h = camera_node.h_offset
		var orig_v = camera_node.v_offset
		camera_node.h_offset += randf_range(-shake_amount, shake_amount)
		camera_node.v_offset += randf_range(-shake_amount * 0.5, shake_amount * 0.5)
		ct.tween_property(camera_node, "h_offset", orig_h, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(camera_node, "v_offset", orig_v, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _spawn_sword_slash_arc(arc_color: Color = Color(1.0, 0.55, 0.1, 0.85), radius: float = 2.0, anim_dur: float = 0.18) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var arc = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.15
	mesh.rings = 1
	mesh.radial_segments = 16
	mesh.cap_top = false
	mesh.cap_bottom = false
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = arc_color
	arc.mesh = mesh
	arc.material_override = mat
	tree.current_scene.add_child(arc)
	arc.global_position = global_position + Vector3(0, 0.75, 0)
	arc.rotation.y = visual_mesh.rotation.y
	arc.scale = Vector3(0.35, 1.0, 0.35)
	var t = arc.create_tween().set_parallel(true)
	t.tween_property(arc, "scale", Vector3(1.15, 1.0, 1.15), anim_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, anim_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.finished.connect(func(): if is_instance_valid(arc): arc.queue_free())

func _spawn_flame_hit_sparks(pos: Vector3, scale_mult: float = 1.0, is_cryo: bool = false) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	# Impact slash flare
	var flare = MeshInstance3D.new()
	var f_mesh = QuadMesh.new()
	f_mesh.size = Vector2(0.9 * scale_mult, 0.9 * scale_mult)
	var f_mat = StandardMaterial3D.new()
	f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	f_mat.albedo_color = Color(0.40, 0.92, 1.0, 0.95) if is_cryo else Color(1.0, 0.85, 0.35, 0.95)
	flare.mesh = f_mesh
	flare.material_override = f_mat
	tree.current_scene.add_child(flare)
	flare.global_position = pos + Vector3(0, 0.75, 0)
	var ft = flare.create_tween()
	ft.tween_property(flare, "scale", Vector3(1.35, 1.35, 1.35), 0.12)
	ft.parallel().tween_property(f_mat, "albedo_color:a", 0.0, 0.12)
	ft.finished.connect(func(): if is_instance_valid(flare): flare.queue_free())

	# Sparks or frost crystals
	var p = CPUParticles3D.new()
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var mesh = SphereMesh.new()
	mesh.material = mat
	mesh.radius = 0.05
	mesh.height = 0.1
	p.mesh = mesh
	p.amount = 18
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3(0, 0.5, 0)
	p.spread = 180.0
	p.gravity = Vector3(0, -2.5, 0)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 8.5
	var grad = Gradient.new()
	if is_cryo:
		grad.colors = PackedColorArray([Color(0.85, 0.98, 1.0, 1), Color(0.3, 0.85, 1.0, 0.9), Color(0.05, 0.4, 0.9, 0)])
	else:
		grad.colors = PackedColorArray([Color(1.0, 0.9, 0.2, 1), Color(1.0, 0.45, 0.1, 0.9), Color(0.8, 0.1, 0.05, 0)])
	p.color_ramp = grad
	tree.current_scene.add_child(p)
	p.global_position = pos + Vector3(0, 0.8, 0)
	p.emitting = true
	tree.create_timer(0.4).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func toggle_target_lock() -> void:
	if locked_target and is_instance_valid(locked_target):
		locked_target = null
		AccessibilityManager.speak("Автоприцел выключен")
		return

	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node3D = null
	var min_dist = 999.0
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist < min_dist and dist < 25.0:
				min_dist = dist
				closest = e

	if closest:
		locked_target = closest
		SoundSynth.play_dash(self)
		AccessibilityManager.speak("Цель: " + closest.enemy_name + ", " + str(int(min_dist)) + " метров")
	else:
		AccessibilityManager.speak("Поблизости нет врагов")

func add_exp(amount: int) -> void:
	current_exp += amount
	exp_gained_event.emit(amount)
	AccessibilityManager.speak("Опыт +" + str(amount))
	if current_exp >= exp_to_next:
		level_up()
	emit_stats()

func level_up() -> void:
	current_exp -= exp_to_next
	level += 1
	exp_to_next = int(exp_to_next * 1.5)
	max_hp += 20
	current_hp = max_hp
	attack_power += 5
	SoundSynth.play_level_up_fanfare(self)
	SoundSynth.play_voice_lvlup(self)
	play_anim("Cheer", 0.1)
	_spawn_level_up_vfx()
	AccessibilityManager.speak_after_voice("Уровень " + str(level) + "! Сила атаки " + str(attack_power), 0.3)
	level_up_event.emit(level, max_hp, attack_power)
	emit_stats()

func _spawn_level_up_vfx() -> void:
	# Attached VFX root child so all effects move seamlessly with the player
	var vfx_root = Node3D.new()
	vfx_root.name = "LevelUpVFX"
	add_child(vfx_root)
	vfx_root.position = Vector3.ZERO

	# 1. Elegant Celestial Golden Mandala Ground Seal (fx_ascension_ring.png)
	var ring_mesh = MeshInstance3D.new()
	var q_mesh = PlaneMesh.new()
	q_mesh.size = Vector2(2.4, 2.4)
	ring_mesh.mesh = q_mesh

	var r_mat = StandardMaterial3D.new()
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	r_mat.albedo_texture = TEX_ASCENSION_RING
	r_mat.albedo_color = Color(1.0, 0.92, 0.65, 0.85)
	ring_mesh.material_override = r_mat
	vfx_root.add_child(ring_mesh)
	ring_mesh.position = Vector3(0.0, 0.05, 0.0)
	ring_mesh.scale = Vector3(0.4, 0.4, 0.4)

	var rt = ring_mesh.create_tween().set_parallel(true)
	rt.tween_property(ring_mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring_mesh, "rotation:y", deg_to_rad(45.0), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.chain().tween_property(r_mat, "albedo_color:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rt.parallel().tween_property(ring_mesh, "scale", Vector3(1.35, 1.35, 1.35), 0.55)

	# 2. Feathered Ethereal Light Shaft (fx_light_shaft.png)
	var shaft_node = Node3D.new()
	vfx_root.add_child(shaft_node)
	shaft_node.position = Vector3(0.0, 1.2, 0.0)

	var s_mat = StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	s_mat.albedo_texture = TEX_LIGHT_SHAFT
	s_mat.albedo_color = Color(1.0, 0.94, 0.70, 0.70)

	for ang in [0.0, PI * 0.5]:
		var shaft_quad = MeshInstance3D.new()
		var sq_mesh = QuadMesh.new()
		sq_mesh.size = Vector2(1.5, 2.6)
		shaft_quad.mesh = sq_mesh
		shaft_quad.material_override = s_mat
		shaft_quad.rotation.y = ang
		shaft_node.add_child(shaft_quad)

	shaft_node.scale = Vector3(0.3, 0.1, 0.3)
	var st = shaft_node.create_tween().set_parallel(true)
	st.tween_property(shaft_node, "scale", Vector3(1.0, 1.0, 1.0), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	st.tween_property(shaft_node, "position:y", 1.4, 0.90)
	st.chain().tween_property(s_mat, "albedo_color:a", 0.0, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	st.parallel().tween_property(shaft_node, "scale", Vector3(1.15, 1.25, 1.15), 0.50)

	# 3. Delicate Celestial Diamond Sparkles (fx_celestial_sparkle.png)
	var p = CPUParticles3D.new()
	p.name = "CelestialSparkles"
	var sp_mat = StandardMaterial3D.new()
	sp_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sp_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sp_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sp_mat.billboard_keep_scale = true
	sp_mat.vertex_color_use_as_albedo = true
	sp_mat.albedo_texture = TEX_CELESTIAL_SPARKLE

	var quad_sparkle = QuadMesh.new()
	quad_sparkle.size = Vector2(0.24, 0.24)
	quad_sparkle.material = sp_mat
	p.mesh = quad_sparkle
	p.amount = 16
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 0.45
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 0.8
	p.emission_ring_inner_radius = 0.2
	p.emission_ring_height = 0.2
	p.direction = Vector3(0, 1.0, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, 0.4, 0)
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.4
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.1

	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 0.8, 0.0),
		Color(1.0, 0.95, 0.7, 0.9),
		Color(1.0, 0.85, 0.5, 0.75),
		Color(1.0, 0.75, 0.3, 0.0)
	])
	p.color_ramp = grad
	vfx_root.add_child(p)
	p.position = Vector3(0.0, 0.15, 0.0)
	p.emitting = true

	# 4. Soft Golden Omni Radiance
	var aura_light = OmniLight3D.new()
	aura_light.light_color = Color(1.0, 0.88, 0.55)
	aura_light.light_energy = 1.6
	aura_light.omni_range = 4.5
	aura_light.omni_attenuation = 1.4
	aura_light.shadow_enabled = false
	vfx_root.add_child(aura_light)
	aura_light.position = Vector3(0.0, 0.8, 0.0)

	var lt = aura_light.create_tween()
	lt.tween_property(aura_light, "light_energy", 0.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Clean up entire attached VFX root after 1.4 seconds
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_instance_valid(vfx_root):
			vfx_root.queue_free()
	)

func take_damage(dmg: int) -> void:
	if is_dead or is_invulnerable:
		return

	current_hp = max(0, current_hp - dmg)
	SoundSynth.play_material_hit(self, "flesh")
	SoundSynth.play_voice_hurt(self)

	# Floating damage popup over player
	var parent = get_parent()
	if parent:
		DamageNumbers.spawn_player_hurt(parent, global_position + Vector3(0, 0.6, 0), dmg)

	# Red screen hit flash in UI
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui and parent:
		ui = parent.get_node_or_null("UI")
	if ui and ui.has_method("trigger_damage_flash"):
		ui.trigger_damage_flash()

	# Flinch squash
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(0.85, 1.15, 0.85), 0.08)
	tween.tween_property(visual_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.12)

	if current_hp <= 0:
		is_dead = true
		play_anim("Death_A", 0.1)
		AccessibilityManager.speak("Поражение! Возрождение через 3 секунды")
		await get_tree().create_timer(3.0).timeout
		current_hp = max_hp
		global_position = Vector3(0, 1, 0)
		is_dead = false
		play_anim("Idle", 0.2)
		AccessibilityManager.speak("Персонаж возрождён")
	else:
		if not is_attacking:
			play_anim("Hit_A", 0.05)
		if current_hp <= max_hp * 0.35:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_low_hp_alert_time > 8.0:
				last_low_hp_alert_time = current_time
				AccessibilityManager.speak("Мало здоровья: " + str(current_hp))

	emit_stats()

func on_equipment_updated(_slot_name: String, _item_data: Dictionary) -> void:
	_recalculate_equipment_stats()

func equip_item(item_name: String, stat_bonus: int, rarity: int) -> void:
	var item = {
		"id": "item_" + str(randi() % 99999),
		"name": item_name,
		"type": "weapon",
		"rarity": rarity,
		"bonus": stat_bonus,
		"stat_name": "Сила атаки",
		"desc": "Снаряжение героя.",
		"count": 1,
		"stackable": false
	}
	InventoryManager.add_item(item, true)
	_recalculate_equipment_stats()

func _recalculate_equipment_stats() -> void:
	attack_power = 15 + InventoryManager.get_attack_bonus()
	speed = 7.0 + InventoryManager.get_speed_bonus()
	emit_stats()

func emit_stats() -> void:
	stats_changed.emit(current_hp, max_hp, current_exp, exp_to_next, level, attack_power)

func _on_contrast_changed(active: bool) -> void:
	_apply_visual_contrast(active)

func _apply_visual_contrast(_active: bool) -> void:
	pass
