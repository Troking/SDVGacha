extends Area3D
class_name LootDrop

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum ItemType { WEAPON, SHIELD, BOOTS, POTION, EXP_CRYSTAL }

var item_name: String = ""
var rarity: Rarity = Rarity.COMMON
var item_type: ItemType = ItemType.WEAPON
var bonus_val: int = 5
var item_data: Dictionary = {}

var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var is_collected: bool = false
var float_time: float = 0.0
var magnet_speed: float = 0.0
const MAGNET_RADIUS: float = 4.8

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D
@onready var light_beam: MeshInstance3D = $LightBeam
@onready var omni_light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_generate_random_loot()
	_update_appearance()

	# Initial physical burst upwards and in random direction
	velocity = Vector3(
		randf_range(-2.8, 2.8),
		randf_range(3.5, 6.0),
		randf_range(-2.8, 2.8)
	)

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	if not is_grounded:
		velocity.y -= 14.0 * delta
		global_position += velocity * delta
		if global_position.y <= 0.4:
			global_position.y = 0.4
			velocity = Vector3.ZERO
			is_grounded = true
	else:
		float_time += delta * 3.0
		mesh_instance.position.y = 0.4 + sin(float_time) * 0.08
		mesh_instance.rotate_y(2.5 * delta)

		# Genshin-style Magnetic Loot Vacuum
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var player_target = player.global_position + Vector3(0, 0.7, 0)
			var dist = global_position.distance_to(player_target)
			if dist <= MAGNET_RADIUS:
				magnet_speed = move_toward(magnet_speed, 16.0, delta * 28.0)
				var dir = (player_target - global_position).normalized()
				global_position += dir * magnet_speed * delta
				if dist <= 0.75:
					_collect_loot(player)

func _generate_random_loot() -> void:
	var roll = randf()
	if roll < 0.45:
		rarity = Rarity.COMMON
	elif roll < 0.75:
		rarity = Rarity.RARE
	elif roll < 0.92:
		rarity = Rarity.EPIC
	else:
		rarity = Rarity.LEGENDARY

	var type_roll = randf()
	var item_key = "sword_wood"

	if type_roll < 0.35:
		item_type = ItemType.WEAPON
		var weapon_keys = [
			"sword_wood",
			"sword_steel",
			"sword_epic",
			"sword_legend"
		]
		item_key = weapon_keys[rarity]

	elif type_roll < 0.60:
		item_type = ItemType.SHIELD
		var shield_keys = [
			"shield_common",
			"shield_rare",
			"shield_epic",
			"shield_legend"
		]
		item_key = shield_keys[rarity]

	elif type_roll < 0.80:
		item_type = ItemType.BOOTS
		var boots_keys = [
			"boots_common",
			"boots_rare",
			"boots_epic",
			"boots_legend"
		]
		item_key = boots_keys[rarity]

	elif type_roll < 0.92:
		item_type = ItemType.POTION
		item_key = "potion_hp"
		rarity = Rarity.RARE

	else:
		item_type = ItemType.EXP_CRYSTAL
		item_key = "crystal_exp"
		rarity = Rarity.EPIC

	item_data = InventoryManager.create_item(item_key)
	item_name = item_data.get("name", "Предмет")
	bonus_val = item_data.get("bonus", 5)

	var rarity_names = ["Обычный", "Редкий", "Эпический", "Легендарный"]
	label.text = "[" + rarity_names[rarity] + "]\n" + item_name

func _update_appearance() -> void:
	var colors = [
		Color(0.85, 0.88, 0.95), # Common Gray/White
		Color(0.25, 0.65, 1.0),  # Rare Cyan/Blue
		Color(0.85, 0.35, 1.0),  # Epic Violet/Magenta
		Color(1.0, 0.82, 0.2)    # Legendary Radiant Gold
	]
	var c = colors[rarity]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c * 0.75
	mesh_instance.material_override = mat

	if light_beam:
		var beam_mat = StandardMaterial3D.new()
		beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beam_mat.albedo_color = Color(c.r, c.g, c.b, 0.6)
		light_beam.material_override = beam_mat

	if omni_light:
		omni_light.light_color = c
		omni_light.light_energy = 1.2 if rarity < Rarity.EPIC else 2.5

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_collected:
		_collect_loot(body)

func _collect_loot(player: Node3D) -> void:
	if is_collected:
		return
	is_collected = true

	# Add to player inventory
	InventoryManager.add_item(item_data, true)

	# If exp crystal, also grant immediate EXP feedback
	if item_type == ItemType.EXP_CRYSTAL and player.has_method("add_exp"):
		player.add_exp(bonus_val)

	SoundSynth.play_chime_rarity(player, rarity)
	_spawn_pickup_sparkles()
	queue_free()

func _spawn_pickup_sparkles() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

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
	p.amount = 16
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5

	var colors = [
		Color(0.85, 0.88, 0.95),
		Color(0.25, 0.65, 1.0),
		Color(0.85, 0.35, 1.0),
		Color(1.0, 0.82, 0.2)
	]
	var c = colors[rarity]
	var grad = Gradient.new()
	grad.colors = PackedColorArray([c, Color(c.r, c.g, c.b, 0.0)])
	p.color_ramp = grad

	tree.current_scene.add_child(p)
	p.global_position = global_position + Vector3(0, 0.3, 0)
	p.emitting = true
	tree.create_timer(0.6).timeout.connect(func(): if is_instance_valid(p): p.queue_free())
