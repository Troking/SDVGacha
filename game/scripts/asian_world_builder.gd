extends Node3D
class_name AsianWorldBuilder

## Orchestrates the complete Asian Fantasy World (Genshin Impact / Liyue / Inazuma style)
## Spawns sculpted terrain, multi-tier pagodas, torii gates, moon bridges,
## shop houses, sakura groves, bamboo forests, karst spires, lanterns, and particles.

const SCENE_TERRAIN = preload("res://assets/models/asian_fantasy_terrain.glb")
const SCENE_TORII = preload("res://assets/models/asian_torii_gate.glb")
const SCENE_PAGODA = preload("res://assets/models/asian_pagoda.glb")
const SCENE_SHOP = preload("res://assets/models/asian_shop_house.glb")
const SCENE_PAVILION = preload("res://assets/models/asian_tea_pavilion.glb")
const SCENE_BRIDGE = preload("res://assets/models/asian_moon_bridge.glb")
const SCENE_LANTERN = preload("res://assets/models/asian_stone_lantern.glb")
const SCENE_SAKURA = preload("res://assets/models/sakura_tree.glb")
const SCENE_BAMBOO = preload("res://assets/models/bamboo_cluster.glb")
const SCENE_KARST = preload("res://assets/models/karst_mountain_spire.glb")
const SCENE_SHRINE = preload("res://assets/models/ancient_stone_shrine.glb")
const SCENE_CRATES = preload("res://assets/models/wood_crate_barrel.glb")
const SCENE_DOCK = preload("res://assets/models/river_dock_pier.glb")
const SCENE_CAMPFIRE = preload("res://assets/models/campfire_brazier.glb")
const SCENE_RUIN = preload("res://assets/models/ancient_ruin_pillar.glb")
const JapaneseSchoolBuilder = preload("res://scripts/japanese_school_builder.gd")
var SCENE_UNDEAD_TOMB: PackedScene = null
var SCENE_BONE_SPIRE: PackedScene = null
var SCENE_CYBER_TOWER: PackedScene = null
var SCENE_CYBER_LAMP: PackedScene = null

var terrain_instance: Node3D = null
var all_lantern_lights: Array[Dictionary] = []

# Ambient Sakura Breeze System (unhurried, occasional, non-intrusive)
var ambient_sakura_particles: CPUParticles3D = null
var player_node: Node3D = null
var breeze_state: int = 0 # 0 = LULL (peaceful quiet), 1 = GENTLE_GUST (soft falling petals)
var breeze_timer: float = 7.0

func _ready() -> void:
	SCENE_UNDEAD_TOMB = load("res://assets/models/undead_crypt_tomb.glb")
	SCENE_BONE_SPIRE = load("res://assets/models/undead_bone_spire.glb")
	SCENE_CYBER_TOWER = load("res://assets/models/cyber_skyscraper_tower.glb")
	SCENE_CYBER_LAMP = load("res://assets/models/cyber_street_lamp.glb")
	_build_terrain()
	_build_world_boundary_walls()
	_build_asian_city()
	_build_sakura_valley()
	_build_bamboo_forest()
	_build_karst_peaks()
	_build_kitsune_shrine_poi()
	_build_river_wharf_poi()
	_build_bandit_camp_poi()
	_build_mountain_teahouse_poi()
	_build_ancient_ruins_poi()
	_build_blighted_undead_lands()
	_build_cyber_city()
	_build_atmospheric_particles()
	_build_ambient_sakura_breeze()
	_build_updraft_wind_current()


func _process(delta: float) -> void:
	_update_sakura_breeze(delta)

func _update_sakura_breeze(delta: float) -> void:
	if not player_node or not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")
		if not player_node:
			return

	if ambient_sakura_particles and is_instance_valid(ambient_sakura_particles):
		ambient_sakura_particles.global_position = player_node.global_position + Vector3(-5.0, 5.2, -4.0)

	breeze_timer -= delta
	if breeze_timer <= 0.0:
		if breeze_state == 1:
			breeze_state = 0
			breeze_timer = randf_range(15.0, 26.0)
			if ambient_sakura_particles:
				ambient_sakura_particles.emitting = false
		else:
			breeze_state = 1
			breeze_timer = randf_range(7.0, 11.0)
			if ambient_sakura_particles:
				ambient_sakura_particles.emitting = true
				ambient_sakura_particles.restart()

func _build_terrain() -> void:
	if not SCENE_TERRAIN:
		return
	terrain_instance = SCENE_TERRAIN.instantiate()
	terrain_instance.name = "AsianTerrain"
	terrain_instance.position = Vector3.ZERO
	add_child(terrain_instance)

	var water_shader = load("res://scripts/anime_water.gdshader") as Shader
	var water_mat = ShaderMaterial.new()
	if water_shader:
		water_mat.shader = water_shader

	var biome_shader = load("res://scripts/genshin_terrain_biome.gdshader") as Shader
	var biome_mat = ShaderMaterial.new()
	if biome_shader:
		biome_mat.shader = biome_shader

	var invis_mat = StandardMaterial3D.new()
	invis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invis_mat.albedo_color = Color(0, 0, 0, 0)

	for child in terrain_instance.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D and child.mesh:
			var mesh = child.mesh
			if mesh.get_surface_count() > 1:
				# Hide terrain's low-poly 4-vertex water quad to prevent Z-fighting with subdivided water plane
				child.set_surface_override_material(1, invis_mat)
			if biome_mat:
				child.set_surface_override_material(0, biome_mat)
			_create_ground_surface_collision(child, 0)

	_build_water_lake_and_river(water_mat)

func _create_ground_surface_collision(mesh_inst: MeshInstance3D, surface_idx: int) -> void:
	if not mesh_inst or not mesh_inst.mesh or mesh_inst.mesh.get_surface_count() <= surface_idx:
		return
	var arr = mesh_inst.mesh.surface_get_arrays(surface_idx)
	if arr.is_empty():
		return
	var single_surf_mesh = ArrayMesh.new()
	single_surf_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var shape = single_surf_mesh.create_trimesh_shape()
	if not shape:
		return
	shape.backface_collision = true

	var sb = StaticBody3D.new()
	sb.name = "GroundStaticBody"
	var col = CollisionShape3D.new()
	col.name = "GroundCollision"
	col.shape = shape
	sb.add_child(col)
	mesh_inst.add_child(sb)

