extends CharacterBody3D
class_name ChibiEnemy

@export var enemy_name: String = "Слизнюк"
@export var max_hp: int = 40
@export var exp_reward: int = 25
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.8

var current_hp: int = 40
var player: CharacterBody3D = null
var can_attack: bool = true
var is_telegraphing: bool = false

# Genshin-style Poise & Stagger System
@export var max_poise: float = 24.0
var current_poise: float = 24.0
var is_staggered: bool = false
var stagger_timer: float = 0.0
var poise_recovery_timer: float = 0.0

enum MonsterType { SLIME, GOBLIN, SKELETON }
var monster_type: MonsterType = MonsterType.SLIME
var monster_color: Color = Color(0.3, 0.75, 0.35)
var is_aggroed: bool = false
var hop_timer: float = 0.0
var is_hopping: bool = false
var slime_hop_cooldown: float = 0.2

@onready var visual: Node3D = $Visual
@onready var hp_label: Label3D = $HpLabel

func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	var n = enemy_name.to_lower()
	if "гоблин" in n:
		monster_type = MonsterType.GOBLIN
	elif "скелет" in n:
		monster_type = MonsterType.SKELETON
	else:
		monster_type = MonsterType.SLIME

	update_hp_display()
	player = get_tree().get_first_node_in_group("player")
	AccessibilityManager.high_contrast_toggled.connect(_on_contrast_changed)
	_setup_monster_appearance()
	_apply_cel_shading()

func _setup_monster_appearance() -> void:
	var body = $Visual/Body as MeshInstance3D
	if not body or not body.material_override:
		return
	var mat = body.material_override.duplicate() as StandardMaterial3D
	body.material_override = mat

	var lower_name = enemy_name.to_lower()
	var eye_col = Color(1.0, 1.0, 0.0)
	if "лазурный" in lower_name:
		monster_color = Color(0.2, 0.65, 1.0)
		eye_col = Color(0.9, 1.0, 1.0)
	elif "изумрудный" in lower_name or "мшистый" in lower_name:
		monster_color = Color(0.25, 0.85, 0.35)
		eye_col = Color(1.0, 0.9, 0.2)
	elif "огненный" in lower_name or "лавовый" in lower_name or "искристый" in lower_name:
		monster_color = Color(1.0, 0.38, 0.12)
		eye_col = Color(1.0, 0.95, 0.3)
	elif "гоблин" in lower_name:
		monster_color = Color(0.38, 0.65, 0.28)
		eye_col = Color(1.0, 0.2, 0.1)
	elif "скелет" in lower_name or "костяной" in lower_name:
		monster_color = Color(0.92, 0.90, 0.84)
		eye_col = Color(0.4, 0.9, 1.0)
	elif "вурдалак" in lower_name or "чумной" in lower_name or "мясник" in lower_name:
		monster_color = Color(0.24, 0.36, 0.26)
		eye_col = Color(0.35, 1.0, 0.25)
	elif "некромант" in lower_name or "призрак" in lower_name:
		monster_color = Color(0.22, 0.16, 0.34)
		eye_col = Color(0.85, 0.35, 1.0)
	elif "ануб'рек" in lower_name:
		monster_color = Color(0.16, 0.14, 0.22)
		eye_col = Color(0.4, 1.0, 0.3)
	elif "дрон" in lower_name or "кибер-дрон" in lower_name:
		monster_color = Color(0.12, 0.16, 0.24)
		eye_col = Color(0.0, 0.95, 1.0)
	elif "механоид" in lower_name or "меха" in lower_name or "синт" in lower_name:
		monster_color = Color(0.22, 0.24, 0.30)
		eye_col = Color(1.0, 0.45, 0.1)
	elif "кибер-ниндзя" in lower_name or "спектр" in lower_name:
		monster_color = Color(0.08, 0.08, 0.12)
		eye_col = Color(1.0, 0.15, 0.75)
	elif "прометей" in lower_name or "титан" in lower_name:
		monster_color = Color(0.14, 0.16, 0.24)
		eye_col = Color(0.0, 1.0, 0.85)
	elif "босс" in lower_name or "владыка" in lower_name:
		monster_color = Color(0.85, 0.25, 0.88)
		eye_col = Color(1.0, 0.95, 0.2)
	else:
		monster_color = Color(0.3, 0.75, 0.35)
	mat.albedo_color = monster_color

	for eye_name in ["EyeLeft", "EyeRight"]:
		var eye = visual.get_node_or_null(eye_name) as MeshInstance3D
		if eye:
			var e_mat = StandardMaterial3D.new()
			e_mat.albedo_color = eye_col
			e_mat.emission_enabled = true
			e_mat.emission = eye_col
			e_mat.emission_energy_multiplier = 2.2
			eye.material_override = e_mat

