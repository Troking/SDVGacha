extends Area3D
class_name TreasureChest

enum ChestRarity { COMMON, EXQUISITE, PRECIOUS, LUXURIOUS }

@export var rarity: ChestRarity = ChestRarity.EXQUISITE

var is_opened: bool = false
var is_player_nearby: bool = false
var float_time: float = 0.0

@onready var chest_model: Node3D = $Model/TreasureChest
@onready var lid_pivot: Node3D = null
@onready var prompt_label: Label3D = $PromptLabel
@onready var aura_particles: CPUParticles3D = $AuraParticles
@onready var beacon_light: OmniLight3D = $BeaconLight

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Locate lid pivot in the instantiated chest model
	if chest_model:
		lid_pivot = chest_model.find_child("ChestLidPivot", true, false) as Node3D

	_setup_rarity_styling()
	_update_prompt()

func _setup_rarity_styling() -> void:
	var color_map = {
		ChestRarity.COMMON: Color(0.85, 0.70, 0.45),
		ChestRarity.EXQUISITE: Color(0.25, 0.75, 1.0),
		ChestRarity.PRECIOUS: Color(0.95, 0.45, 1.0),
		ChestRarity.LUXURIOUS: Color(1.0, 0.85, 0.2)
	}
	var c = color_map.get(rarity, Color(1.0, 0.85, 0.2))

	if beacon_light:
		beacon_light.light_color = c
		beacon_light.light_energy = 1.6

	if aura_particles:
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(c.r, c.g, c.b, 0.0),
			Color(c.r, c.g, c.b, 0.85),
			Color(1.0, 1.0, 0.9, 0.95),
			Color(c.r, c.g, c.b, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
		aura_particles.color_ramp = grad

func _process(delta: float) -> void:
	if is_opened:
		return

	# Gentle idle breathing bob & magical shimmer
	float_time += delta * 2.5
	if chest_model:
		chest_model.position.y = sin(float_time) * 0.035

	# Fallback interaction check
	if is_player_nearby and not is_opened:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack") or Input.is_key_pressed(KEY_F) or Input.is_physical_key_pressed(KEY_F):
			open_chest()

func _unhandled_input(event: InputEvent) -> void:
	if is_player_nearby and not is_opened:
		var key_code = 0
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			key_code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if event.is_action_pressed("interact") or event.is_action_pressed("attack") or key_code == KEY_F or key_code == 0x410: # Russian 'А'
			open_chest()

func _update_prompt() -> void:
	if not prompt_label:
		return
	if is_opened:
		prompt_label.visible = false
	else:
		prompt_label.visible = is_player_nearby
		var rarity_names = {
			ChestRarity.COMMON: "Обычный сундук",
			ChestRarity.EXQUISITE: "Богатый сундук",
			ChestRarity.PRECIOUS: "Драгоценный сундук",
			ChestRarity.LUXURIOUS: "Роскошный сундук"
		}
		prompt_label.text = "✦ [ F / ЛКМ ] Открыть ✦\n" + rarity_names.get(rarity, "Сундук сокровищ")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_opened:
		is_player_nearby = true
		_update_prompt()
		# Subtle pop squash when player approaches
		var t = create_tween()
		t.tween_property(self, "scale", Vector3(1.1, 0.92, 1.1), 0.1)
		t.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.15)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		_update_prompt()