func _build_water_lake_and_river(water_mat: Material) -> void:
	var water_plane = MeshInstance3D.new()
	water_plane.name = "ReflectiveWaterSurface"
	var p_mesh = PlaneMesh.new()
	p_mesh.size = Vector2(24.0, 210.0)
	p_mesh.subdivide_width = 48
	p_mesh.subdivide_depth = 192
	water_plane.mesh = p_mesh
	if water_mat:
		water_plane.material_override = water_mat
	water_plane.position = Vector3(0.0, -0.45, 0.0)
	add_child(water_plane)

	# 1. Natural Riverbank Boulders & Shoreline Stones
	var mat_rock = StandardMaterial3D.new()
	mat_rock.albedo_color = Color(0.48, 0.50, 0.52)
	mat_rock.roughness = 0.90
	mat_rock.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var mat_moss = StandardMaterial3D.new()
	mat_moss.albedo_color = Color(0.38, 0.42, 0.36)
	mat_moss.roughness = 0.95
	mat_moss.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var rock_z_coords = [-85.0, -68.0, -50.0, -32.0, -14.0, 6.0, 24.0, 44.0, 64.0, 84.0]
	for rz in rock_z_coords:
		var x_mid = sin(rz * 0.025) * 3.5
		for side in [-1.0, 1.0]:
			var rx = x_mid + side * (3.8 + randf() * 1.5)
			var ry = get_terrain_height(rx, rz)
			var rock = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = randf_range(0.40, 0.85)
			sm.height = sm.radius * randf_range(1.1, 1.6)
			rock.mesh = sm
			rock.material_override = mat_moss if randf() > 0.4 else mat_rock
			rock.position = Vector3(rx, ry - sm.radius * 0.30, rz + randf_range(-1.5, 1.5))
			rock.scale = Vector3(randf_range(0.9, 1.4), randf_range(0.7, 1.1), randf_range(0.9, 1.4))
			add_child(rock)

	# 3. River Stepping Stones (Natural flat tobi-ishi crossing near Z = -4.0)
	var mat_stepping = StandardMaterial3D.new()
	mat_stepping.albedo_color = Color(0.32, 0.34, 0.36)
	mat_stepping.roughness = 0.82
	mat_stepping.specular_mode = BaseMaterial3D.SPECULAR_TOON
	var step_xs = [-2.8, -1.7, -0.6, 0.5, 1.6, 2.7]
	for sx in step_xs:
		var step_stone = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.44
		cyl.bottom_radius = 0.50
		cyl.height = 0.30
		step_stone.mesh = cyl
		step_stone.material_override = mat_stepping
		var z_step = -4.0 + sx * 0.12
		step_stone.position = Vector3(sx, -0.36, z_step)
		# Add static collision so player can hop on them
		var sb = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var cshape = CylinderShape3D.new()
		cshape.radius = 0.44
		cshape.height = 0.30
		col.shape = cshape
		sb.add_child(col)
		step_stone.add_child(sb)
		add_child(step_stone)

	# 4. Riverbank Water Reeds & Cattails
	var mat_reed = StandardMaterial3D.new()
	mat_reed.albedo_color = Color(0.35, 0.58, 0.22)
	mat_reed.roughness = 0.85
	mat_reed.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var reed_z_coords = [-70.0, -42.0, -18.0, 10.0, 38.0, 68.0]
	for rz in reed_z_coords:
		var x_mid = sin(rz * 0.025) * 3.5
		for side in [-1.0, 1.0]:
			var cluster_x = x_mid + side * (3.6 + randf() * 0.6)
			var cluster_y = get_terrain_height(cluster_x, rz)
			if cluster_y < 0.25:
				for reed_i in range(4):
					var reed = MeshInstance3D.new()
					var r_cyl = CylinderMesh.new()
					r_cyl.top_radius = 0.025
					r_cyl.bottom_radius = 0.045
					r_cyl.height = randf_range(1.1, 1.7)
					reed.mesh = r_cyl
					reed.material_override = mat_reed
					reed.position = Vector3(
						cluster_x + randf_range(-0.4, 0.4),
						cluster_y + r_cyl.height * 0.45,
						rz + randf_range(-0.4, 0.4)
					)
					reed.rotation_degrees = Vector3(randf_range(-6.0, 6.0), randf_range(0.0, 360.0), randf_range(-8.0, 8.0))
					add_child(reed)

	# 5. Scenic Floating Lotus Blossom Lily Pads (Guaranteed in deep water only)
	var mat_pad = StandardMaterial3D.new()
	mat_pad.albedo_color = Color(0.20, 0.58, 0.25)
	mat_pad.roughness = 0.85
	mat_pad.specular_mode = BaseMaterial3D.SPECULAR_TOON

	var mat_lotus = StandardMaterial3D.new()
	mat_lotus.albedo_color = Color(0.98, 0.65, 0.82)
	mat_lotus.emission_enabled = true
	mat_lotus.emission = Color(0.85, 0.35, 0.65)
	mat_lotus.emission_energy_multiplier = 0.45
	mat_lotus.roughness = 0.70

	var lotus_spots = [
		Vector3(sin(-55.0 * 0.025) * 3.5 - 0.8, -0.44, -55.0),
		Vector3(sin(-35.0 * 0.025) * 3.5 - 0.8, -0.44, -35.0),
		Vector3(sin(-15.0 * 0.025) * 3.5 + 0.9, -0.44, -15.0),
		Vector3(sin(12.0 * 0.025) * 3.5 - 0.6, -0.44, 12.0),
		Vector3(sin(32.0 * 0.025) * 3.5 + 0.8, -0.44, 32.0),
		Vector3(sin(48.0 * 0.025) * 3.5 + 0.7, -0.44, 48.0),
		Vector3(sin(75.0 * 0.025) * 3.5 - 0.9, -0.44, 75.0),
	]
	for spot in lotus_spots:
		# Check depth: only spawn if ground is submerged beneath water
		if get_terrain_height(spot.x, spot.z) < -0.80:
			for p_idx in range(3):
				var pad_pos = spot + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5))
				if get_terrain_height(pad_pos.x, pad_pos.z) < -0.75:
					var pad = MeshInstance3D.new()
					var cyl = CylinderMesh.new()
					cyl.top_radius = randf_range(0.32, 0.48)
					cyl.bottom_radius = cyl.top_radius
					cyl.height = 0.02
					pad.mesh = cyl
					pad.material_override = mat_pad
					pad.position = pad_pos
					add_child(pad)

					if p_idx == 0:
						var flower = MeshInstance3D.new()
						var f_mesh = SphereMesh.new()
						f_mesh.radius = 0.15
						f_mesh.height = 0.20
						flower.mesh = f_mesh
						flower.material_override = mat_lotus
						flower.position = pad.position + Vector3(0.0, 0.08, 0.0)
						add_child(flower)

func _build_world_boundary_walls() -> void:
	var boundary_body = StaticBody3D.new()
	boundary_body.name = "WorldBoundaryWalls"

	var wall_configs = [
		{"pos": Vector3(0.0, 20.0, -118.0), "size": Vector3(240.0, 60.0, 4.0)},
		{"pos": Vector3(0.0, 20.0, 118.0), "size": Vector3(240.0, 60.0, 4.0)},
		{"pos": Vector3(-118.0, 20.0, 0.0), "size": Vector3(4.0, 60.0, 240.0)},
		{"pos": Vector3(118.0, 20.0, 0.0), "size": Vector3(4.0, 60.0, 240.0)},
	]
	for cfg in wall_configs:
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = cfg["size"]
		col.shape = box
		col.position = cfg["pos"]
		boundary_body.add_child(col)

	add_child(boundary_body)

func _setup_bridge_solid_deck_collision(bridge: Node3D) -> void:
	if not bridge:
		return
	var sb = StaticBody3D.new()
	sb.name = "BridgeDeckBody"

	# Segmented arched walkable collision along bridge local Z (length 12m, width 3.8m)
	var segs = 8
	for i in range(segs):
		var t1 = (float(i) / segs) * 2.0 - 1.0
		var t2 = (float(i + 1) / segs) * 2.0 - 1.0
		var z1 = t1 * 6.0
		var z2 = t2 * 6.0
		var y1 = (1.0 - t1 * t1) * 1.6
		var y2 = (1.0 - t2 * t2) * 1.6

		var cz = (z1 + z2) * 0.5
		var cy = (y1 + y2) * 0.5
		var dz = z2 - z1
		var dy = y2 - y1
		var seg_len = sqrt(dz * dz + dy * dy)
		var angle = atan2(dy, dz)

		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(3.8, 0.35, seg_len + 0.06)
		col.shape = box
		col.position = Vector3(0.0, cy, cz)
		col.rotation = Vector3(-angle, 0.0, 0.0)
		sb.add_child(col)

	# Left and Right solid safety railings
	for side in [-1.9, 1.9]:
		var col_rail = CollisionShape3D.new()
		var box_rail = BoxShape3D.new()
		box_rail.size = Vector3(0.25, 1.6, 12.2)
		col_rail.shape = box_rail
		col_rail.position = Vector3(side, 1.2, 0.0)
		sb.add_child(col_rail)

	bridge.add_child(sb)