func _apply_cel_shading() -> void:
	var shader = load("res://scripts/genshin_cel_shader.gdshader")
	var visual_node = get_node_or_null("Visual")
	if not shader or not visual_node:
		return
	for m in visual_node.find_children("*", "MeshInstance3D", true, false):
		if m is MeshInstance3D:
			var mat = m.material_override
			if not mat and m.mesh and m.mesh.get_surface_count() > 0:
				mat = m.get_active_material(0)
			
			var toon = ShaderMaterial.new()
			toon.shader = shader
			if mat is StandardMaterial3D:
				toon.set_shader_parameter("albedo_color", mat.albedo_color)
				if mat.albedo_texture:
					toon.set_shader_parameter("use_texture", true)
					toon.set_shader_parameter("albedo_texture", mat.albedo_texture)
				else:
					toon.set_shader_parameter("use_texture", false)
			m.material_override = toon

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	# 1. Realistic 3D Gravity
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif velocity.y < 0:
		velocity.y = 0.0

	# 2. Handle Stagger (interruption state from poise break)
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			is_staggered = false
			current_poise = max_poise
		# Smoothly decay knockback velocity with ground friction
		var fric = 16.0 if is_on_floor() else 3.5
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)
		velocity.z = move_toward(velocity.z, 0.0, fric * delta)
		move_and_slide()
		return

	# 3. Poise passive recovery
	if current_poise < max_poise:
		poise_recovery_timer += delta
		if poise_recovery_timer >= 2.0:
			current_poise = move_toward(current_poise, max_poise, 15.0 * delta)
	else:
		poise_recovery_timer = 0.0

	var dist = global_position.distance_to(player.global_position)
	# Distant monsters skip expensive pathing
	if dist > 32.0:
		is_aggroed = false
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		move_and_slide()
		return

	# Aggro notice audio
	if dist < 14.0 and not is_aggroed:
		is_aggroed = true
		if monster_type == MonsterType.GOBLIN:
			SoundSynth.play_goblin_alert(self)
		elif monster_type == MonsterType.SKELETON:
			SoundSynth.play_skeleton_alert(self)
		else:
			SoundSynth.play_slime_alert(self)
	elif dist >= 18.0:
		is_aggroed = false

	# AI Locomotion & Attacks
	if is_telegraphing:
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		move_and_slide()
		return

	if dist <= 1.9 and can_attack:
		attack_player()
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		move_and_slide()
		return

	var target_vx = 0.0
	var target_vz = 0.0

	if is_aggroed and dist > 1.9:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0

		# Face the target smoothly
		var target_rot = atan2(dir.x, dir.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_rot, 7.5 * delta)

		if monster_type == MonsterType.SLIME:
			_process_slime_hop_physics(delta, dir, dist)
		elif monster_type == MonsterType.GOBLIN:
			var spd = 3.5
			target_vx = dir.x * spd
			target_vz = dir.z * spd
			visual.position.y = abs(sin(Time.get_ticks_msec() * 0.012)) * 0.14
		else: # SKELETON
			var spd = 2.3
			target_vx = dir.x * spd
			target_vz = dir.z * spd
			visual.position.y = abs(sin(Time.get_ticks_msec() * 0.008)) * 0.08
	else:
		# Idle resting breathing pulse for slimes
		if monster_type == MonsterType.SLIME and is_on_floor() and not is_hopping:
			var breath = sin(Time.get_ticks_msec() * 0.0035) * 0.06
			visual.scale = Vector3(1.0 + breath, 1.0 - breath, 1.0 + breath)
		elif visual.position.y != 0.0:
			visual.position.y = move_toward(visual.position.y, 0.0, 2.0 * delta)

	# Apply target movement smoothly while preserving external knockback momentum
	if monster_type != MonsterType.SLIME or not is_aggroed:
		var accel = 14.0 if is_on_floor() else 3.5
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)
		velocity.z = move_toward(velocity.z, target_vz, accel * delta)

	move_and_slide()

