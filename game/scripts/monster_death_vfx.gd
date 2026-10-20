extends Node
class_name MonsterDeathVFX

## Handles visceral, juicy, cartoon-physics monster defeat effects.
## Slimes burst into bouncy 3D gelatinous droplets that splatter and evaporate.
## Skeletons collapse into clattering bone fragments.
## Goblins poof in comic star puffs.

static func spawn_slime_burst(scene: Node, pos: Vector3, slime_color: Color, is_boss: bool = false) -> void:
	if not scene or not is_instance_valid(scene):
		return

	var count = 18 if is_boss else randi_range(9, 14)
	var scale_mult = 1.6 if is_boss else 1.0

	# 1. Radiant Expanding Shockwave Ring on the floor
	var ring = MeshInstance3D.new()
	var r_mesh = TorusMesh.new()
	r_mesh.inner_radius = 0.35 * scale_mult
	r_mesh.outer_radius = 0.55 * scale_mult
	r_mesh.rings = 24
	r_mesh.ring_segments = 16
	var r_mat = StandardMaterial3D.new()
	r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r_mat.albedo_color = Color(slime_color.r, slime_color.g, slime_color.b, 0.95)
	ring.mesh = r_mesh
	ring.material_override = r_mat
	scene.add_child(ring)
	ring.global_position = pos + Vector3(0, 0.1, 0)

	var rt = ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(3.2, 1.0, 3.2) * scale_mult, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(r_mat, "albedo_color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rt.finished.connect(func(): if is_instance_valid(ring): ring.queue_free())

	# 2. Central Burst Particle Fountain
	var p = CPUParticles3D.new()
	var p_mat = StandardMaterial3D.new()
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.vertex_color_use_as_albedo = true
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.07 * scale_mult
	s_mesh.height = 0.14 * scale_mult
	s_mesh.material = p_mat
	p.mesh = s_mesh
	p.amount = 35 if is_boss else 22
	p.lifetime = 0.65
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3(0, 1.0, 0)
	p.spread = 75.0
	p.gravity = Vector3(0, -18.0, 0)
	p.initial_velocity_min = 4.5 * scale_mult
	p.initial_velocity_max = 8.5 * scale_mult
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(slime_color.r * 1.2, slime_color.g * 1.2, slime_color.b * 1.2, 0.9),
		Color(slime_color.r, slime_color.g, slime_color.b, 0.0)
	])
	p.color_ramp = grad
	scene.add_child(p)
	p.global_position = pos + Vector3(0, 0.4, 0)
	p.emitting = true
	scene.get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

	# 3. Translucent Glowing Jelly Material for Bouncy Droplets
	var jelly_mat = StandardMaterial3D.new()
	jelly_mat.albedo_color = Color(slime_color.r, slime_color.g, slime_color.b, 0.88)
	jelly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jelly_mat.roughness = 0.12
	jelly_mat.metallic = 0.05
	jelly_mat.rim_enabled = true
	jelly_mat.rim = 0.85
	jelly_mat.emission_enabled = true
	jelly_mat.emission = slime_color * 0.45

	# Shared Bouncy Physics Material
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = 0.68
	phys_mat.friction = 0.35

	# 4. Spawn 3D Bouncy Slime Droplets (RigidBody3D)
	for i in range(count):
		var drop = RigidBody3D.new()
		drop.physics_material_override = phys_mat
		drop.collision_layer = 0 # Doesn't push player or enemies
		drop.collision_mask = 1  # Collides with environment/ground
		drop.continuous_cd = true
		drop.contact_monitor = true
		drop.max_contacts_reported = 2

		# Varied Droplet Size & Squash
		var drop_rad = randf_range(0.09, 0.20) * scale_mult
		var col_shape = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = drop_rad
		col_shape.shape = sphere_shape
		drop.add_child(col_shape)

		var mesh_inst = MeshInstance3D.new()
		var d_mesh = SphereMesh.new()
		d_mesh.radius = drop_rad
		d_mesh.height = drop_rad * 2.0
		mesh_inst.mesh = d_mesh
		mesh_inst.material_override = jelly_mat
		drop.add_child(mesh_inst)

		scene.add_child(drop)
		# Spread around center
		var spawn_offset = Vector3(randf_range(-0.35, 0.35), randf_range(0.2, 0.7), randf_range(-0.35, 0.35)) * scale_mult
		drop.global_position = pos + spawn_offset

		# Outward explosive impulse
		var launch_dir = (spawn_offset.normalized() + Vector3(0, randf_range(0.5, 1.2), 0)).normalized()
		var launch_speed = randf_range(3.8, 7.8) * scale_mult
		drop.linear_velocity = launch_dir * launch_speed
		drop.angular_velocity = Vector3(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))

		# Sound & squish on bounce
		var has_splatted = [false]
		drop.body_entered.connect(func(_b):
			if not has_splatted[0] and is_instance_valid(drop):
				has_splatted[0] = true
				var tree = drop.get_tree()
				if tree and tree.root.has_node("SoundSynth"):
					var ss = tree.root.get_node("SoundSynth")
					if ss.has_method("play_slime_splat"):
						ss.play_slime_splat(drop)
				# Quick squish on impact
				var st = mesh_inst.create_tween()
				st.tween_property(mesh_inst, "scale", Vector3(1.35, 0.65, 1.35), 0.06)
				st.tween_property(mesh_inst, "scale", Vector3(1.0, 1.0, 1.0), 0.12)
		)

		# Evaporation timer: Bounces around, then shrinks to 0 with a cute pop
		var life = randf_range(1.1, 1.7)
		var drop_tween = drop.create_tween()
		drop_tween.tween_interval(life)
		# Wobble and shrink down into nothing
		drop_tween.tween_property(mesh_inst, "scale", Vector3(1.25, 0.75, 1.25), 0.08)
		drop_tween.tween_property(mesh_inst, "scale", Vector3(0.01, 0.01, 0.01), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		drop_tween.tween_callback(func():
			if is_instance_valid(drop):
				drop.queue_free()
		)

static func spawn_skeleton_collapse(scene: Node, pos: Vector3) -> void:
	if not scene or not is_instance_valid(scene):
		return

	var bone_mat = StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.92, 0.90, 0.84)
	bone_mat.roughness = 0.65

	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = 0.35
	phys_mat.friction = 0.65

	# Tumbling Bone Chunks
	var bone_count = randi_range(6, 9)
	for i in range(bone_count):
		var bone = RigidBody3D.new()
		bone.physics_material_override = phys_mat
		bone.collision_layer = 0
		bone.collision_mask = 1

		var col = CollisionShape3D.new()
		var mesh_inst = MeshInstance3D.new()

		if i == 0:
			# Skull
			var sphere = SphereShape3D.new()
			sphere.radius = 0.18
			col.shape = sphere
			var sm = SphereMesh.new()
			sm.radius = 0.18
			sm.height = 0.32
			mesh_inst.mesh = sm
		else:
			# Rib / Limb bone
			var cyl = BoxShape3D.new()
			cyl.size = Vector3(0.10, 0.32, 0.10)
			col.shape = cyl
			var bm = BoxMesh.new()
			bm.size = Vector3(0.10, 0.32, 0.10)
			mesh_inst.mesh = bm

		mesh_inst.material_override = bone_mat
		bone.add_child(col)
		bone.add_child(mesh_inst)
		scene.add_child(bone)

		bone.global_position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(0.3, 1.0), randf_range(-0.3, 0.3))
		bone.linear_velocity = Vector3(randf_range(-3.5, 3.5), randf_range(2.5, 5.5), randf_range(-3.5, 3.5))
		bone.angular_velocity = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))

		# Fade out into white-gold ash
		var bt = bone.create_tween()
		bt.tween_interval(randf_range(1.2, 1.8))
		bt.tween_property(mesh_inst, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
		bt.tween_callback(func():
			if is_instance_valid(bone):
				bone.queue_free()
		)

static func spawn_goblin_defeat(scene: Node, pos: Vector3) -> void:
	if not scene or not is_instance_valid(scene):
		return

	# Comic Star & Smoke Puff
	var p = CPUParticles3D.new()
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var mesh = SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.material = mat
	p.mesh = mesh
	p.amount = 18
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.gravity = Vector3(0, -2.0, 0)
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.5
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 0.9, 0.3, 1.0), # Comic gold stars
		Color(0.8, 0.85, 0.9, 0.8), # White smoke
		Color(0.4, 0.4, 0.45, 0.0)
	])
	p.color_ramp = grad
	scene.add_child(p)
	p.global_position = pos + Vector3(0, 0.6, 0)
	p.emitting = true
	scene.get_tree().create_timer(0.8).timeout.connect(func(): if is_instance_valid(p): p.queue_free())