func _build_asian_city() -> void:
	# 1. Grand Moon Bridge spanning across the river from Sakura Valley into the City Avenue (Destructible)
	var bridge = _spawn_destructible(SCENE_BRIDGE, Vector3(0.0, 1.85, -6.0), Vector3(0, 90, 0), Vector3.ONE, DestructibleProp.PropType.BRIDGE, 350, false)
	_setup_bridge_solid_deck_collision(bridge)

	# 1b. 3-Story Japanese High School (桜ヶ丘学園) with classrooms, stairs, rooftop terrace and sports courtyard
	var school_y = get_terrain_height(30.0, -48.0)
	JapaneseSchoolBuilder.build_school(self, Vector3(30.0, school_y, -48.0))

	# 2. Grand Torii Gateway at city entrance (Destructible)
	var torii = _spawn_destructible(SCENE_TORII, Vector3(14.0, 2.9, -6.0), Vector3(0, 90, 0), Vector3.ONE, DestructibleProp.PropType.TORII, 120)
	_add_lantern_light(torii, Vector3(0, 3.8, 0), Color(1.0, 0.45, 0.2), 1.8, 7.0)

	# 3. Majestic 3-Tier Asian Pagoda Tower crowning the end of the grand promenade (Destructible)
	var pagoda = _spawn_destructible(SCENE_PAGODA, Vector3(46.0, 3.2, -6.0), Vector3(0, -90, 0), Vector3.ONE, DestructibleProp.PropType.PAGODA, 280)
	_add_lantern_light(pagoda, Vector3(0, 2.5, 6.2), Color(1.0, 0.8, 0.4), 1.5, 9.0)

	# 4. Asian Merchant Shops lining both sides of the city avenue with wide central street
	var shops = [
		{"pos": Vector3(25.0, 3.0, -18.0), "rot": 0.0},
		{"pos": Vector3(37.0, 3.1, -18.0), "rot": 0.0},
		{"pos": Vector3(25.0, 3.0, 6.0), "rot": 180.0},
		{"pos": Vector3(37.0, 3.1, 6.0), "rot": 180.0},
	]
	for s_data in shops:
		var shop = _spawn_destructible(SCENE_SHOP, s_data["pos"], Vector3(0, s_data["rot"], 0), Vector3.ONE, DestructibleProp.PropType.SHOP, 180)
		_add_lantern_light(shop, Vector3(-2.2, 2.0, 2.6), Color(1.0, 0.5, 0.25), 1.2, 5.0)
		_add_lantern_light(shop, Vector3(2.2, 2.0, 2.6), Color(1.0, 0.5, 0.25), 1.2, 5.0)

	# 5. City Tea Pavilion on picturesque riverside garden terrace (Destructible)
	var pav = _spawn_destructible(SCENE_PAVILION, Vector3(16.0, 2.9, 8.0), Vector3(0, 30, 0), Vector3.ONE, DestructibleProp.PropType.PAVILION, 150)
	_add_lantern_light(pav, Vector3(0, 2.2, 0), Color(1.0, 0.8, 0.5), 1.4, 7.0)

	# 6. Avenue Stone Lanterns (Tōrō) lining the promenade edges (Destructible)
	var city_lanterns = [
		Vector3(8.0, 2.8, -10.0),
		Vector3(8.0, 2.8, -2.0),
		Vector3(18.0, 2.9, -10.0),
		Vector3(18.0, 2.9, -2.0),
		Vector3(28.0, 3.0, -10.0),
		Vector3(28.0, 3.0, -2.0),
		Vector3(38.0, 3.1, -10.0),
		Vector3(38.0, 3.1, -2.0),
	]
	for pos in city_lanterns:
		var l_node = _spawn_destructible(SCENE_LANTERN, pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l_node, Vector3(0, 1.85, 0), Color(1.0, 0.82, 0.45), 1.4, 8.0)

	# 7. Merchant Cargo Crates & Sake Barrels around shop fronts (Destructible)
	var city_crates = [
		{"pos": Vector3(21.5, 3.0, -15.5), "rot": 15.0},
		{"pos": Vector3(33.5, 3.1, -15.5), "rot": -25.0},
		{"pos": Vector3(21.5, 3.0, 3.5), "rot": 40.0},
		{"pos": Vector3(33.5, 3.1, 3.5), "rot": -10.0},
		{"pos": Vector3(42.0, 3.2, -10.0), "rot": 60.0},
	]
	for c_data in city_crates:
		_spawn_destructible(SCENE_CRATES, c_data["pos"], Vector3(0, c_data["rot"], 0), Vector3.ONE, DestructibleProp.PropType.CRATE, 50)

func _build_sakura_valley() -> void:
	# 1. Meditation Pavilion beside the river in Sakura Valley (Destructible)
	var pav = _spawn_destructible(SCENE_PAVILION, Vector3(-24.0, 2.3, -6.0), Vector3(0, 15, 0), Vector3.ONE, DestructibleProp.PropType.PAVILION, 150)
	_add_lantern_light(pav, Vector3(0, 2.2, 0), Color(1.0, 0.8, 0.5), 1.3, 7.0)

	# 2. Dense Sakura Blossom Forest across the rolling hills (Destructible)
	var sakura_trees = [
		{"pos": Vector3(-14.0, 2.3, -16.0), "scale": 1.0, "rot": 20.0},
		{"pos": Vector3(-24.0, 2.4, -20.0), "scale": 1.15, "rot": 75.0},
		{"pos": Vector3(-34.0, 2.5, -26.0), "scale": 1.25, "rot": 140.0},
		{"pos": Vector3(-16.0, 2.3, 10.0), "scale": 1.05, "rot": -40.0},
		{"pos": Vector3(-38.0, 2.6, -10.0), "scale": 1.3, "rot": 210.0},
		{"pos": Vector3(-28.0, 2.4, 18.0), "scale": 1.1, "rot": 95.0},
		{"pos": Vector3(-48.0, 3.2, -22.0), "scale": 1.2, "rot": 310.0},
		{"pos": Vector3(-42.0, 2.8, 14.0), "scale": 1.15, "rot": 50.0},
		{"pos": Vector3(-12.0, 2.2, -26.0), "scale": 1.1, "rot": 45.0},
		{"pos": Vector3(-20.0, 2.3, -32.0), "scale": 1.25, "rot": 110.0},
		{"pos": Vector3(-30.0, 2.5, -36.0), "scale": 1.35, "rot": 190.0},
		{"pos": Vector3(-42.0, 2.9, -34.0), "scale": 1.15, "rot": 260.0},
		{"pos": Vector3(-54.0, 3.4, -28.0), "scale": 1.3, "rot": 15.0},
		{"pos": Vector3(-62.0, 3.8, -18.0), "scale": 1.25, "rot": 85.0},
		{"pos": Vector3(-50.0, 3.2, -12.0), "scale": 1.1, "rot": 150.0},
		{"pos": Vector3(-32.0, 2.4, -4.0), "scale": 1.05, "rot": 220.0},
		{"pos": Vector3(-44.0, 2.7, 2.0), "scale": 1.2, "rot": 300.0},
		{"pos": Vector3(-56.0, 3.3, 8.0), "scale": 1.25, "rot": 40.0},
		{"pos": Vector3(-18.0, 2.2, -24.0), "scale": 1.15, "rot": 130.0},
		{"pos": Vector3(-36.0, 2.6, 22.0), "scale": 1.2, "rot": 175.0},
	]
	for t_data in sakura_trees:
		_spawn_destructible(SCENE_SAKURA, t_data["pos"], Vector3(0, t_data["rot"], 0), Vector3.ONE * t_data["scale"], DestructibleProp.PropType.TREE, 80)

	# 3. Garden Stone Lanterns along the valley path (Destructible)
	var garden_lanterns = [
		Vector3(-8.0, 2.1, -9.0),
		Vector3(-8.0, 2.1, -3.0),
		Vector3(-18.0, 2.3, -10.0),
		Vector3(-24.0, 2.4, -14.0),
		Vector3(-28.0, 2.4, 2.0),
		Vector3(-36.0, 2.6, -18.0),
		Vector3(-44.0, 2.8, -14.0),
	]
	for pos in garden_lanterns:
		var l_node = _spawn_destructible(SCENE_LANTERN, pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l_node, Vector3(0, 1.85, 0), Color(1.0, 0.78, 0.4), 1.2, 7.0)

func _build_bamboo_forest() -> void:
	var bamboo_groves = [
		{"pos": Vector3(-16.0, 1.8, 28.0), "rot": 15.0, "scale": 1.0},
		{"pos": Vector3(-24.0, 2.2, 34.0), "rot": 65.0, "scale": 1.1},
		{"pos": Vector3(-36.0, 2.8, 42.0), "rot": 120.0, "scale": 1.15},
		{"pos": Vector3(-18.0, 2.0, 52.0), "rot": 200.0, "scale": 1.05},
		{"pos": Vector3(-46.0, 3.2, 26.0), "rot": -45.0, "scale": 1.2},
		{"pos": Vector3(-30.0, 2.6, 64.0), "rot": 85.0, "scale": 1.1},
		{"pos": Vector3(-52.0, 3.6, 48.0), "rot": 160.0, "scale": 1.25},
		{"pos": Vector3(-26.0, 2.4, 76.0), "rot": 30.0, "scale": 1.1},
		{"pos": Vector3(-42.0, 3.1, 72.0), "rot": 240.0, "scale": 1.15},
		{"pos": Vector3(-58.0, 4.0, 62.0), "rot": 95.0, "scale": 1.2},
		{"pos": Vector3(-14.0, 1.8, 42.0), "rot": 40.0, "scale": 1.1},
		{"pos": Vector3(-22.0, 2.1, 62.0), "rot": 110.0, "scale": 1.15},
		{"pos": Vector3(-32.0, 2.7, 52.0), "rot": 170.0, "scale": 1.2},
		{"pos": Vector3(-48.0, 3.4, 38.0), "rot": 225.0, "scale": 1.05},
		{"pos": Vector3(-64.0, 4.2, 52.0), "rot": 310.0, "scale": 1.3},
		{"pos": Vector3(-38.0, 2.9, 84.0), "rot": 55.0, "scale": 1.15},
		{"pos": Vector3(-50.0, 3.6, 80.0), "rot": 135.0, "scale": 1.2},
		{"pos": Vector3(-18.0, 2.0, 68.0), "rot": 195.0, "scale": 1.1},
	]
	for b_data in bamboo_groves:
		_spawn_destructible(SCENE_BAMBOO, b_data["pos"], Vector3(0, b_data["rot"], 0), Vector3.ONE * b_data["scale"], DestructibleProp.PropType.BAMBOO, 45)

	var trail_lanterns = [
		Vector3(-20.0, 2.0, 38.0),
		Vector3(-28.0, 2.5, 48.0),
		Vector3(-34.0, 2.8, 58.0),
		Vector3(-24.0, 2.3, 70.0),
		Vector3(-40.0, 3.0, 68.0),
	]
	for pos in trail_lanterns:
		var l_node = _spawn_destructible(SCENE_LANTERN, pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l_node, Vector3(0, 1.85, 0), Color(0.9, 0.85, 0.5), 1.1, 6.5)