func _process_slime_hop_physics(delta: float, dir: Vector3, dist: float) -> void:
	if is_hopping:
		# Mid-air hop stretching
		if not is_on_floor():
			visual.scale = Vector3(0.85, 1.28, 0.85)
		else:
			# Landed!
			is_hopping = false
			slime_hop_cooldown = randf_range(0.35, 0.60)
			# Squishy impact bounce on landing
			var lt = create_tween()
			lt.tween_property(visual, "scale", Vector3(1.35, 0.65, 1.35), 0.07)
			lt.tween_property(visual, "scale", Vector3(1.0, 1.0, 1.0), 0.14)
			SoundSynth.play_slime_hop(self)
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		slime_hop_cooldown -= delta
		if slime_hop_cooldown <= 0.0 and is_on_floor():
			is_hopping = true
			# Squash wind-up before leap
			var wt = create_tween()
			wt.tween_property(visual, "scale", Vector3(1.4, 0.55, 1.4), 0.10)
			wt.tween_callback(func():
				if is_instance_valid(self) and is_instance_valid(player):
					# Leap forward and upward!
					var hop_power = clamp(dist * 0.72, 3.2, 5.4)
					velocity.y = 4.4
					velocity.x = dir.x * hop_power
					velocity.z = dir.z * hop_power
			)

