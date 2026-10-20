extends Node3D
class_name DestructibleProp

## Manages destructible environment props (Sakura trees, bamboo clusters,
## Asian shop houses, tea pavilions, torii gateways, pagodas, and stone lanterns).
## Provides tactile hit reactions, wood chopping/stone chipping effects,
## realistic tree felling sequences with stump creation and ground slam impact,
## and dynamic physics collapses with exploding RigidBody3D debris chunks.

enum PropType {
	TREE,      # Sakura trees: snaps at trunk, topples flat over, leaves stump & blossom burst
	BAMBOO,    # Bamboo clusters: snaps apart into bamboo stalks with lush leaf scatter
	SHOP,      # Shop houses: collapses into timber beams, roof shingles, and stone rubble
	PAVILION,  # Tea pavilions: collapses into wood pillars, lattice screens, and roof tiles
	TORII,     # Torii gates: fractures into red lacquered timber beams and black roof caps
	PAGODA,    # Pagodas: multi-chunk dramatic collapse of pagoda tiers and curved tiles
	LANTERN,   # Stone lanterns: granite shatter and bouncing stone blocks
	CRATE      # Cargo crates & sake barrels: explodes into cedar wood planks and loot
}

@export var prop_type: PropType = PropType.TREE
@export var max_health: int = 100
@export var current_health: int = 100

var is_destroyed: bool = false
var is_wobbling: bool = false
var original_basis: Basis
var original_pos: Vector3

func _ready() -> void:
	add_to_group("destructible")
	original_basis = transform.basis
	original_pos = global_position
	
	# Tag all child static bodies with metadata so hit detection finds this controller instantly
	for c in find_children("*", "StaticBody3D", true, false):
		if c is StaticBody3D:
			c.add_to_group("destructible_body")
			c.set_meta("destructible_parent", self)

func take_damage(amount: int, is_pyro: bool = false, is_heavy: bool = false, hit_source_pos: Vector3 = Vector3.ZERO) -> void:
	if is_destroyed:
		return

	current_health -= amount

	# Determine hit direction
	var hit_dir = Vector3.FORWARD
	if hit_source_pos != Vector3.ZERO:
		var diff = global_position - hit_source_pos
		diff.y = 0.0
		if diff.length_squared() > 0.001:
			hit_dir = diff.normalized()

	# Audio feedback
	if prop_type == PropType.LANTERN:
		SoundSynth.play_stone_crumble(self)
	else:
		SoundSynth.play_wood_chop(self)

	# Hit reaction: wobble tilt & impact particles
	_trigger_hit_wobble(hit_dir, is_heavy)
	_spawn_hit_particles(hit_dir, is_pyro, is_heavy)

	if current_health <= 0:
		destroy(hit_dir, is_heavy)