func _build_karst_peaks() -> void:
	var spires = [
		{"pos": Vector3(82.0, 2.8, 38.0), "scale": Vector3(1.0, 1.0, 1.0), "rot": 10.0},
		{"pos": Vector3(68.0, 2.4, 46.0), "scale": Vector3(1.15, 1.1, 1.15), "rot": 70.0},
		{"pos": Vector3(76.0, 2.5, 72.0), "scale": Vector3(1.1, 1.05, 1.1), "rot": 135.0},
		{"pos": Vector3(66.0, 2.6, 28.0), "scale": Vector3(1.2, 1.15, 1.2), "rot": -45.0},
		{"pos": Vector3(58.0, 2.8, 85.0), "scale": Vector3(1.25, 1.2, 1.25), "rot": 210.0},
		{"pos": Vector3(72.0, 2.8, 58.0), "scale": Vector3(1.3, 1.25, 1.3), "rot": 115.0},
	]
	for s_data in spires:
		var spire = _spawn_structure(SCENE_KARST, s_data["pos"], Vector3(0, s_data["rot"], 0), s_data["scale"])
		_setup_trimesh_collision(spire)

		# Double-defense solid core collision (Convex Cylinder prevents any walk-through / glitch clipping)
		var core_body = StaticBody3D.new()
		core_body.name = "SpireCoreCollision"
		var core_col = CollisionShape3D.new()
		var core_shape = CylinderShape3D.new()
		core_shape.radius = 4.6 * s_data["scale"].x
		core_shape.height = 36.0 * s_data["scale"].y
		core_col.shape = core_shape
		core_col.position = Vector3(0.0, 16.0 * s_data["scale"].y, 0.0)
		core_body.add_child(core_col)
		spire.add_child(core_body)

	# High Mountain Pass Shrine Torii Gate (Destructible)
	var mountain_torii = _spawn_destructible(SCENE_TORII, Vector3(45.0, 7.8, 52.0), Vector3(0, -35, 0), Vector3(0.85, 0.85, 0.85), DestructibleProp.PropType.TORII, 120)
	_add_lantern_light(mountain_torii, Vector3(0, 3.2, 0), Color(1.0, 0.45, 0.2), 1.6, 6.0)

	# Dragon Sanctum Pavilion atop mountain terrace (Destructible)
	var sanctum = _spawn_destructible(SCENE_PAVILION, Vector3(52.0, 8.4, 66.0), Vector3(0, 45, 0), Vector3(1.2, 1.2, 1.2), DestructibleProp.PropType.PAVILION, 180)
	_add_lantern_light(sanctum, Vector3(0, 2.6, 0), Color(1.0, 0.65, 0.2), 2.0, 10.0)

	for offset_pos in [Vector3(47.0, 8.4, 62.0), Vector3(57.0, 8.4, 62.0), Vector3(47.0, 8.4, 70.0), Vector3(57.0, 8.4, 70.0)]:
		var l_node = _spawn_destructible(SCENE_LANTERN, offset_pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l_node, Vector3(0, 1.85, 0), Color(1.0, 0.6, 0.2), 1.6, 8.0)

func _build_kitsune_shrine_poi() -> void:
	# 1. Ancient Fox Spirit (Kitsune) Shrine in a secluded clearing of Sakura Valley
	var shrine_pos = Vector3(-32.0, 2.5, -18.0)
	var shrine = _spawn_structure(SCENE_SHRINE, shrine_pos, Vector3(0, 45, 0), Vector3(1.1, 1.1, 1.1))
	_setup_trimesh_collision(shrine)
	_add_lantern_light(shrine, Vector3(0, 2.8, 0), Color(1.0, 0.45, 0.25), 1.8, 9.0)

	# Shrine Approach Red Torii Gate
	var torii = _spawn_destructible(SCENE_TORII, Vector3(-24.0, 2.4, -13.0), Vector3(0, 45, 0), Vector3(0.9, 0.9, 0.9), DestructibleProp.PropType.TORII, 120)
	_add_lantern_light(torii, Vector3(0, 3.4, 0), Color(1.0, 0.4, 0.15), 1.6, 6.5)

	# Flanking Shrine Lanterns
	for l_pos in [Vector3(-28.0, 2.4, -13.5), Vector3(-24.5, 2.4, -17.0), Vector3(-35.0, 2.5, -14.5), Vector3(-29.5, 2.5, -22.0)]:
		var l = _spawn_destructible(SCENE_LANTERN, l_pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l, Vector3(0, 1.85, 0), Color(1.0, 0.55, 0.2), 1.5, 7.5)

	# Offering Sake Barrels & Cargo Crates (Destructible loot containers)
	_spawn_destructible(SCENE_CRATES, Vector3(-34.5, 2.5, -20.5), Vector3(0, 30, 0), Vector3.ONE, DestructibleProp.PropType.CRATE, 50)
	_spawn_destructible(SCENE_CRATES, Vector3(-29.0, 2.5, -21.0), Vector3(0, -50, 0), Vector3(0.9, 0.9, 0.9), DestructibleProp.PropType.CRATE, 50)