func attack_player() -> void:
	can_attack = false
	is_telegraphing = true

	# AUDIO TELEGRAPH: Thematic warning sound before monster strikes
	if monster_type == MonsterType.GOBLIN:
		SoundSynth.play_goblin_charge(self)
	elif monster_type == MonsterType.SKELETON:
		SoundSynth.play_skeleton_alert(self)
	else:
		SoundSynth.play_slime_charge(self)

	# Visual wind-up (coiling/compressing)
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector3(1.45, 0.55, 1.45), 0.32)
	await tween.finished

	# Strike!
	if monster_type == MonsterType.GOBLIN:
		SoundSynth.play_goblin_attack(self)
	elif monster_type == MonsterType.SKELETON:
		SoundSynth.play_hit(self)
	else:
		SoundSynth.play_slime_attack(self)

	# Snappy forward strike lunge
	if is_instance_valid(player):
		var strike_dir = (player.global_position - global_position).normalized()
		strike_dir.y = 0.2
		velocity += strike_dir * 5.2

	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 2.2:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

	var tween_back = create_tween()
	tween_back.tween_property(visual, "scale", Vector3(1.0, 1.0, 1.0), 0.18)
	await tween_back.finished

	is_telegraphing = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(dmg: int, is_pyro: bool = false, is_crit: bool = false) -> void:
	current_hp -= dmg
	update_hp_display()

	# Spawn floating combat damage popup above enemy
	var parent = get_parent()
	if is_crit:
		DamageNumbers.spawn_crit(parent, global_position + Vector3(0, 0.4, 0), dmg)
	elif is_pyro:
		DamageNumbers.spawn_pyro(parent, global_position + Vector3(0, 0.4, 0), dmg)
	else:
		DamageNumbers.spawn_physical(parent, global_position + Vector3(0, 0.4, 0), dmg)

	# White-hot / fiery impact flash on enemy cel-shader
	var flash_col = Color(1.0, 0.45, 0.1) if is_pyro else Color(1.0, 0.95, 0.85)
	for m in visual.find_children("*", "MeshInstance3D", true, false):
		if m is MeshInstance3D and m.material_override is ShaderMaterial:
			var smat = m.material_override as ShaderMaterial
			smat.set_shader_parameter("hit_flash", 0.80)
			smat.set_shader_parameter("hit_flash_color", flash_col)
			var ft = create_tween()
			ft.tween_method(func(val: float):
				if is_instance_valid(smat):
					smat.set_shader_parameter("hit_flash", val)
			, 0.80, 0.0, 0.08)

	# Juicy Impact Audio (crunchy pop on hit)
	SoundSynth.play_juicy_hit(self)

	# Exaggerated Genshin Squash & Stretch on hit
	var tween = create_tween()
	var squash_scale = Vector3(1.35, 0.65, 1.35) if is_crit else Vector3(1.22, 0.78, 1.22)
	var stretch_scale = Vector3(0.82, 1.25, 0.82) if is_crit else Vector3(0.9, 1.15, 0.9)
	tween.tween_property(visual, "scale", squash_scale, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", stretch_scale, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", Vector3(1.0, 1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Poise damage & Genshin Stagger Interruption
	var poise_dmg = 12.0 if not is_pyro else (28.0 if is_crit else 7.0)
	current_poise -= poise_dmg
	poise_recovery_timer = 0.0

	# Break poise -> Stagger interrupt!
	if current_poise <= 0.0 and not is_staggered and current_hp > 0:
		is_staggered = true
		stagger_timer = 0.55
		is_telegraphing = false
		can_attack = true

		if is_instance_valid(player):
			var knock_dir = (global_position - player.global_position).normalized()
			knock_dir.y = 0.35
			velocity = knock_dir * (7.5 if is_crit else 4.8)
			move_and_slide()

		var stagger_tween = create_tween()
		stagger_tween.tween_property(visual, "scale", Vector3(1.35, 0.65, 1.35), 0.08)
		stagger_tween.tween_property(visual, "scale", Vector3(0.85, 1.25, 0.85), 0.16)
		stagger_tween.tween_property(visual, "scale", Vector3(1.0, 1.0, 1.0), 0.15)

	if current_hp <= 0:
		die()
	else:
		# Play thematic hurt sound
		if monster_type == MonsterType.GOBLIN:
			SoundSynth.play_goblin_hurt(self)
		elif monster_type == MonsterType.SKELETON:
			SoundSynth.play_skeleton_alert(self)
		else:
			SoundSynth.play_slime_hurt(self)

func die() -> void:
	# Immediately disable collision and hide visual components
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col: col.set_deferred("disabled", true)
	visual.visible = false
	if hp_label: hp_label.visible = false
	if has_node("EnemyHpBar"): $EnemyHpBar.visible = false

	var tree = get_tree()
	var scene = tree.current_scene if tree else get_parent()
	var death_pos = global_position
	var is_boss = "босс" in enemy_name.to_lower() or "владыка" in enemy_name.to_lower()

	# Thematic defeat audio & juicy death VFX
	if monster_type == MonsterType.GOBLIN:
		SoundSynth.play_goblin_die(self)
		MonsterDeathVFX.spawn_goblin_defeat(scene, death_pos)
	elif monster_type == MonsterType.SKELETON:
		SoundSynth.play_skeleton_die(self)
		MonsterDeathVFX.spawn_skeleton_collapse(scene, death_pos)
	else:
		SoundSynth.play_slime_die(self)
		MonsterDeathVFX.spawn_slime_burst(scene, death_pos, monster_color, is_boss)

	# Spawn magnetic flying EXP orbs
	_spawn_exp_orbs()

	# Spawn Loot
	_spawn_loot()
	queue_free()

func _spawn_exp_orbs() -> void:
	var orb_scene = preload("res://scenes/exp_orb.tscn")
	var num_orbs = clamp(int(exp_reward / 8), 2, 5)
	var exp_each = int(exp_reward / num_orbs)
	var remainder = exp_reward - (exp_each * num_orbs)
	for i in range(num_orbs):
		var orb = orb_scene.instantiate()
		orb.exp_value = exp_each + (remainder if i == 0 else 0)
		orb.global_position = global_position + Vector3(randf_range(-0.4, 0.4), randf_range(0.3, 0.7), randf_range(-0.4, 0.4))
		get_parent().add_child(orb)

func _spawn_loot() -> void:
	var loot_scene = preload("res://scenes/loot_drop.tscn")
	var num_loot = randi_range(2, 4)
	if "босс" in enemy_name.to_lower() or "владыка" in enemy_name.to_lower():
		num_loot = 6
	for i in range(num_loot):
		var loot = loot_scene.instantiate()
		loot.global_position = global_position + Vector3(randf_range(-0.4, 0.4), 0.5, randf_range(-0.4, 0.4))
		get_parent().add_child(loot)

func update_hp_display() -> void:
	if hp_label:
		hp_label.text = enemy_name + " (" + str(current_hp) + "/" + str(max_hp) + ")"
	if has_node("EnemyHpBar"):
		$EnemyHpBar.update_hp(current_hp, max_hp)

func _on_contrast_changed(active: bool) -> void:
	_apply_visual_contrast(active)

func _apply_visual_contrast(active: bool) -> void:
	var mesh = $Visual/Body as MeshInstance3D
	if mesh and mesh.material_override:
		var mat = mesh.material_override as StandardMaterial3D
		if active:
			mat.albedo_color = Color(1.0, 0.2, 0.1) # Bright alert red
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.1, 0.0)
		else:
			mat.albedo_color = Color(0.8, 0.4, 0.2)
			mat.emission_enabled = false

func apply_hitstop(duration: float = 0.05) -> void:
	var old_vel = velocity
	velocity = Vector3.ZERO
	await get_tree().create_timer(duration, false).timeout
	if is_instance_valid(self):
		velocity = old_vel