func _trigger_hit_wobble(hit_dir: Vector3, is_heavy: bool) -> void:
	if is_wobbling or is_destroyed:
		return
	is_wobbling = true
	var tilt_axis = hit_dir.cross(Vector3.UP).normalized()
	if tilt_axis.length_squared() < 0.01:
		tilt_axis = Vector3.RIGHT

	var max_tilt = deg_to_rad(3.8 if is_heavy else 1.8)
	var wt = create_tween()
	wt.tween_method(func(factor: float):
		if not is_destroyed and is_instance_valid(self):
			transform.basis = Basis(tilt_axis, max_tilt * factor) * original_basis
	, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	wt.finished.connect(func():
		is_wobbling = false
		if not is_destroyed and is_instance_valid(self):
			transform.basis = original_basis
	)

func _spawn_hit_particles(hit_dir: Vector3, is_pyro: bool, is_heavy: bool) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var p = CPUParticles3D.new()
	var p_mesh = BoxMesh.new()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	if prop_type == PropType.LANTERN:
		# Stone chips
		p_mesh.size = Vector3(0.08, 0.08, 0.08)
		mat.albedo_color = Color(0.65, 0.63, 0.60)
	elif prop_type == PropType.CRATE:
		# Wood splinters
		p_mesh.size = Vector3(0.08, 0.08, 0.20)
		mat.albedo_color = Color(0.44, 0.30, 0.18)
	elif prop_type == PropType.TREE or prop_type == PropType.BAMBOO:
		# Wood splinters and leaves
		p_mesh.size = Vector3(0.06, 0.12, 0.04)
		mat.albedo_color = Color(0.98, 0.65, 0.75) if prop_type == PropType.TREE else Color(0.45, 0.78, 0.35)
	else:
		# Building wood/plaster dust
		p_mesh.size = Vector3(0.10, 0.10, 0.05)
		mat.albedo_color = Color(0.85, 0.45, 0.20) if is_pyro else Color(0.55, 0.40, 0.28)

	p_mesh.material = mat
	p.mesh = p_mesh
	p.amount = 16 if is_heavy else 8
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = (hit_dir + Vector3.UP * 0.8).normalized()
	p.spread = 45.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.5

	tree.current_scene.add_child(p)
	p.global_position = global_position + Vector3(0, 1.0, 0)
	p.emitting = true
	tree.create_timer(0.6).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func destroy(hit_dir: Vector3 = Vector3.FORWARD, is_heavy: bool = false) -> void:
	if is_destroyed:
		return
	is_destroyed = true

	# Disable all static bodies immediately
	for body in find_children("*", "StaticBody3D", true, false):
		if body is StaticBody3D:
			body.collision_layer = 0
			body.collision_mask = 0
			for c in body.get_children():
				if c is CollisionShape3D:
					c.set_deferred("disabled", true)

	if prop_type == PropType.TREE:
		_felling_tree_sequence(hit_dir, is_heavy)
	elif prop_type == PropType.BAMBOO:
		_felling_bamboo_sequence(hit_dir, is_heavy)
	else:
		_collapse_building_sequence(hit_dir, is_heavy)

# ==================== TREE FELLING SEQUENCE ====================

func _felling_tree_sequence(hit_dir: Vector3, is_heavy: bool) -> void:
	var tree = get_tree()
	var scene = tree.current_scene if tree else null
	if not scene:
		queue_free()
		return

	# Play tree fall creak and ground thud audio
	SoundSynth.play_tree_fall(self)

	# 1. Leave permanent tree stump at base
	var stump = MeshInstance3D.new()
	stump.name = "TreeStump"
	var stump_mesh = CylinderMesh.new()
	stump_mesh.top_radius = 0.42
	stump_mesh.bottom_radius = 0.50
	stump_mesh.height = 0.45
	var stump_mat = StandardMaterial3D.new()
	stump_mat.albedo_color = Color(0.26, 0.16, 0.10) # Dark aged bark
	stump_mat.roughness = 0.95
	stump.mesh = stump_mesh
	stump.material_override = stump_mat
	scene.add_child(stump)
	stump.global_position = global_position + Vector3(0, 0.22, 0)

	# Add collision to stump so player can stand on it
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var col_shape = CylinderShape3D.new()
	col_shape.radius = 0.46
	col_shape.height = 0.45
	col.shape = col_shape
	sb.add_child(col)
	stump.add_child(sb)

	if is_heavy:
		# Heavy strike / charged attack violently shatters tree into flying timber logs!
		_spawn_tree_timber_debris(hit_dir, true)
		_spawn_ground_impact_burst(global_position + hit_dir * 2.0)
		_spawn_loot_and_exp(2, 4)
		visible = false
		tree.create_timer(0.1).timeout.connect(func(): if is_instance_valid(self): queue_free())
		return

	# 2. Physics-like toppling tween around base
	var fall_axis = hit_dir.cross(Vector3.UP).normalized()
	if fall_axis.length_squared() < 0.01:
		fall_axis = Vector3.RIGHT

	var fall_angle = deg_to_rad(86.0)
	var fall_duration = 1.35
	var target_basis = Basis(fall_axis, fall_angle) * transform.basis

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "transform:basis", target_basis, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y - 0.25, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.finished.connect(func():
		if not is_instance_valid(self):
			return
		# Ground impact burst & break into timber logs
		_spawn_ground_impact_burst(global_position + hit_dir * 3.5)
		_spawn_tree_timber_debris(hit_dir, false)
		_spawn_loot_and_exp(2, 3)

		# Camera punch if near player
		var player = tree.get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < 26.0 and player.has_method("_apply_hit_impact"):
				var str_cam = clamp(1.0 - (dist / 26.0), 0.1, 1.0) * 0.16
				player._apply_hit_impact(0.04, str_cam)

		# Graceful dissolution of fallen tree after 4.5 seconds
		tree.create_timer(4.5).timeout.connect(func():
			if not is_instance_valid(self):
				return
			var dt = create_tween().set_parallel(true)
			dt.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			dt.finished.connect(func(): if is_instance_valid(self): queue_free())
		)
	)

func _spawn_tree_timber_debris(hit_dir: Vector3, is_heavy_hit: bool) -> void:
	var tree = get_tree()
	var scene = tree.current_scene if tree else null
	if not scene:
		return

	# Spawn 2-3 dynamic rough cut timber logs with physics collision
	var log_count = 3 if is_heavy_hit else 2
	for i in range(log_count):
		var timber = RigidBody3D.new()
		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.radius = randf_range(0.20, 0.32)
		c_shape.height = randf_range(1.2, 2.0)
		col.shape = c_shape
		timber.add_child(col)

		var mesh_inst = MeshInstance3D.new()
		var c_mesh = CylinderMesh.new()
		c_mesh.top_radius = c_shape.radius
		c_mesh.bottom_radius = c_shape.radius
		c_mesh.height = c_shape.height
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.17, 0.10) # Aged cedar bark
		mat.roughness = 0.90
		mesh_inst.mesh = c_mesh
		mesh_inst.material_override = mat
		timber.add_child(mesh_inst)

		timber.collision_layer = 1
		timber.collision_mask = 1
		timber.mass = randf_range(8.0, 16.0)
		timber.linear_damp = 1.0
		timber.angular_damp = 1.5
		scene.add_child(timber)

		var spawn_offset = hit_dir * (2.0 + i * 1.2) + Vector3(randf_range(-0.5, 0.5), 0.6 + i * 0.4, randf_range(-0.5, 0.5))
		timber.global_position = global_position + spawn_offset

		# Apply lateral rolling impulse + torque
		var impulse = hit_dir * randf_range(3.0, 7.0) + Vector3.UP * randf_range(1.5, 4.0)
		timber.apply_central_impulse(impulse)
		timber.apply_torque_impulse(Vector3(randf_range(-12, 12), randf_range(-8, 8), randf_range(-12, 12)))

		# Auto dissolve logs after 5.0s
		tree.create_timer(5.0).timeout.connect(func():
			if is_instance_valid(timber):
				var dt = timber.create_tween()
				dt.tween_property(timber, "scale", Vector3(0.01, 0.01, 0.01), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				dt.finished.connect(func(): if is_instance_valid(timber): timber.queue_free())
		)

func _spawn_ground_impact_burst(impact_pos: Vector3) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	# Sakura Petal Shockwave Burst
	var p = CPUParticles3D.new()
	var p_mat = StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_color = Color(1.0, 0.65, 0.78, 0.95)
	var q_mesh = QuadMesh.new()
	q_mesh.size = Vector2(0.22, 0.22)
	q_mesh.material = p_mat
	p.mesh = q_mesh
	p.amount = 45
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 0.92
	p.direction = Vector3(0, 1.0, 0)
	p.spread = 80.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 9.0
	p.damping_min = 3.0
	p.damping_max = 5.0

	tree.current_scene.add_child(p)
	p.global_position = impact_pos + Vector3(0, 0.4, 0)
	p.emitting = true
	tree.create_timer(1.5).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

	# Ground Dust Ring
	var dust = CPUParticles3D.new()
	var d_mat = StandardMaterial3D.new()
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	d_mat.albedo_color = Color(0.75, 0.70, 0.60, 0.5)
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.35
	s_mesh.height = 0.35
	s_mesh.material = d_mat
	dust.mesh = s_mesh
	dust.amount = 25
	dust.lifetime = 1.0
	dust.one_shot = true
	dust.explosiveness = 0.95
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	dust.emission_ring_radius = 2.0
	dust.direction = Vector3(0, 0.2, 0)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 5.0
	tree.current_scene.add_child(dust)
	dust.global_position = impact_pos + Vector3(0, 0.2, 0)
	dust.emitting = true
	tree.create_timer(1.3).timeout.connect(func(): if is_instance_valid(dust): dust.queue_free())

# ==================== BAMBOO FELLING SEQUENCE ====================

func _felling_bamboo_sequence(hit_dir: Vector3, _is_heavy: bool) -> void:
	var tree = get_tree()
	var scene = tree.current_scene if tree else null
	if not scene:
		queue_free()
		return

	SoundSynth.play_wood_chop(self)
	_spawn_loot_and_exp(1, 2)

	# Scatter 6 dynamic bamboo stalk cylinders
	for i in range(6):
		var stalk = RigidBody3D.new()
		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.radius = 0.08
		c_shape.height = 1.8
		col.shape = c_shape
		stalk.add_child(col)

		var mesh_inst = MeshInstance3D.new()
		var c_mesh = CylinderMesh.new()
		c_mesh.top_radius = 0.08
		c_mesh.bottom_radius = 0.08
		c_mesh.height = 1.8
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.38, 0.68, 0.28) # Bamboo green
		mat.roughness = 0.65
		mesh_inst.mesh = c_mesh
		mesh_inst.material_override = mat
		stalk.add_child(mesh_inst)

		stalk.collision_layer = 1
		stalk.collision_mask = 1
		stalk.mass = 2.5
		scene.add_child(stalk)

		var offset = Vector3(randf_range(-0.6, 0.6), randf_range(0.4, 1.2), randf_range(-0.6, 0.6))
		stalk.global_position = global_position + offset

		var impulse = (hit_dir * randf_range(2.5, 6.0) + Vector3.UP * randf_range(2.0, 4.5) + offset.normalized() * 2.0)
		stalk.apply_central_impulse(impulse)
		stalk.apply_torque_impulse(Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8)))

		# Auto dissolve debris
		tree.create_timer(4.0).timeout.connect(func():
			if is_instance_valid(stalk):
				var dt = stalk.create_tween()
				dt.tween_property(stalk, "scale", Vector3(0.01, 0.01, 0.01), 1.0)
				dt.finished.connect(func(): if is_instance_valid(stalk): stalk.queue_free())
		)

	# Hide and queue free original
	visible = false
	tree.create_timer(0.1).timeout.connect(func(): if is_instance_valid(self): queue_free())