func _build_river_wharf_poi() -> void:
	# 2. Fisherman's Wharf, Mooring Pier & Sampan Boat along the lotus river
	var dock_pos = Vector3(4.0, 0.1, 14.0)
	var dock = _spawn_structure(SCENE_DOCK, dock_pos, Vector3(0, 90, 0), Vector3(1.0, 1.0, 1.0))
	_setup_trimesh_collision(dock)

	# Dock Walkway Solid Collision (Box collision for sturdy deck walking)
	var dock_sb = StaticBody3D.new()
	dock_sb.name = "DockWalkwayCollision"
	var col_deck = CollisionShape3D.new()
	var box_deck = BoxShape3D.new()
	box_deck.size = Vector3(2.4, 0.35, 7.8)
	col_deck.shape = box_deck
	col_deck.position = Vector3(0.8, 0.35, 0.0)
	dock_sb.add_child(col_deck)
	dock.add_child(dock_sb)

	# Fishermen's Crates and Barrels stacked on the wharf
	_spawn_destructible(SCENE_CRATES, Vector3(3.6, 0.5, 12.0), Vector3(0, 15, 0), Vector3.ONE, DestructibleProp.PropType.CRATE, 50)
	_spawn_destructible(SCENE_CRATES, Vector3(4.2, 0.5, 16.5), Vector3(0, -35, 0), Vector3(0.95, 0.95, 0.95), DestructibleProp.PropType.CRATE, 50)

	# Riverside Campfire for cooking fish & resting
	var campfire = _spawn_structure(SCENE_CAMPFIRE, Vector3(8.5, 0.9, 13.5), Vector3(0, 20, 0))
	_setup_trimesh_collision(campfire)
	_spawn_campfire_particles(campfire)

	# Wharf Lanterns
	var l_wharf = _spawn_destructible(SCENE_LANTERN, Vector3(7.0, 0.9, 16.0), Vector3(0, 0, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
	_add_lantern_light(l_wharf, Vector3(0, 1.85, 0), Color(1.0, 0.75, 0.35), 1.5, 8.0)

func _build_bandit_camp_poi() -> void:
	# 3. Mountain Bandit Outpost Camp at the karst foothills
	var camp_center = Vector3(38.0, 2.2, 18.0)

	# Central Roaring Campfire
	var campfire = _spawn_structure(SCENE_CAMPFIRE, camp_center, Vector3(0, 45, 0))
	_setup_trimesh_collision(campfire)
	_spawn_campfire_particles(campfire)

	# Stash of Looted Cargo Crates and Cedar Barrels
	var crate_positions = [
		{"pos": camp_center + Vector3(-2.8, 0.0, 1.5), "rot": 25.0},
		{"pos": camp_center + Vector3(3.2, 0.0, -1.8), "rot": -40.0},
		{"pos": camp_center + Vector3(1.6, 0.0, 3.4), "rot": 70.0},
		{"pos": camp_center + Vector3(-1.8, 0.0, -3.0), "rot": 110.0},
	]
	for c_data in crate_positions:
		_spawn_destructible(SCENE_CRATES, c_data["pos"], Vector3(0, c_data["rot"], 0), Vector3.ONE, DestructibleProp.PropType.CRATE, 50)

	# Outpost Watch Lanterns
	for l_pos in [camp_center + Vector3(-4.0, 0.0, -2.5), camp_center + Vector3(4.5, 0.0, 3.0)]:
		var l = _spawn_destructible(SCENE_LANTERN, l_pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l, Vector3(0, 1.85, 0), Color(1.0, 0.5, 0.15), 1.6, 7.5)

func _build_mountain_teahouse_poi() -> void:
	# 4. Mountain Scenic Overlook Teahouse overlooking the misty lake and city
	var lookout_pos = Vector3(22.0, 3.2, 38.0)
	var teahouse = _spawn_destructible(SCENE_PAVILION, lookout_pos, Vector3(0, 35, 0), Vector3(1.15, 1.15, 1.15), DestructibleProp.PropType.PAVILION, 160)
	_add_lantern_light(teahouse, Vector3(0, 2.4, 0), Color(1.0, 0.75, 0.45), 1.6, 8.5)

	# Crates with imported tea casks
	_spawn_destructible(SCENE_CRATES, lookout_pos + Vector3(3.5, 0.0, 1.8), Vector3(0, 15, 0), Vector3.ONE, DestructibleProp.PropType.CRATE, 50)

	# Terrace Lanterns
	for l_pos in [lookout_pos + Vector3(-3.8, 0.0, 2.2), lookout_pos + Vector3(3.8, 0.0, -2.5)]:
		var l = _spawn_destructible(SCENE_LANTERN, l_pos, Vector3(0, randf() * 360, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
		_add_lantern_light(l, Vector3(0, 1.85, 0), Color(1.0, 0.8, 0.4), 1.4, 7.0)

func _build_ancient_ruins_poi() -> void:
	# 5. Overgrown Ancient Monolith Ruins in Bamboo Grove
	var r1 = _spawn_structure(SCENE_RUIN, Vector3(-28.0, 2.6, 48.0), Vector3(0, 25, 0), Vector3(1.1, 1.1, 1.1))
	_setup_trimesh_collision(r1)

	var r2 = _spawn_structure(SCENE_RUIN, Vector3(-34.0, 2.8, 54.0), Vector3(0, 115, 0), Vector3(1.0, 0.95, 1.0))
	_setup_trimesh_collision(r2)

	# Ancient Crates left by previous explorers
	_spawn_destructible(SCENE_CRATES, Vector3(-31.0, 2.7, 50.5), Vector3(0, -35, 0), Vector3.ONE, DestructibleProp.PropType.CRATE, 50)

	# Ruin Guardian Lanterns
	var l = _spawn_destructible(SCENE_LANTERN, Vector3(-25.0, 2.5, 46.0), Vector3(0, 45, 0), Vector3.ONE, DestructibleProp.PropType.LANTERN, 40)
	_add_lantern_light(l, Vector3(0, 1.85, 0), Color(0.75, 0.95, 1.0), 1.5, 7.5) # Mystical cyan ancient glow

# ==================== NEW EXPANSION TERRITORIES ====================

func _build_blighted_undead_lands() -> void:
	# 1. Central Crypt Mausoleum
	var tomb_main = _spawn_structure(SCENE_UNDEAD_TOMB, Vector3(-48.0, 2.6, -78.0), Vector3(0, 30, 0), Vector3(1.3, 1.3, 1.3), true)
	_setup_trimesh_collision(tomb_main)
	_add_lantern_light(tomb_main, Vector3(0, 1.6, 0), Color(0.35, 1.0, 0.45), 2.2, 9.0)

	# 2. Secondary Tombs
	var t2 = _spawn_structure(SCENE_UNDEAD_TOMB, Vector3(-36.0, 2.4, -68.0), Vector3(0, -45, 0), Vector3(1.0, 1.0, 1.0), true)
	_setup_trimesh_collision(t2)
	var t3 = _spawn_structure(SCENE_UNDEAD_TOMB, Vector3(-62.0, 2.8, -88.0), Vector3(0, 75, 0), Vector3(1.1, 1.1, 1.1), true)
	_setup_trimesh_collision(t3)

	# 3. Bone Spires framing the blighted area
	var spires = [
		Vector3(-54.0, 2.8, -72.0),
		Vector3(-42.0, 2.4, -72.0),
		Vector3(-58.0, 2.9, -84.0),
		Vector3(-38.0, 2.3, -84.0),
		Vector3(-48.0, 2.6, -92.0),
		Vector3(-66.0, 3.2, -78.0)
	]
	for pos in spires:
		var s = _spawn_structure(SCENE_BONE_SPIRE, pos, Vector3(0, randf() * 360, 0), Vector3(1.0, 1.1, 1.0), true)
		_setup_trimesh_collision(s)
		_add_lantern_light(s, Vector3(0, 3.2, 0), Color(0.75, 0.25, 0.95), 1.6, 7.0)

	# 4. Necrotic Soul Mist (creeping green and purple ground fog)
	var mist = CPUParticles3D.new()
	mist.name = "NecroticSoulMist"
	mist.position = Vector3(-48.0, 3.0, -78.0)
	mist.amount = 48
	mist.lifetime = 4.5
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 1.2
	p_mesh.height = 2.4
	p_mesh.material = mat
	mist.mesh = p_mesh
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(25.0, 0.8, 25.0)
	mist.direction = Vector3(0.2, 0.1, 0.1)
	mist.gravity = Vector3(0, 0.05, 0)
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(0.2, 0.8, 0.3, 0), Color(0.25, 0.95, 0.35, 0.45), Color(0.65, 0.25, 0.85, 0.35), Color(0.1, 0.4, 0.2, 0)])
	mist.color_ramp = grad
	add_child(mist)

	# 5. Twisted Dead Trees in the Corrupted Lands
	var dead_tree_positions = [
		Vector3(-40.0, 2.5, -74.0),
		Vector3(-52.0, 2.7, -66.0),
		Vector3(-66.0, 3.0, -82.0),
		Vector3(-34.0, 2.3, -86.0),
		Vector3(-56.0, 2.8, -96.0)
	]
	for dt_pos in dead_tree_positions:
		_build_dead_tree(dt_pos, randf_range(0.9, 1.3))

func _build_dead_tree(pos: Vector3, scale_mult: float = 1.0) -> Node3D:
	var tree = Node3D.new()
	tree.position = pos
	var mat_bark = StandardMaterial3D.new()
	mat_bark.albedo_color = Color(0.15, 0.13, 0.17)
	mat_bark.roughness = 0.95
	mat_bark.specular_mode = BaseMaterial3D.SPECULAR_TOON

	# Main gnarled trunk
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.20 * scale_mult
	cyl.bottom_radius = 0.42 * scale_mult
	cyl.height = 3.8 * scale_mult
	trunk.mesh = cyl
	trunk.material_override = mat_bark
	trunk.position = Vector3(0, 1.9 * scale_mult, 0)
	tree.add_child(trunk)

	# Gnarled twisted leafless branches
	for i in range(4):
		var branch = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.05 * scale_mult
		b_cyl.bottom_radius = 0.14 * scale_mult
		b_cyl.height = 2.0 * scale_mult
		branch.mesh = b_cyl
		branch.material_override = mat_bark
		var ang = (float(i) / 4.0) * TAU
		branch.position = Vector3(cos(ang) * 0.6 * scale_mult, 2.8 * scale_mult, sin(ang) * 0.6 * scale_mult)
		branch.rotation = Vector3(0.55 * sin(ang), ang, 0.55 * cos(ang))
		tree.add_child(branch)

	add_child(tree)
	return tree

func _build_cyber_city() -> void:
	# 1. Cyber Skyscraper Towers
	var towers = [
		{"pos": Vector3(45.0, 3.5, 90.0), "scale": Vector3(1.15, 1.15, 1.15), "rot": 0.0},
		{"pos": Vector3(28.0, 3.2, 78.0), "scale": Vector3(0.95, 0.95, 0.95), "rot": 35.0},
		{"pos": Vector3(64.0, 3.8, 86.0), "scale": Vector3(1.05, 1.05, 1.05), "rot": -25.0},
		{"pos": Vector3(42.0, 3.6, 106.0), "scale": Vector3(1.25, 1.25, 1.25), "rot": 180.0}
	]
	for t_data in towers:
		var tower = _spawn_structure(SCENE_CYBER_TOWER, t_data["pos"], Vector3(0, t_data["rot"], 0), t_data["scale"], true)
		_setup_trimesh_collision(tower)
		_add_lantern_light(tower, Vector3(0, 8.0, 2.5), Color(0.0, 0.95, 1.0), 2.4, 14.0) # Cyber cyan beacon
		_add_lantern_light(tower, Vector3(0, 14.0, -2.5), Color(1.0, 0.15, 0.75), 2.2, 12.0) # Cyber magenta beacon

	# 2. Cyber Streetlamps lining the Neon Boulevard
	var cyber_lamps = [
		Vector3(36.0, 3.3, 74.0),
		Vector3(44.0, 3.4, 74.0),
		Vector3(36.0, 3.4, 86.0),
		Vector3(44.0, 3.5, 86.0),
		Vector3(36.0, 3.5, 98.0),
		Vector3(44.0, 3.6, 98.0)
	]
	for pos in cyber_lamps:
		var lamp = _spawn_structure(SCENE_CYBER_LAMP, pos, Vector3(0, 90.0, 0), Vector3.ONE, true)
		_setup_trimesh_collision(lamp)
		_add_lantern_light(lamp, Vector3(1.15, 4.15, 0), Color(0.0, 0.95, 1.0), 1.8, 8.0)

	# 3. Holographic Neon Road Bollards
	var mat_cyan_neon = StandardMaterial3D.new()
	mat_cyan_neon.albedo_color = Color(0.0, 0.95, 1.0)
	mat_cyan_neon.emission_enabled = true
	mat_cyan_neon.emission = Color(0.0, 0.95, 1.0)
	mat_cyan_neon.emission_energy_multiplier = 2.4

	var mat_magenta_neon = StandardMaterial3D.new()
	mat_magenta_neon.albedo_color = Color(1.0, 0.12, 0.80)
	mat_magenta_neon.emission_enabled = true
	mat_magenta_neon.emission = Color(1.0, 0.12, 0.80)
	mat_magenta_neon.emission_energy_multiplier = 2.4

	var mat_tech_metal = StandardMaterial3D.new()
	mat_tech_metal.albedo_color = Color(0.12, 0.14, 0.18)
	mat_tech_metal.metallic = 0.85
	mat_tech_metal.roughness = 0.35

	var bollard_positions = [
		Vector3(32.0, 3.2, 70.0), Vector3(48.0, 3.3, 70.0),
		Vector3(32.0, 3.3, 82.0), Vector3(48.0, 3.4, 82.0),
		Vector3(32.0, 3.4, 94.0), Vector3(48.0, 3.5, 94.0),
		Vector3(32.0, 3.5, 106.0), Vector3(48.0, 3.6, 106.0)
	]
	for idx in range(bollard_positions.size()):
		var b_pos = bollard_positions[idx]
		var bollard = Node3D.new()
		bollard.position = b_pos
		var base = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.35, 0.8, 0.35)
		base.mesh = b_box
		base.material_override = mat_tech_metal
		base.position = Vector3(0, 0.4, 0)
		bollard.add_child(base)

		var cap = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(0.38, 0.22, 0.38)
		cap.mesh = c_box
		cap.material_override = mat_cyan_neon if (idx % 2 == 0) else mat_magenta_neon
		cap.position = Vector3(0, 0.9, 0)
		bollard.add_child(cap)
		add_child(bollard)

	# 4. Floating Digital Matrix Data Cubes
	var matrix_p = CPUParticles3D.new()
	matrix_p.name = "CyberMatrixParticles"
	matrix_p.position = Vector3(40.0, 4.0, 90.0)
	matrix_p.amount = 54
	matrix_p.lifetime = 3.2
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.08, 0.08, 0.08)
	p_mesh.material = mat
	matrix_p.mesh = p_mesh
	matrix_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	matrix_p.emission_box_extents = Vector3(22.0, 2.5, 22.0)
	matrix_p.direction = Vector3(0, 1.0, 0)
	matrix_p.gravity = Vector3(0, 0.25, 0)
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(0.0, 0.9, 1.0, 0), Color(0.0, 1.0, 0.9, 0.9), Color(1.0, 0.1, 0.8, 0.75), Color(0.0, 0.5, 1.0, 0)])
	matrix_p.color_ramp = grad
	add_child(matrix_p)

