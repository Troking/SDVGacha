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

	# Check interaction key 'F' or 'E' or Attack when in range
	if is_player_nearby and not is_opened:
		if Input.is_action_just_pressed("attack") or Input.is_key_pressed(KEY_F):
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
		prompt_label.text = "[ F / ЛКМ ] Открыть\n" + rarity_names.get(rarity, "Сундук сокровищ")

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

	# 1. Play rich audio: unlock click, lid whoosh and celestial chime
	SoundSynth.play_chest_open(self)

	# 2. Genshin Impact Juicy Chest Opening Sequence:
	# A. Anticipation Squash
	var t_squash = create_tween()
	t_squash.tween_property(self, "scale", Vector3(1.22, 0.78, 1.22), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_squash.tween_property(self, "scale", Vector3(0.92, 1.25, 0.92), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_squash.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# B. Dramatic Lid Fling (Rotates -115 degrees backwards around X axis)
	if lid_pivot:
		var t_lid = create_tween()
		t_lid.tween_property(lid_pivot, "rotation_degrees:x", -118.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# C. Spawn Brilliant Golden Sunburst Fountain Particles
	_spawn_fountain_burst()

	# D. Spew Out Abundant Juicy Resources
	await get_tree().create_timer(0.18).timeout
	_spew_loot_drops()

	# E. Camera Juice Impact
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_apply_hit_impact"):
		player._apply_hit_impact(0.04, 0.08)

	# F. Dissolve and vanish chest smoothly into stardust
	await get_tree().create_timer(2.2).timeout
	_dissolve_and_vanish()

func _spawn_fountain_burst() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	# Ascending golden light cylinder
	var beam = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.8
	b_mesh.bottom_radius = 0.4
	b_mesh.height = 4.0
	var b_mat = StandardMaterial3D.new()
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	b_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	b_mat.albedo_color = Color(1.0, 0.9, 0.4, 0.85)
	beam.mesh = b_mesh
	beam.material_override = b_mat
	tree.current_scene.add_child(beam)
	beam.global_position = global_position + Vector3(0, 2.0, 0)

	var bt = beam.create_tween().set_parallel(true)
	bt.tween_property(beam, "scale", Vector3(1.6, 1.0, 1.6), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bt.tween_property(b_mat, "albedo_color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bt.finished.connect(func(): if is_instance_valid(beam): beam.queue_free())

	# Explosive gold sparkles
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
	p.amount = 40
	p.lifetime = 0.85
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector3(0, 1.0, 0)
	p.spread = 55.0
	p.initial_velocity_min = 4.5
	p.initial_velocity_max = 8.5
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 0.95, 0.5, 1), Color(1, 0.65, 0.15, 0.9), Color(1, 0.25, 0.05, 0)])
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
		loot_count = 4
		exp_count = 6
	elif rarity == ChestRarity.PRECIOUS:
		loot_count = 6
		exp_count = 10
	elif rarity == ChestRarity.LUXURIOUS:
		loot_count = 8
		exp_count = 16

	# Spew equipment & items in fountain arc
	for i in range(loot_count):
		var loot = loot_scene.instantiate() as LootDrop
		loot.position = global_position + Vector3(0, 0.7, 0)
		scene.add_child(loot)
		# Arc trajectory
		var angle = (float(i) / float(loot_count)) * TAU + randf_range(-0.3, 0.3)
		var speed = randf_range(3.2, 5.5)
		loot.velocity = Vector3(cos(angle) * speed, randf_range(5.0, 8.0), sin(angle) * speed)

	# Spew bouncing golden EXP orbs
	for i in range(exp_count):
		var orb = exp_scene.instantiate()
		orb.position = global_position + Vector3(0, 0.8, 0)
		orb.exp_amount = 15
		scene.add_child(orb)
		var angle = randf() * TAU
		var spd = randf_range(2.0, 4.2)
		if "velocity" in orb:
			orb.velocity = Vector3(cos(angle) * spd, randf_range(4.5, 7.5), sin(angle) * spd)

func _dissolve_and_vanish() -> void:
	# Ethereal dissolution: shrink into vertical light ray and disappear silently
	var dt = create_tween().set_parallel(true)
	dt.tween_property(self, "scale", Vector3(0.01, 2.5, 0.01), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dt.tween_property(self, "position:y", position.y + 0.6, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Disappear burst
	var tree = get_tree()
	if tree and tree.current_scene:
		var p = CPUParticles3D.new()
		var p_mat = StandardMaterial3D.new()
		p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		p_mat.vertex_color_use_as_albedo = true
		var p_mesh = SphereMesh.new()
		p_mesh.radius = 0.04
		p_mesh.height = 0.08
		p_mesh.material = p_mat
		p.mesh = p_mesh
		p.amount = 25
		p.lifetime = 0.6
		p.one_shot = true
		p.explosiveness = 0.95
		p.direction = Vector3(0, 1, 0)
		p.spread = 70.0
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 4.5
		var grad = Gradient.new()
		grad.colors = PackedColorArray([Color(1, 0.95, 0.7, 1), Color(1, 0.6, 0.2, 0.7), Color(0.3, 0.05, 0.02, 0)])
		p.color_ramp = grad
		tree.current_scene.add_child(p)
		p.global_position = global_position + Vector3(0, 0.3, 0)
		p.emitting = true
		tree.create_timer(0.9).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

	await dt.finished
	queue_free()