# ==================== BUILDING COLLAPSE SEQUENCE ====================

func _collapse_building_sequence(hit_dir: Vector3, _is_heavy: bool) -> void:
	var tree = get_tree()
	var scene = tree.current_scene if tree else null
	if not scene:
		queue_free()
		return

	# Audio feedback
	if prop_type == PropType.LANTERN:
		SoundSynth.play_stone_crumble(self)
	elif prop_type == PropType.CRATE:
		SoundSynth.play_wood_chop(self)
	else:
		SoundSynth.play_building_collapse(self)

	# Camera rumble if near player
	var player = tree.get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 32.0 and player.has_method("_apply_hit_impact"):
			var str_cam = clamp(1.0 - (dist / 32.0), 0.1, 1.0) * 0.22
			player._apply_hit_impact(0.05, str_cam)

	# Hide original mesh
	visible = false

	# Dimensions & chunk count depending on structure type
	var chunk_count = 14
	var w = 2.5
	var h = 3.5
	var d = 2.5

	match prop_type:
		PropType.LANTERN:
			chunk_count = 8
			w = 0.5; h = 1.8; d = 0.5
		PropType.CRATE:
			chunk_count = 6
			w = 0.8; h = 0.9; d = 0.8
		PropType.TORII:
			chunk_count = 12
			w = 2.0; h = 4.2; d = 1.0
		PropType.SHOP:
			chunk_count = 18
			w = 3.0; h = 4.0; d = 3.0
		PropType.PAVILION:
			chunk_count = 16
			w = 2.8; h = 3.8; d = 2.8
		PropType.PAGODA:
			chunk_count = 22
			w = 3.5; h = 7.5; d = 3.5

	# Spawn Dynamic Physics RigidBody3D Debris Chunks
	for i in range(chunk_count):
		var chunk = RigidBody3D.new()
		var col = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		var mesh_inst = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		var mat = StandardMaterial3D.new()
		mat.roughness = 0.85

		# Categorize chunk style: timber beam, roof tile, or stone block
		var piece_type = i % 3
		if prop_type == PropType.LANTERN:
			piece_type = 2 # All stone for lanterns
		elif prop_type == PropType.CRATE:
			piece_type = 0 # All timber for crates

		if piece_type == 0:
			# Timber beam
			b_mesh.size = Vector3(randf_range(0.25, 0.40), randf_range(0.25, 0.40), randf_range(1.1, 2.2))
			if prop_type == PropType.TORII:
				mat.albedo_color = Color(0.85, 0.18, 0.12) # Crimson lacquer
			else:
				mat.albedo_color = Color(0.24, 0.15, 0.08) # Cedar wood
		elif piece_type == 1:
			# Curved roof tile / slab
			b_mesh.size = Vector3(randf_range(0.5, 0.8), 0.10, randf_range(0.6, 1.0))
			if prop_type == PropType.TORII:
				mat.albedo_color = Color(0.12, 0.12, 0.14) # Black cap
			else:
				mat.albedo_color = Color(0.16, 0.24, 0.28) # Asian ceramic teal/slate
		else:
			# Granite stone block
			b_mesh.size = Vector3(randf_range(0.35, 0.65), randf_range(0.25, 0.50), randf_range(0.35, 0.65))
			mat.albedo_color = Color(0.44, 0.43, 0.42) # Granite grey

		box_shape.size = b_mesh.size
		col.shape = box_shape
		mesh_inst.mesh = b_mesh
		mesh_inst.material_override = mat

		chunk.add_child(col)
		chunk.add_child(mesh_inst)

		chunk.collision_layer = 1
		chunk.collision_mask = 1
		chunk.mass = randf_range(4.0, 12.0)
		chunk.linear_damp = 0.8
		chunk.angular_damp = 1.2
		scene.add_child(chunk)

		# Initial distributed position within building volume
		var spawn_offset = Vector3(randf_range(-w, w), randf_range(0.4, h), randf_range(-d, d))
		chunk.global_position = global_position + spawn_offset

		# Explosive physics impulse outwards from center + upward + hit direction
		var out_dir = spawn_offset.normalized()
		out_dir.y = randf_range(0.6, 1.5)
		var impulse = (out_dir * randf_range(4.0, 9.5) + hit_dir * randf_range(2.0, 5.0) + Vector3.UP * randf_range(2.5, 7.0))
		chunk.apply_central_impulse(impulse)
		chunk.apply_torque_impulse(Vector3(randf_range(-14, 14), randf_range(-14, 14), randf_range(-14, 14)))

		# Auto dissolve debris after 5.0 seconds
		tree.create_timer(5.0).timeout.connect(func():
			if is_instance_valid(chunk):
				var dt = chunk.create_tween()
				dt.tween_property(chunk, "scale", Vector3(0.01, 0.01, 0.01), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				dt.finished.connect(func(): if is_instance_valid(chunk): chunk.queue_free())
		)

	# Expanding Dust Cloud
	_spawn_collapse_dust_cloud(global_position + Vector3(0, 0.5, 0), w, h)

	# Spew loot drops & EXP
	_spawn_loot_and_exp(3, 4)

	# Clean up original building node
	tree.create_timer(0.2).timeout.connect(func(): if is_instance_valid(self): queue_free())

func _spawn_collapse_dust_cloud(pos: Vector3, width: float, height: float) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return

	var dust = CPUParticles3D.new()
	var d_mat = StandardMaterial3D.new()
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	d_mat.albedo_color = Color(0.72, 0.68, 0.62, 0.55)
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.5
	s_mesh.height = 0.5
	s_mesh.material = d_mat
	dust.mesh = s_mesh
	dust.amount = 40
	dust.lifetime = 1.8
	dust.one_shot = true
	dust.explosiveness = 0.95
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(width, height * 0.5, width)
	dust.direction = Vector3(0, 1.0, 0)
	dust.spread = 75.0
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 6.0
	dust.damping_min = 2.0
	dust.damping_max = 4.0

	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.8, 0.75, 0.7, 0.65), Color(0.75, 0.70, 0.65, 0.4), Color(0.7, 0.65, 0.6, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	dust.color_ramp = grad

	tree.current_scene.add_child(dust)
	dust.global_position = pos
	dust.emitting = true
	tree.create_timer(2.2).timeout.connect(func(): if is_instance_valid(dust): dust.queue_free())

func _spawn_loot_and_exp(loot_count: int, exp_count: int) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	var scene = tree.current_scene
	var loot_scene = preload("res://scenes/loot_drop.tscn")
	var exp_scene = preload("res://scenes/exp_orb.tscn")

	for i in range(loot_count):
		if not loot_scene: break
		var loot = loot_scene.instantiate() as LootDrop
		loot.position = global_position + Vector3(randf_range(-0.5, 0.5), 0.8, randf_range(-0.5, 0.5))
		scene.add_child(loot)
		var angle = randf() * TAU
		var spd = randf_range(2.8, 4.8)
		loot.velocity = Vector3(cos(angle) * spd, randf_range(4.5, 7.5), sin(angle) * spd)

	for i in range(exp_count):
		if not exp_scene: break
		var orb = exp_scene.instantiate()
		orb.position = global_position + Vector3(randf_range(-0.4, 0.4), 0.8, randf_range(-0.4, 0.4))
		if "exp_amount" in orb:
			orb.exp_amount = 12
		scene.add_child(orb)
		var angle = randf() * TAU
		var spd = randf_range(2.0, 3.8)
		if "velocity" in orb:
			orb.velocity = Vector3(cos(angle) * spd, randf_range(4.0, 6.5), sin(angle) * spd)