func _spawn_campfire_particles(parent: Node3D) -> void:
	if not parent:
		return
	var embers = CPUParticles3D.new()
	embers.name = "CampfireEmbers"
	embers.amount = 24
	embers.lifetime = 1.3
	embers.position = Vector3(0, 0.22, 0)
	embers.direction = Vector3(0, 1.0, 0)
	embers.spread = 22.0
	embers.gravity = Vector3(0, 0.25, 0)
	embers.initial_velocity_min = 1.1
	embers.initial_velocity_max = 2.2
	embers.scale_amount_min = 0.05
	embers.scale_amount_max = 0.10

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	var quad = QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	embers.mesh = quad

	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(1.0, 0.9, 0.4, 1.0), Color(1.0, 0.5, 0.1, 0.9), Color(0.8, 0.2, 0.05, 0.5), Color(0.3, 0.3, 0.3, 0.0)])
	embers.color_ramp = grad
	parent.add_child(embers)

	_add_lantern_light(parent, Vector3(0, 0.55, 0), Color(1.0, 0.55, 0.18), 1.8, 7.5)

func _build_atmospheric_particles() -> void:
	var sakura_particles = CPUParticles3D.new()
	sakura_particles.name = "SakuraFallingPetals"
	sakura_particles.position = Vector3(-25.0, 7.0, -10.0)
	sakura_particles.amount = 30
	sakura_particles.lifetime = 8.0
	sakura_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sakura_particles.emission_box_extents = Vector3(25.0, 3.5, 25.0)
	sakura_particles.direction = Vector3(0.6, -0.35, 0.4)
	sakura_particles.spread = 40.0
	sakura_particles.gravity = Vector3(0.2, -0.45, 0.18)
	sakura_particles.initial_velocity_min = 0.4
	sakura_particles.initial_velocity_max = 1.0
	sakura_particles.angular_velocity_min = -25.0
	sakura_particles.angular_velocity_max = 35.0
	sakura_particles.angle_min = 0.0
	sakura_particles.angle_max = 360.0
	sakura_particles.scale_amount_min = 0.75
	sakura_particles.scale_amount_max = 1.30

	var mat_petal = StandardMaterial3D.new()
	mat_petal.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_petal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_petal.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_petal.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_petal.billboard_keep_scale = true
	var petal_tex = load("res://assets/textures/sakura_petal.png") as Texture2D
	if petal_tex:
		mat_petal.albedo_texture = petal_tex
	else:
		mat_petal.albedo_color = Color(1.0, 0.75, 0.85, 0.85)

	var quad = QuadMesh.new()
	quad.size = Vector2(0.16, 0.16)
	quad.material = mat_petal
	sakura_particles.mesh = quad

	var grad_petal = Gradient.new()
	grad_petal.offsets = PackedFloat32Array([0.0, 0.18, 0.82, 1.0])
	grad_petal.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.0)
	])
	sakura_particles.color_ramp = grad_petal
	add_child(sakura_particles)

func _build_ambient_sakura_breeze() -> void:
	ambient_sakura_particles = CPUParticles3D.new()
	ambient_sakura_particles.name = "AmbientSakuraBreeze"
	ambient_sakura_particles.emitting = false
	ambient_sakura_particles.amount = 20
	ambient_sakura_particles.lifetime = 8.5
	ambient_sakura_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ambient_sakura_particles.emission_box_extents = Vector3(14.0, 2.5, 14.0)
	ambient_sakura_particles.direction = Vector3(0.65, -0.35, 0.4)
	ambient_sakura_particles.spread = 45.0
	ambient_sakura_particles.gravity = Vector3(0.22, -0.42, 0.16)
	ambient_sakura_particles.initial_velocity_min = 0.4
	ambient_sakura_particles.initial_velocity_max = 1.0
	ambient_sakura_particles.angular_velocity_min = -25.0
	ambient_sakura_particles.angular_velocity_max = 35.0
	ambient_sakura_particles.angle_min = 0.0
	ambient_sakura_particles.angle_max = 360.0
	ambient_sakura_particles.scale_amount_min = 0.75
	ambient_sakura_particles.scale_amount_max = 1.30

	var mat_breeze = StandardMaterial3D.new()
	mat_breeze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_breeze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_breeze.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_breeze.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_breeze.billboard_keep_scale = true
	var tex = load("res://assets/textures/sakura_petal.png") as Texture2D
	if tex:
		mat_breeze.albedo_texture = tex
	else:
		mat_breeze.albedo_color = Color(1.0, 0.75, 0.85, 0.8)

	var quad_breeze = QuadMesh.new()
	quad_breeze.size = Vector2(0.16, 0.16)
	quad_breeze.material = mat_breeze
	ambient_sakura_particles.mesh = quad_breeze

	var grad_breeze = Gradient.new()
	grad_breeze.offsets = PackedFloat32Array([0.0, 0.18, 0.82, 1.0])
	grad_breeze.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.0)
	])
	ambient_sakura_particles.color_ramp = grad_breeze
	add_child(ambient_sakura_particles)

	# Bamboo Forest Fireflies
	var bamboo_fireflies = CPUParticles3D.new()
	bamboo_fireflies.name = "BambooFireflies"
	bamboo_fireflies.position = Vector3(-35.0, 4.0, 50.0)
	bamboo_fireflies.amount = 50
	bamboo_fireflies.lifetime = 5.0
	bamboo_fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bamboo_fireflies.emission_box_extents = Vector3(25.0, 3.0, 30.0)
	bamboo_fireflies.direction = Vector3(0, 0.5, 0)
	bamboo_fireflies.spread = 90.0
	bamboo_fireflies.gravity = Vector3(0, 0.05, 0)
	bamboo_fireflies.initial_velocity_min = 0.2
	bamboo_fireflies.initial_velocity_max = 0.8

	var mat_fly = StandardMaterial3D.new()
	mat_fly.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_fly.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_fly.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat_fly.vertex_color_use_as_albedo = true
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.material = mat_fly
	bamboo_fireflies.mesh = sphere

	var grad_fly = Gradient.new()
	grad_fly.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad_fly.colors = PackedColorArray([Color(0.8, 1.0, 0.4, 0), Color(0.9, 1.0, 0.5, 0.9), Color(0.6, 0.9, 0.3, 0)])
	bamboo_fireflies.color_ramp = grad_fly
	add_child(bamboo_fireflies)