func open_chest() -> void:
	if is_opened:
		return
	is_opened = true
	_update_prompt()

	# Double check lid pivot resolution
	if not lid_pivot:
		lid_pivot = find_child("ChestLidPivot", true, false) as Node3D

	# 1. Play rich audio: unlock click, lid whoosh and celestial chime
	SoundSynth.play_chest_open(self)

	# 2. Multi-stage Juicy Chest Opening Sequence:
	# A. Anticipation Squash & Energetic Tremble
	var t_squash = create_tween()
	t_squash.tween_property(self, "scale", Vector3(1.24, 0.76, 1.24), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_squash.tween_property(self, "scale", Vector3(0.92, 1.26, 0.92), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_squash.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# B. Dramatic Animated Lid Fling (Rotates backwards around X axis with springy bounce)
	if lid_pivot:
		var t_lid = create_tween()
		t_lid.tween_property(lid_pivot, "rotation_degrees:x", -124.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# C. Radiance Flare: Glowing inner omni light emerging from the opened chest
	var inner_light = OmniLight3D.new()
	inner_light.light_color = Color(1.0, 0.88, 0.45)
	inner_light.light_energy = 5.5
	inner_light.omni_range = 6.5
	inner_light.omni_attenuation = 1.1
	add_child(inner_light)
	inner_light.position = Vector3(0, 0.45, 0)

	# D. Spawn Brilliant Sunburst Pillar, Expanding Ground Shockwave Ring & Stardust Fountain
	_spawn_fountain_burst()

	# E. Spew Out Abundant Juicy Resources in Parabolic Arcs
	await get_tree().create_timer(0.18).timeout
	_spew_loot_drops()

	# F. Camera Juice Impact & Screen Shake
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_apply_hit_impact"):
		player._apply_hit_impact(0.05, 0.09)

	# G. Exactly 1.0 second after opening: evaporate into stardust particles
	await get_tree().create_timer(1.0).timeout
	_dissolve_and_vanish(inner_light)

func _spawn_fountain_burst() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	# 1. Ascending vertical golden light cylinder
	var beam = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.9
	b_mesh.bottom_radius = 0.45
	b_mesh.height = 5.2
	var b_mat = StandardMaterial3D.new()
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	b_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(1.0, 0.92, 0.45, 0.90)
	beam.mesh = b_mesh
	beam.material_override = b_mat
	tree.current_scene.add_child(beam)
	beam.global_position = global_position + Vector3(0, 2.6, 0)

	var bt = beam.create_tween().set_parallel(true)
	bt.tween_property(beam, "scale", Vector3(1.8, 1.0, 1.8), 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bt.tween_property(b_mat, "albedo_color:a", 0.0, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bt.finished.connect(func(): if is_instance_valid(beam): beam.queue_free())

	# 2. Expanding golden shockwave ring along the ground
	var ring = MeshInstance3D.new()
	var r_mesh = TorusMesh.new()
	r_mesh.inner_radius = 0.35
	r_mesh.outer_radius = 0.48
	var r_mat = StandardMaterial3D.new()
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.95)
	ring.mesh = r_mesh
	ring.material_override = r_mat
	tree.current_scene.add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.05, 0)

	var rt = ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(5.5, 1.0, 5.5), 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(r_mat, "albedo_color:a", 0.0, 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rt.finished.connect(func(): if is_instance_valid(ring): ring.queue_free())

	# 3. Explosive gold sparkles fountain
	var p = CPUParticles3D.new()
	var p_mat = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.05
	p_mesh.height = 0.1
	p_mesh.material = p_mat
	p.mesh = p_mesh
	p.amount = 55
	p.lifetime = 0.90
	p.one_shot = true
	p.explosiveness = 0.92
	p.direction = Vector3(0, 1.0, 0)
	p.spread = 55.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 9.5
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 0.98, 0.6, 1), Color(1, 0.70, 0.2, 0.9), Color(1, 0.25, 0.05, 0)])
	p.color_ramp = grad
	tree.current_scene.add_child(p)
	p.global_position = global_position + Vector3(0, 0.5, 0)
	p.emitting = true
	tree.create_timer(1.2).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func _spew_loot_drops() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var scene = tree.current_scene
	var loot_scene = preload("res://scenes/loot_drop.tscn")
	var exp_scene = preload("res://scenes/exp_orb.tscn")

	# Number of drops based on rarity
	var loot_count = 3
	var exp_count = 4
	if rarity == ChestRarity.EXQUISITE:
		loot_count = 5
		exp_count = 7
	elif rarity == ChestRarity.PRECIOUS:
		loot_count = 7
		exp_count = 12
	elif rarity == ChestRarity.LUXURIOUS:
		loot_count = 10
		exp_count = 18

	# Spew equipment & items in fountain arc
	for i in range(loot_count):
		var loot = loot_scene.instantiate() as LootDrop
		loot.position = global_position + Vector3(0, 0.7, 0)
		scene.add_child(loot)
		var angle = (float(i) / float(loot_count)) * TAU + randf_range(-0.3, 0.3)
		var speed = randf_range(3.5, 6.0)
		loot.velocity = Vector3(cos(angle) * speed, randf_range(5.5, 8.5), sin(angle) * speed)

	# Spew bouncing golden EXP orbs
	for i in range(exp_count):
		var orb = exp_scene.instantiate()
		orb.position = global_position + Vector3(0, 0.8, 0)
		if "exp_value" in orb:
			orb.exp_value = 15
		scene.add_child(orb)
		var angle = randf() * TAU
		var spd = randf_range(2.2, 4.5)
		if "velocity" in orb:
			orb.velocity = Vector3(cos(angle) * spd, randf_range(4.5, 7.8), sin(angle) * spd)

func _dissolve_and_vanish(inner_light: OmniLight3D = null) -> void:
	# Audio whoosh chime
	SoundSynth.play_chest_vanish(self)

	# Ethereal dissolution: stretch upward into ray of light while shrinking to zero
	var dt = create_tween().set_parallel(true)
	dt.tween_property(self, "scale", Vector3(0.01, 2.6, 0.01), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dt.tween_property(self, "position:y", position.y + 0.9, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if chest_model and is_instance_valid(chest_model):
		dt.tween_property(chest_model, "scale", Vector3.ZERO, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if inner_light and is_instance_valid(inner_light):
		dt.tween_property(inner_light, "light_energy", 0.0, 0.35)
	if beacon_light and is_instance_valid(beacon_light):
		dt.tween_property(beacon_light, "light_energy", 0.0, 0.35)

	# Volumetric Disintegration Particle Cloud (dissolves into stardust)
	var tree = get_tree()
	if tree and tree.current_scene:
		var p = CPUParticles3D.new()
		var p_mat = StandardMaterial3D.new()
		p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		p_mat.vertex_color_use_as_albedo = true
		var p_mesh = SphereMesh.new()
		p_mesh.radius = 0.05
		p_mesh.height = 0.10
		p_mesh.material = p_mat
		p.mesh = p_mesh
		p.amount = 75
		p.lifetime = 0.95
		p.one_shot = true
		p.explosiveness = 0.90
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(0.7, 0.45, 0.5)
		p.direction = Vector3(0, 1.0, 0)
		p.spread = 50.0
		p.gravity = Vector3(0, 1.6, 0)
		p.initial_velocity_min = 2.8
		p.initial_velocity_max = 5.8
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(1.0, 0.98, 0.7, 1.0),
			Color(1.0, 0.75, 0.25, 0.9),
			Color(0.85, 0.35, 1.0, 0.65),
			Color(0.2, 0.05, 0.5, 0.0)
		])
		p.color_ramp = grad
		tree.current_scene.add_child(p)
		p.global_position = global_position + Vector3(0, 0.4, 0)
		p.emitting = true
		tree.create_timer(1.3).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

		# Upward dissolving light flash
		var flash = MeshInstance3D.new()
		var f_mesh = CylinderMesh.new()
		f_mesh.top_radius = 0.1
		f_mesh.bottom_radius = 0.6
		f_mesh.height = 2.4
		var f_mat = StandardMaterial3D.new()
		f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		f_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		f_mat.albedo_color = Color(1.0, 0.9, 0.5, 0.8)
		flash.mesh = f_mesh
		flash.material_override = f_mat
		tree.current_scene.add_child(flash)
		flash.global_position = global_position + Vector3(0, 1.2, 0)
		var ft = flash.create_tween().set_parallel(true)
		ft.tween_property(flash, "scale", Vector3(1.6, 2.0, 1.6), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ft.tween_property(f_mat, "albedo_color:a", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ft.finished.connect(func(): if is_instance_valid(flash): flash.queue_free())

	await dt.finished
	queue_free()
