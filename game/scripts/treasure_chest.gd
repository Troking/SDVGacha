extends Area3D
class_name TreasureChest

enum ChestRarity { COMMON, EXQUISITE, PRECIOUS, LUXURIOUS }

@export var rarity: ChestRarity = ChestRarity.EXQUISITE
@export var theme_style: String = "" # Optional: "school", "cyber", "undead", etc.

var is_opened: bool = false
var is_player_nearby: bool = false
var float_time: float = 0.0

var active_vfx_color: Color = Color(1.0, 0.85, 0.3)
var active_chest_title: String = "Сундук сокровищ"

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
	# Define distinct vibrant colors & materials for each style
	var body_col = Color(0.48, 0.32, 0.18)
	var metal_col = Color(0.72, 0.50, 0.28)
	var gem_col = Color(0.18, 0.82, 0.75)
	var vfx_col = Color(0.85, 0.65, 0.35)
	var scale_mult = 0.90
	var metal_rough = 0.35
	var body_rough = 0.45
	var title = "Обычный деревянный сундук"

	var s = theme_style.to_lower()
	if s == "school":
		# Sakuragaoka High: Polished cherry/mahogany, school brass trim, pink sakura gem
		body_col = Color(0.52, 0.16, 0.18)
		metal_col = Color(0.92, 0.76, 0.32)
		gem_col = Color(1.0, 0.52, 0.75)
		vfx_col = Color(1.0, 0.65, 0.80)
		body_rough = 0.25
		metal_rough = 0.20
		scale_mult = 1.02
		title = "Школьный памятный ларец"
	elif s == "cyber":
		# Cyber City: Dark cyan-titanium tech chassis, electric neon cyan trim, pink holographic core
		body_col = Color(0.06, 0.09, 0.16)
		metal_col = Color(0.10, 0.88, 1.0)
		gem_col = Color(1.0, 0.15, 0.75)
		vfx_col = Color(0.15, 0.85, 1.0)
		body_rough = 0.15
		metal_rough = 0.10
		scale_mult = 1.08
		title = "Кибернетический контейнер"
	elif s == "undead":
		# Blighted Undead Crypt: Weathered basalt stone, dark forged iron, spectral emerald flame
		body_col = Color(0.15, 0.17, 0.20)
		metal_col = Color(0.45, 0.48, 0.54)
		gem_col = Color(0.18, 0.95, 0.45)
		vfx_col = Color(0.30, 0.92, 0.55)
		body_rough = 0.60
		metal_rough = 0.40
		scale_mult = 1.10
		title = "Склепный саркофаг"
	else:
		match rarity:
			ChestRarity.COMMON:
				# Common: Natural cedar oak, forged rustic bronze bands, bright turquoise jewel
				body_col = Color(0.48, 0.30, 0.16)
				metal_col = Color(0.72, 0.50, 0.28)
				gem_col = Color(0.18, 0.82, 0.75)
				vfx_col = Color(0.85, 0.65, 0.35)
				scale_mult = 0.90
				metal_rough = 0.35
				body_rough = 0.50
				title = "Обычный деревянный сундук"
			ChestRarity.EXQUISITE:
				# Exquisite: Vibrant sapphire/lazurite lacquer, mirror silver trim, aquamarine jewel
				body_col = Color(0.10, 0.38, 0.62)
				metal_col = Color(0.92, 0.95, 0.99)
				gem_col = Color(0.20, 0.78, 1.0)
				vfx_col = Color(0.28, 0.75, 1.0)
				scale_mult = 1.00
				metal_rough = 0.14
				body_rough = 0.22
				title = "Богатый лазурный сундук"
			ChestRarity.PRECIOUS:
				# Precious: Royal amethyst violet enamel, filigree rose gold trim, radiant star amethyst
				body_col = Color(0.38, 0.10, 0.48)
				metal_col = Color(0.96, 0.68, 0.40)
				gem_col = Color(0.88, 0.32, 1.0)
				vfx_col = Color(0.85, 0.42, 0.95)
				scale_mult = 1.08
				metal_rough = 0.18
				body_rough = 0.20
				title = "Драгоценный аметистовый сундук"
			ChestRarity.LUXURIOUS:
				# Luxurious: Imperial black obsidian lacquer, 24k radiant gold, blazing dragon ruby
				body_col = Color(0.07, 0.07, 0.09)
				metal_col = Color(1.0, 0.82, 0.18)
				gem_col = Color(1.0, 0.12, 0.20)
				vfx_col = Color(1.0, 0.84, 0.32)
				scale_mult = 1.18
				metal_rough = 0.10
				body_rough = 0.08
				title = "Роскошный императорский ларец"

	active_vfx_color = vfx_col
	active_chest_title = title

	# Apply custom materials to model meshes
	_apply_chest_materials(body_col, metal_col, gem_col, metal_rough, body_rough, scale_mult)

	# Gentle beacon light (soft, pleasant, non-blinding)
	if beacon_light:
		beacon_light.light_color = vfx_col
		beacon_light.light_energy = 0.85
		beacon_light.omni_range = 3.6

	# Subtle aura particles around chest
	if aura_particles:
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(vfx_col.r, vfx_col.g, vfx_col.b, 0.0),
			Color(vfx_col.r, vfx_col.g, vfx_col.b, 0.50),
			Color(vfx_col.r, vfx_col.g, vfx_col.b, 0.60),
			Color(vfx_col.r, vfx_col.g, vfx_col.b, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
		aura_particles.color_ramp = grad
		aura_particles.amount = 14

func _apply_chest_materials(body_col: Color, metal_col: Color, gem_col: Color, metal_rough: float, body_rough: float, scale_mult: float) -> void:
	var mat_body = StandardMaterial3D.new()
	mat_body.albedo_color = body_col
	mat_body.roughness = body_rough
	if body_col.v < 0.15: # Obsidian / high-tech lacquer
		mat_body.metallic = 0.25
		mat_body.clearcoat_enabled = true
		mat_body.clearcoat = 0.85

	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = metal_col
	mat_metal.metallic = 0.92
	mat_metal.roughness = metal_rough
	if metal_col.g > 0.8 and metal_col.b > 0.8: # Neon cyan
		mat_metal.emission_enabled = true
		mat_metal.emission = metal_col * 0.45

	var mat_gem = StandardMaterial3D.new()
	mat_gem.albedo_color = gem_col
	mat_gem.emission_enabled = true
	mat_gem.emission = gem_col * 1.5
	mat_gem.roughness = 0.12

	_apply_to_mesh_hierarchy(self, mat_body, mat_metal, mat_gem)
	if chest_model and scale_mult != 1.0:
		chest_model.scale = Vector3.ONE * 0.9 * scale_mult

func _apply_to_mesh_hierarchy(node: Node, m_body: Material, m_metal: Material, m_gem: Material) -> void:
	if node is MeshInstance3D:
		var n_name = node.name.to_lower()
		if "gem" in n_name:
			node.set_surface_override_material(0, m_gem)
		elif "base" in n_name or "lidmesh" in n_name or "wood" in n_name:
			node.set_surface_override_material(0, m_body)
		elif "trim" in n_name or "band" in n_name or "bracket" in n_name or "latch" in n_name or "plate" in n_name:
			node.set_surface_override_material(0, m_metal)
	for child in node.get_children():
		_apply_to_mesh_hierarchy(child, m_body, m_metal, m_gem)

func _process(delta: float) -> void:
	if is_opened:
		return

	# Gentle idle breathing bob
	float_time += delta * 2.2
	if chest_model:
		chest_model.position.y = sin(float_time) * 0.025

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
		prompt_label.text = "✦ [ F / ЛКМ ] Открыть ✦\n" + active_chest_title

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_opened:
		is_player_nearby = true
		_update_prompt()
		# Gentle pop squash when player approaches
		var t = create_tween()
		t.tween_property(self, "scale", Vector3(1.06, 0.95, 1.06), 0.10)
		t.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.12)

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

	# 2. Multi-stage Juicy Chest Opening Sequence (Tasteful, anime-styled, non-blinding):
	# A. Pleasant Anticipation Squash & Spring
	var t_squash = create_tween()
	t_squash.tween_property(self, "scale", Vector3(1.14, 0.88, 1.14), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_squash.tween_property(self, "scale", Vector3(0.96, 1.12, 0.96), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_squash.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# B. Animated Lid Fling (Backwards around X axis with pleasant spring)
	if lid_pivot:
		var t_lid = create_tween()
		t_lid.tween_property(lid_pivot, "rotation_degrees:x", -122.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# C. Radiance Flare: Warm, soft inner light emerging from the opened chest (non-blinding energy 1.6)
	var inner_light = OmniLight3D.new()
	inner_light.light_color = active_vfx_color.lerp(Color.WHITE, 0.35)
	inner_light.light_energy = 1.6
	inner_light.omni_range = 4.2
	inner_light.omni_attenuation = 1.4
	add_child(inner_light)
	inner_light.position = Vector3(0, 0.38, 0)

	# D. Soft Translucent Sunburst Pillar, Thin Ground Shockwave Ring & Stardust Fountain
	_spawn_fountain_burst()

	# E. Spew Out Abundant Juicy Resources in Parabolic Arcs
	await get_tree().create_timer(0.18).timeout
	_spew_loot_drops()

	# F. Subtle micro-shake feedback (tactile, non-jarring)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_apply_hit_impact"):
		player._apply_hit_impact(0.02, 0.04)

	# G. Exactly 1.0 second after opening: evaporate into stardust particles
	await get_tree().create_timer(1.0).timeout
	_dissolve_and_vanish(inner_light)

func _spawn_fountain_burst() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	# 1. Soft Translucent vertical light cylinder (ethereal beam, non-blinding 0.20 alpha)
	var beam = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.45
	b_mesh.bottom_radius = 0.22
	b_mesh.height = 3.6
	var b_mat = StandardMaterial3D.new()
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	b_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(active_vfx_color.r, active_vfx_color.g, active_vfx_color.b, 0.20)
	beam.mesh = b_mesh
	beam.material_override = b_mat
	tree.current_scene.add_child(beam)
	beam.global_position = global_position + Vector3(0, 1.8, 0)

	var bt = beam.create_tween().set_parallel(true)
	bt.tween_property(beam, "scale", Vector3(1.4, 1.0, 1.4), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bt.tween_property(b_mat, "albedo_color:a", 0.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bt.finished.connect(func(): if is_instance_valid(beam): beam.queue_free())

	# 2. Expanding thin shockwave ring along the ground (sleek runic ripple)
	var ring = MeshInstance3D.new()
	var r_mesh = TorusMesh.new()
	r_mesh.inner_radius = 0.38
	r_mesh.outer_radius = 0.42
	var r_mat = StandardMaterial3D.new()
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = Color(active_vfx_color.r, active_vfx_color.g, active_vfx_color.b, 0.30)
	ring.mesh = r_mesh
	ring.material_override = r_mat
	tree.current_scene.add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.05, 0)

	var rt = ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(3.6, 1.0, 3.6), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(r_mat, "albedo_color:a", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rt.finished.connect(func(): if is_instance_valid(ring): ring.queue_free())

	# 3. Delicate twinkling sparkles fountain
	var p = CPUParticles3D.new()
	var p_mat = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.032
	p_mesh.height = 0.064
	p_mesh.material = p_mat
	p.mesh = p_mesh
	p.amount = 26
	p.lifetime = 0.75
	p.one_shot = true
	p.explosiveness = 0.88
	p.direction = Vector3(0, 1.0, 0)
	p.spread = 45.0
	p.initial_velocity_min = 3.2
	p.initial_velocity_max = 5.8
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(active_vfx_color.r, active_vfx_color.g, active_vfx_color.b, 0.80),
		Color(1.0, 1.0, 0.9, 0.50),
		Color(active_vfx_color.r, active_vfx_color.g, active_vfx_color.b, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	p.color_ramp = grad
	tree.current_scene.add_child(p)
	p.global_position = global_position + Vector3(0, 0.4, 0)
	p.emitting = true
	tree.create_timer(1.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

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
		loot_count = 4
		exp_count = 6
	elif rarity == ChestRarity.PRECIOUS:
		loot_count = 6
		exp_count = 10
	elif rarity == ChestRarity.LUXURIOUS:
		loot_count = 8
		exp_count = 14

	# Spew equipment & items in fountain arc
	for i in range(loot_count):
		var loot = loot_scene.instantiate() as LootDrop
		loot.position = global_position + Vector3(0, 0.6, 0)
		scene.add_child(loot)
		var angle = (float(i) / float(loot_count)) * TAU + randf_range(-0.25, 0.25)
		var speed = randf_range(3.0, 5.0)
		loot.velocity = Vector3(cos(angle) * speed, randf_range(4.5, 7.0), sin(angle) * speed)

	# Spew bouncing golden EXP orbs
	for i in range(exp_count):
		var orb = exp_scene.instantiate()
		orb.position = global_position + Vector3(0, 0.7, 0)
		if "exp_value" in orb:
			orb.exp_value = 15
		scene.add_child(orb)
		var angle = randf() * TAU
		var spd = randf_range(2.0, 3.8)
		if "velocity" in orb:
			orb.velocity = Vector3(cos(angle) * spd, randf_range(4.0, 6.5), sin(angle) * spd)

func _dissolve_and_vanish(inner_light: OmniLight3D = null) -> void:
	# Audio whoosh chime
	SoundSynth.play_chest_vanish(self)

	# Ethereal dissolution: stretch upward into ray of light while shrinking to zero smoothly
	var dt = create_tween().set_parallel(true)
	dt.tween_property(self, "scale", Vector3(0.01, 1.8, 0.01), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dt.tween_property(self, "position:y", position.y + 0.5, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if chest_model and is_instance_valid(chest_model):
		dt.tween_property(chest_model, "scale", Vector3.ZERO, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if inner_light and is_instance_valid(inner_light):
		dt.tween_property(inner_light, "light_energy", 0.0, 0.32)
	if beacon_light and is_instance_valid(beacon_light):
		dt.tween_property(beacon_light, "light_energy", 0.0, 0.32)

	# Volumetric Disintegration Particle Cloud (soft stardust, non-blinding)
	var tree = get_tree()
	if tree and tree.current_scene:
		var p = CPUParticles3D.new()
		var p_mat = StandardMaterial3D.new()
		p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		p_mat.vertex_color_use_as_albedo = true
		var p_mesh = SphereMesh.new()
		p_mesh.radius = 0.035
		p_mesh.height = 0.070
		p_mesh.material = p_mat
		p.mesh = p_mesh
		p.amount = 38
		p.lifetime = 0.85
		p.one_shot = true
		p.explosiveness = 0.85
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(0.55, 0.35, 0.40)
		p.direction = Vector3(0, 1.0, 0)
		p.spread = 40.0
		p.gravity = Vector3(0, 1.0, 0)
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 4.2
		var grad = Gradient.new()
		grad.colors = PackedColorArray([
			Color(active_vfx_color.r, active_vfx_color.g, active_vfx_color.b, 0.60),
			Color(1.0, 0.95, 0.8, 0.40),
			Color(active_vfx_color.r, active_vfx_color.g, active_vfx_color.b, 0.0)
		])
		grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		p.color_ramp = grad
		tree.current_scene.add_child(p)
		p.global_position = global_position + Vector3(0, 0.3, 0)
		p.emitting = true
		tree.create_timer(1.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

	await dt.finished
	queue_free()