func _build_updraft_wind_current() -> void:
	var wind_area = Area3D.new()
	wind_area.name = "UpdraftWindCurrent"
	wind_area.position = Vector3(26.0, 1.8, 26.0)

	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 3.0
	cyl.height = 4.0
	col.shape = cyl
	col.position = Vector3(0, 2.0, 0)
	wind_area.add_child(col)

	var wind_p = CPUParticles3D.new()
	wind_p.amount = 45
	wind_p.lifetime = 1.6
	wind_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	wind_p.emission_sphere_radius = 2.4
	wind_p.direction = Vector3(0, 1, 0)
	wind_p.spread = 10.0
	wind_p.gravity = Vector3(0, 4.0, 0)
	wind_p.initial_velocity_min = 6.0
	wind_p.initial_velocity_max = 12.0

	var mat_w = StandardMaterial3D.new()
	mat_w.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_w.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_w.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat_w.vertex_color_use_as_albedo = true
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.035
	p_mesh.height = 0.25
	p_mesh.material = mat_w
	wind_p.mesh = p_mesh

	var grad_w = Gradient.new()
	grad_w.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	grad_w.colors = PackedColorArray([Color(0.6, 1.0, 0.9, 0), Color(0.7, 1.0, 0.95, 0.8), Color(0.5, 0.95, 0.85, 0.6), Color(0.3, 0.8, 0.7, 0)])
	wind_p.color_ramp = grad_w
	wind_area.add_child(wind_p)

	wind_area.body_entered.connect(func(body):
		if body is CharacterBody3D and body.has_method("start_gliding"):
			body.velocity.y = 19.5
			SoundSynth.play_glider_open(body)
	)

	add_child(wind_area)

static func get_terrain_height(x: float, z: float) -> float:
	var ss = func(edge0: float, edge1: float, val: float) -> float:
		var t = clampf((val - edge0) / (edge1 - edge0), 0.0, 1.0)
		return t * t * (3.0 - 2.0 * t)

	# 1. Gentle river course meandering along Z around X = 0
	var x_riv = sin(z * 0.025) * 3.0
	var d_riv = absf(x - x_riv)

	# 2. Sakura Valley (West) - gentle rolling hills
	var h_sakura = 2.4 + 0.9 * sin(x * 0.04) * cos(z * 0.04)

	# 3. Bamboo Forest (North-West)
	var w_bamboo = ss.call(10.0, 32.0, z) * ss.call(-6.0, -24.0, x)
	h_sakura += w_bamboo * (2.2 + 0.6 * sin(x * 0.06 + z * 0.05))

	# 4. City Avenue & Promenade (East) - stable flat paved plateau
	var h_city = 2.8 + 0.4 * ss.call(8.0, 20.0, x)

	# 5. Karst Peaks (North-East) - scenic elevation
	var d_karst = sqrt((x - 45.0) * (x - 45.0) + (z - 50.0) * (z - 50.0))
	var w_karst = ss.call(46.0, 14.0, d_karst)
	h_city += w_karst * 4.2

	# 6. Smooth blend between West bank and East bank
	var t_side = ss.call(-4.5, 4.5, x - x_riv)
	var h_land = h_sakura * (1.0 - t_side) + h_city * t_side

	# 7. River Channel & Bed
	var h_river_bed = -2.2
	var w_river = ss.call(6.2, 2.2, d_riv)
	var h = h_land * (1.0 - w_river) + h_river_bed * w_river

	# 8. Majestic Perimeter Mountain Ring
	var d_edge = maxf(absf(x), absf(z))
	if d_edge > 78.0:
		var w_edge = ss.call(78.0, 116.0, d_edge)
		h += (w_edge * w_edge) * 34.0

	return h

func _spawn_structure(scene: PackedScene, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, p_scale: Vector3 = Vector3.ONE, snap_ground: bool = false) -> Node3D:
	if not scene:
		return null
	if snap_ground:
		pos.y = get_terrain_height(pos.x, pos.z)
	var inst = scene.instantiate() as Node3D
	inst.position = pos
	inst.rotation_degrees = rot_deg
	inst.scale = p_scale
	add_child(inst)
	_setup_trimesh_collision(inst)
	return inst

func _spawn_destructible(scene: PackedScene, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, p_scale: Vector3 = Vector3.ONE, p_type: DestructibleProp.PropType = DestructibleProp.PropType.TREE, health: int = 100, snap_ground: bool = true) -> DestructibleProp:
	if not scene:
		return null
	
	if snap_ground:
		var gh = get_terrain_height(pos.x, pos.z)
		if p_type == DestructibleProp.PropType.TREE:
			pos.y = gh - 0.12 # Embed trunk base slightly into ground to prevent floating
		elif p_type == DestructibleProp.PropType.BAMBOO:
			pos.y = gh - 0.08
		elif p_type == DestructibleProp.PropType.LANTERN:
			pos.y = gh
		elif p_type == DestructibleProp.PropType.CRATE:
			pos.y = maxf(pos.y, gh)
		else:
			pos.y = gh

	var d_prop = DestructibleProp.new()
	d_prop.position = pos
	d_prop.rotation_degrees = rot_deg
	d_prop.scale = p_scale
	d_prop.prop_type = p_type
	d_prop.max_health = health
	d_prop.current_health = health
	add_child(d_prop)

	var visual = scene.instantiate() as Node3D
	d_prop.add_child(visual)

	_setup_destructible_collision(d_prop, p_type)

	return d_prop

func _setup_destructible_collision(d_prop: DestructibleProp, p_type: DestructibleProp.PropType) -> void:
	var sb = StaticBody3D.new()
	sb.name = "DestructibleStaticBody"
	sb.add_to_group("destructible_body")
	sb.set_meta("destructible_parent", d_prop)

	match p_type:
		DestructibleProp.PropType.TREE:
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.55
			cyl.height = 4.8
			col.shape = cyl
			col.position = Vector3(0.0, 2.4, 0.0)
			sb.add_child(col)

		DestructibleProp.PropType.BAMBOO:
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.75
			cyl.height = 4.2
			col.shape = cyl
			col.position = Vector3(0.0, 2.1, 0.0)
			sb.add_child(col)

		DestructibleProp.PropType.LANTERN:
			var col = CollisionShape3D.new()
			var cyl = CylinderShape3D.new()
			cyl.radius = 0.42
			cyl.height = 2.2
			col.shape = cyl
			col.position = Vector3(0.0, 1.1, 0.0)
			sb.add_child(col)

		DestructibleProp.PropType.TORII:
			var col_l = CollisionShape3D.new()
			var cyl_l = CylinderShape3D.new()
			cyl_l.radius = 0.48
			cyl_l.height = 6.0
			col_l.shape = cyl_l
			col_l.position = Vector3(-2.6, 3.0, 0.0)
			sb.add_child(col_l)

			var col_r = CollisionShape3D.new()
			var cyl_r = CylinderShape3D.new()
			cyl_r.radius = 0.48
			cyl_r.height = 6.0
			col_r.shape = cyl_r
			col_r.position = Vector3(2.6, 3.0, 0.0)
			sb.add_child(col_r)

			var col_top = CollisionShape3D.new()
			var box_top = BoxShape3D.new()
			box_top.size = Vector3(7.4, 0.7, 0.7)
			col_top.shape = box_top
			col_top.position = Vector3(0.0, 5.8, 0.0)
			sb.add_child(col_top)

		DestructibleProp.PropType.PAVILION:
			var col_base = CollisionShape3D.new()
			var cyl_base = CylinderShape3D.new()
			cyl_base.radius = 3.9
			cyl_base.height = 0.65
			col_base.shape = cyl_base
			col_base.position = Vector3(0.0, 0.32, 0.0)
			sb.add_child(col_base)

			var col_tbl = CollisionShape3D.new()
			var cyl_tbl = CylinderShape3D.new()
			cyl_tbl.radius = 1.15
			cyl_tbl.height = 1.5
			col_tbl.shape = cyl_tbl
			col_tbl.position = Vector3(0.0, 0.75, 0.0)
			sb.add_child(col_tbl)

			for i in range(6):
				var ang = (2.0 * PI * i) / 6.0
				var p_col = CollisionShape3D.new()
				var p_cyl = CylinderShape3D.new()
				p_cyl.radius = 0.22
				p_cyl.height = 3.2
				p_col.shape = p_cyl
				p_col.position = Vector3(cos(ang) * 3.0, 2.2, sin(ang) * 3.0)
				sb.add_child(p_col)

		DestructibleProp.PropType.SHOP:
			var c_fl = CollisionShape3D.new()
			var b_fl = BoxShape3D.new()
			b_fl.size = Vector3(7.4, 0.45, 6.0)
			c_fl.shape = b_fl
			c_fl.position = Vector3(0.0, 0.22, 0.0)
			sb.add_child(c_fl)

			var c_wl = CollisionShape3D.new()
			var b_wl = BoxShape3D.new()
			b_wl.size = Vector3(2.4, 3.2, 5.4)
			c_wl.shape = b_wl
			c_wl.position = Vector3(-2.2, 1.8, 0.0)
			sb.add_child(c_wl)

			var c_wr = CollisionShape3D.new()
			var b_wr = BoxShape3D.new()
			b_wr.size = Vector3(2.4, 3.2, 5.4)
			c_wr.shape = b_wr
			c_wr.position = Vector3(2.2, 1.8, 0.0)
			sb.add_child(c_wr)

			var c_wb = CollisionShape3D.new()
			var b_wb = BoxShape3D.new()
			b_wb.size = Vector3(6.8, 3.2, 0.5)
			c_wb.shape = b_wb
			c_wb.position = Vector3(0.0, 1.8, -2.4)
			sb.add_child(c_wb)

			var c_cnt = CollisionShape3D.new()
			var b_cnt = BoxShape3D.new()
			b_cnt.size = Vector3(3.4, 1.0, 0.9)
			c_cnt.shape = b_cnt
			c_cnt.position = Vector3(0.0, 1.0, 2.2)
			sb.add_child(c_cnt)

			# Non-passable solid roof/eaves/awning
			var c_roof = CollisionShape3D.new()
			var b_roof = BoxShape3D.new()
			b_roof.size = Vector3(8.4, 0.45, 7.4)
			c_roof.shape = b_roof
			c_roof.position = Vector3(0.0, 3.4, 0.2)
			sb.add_child(c_roof)

		DestructibleProp.PropType.PAVILION:
			var col_base = CollisionShape3D.new()
			var cyl_base = CylinderShape3D.new()
			cyl_base.radius = 3.9
			cyl_base.height = 0.65
			col_base.shape = cyl_base
			col_base.position = Vector3(0.0, 0.32, 0.0)
			sb.add_child(col_base)

			var col_tbl = CollisionShape3D.new()
			var cyl_tbl = CylinderShape3D.new()
			cyl_tbl.radius = 1.15
			cyl_tbl.height = 1.5
			col_tbl.shape = cyl_tbl
			col_tbl.position = Vector3(0.0, 0.75, 0.0)
			sb.add_child(col_tbl)

			for i in range(6):
				var ang = (2.0 * PI * i) / 6.0
				var p_col = CollisionShape3D.new()
				var p_cyl = CylinderShape3D.new()
				p_cyl.radius = 0.22
				p_cyl.height = 3.2
				p_col.shape = p_cyl
				p_col.position = Vector3(cos(ang) * 3.0, 2.2, sin(ang) * 3.0)
				sb.add_child(p_col)

			# Non-passable pavilion roof canopy
			var c_pav_roof = CollisionShape3D.new()
			var b_pav_roof = BoxShape3D.new()
			b_pav_roof.size = Vector3(8.2, 0.6, 8.2)
			c_pav_roof.shape = b_pav_roof
			c_pav_roof.position = Vector3(0.0, 3.8, 0.0)
			sb.add_child(c_pav_roof)

		DestructibleProp.PropType.PAGODA:
			var c_terr = CollisionShape3D.new()
			var b_terr = BoxShape3D.new()
			b_terr.size = Vector3(12.2, 1.25, 12.2)
			c_terr.shape = b_terr
			c_terr.position = Vector3(0.0, 0.62, 0.0)
			sb.add_child(c_terr)

			var c_core = CollisionShape3D.new()
			var b_core = BoxShape3D.new()
			b_core.size = Vector3(7.6, 8.0, 7.6)
			c_core.shape = b_core
			c_core.position = Vector3(0.0, 5.2, 0.0)
			sb.add_child(c_core)

			# Tier 1, 2, 3 solid roof eaves
			var c_r1 = CollisionShape3D.new()
			var b_r1 = BoxShape3D.new()
			b_r1.size = Vector3(10.8, 0.5, 10.8)
			c_r1.shape = b_r1
			c_r1.position = Vector3(0.0, 3.8, 0.0)
			sb.add_child(c_r1)

			var c_r2 = CollisionShape3D.new()
			var b_r2 = BoxShape3D.new()
			b_r2.size = Vector3(9.2, 0.5, 9.2)
			c_r2.shape = b_r2
			c_r2.position = Vector3(0.0, 6.8, 0.0)
			sb.add_child(c_r2)

			var c_r3 = CollisionShape3D.new()
			var b_r3 = BoxShape3D.new()
			b_r3.size = Vector3(7.4, 0.5, 7.4)
			c_r3.shape = b_r3
			c_r3.position = Vector3(0.0, 9.6, 0.0)
			sb.add_child(c_r3)

		DestructibleProp.PropType.BRIDGE:
			var c_b_deck = CollisionShape3D.new()
			var b_b_deck = BoxShape3D.new()
			b_b_deck.size = Vector3(4.2, 0.5, 12.0)
			c_b_deck.shape = b_b_deck
			c_b_deck.position = Vector3(0.0, 1.2, 0.0)
			sb.add_child(c_b_deck)

		DestructibleProp.PropType.CRATE:
			var col_c = CollisionShape3D.new()
			var box_c = BoxShape3D.new()
			box_c.size = Vector3(1.6, 1.2, 1.6)
			col_c.shape = box_c
			col_c.position = Vector3(0.0, 0.6, 0.0)
			sb.add_child(col_c)

	d_prop.add_child(sb)

func _setup_trimesh_collision(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var m_name = node.name.to_lower()
		var mesh_name = node.mesh.resource_name.to_lower()
		var is_foliage_or_water = ("blossom" in m_name or "foliage" in m_name or "leaves" in m_name or "leaf" in m_name or "water" in m_name or
			"blossom" in mesh_name or "foliage" in mesh_name or "leaves" in mesh_name or "leaf" in mesh_name or "water" in mesh_name)
		if not is_foliage_or_water:
			var has_body = false
			for c in node.get_children():
				if c is StaticBody3D:
					has_body = true
					break
			if not has_body:
				node.create_trimesh_collision()
				for c in node.get_children():
					if c is StaticBody3D:
						for cs in c.get_children():
							if cs is CollisionShape3D and cs.shape is ConcavePolygonShape3D:
								(cs.shape as ConcavePolygonShape3D).backface_collision = true
	for child in node.get_children():
		if not child is StaticBody3D:
			_setup_trimesh_collision(child)

func _add_lantern_light(parent: Node3D, local_pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	if not parent:
		return
	var light = OmniLight3D.new()
	light.position = local_pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	parent.add_child(light)
	all_lantern_lights.append({"light": light, "base_energy": energy, "base_color": color})

func update_lantern_time_of_day(night_factor: float) -> void:
	for entry in all_lantern_lights:
		var l: OmniLight3D = entry.get("light")
		if is_instance_valid(l):
			var base_e: float = entry.get("base_energy", 1.2)
			l.light_energy = base_e * lerp(0.85, 1.85, night_factor)
			var base_c: Color = entry.get("base_color", Color(1.0, 0.75, 0.35))
			var night_c = Color(1.0, 0.65, 0.25)
			l.light_color = base_c.lerp(night_c, night_factor)
