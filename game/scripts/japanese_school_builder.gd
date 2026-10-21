extends Node3D
class_name JapaneseSchoolBuilder

## Builds a fully detailed, modular, and completely destructible
## 3-story Japanese High School (桜ヶ丘学園) with interior classrooms,
## shoe lockers (genkan), stairs to all 3 floors, rooftop terrace,
## safety fencing, sports ground, soccer goals, and school gate.
## Each floor, rooftop, gate, and furniture cluster is an independent
## DestructibleProp with individual health, collision, and debris physics!

static func build_school(parent: Node3D, origin: Vector3) -> Node3D:
	var school_root = Node3D.new()
	school_root.name = "JapaneseHighSchool"
	school_root.position = origin
	parent.add_child(school_root)

	# Palette materials (Balanced anime palette with high contrast and zero blinding glare)
	var mat_wall = _make_mat(Color(0.86, 0.88, 0.91), 0.85, 0.0) # Soft anime architectural school plaster
	var mat_base = _make_mat(Color(0.22, 0.28, 0.40), 0.75, 0.0) # Navy blue foundation
	var mat_floor = _make_mat(Color(0.76, 0.58, 0.42), 0.75, 0.0) # Polished wooden parquet floor
	var mat_roof = _make_mat(Color(0.48, 0.52, 0.56), 0.85, 0.0) # Rooftop concrete
	var mat_window = _make_glass_mat()
	var mat_frame = _make_mat(Color(0.18, 0.20, 0.25), 0.70, 0.3) # Aluminum window frames
	var mat_door = _make_mat(Color(0.65, 0.42, 0.25), 0.80, 0.0) # Wood classroom doors
	var mat_bb = _make_mat(Color(0.10, 0.30, 0.20), 0.85, 0.0) # Green chalkboard
	var mat_fence = _make_mat(Color(0.32, 0.35, 0.38), 0.70, 0.5) # Steel mesh fence
	var mat_track = _make_mat(Color(0.68, 0.30, 0.20), 0.92, 0.0) # Rich reddish-clay athletic track
	var mat_grass = _make_mat(Color(0.26, 0.58, 0.20), 0.90, 0.0) # Manicured athletic turf
	var mat_asphalt = _make_mat(Color(0.44, 0.45, 0.48), 0.88, 0.0) # School plaza concrete/asphalt

	var b_w = 26.0 # Width (X)
	var b_d = 12.0 # Depth (Z)
	var fl_h = 3.6 # Floor height
	var total_h = fl_h * 3.0 # 10.8m

	# ==================== 1. PERMANENT GROUND FOUNDATION & PLAZA ====================
	# Static ground podium ensures the terrain never vanishes when building collapses
	var ground_body = StaticBody3D.new()
	ground_body.name = "SchoolCampusGround"
	school_root.add_child(ground_body)

	# Paved School Campus Podium & Courtyard
	_add_box(school_root, ground_body, Vector3(0, -0.05, 12.0), Vector3(56.0, 0.12, 52.0), mat_asphalt, true)

	# Running Track / Athletic Field
	_add_box(school_root, null, Vector3(0, 0.02, 19.0), Vector3(38.0, 0.02, 18.0), mat_track, false)
	_add_box(school_root, null, Vector3(0, 0.03, 19.0), Vector3(30.0, 0.02, 11.0), mat_grass, false)

	# Athletic Field Markings
	var mat_line = _make_mat(Color(0.95, 0.95, 0.95), 0.85, 0.0)
	_add_box(school_root, null, Vector3(0, 0.035, 19.0), Vector3(0.12, 0.01, 10.8), mat_line, false)
	_add_box(school_root, null, Vector3(0, 0.035, 19.0), Vector3(29.6, 0.01, 0.12), mat_line, false)

	# Entrance Paved Promenade connecting School Gate to City Avenue
	_add_box(school_root, null, Vector3(0, 0.01, 36.0), Vector3(9.0, 0.02, 14.0), mat_asphalt, false)

	# ==================== 2. DESTRUCTIBLE FLOOR 1 & ENTRANCE MODULE ====================
	var f1_mod = _create_module(school_root, "School_Module_Floor1", DestructibleProp.PropType.SCHOOL_SECTION, 320)
	# Foundation podium
	_add_box_to_mod(f1_mod, Vector3(0, -0.3, 0), Vector3(b_w + 1.2, 0.6, b_d + 1.2), mat_base, true)
	# 1st floor parquet floor
	_add_box_to_mod(f1_mod, Vector3(0, 0.1, 0), Vector3(b_w, 0.22, b_d), mat_floor, true)
	# Back wall (floor 1)
	_add_box_to_mod(f1_mod, Vector3(0, fl_h * 0.5, -b_d * 0.5), Vector3(b_w, fl_h, 0.35), mat_wall, true)
	# Outer side walls (floor 1)
	_add_box_to_mod(f1_mod, Vector3(-b_w * 0.5, fl_h * 0.5, 0), Vector3(0.35, fl_h, b_d), mat_wall, true)
	_add_box_to_mod(f1_mod, Vector3(b_w * 0.5, fl_h * 0.5, 0), Vector3(0.35, fl_h, b_d), mat_wall, true)
	# Front facade sill, lintel, window glass
	_add_box_to_mod(f1_mod, Vector3(0, 0.6, b_d * 0.5), Vector3(b_w, 1.2, 0.35), mat_wall, true)
	_add_box_to_mod(f1_mod, Vector3(0, fl_h - 0.4, b_d * 0.5), Vector3(b_w, 0.8, 0.35), mat_wall, true)
	_add_box_to_mod(f1_mod, Vector3(0, 1.8, b_d * 0.5), Vector3(b_w - 0.6, 1.4, 0.08), mat_window, false)
	# Facade vertical pillars (floor 1)
	for px in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		_add_box_to_mod(f1_mod, Vector3(px, fl_h * 0.5, b_d * 0.5 + 0.15), Vector3(0.7, fl_h, 0.6), mat_base, true)
	# Grand Entrance Canopy
	_add_box_to_mod(f1_mod, Vector3(0, 3.4, b_d * 0.5 + 2.2), Vector3(7.4, 0.4, 4.4), mat_base, true)
	_add_box_to_mod(f1_mod, Vector3(-3.2, 1.6, b_d * 0.5 + 4.0), Vector3(0.4, 3.2, 0.4), mat_frame, true)
	_add_box_to_mod(f1_mod, Vector3(3.2, 1.6, b_d * 0.5 + 4.0), Vector3(0.4, 3.2, 0.4), mat_frame, true)
	# Entrance Steps
	for st in range(3):
		var sy = st * 0.12
		var sz = b_d * 0.5 + 4.2 + (2 - st) * 0.4
		_add_box_to_mod(f1_mod, Vector3(0, sy + 0.06, sz), Vector3(6.8, 0.12, 0.45), mat_roof, true)
	# Genkan shoe lockers (Getabako)
	for gx in [-2.4, 2.4]:
		for gz in [0.0, 2.4]:
			_add_box_to_mod(f1_mod, Vector3(gx, 0.8, gz), Vector3(2.6, 1.4, 0.6), mat_door, true)
	_add_box_to_mod(f1_mod, Vector3(0, 0.22, 4.2), Vector3(5.4, 0.02, 1.8), mat_base, false)
	# Corridor walls
	_add_box_to_mod(f1_mod, Vector3(-7.0, fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
	_add_box_to_mod(f1_mod, Vector3(7.0, fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
	_add_box_to_mod(f1_mod, Vector3(0, fl_h * 0.5, 1.7), Vector3(0.25, fl_h, 8.2), mat_wall, true)
	# 1st floor stairwell
	_build_stair_flight_to_mod(f1_mod, 0.0, fl_h, mat_floor, mat_frame)

	# ==================== 3. DESTRUCTIBLE FLOOR 2 MODULE ====================
	var f2_mod = _create_module(school_root, "School_Module_Floor2", DestructibleProp.PropType.SCHOOL_SECTION, 260)
	var f2_y = fl_h
	# 2nd floor parquet floor
	_add_box_to_mod(f2_mod, Vector3(0, f2_y + 0.1, 0), Vector3(b_w, 0.22, b_d), mat_floor, true)
	# Back wall (floor 2)
	_add_box_to_mod(f2_mod, Vector3(0, f2_y + fl_h * 0.5, -b_d * 0.5), Vector3(b_w, fl_h, 0.35), mat_wall, true)
	# Outer side walls (floor 2)
	_add_box_to_mod(f2_mod, Vector3(-b_w * 0.5, f2_y + fl_h * 0.5, 0), Vector3(0.35, fl_h, b_d), mat_wall, true)
	_add_box_to_mod(f2_mod, Vector3(b_w * 0.5, f2_y + fl_h * 0.5, 0), Vector3(0.35, fl_h, b_d), mat_wall, true)
	# Front facade sill, lintel, window glass
	_add_box_to_mod(f2_mod, Vector3(0, f2_y + 0.6, b_d * 0.5), Vector3(b_w, 1.2, 0.35), mat_wall, true)
	_add_box_to_mod(f2_mod, Vector3(0, f2_y + fl_h - 0.4, b_d * 0.5), Vector3(b_w, 0.8, 0.35), mat_wall, true)
	_add_box_to_mod(f2_mod, Vector3(0, f2_y + 1.8, b_d * 0.5), Vector3(b_w - 0.6, 1.4, 0.08), mat_window, false)
	# Facade vertical pillars (floor 2)
	for px in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		_add_box_to_mod(f2_mod, Vector3(px, f2_y + fl_h * 0.5, b_d * 0.5 + 0.15), Vector3(0.7, fl_h, 0.6), mat_base, true)
	# Corridor walls
	_add_box_to_mod(f2_mod, Vector3(-7.0, f2_y + fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
	_add_box_to_mod(f2_mod, Vector3(7.0, f2_y + fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
	_add_box_to_mod(f2_mod, Vector3(0, f2_y + fl_h * 0.5, 1.7), Vector3(0.25, fl_h, 8.2), mat_wall, true)
	# 2nd floor stairwell
	_build_stair_flight_to_mod(f2_mod, f2_y, fl_h, mat_floor, mat_frame)

	# ==================== 4. DESTRUCTIBLE FLOOR 3 MODULE ====================
	var f3_mod = _create_module(school_root, "School_Module_Floor3", DestructibleProp.PropType.SCHOOL_SECTION, 260)
	var f3_y = fl_h * 2.0
	# 3rd floor parquet floor
	_add_box_to_mod(f3_mod, Vector3(0, f3_y + 0.1, 0), Vector3(b_w, 0.22, b_d), mat_floor, true)
	# Back wall (floor 3)
	_add_box_to_mod(f3_mod, Vector3(0, f3_y + fl_h * 0.5, -b_d * 0.5), Vector3(b_w, fl_h, 0.35), mat_wall, true)
	# Outer side walls (floor 3)
	_add_box_to_mod(f3_mod, Vector3(-b_w * 0.5, f3_y + fl_h * 0.5, 0), Vector3(0.35, fl_h, b_d), mat_wall, true)
	_add_box_to_mod(f3_mod, Vector3(b_w * 0.5, f3_y + fl_h * 0.5, 0), Vector3(0.35, fl_h, b_d), mat_wall, true)
	# Front facade sill, lintel, window glass
	_add_box_to_mod(f3_mod, Vector3(0, f3_y + 0.6, b_d * 0.5), Vector3(b_w, 1.2, 0.35), mat_wall, true)
	_add_box_to_mod(f3_mod, Vector3(0, f3_y + fl_h - 0.4, b_d * 0.5), Vector3(b_w, 0.8, 0.35), mat_wall, true)
	_add_box_to_mod(f3_mod, Vector3(0, f3_y + 1.8, b_d * 0.5), Vector3(b_w - 0.6, 1.4, 0.08), mat_window, false)
	# Facade vertical pillars (floor 3)
	for px in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		_add_box_to_mod(f3_mod, Vector3(px, f3_y + fl_h * 0.5, b_d * 0.5 + 0.15), Vector3(0.7, fl_h, 0.6), mat_base, true)
	# Corridor walls
	_add_box_to_mod(f3_mod, Vector3(-7.0, f3_y + fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
	_add_box_to_mod(f3_mod, Vector3(7.0, f3_y + fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
	_add_box_to_mod(f3_mod, Vector3(0, f3_y + fl_h * 0.5, 1.7), Vector3(0.25, fl_h, 8.2), mat_wall, true)
	# 3rd floor stairwell to roof
	_build_stair_flight_to_mod(f3_mod, f3_y, fl_h, mat_floor, mat_frame)

	# ==================== 5. DESTRUCTIBLE ROOFTOP & CLOCK TOWER MODULE ====================
	var roof_mod = _create_module(school_root, "School_Module_Rooftop", DestructibleProp.PropType.SCHOOL_ROOF, 220)
	var r_y = total_h
	# Roof concrete slab
	_add_box_to_mod(roof_mod, Vector3(0, r_y + 0.1, 0), Vector3(b_w, 0.22, b_d), mat_roof, true)
	# Perimeter concrete curbs
	_add_box_to_mod(roof_mod, Vector3(0, r_y + 0.3, b_d * 0.5), Vector3(b_w + 0.4, 0.6, 0.4), mat_base, true)
	_add_box_to_mod(roof_mod, Vector3(0, r_y + 0.3, -b_d * 0.5), Vector3(b_w + 0.4, 0.6, 0.4), mat_base, true)
	_add_box_to_mod(roof_mod, Vector3(b_w * 0.5, r_y + 0.3, 0), Vector3(0.4, 0.6, b_d + 0.4), mat_base, true)
	_add_box_to_mod(roof_mod, Vector3(-b_w * 0.5, r_y + 0.3, 0), Vector3(0.4, 0.6, b_d + 0.4), mat_base, true)
	# High Safety Steel Mesh Fence
	_add_box_to_mod(roof_mod, Vector3(0, r_y + 1.7, b_d * 0.5), Vector3(b_w, 2.2, 0.1), mat_fence, true)
	_add_box_to_mod(roof_mod, Vector3(0, r_y + 1.7, -b_d * 0.5), Vector3(b_w, 2.2, 0.1), mat_fence, true)
	_add_box_to_mod(roof_mod, Vector3(b_w * 0.5, r_y + 1.7, 0), Vector3(0.1, 2.2, b_d), mat_fence, true)
	_add_box_to_mod(roof_mod, Vector3(-b_w * 0.5, r_y + 1.7, 0), Vector3(0.1, 2.2, b_d), mat_fence, true)
	# School Clock Tower on Entrance Roof
	_add_box_to_mod(roof_mod, Vector3(0, total_h + 1.6, b_d * 0.5), Vector3(3.2, 3.2, 0.8), mat_wall, true)
	_add_box_to_mod(roof_mod, Vector3(0, total_h + 1.6, b_d * 0.5 + 0.45), Vector3(1.4, 1.4, 0.1), mat_frame, false)
	# Rooftop HVAC ventilation & water tank
	_add_box_to_mod(roof_mod, Vector3(4.5, r_y + 1.2, -2.5), Vector3(2.4, 2.2, 2.4), mat_frame, true)
	_add_box_to_mod(roof_mod, Vector3(8.5, r_y + 0.9, -2.5), Vector3(3.2, 1.6, 1.8), mat_frame, true)
	# Rooftop Lunch Benches
	_add_box_to_mod(roof_mod, Vector3(-4.0, r_y + 0.35, 2.0), Vector3(2.2, 0.5, 0.7), mat_door, true)
	_add_box_to_mod(roof_mod, Vector3(4.0, r_y + 0.35, 2.0), Vector3(2.2, 0.5, 0.7), mat_door, true)

	# ==================== 6. DESTRUCTIBLE FURNITURE CLUSTERS ====================
	# Classroom 2-A Student Desks (West Classroom Floor 2)
	var d2a = _create_module(school_root, "School_Desks_Class2A", DestructibleProp.PropType.SCHOOL_FURNITURE, 55)
	for cx_offset in [-8.5, -2.5]:
		for dz in [0.5, 2.2]:
			_add_box_to_mod(d2a, Vector3(cx_offset, f2_y + 0.45, dz), Vector3(1.0, 0.75, 0.65), mat_door, true)
	_add_box_to_mod(d2a, Vector3(-5.5, f2_y + 0.5, 4.2), Vector3(1.4, 0.9, 0.8), mat_door, true) # Teacher podium

	# Classroom 2-B Student Desks (East Classroom Floor 2)
	var d2b = _create_module(school_root, "School_Desks_Class2B", DestructibleProp.PropType.SCHOOL_FURNITURE, 55)
	for cx_offset in [2.5, 8.5]:
		for dz in [0.5, 2.2]:
			_add_box_to_mod(d2b, Vector3(cx_offset, f2_y + 0.45, dz), Vector3(1.0, 0.75, 0.65), mat_door, true)
	_add_box_to_mod(d2b, Vector3(5.5, f2_y + 0.5, 4.2), Vector3(1.4, 0.9, 0.8), mat_door, true) # Teacher podium

	# Chalkboards (Floor 2)
	var bb2 = _create_module(school_root, "School_Chalkboards_Floor2", DestructibleProp.PropType.SCHOOL_FURNITURE, 40)
	_add_box_to_mod(bb2, Vector3(-5.5, f2_y + 1.8, 5.6), Vector3(4.8, 1.4, 0.06), mat_bb, true)
	_add_box_to_mod(bb2, Vector3(5.5, f2_y + 1.8, 5.6), Vector3(4.8, 1.4, 0.06), mat_bb, true)

	# 3rd Floor Student Council & Music Club Furniture
	var d3 = _create_module(school_root, "School_Furniture_Floor3", DestructibleProp.PropType.SCHOOL_FURNITURE, 60)
	_add_box_to_mod(d3, Vector3(0.0, f3_y + 0.45, 2.0), Vector3(4.2, 0.75, 1.6), mat_door, true) # Conference table
	_add_box_to_mod(d3, Vector3(-5.5, f3_y + 1.8, 5.6), Vector3(4.8, 1.4, 0.06), mat_bb, true)

	# ==================== 7. DESTRUCTIBLE CAMPUS PROPS ====================
	# Main School Gate
	var gate_mod = _create_module(school_root, "School_MainGate", DestructibleProp.PropType.SCHOOL_GATE, 150)
	_add_box_to_mod(gate_mod, Vector3(-4.5, 1.8, 30.0), Vector3(0.9, 3.6, 0.9), mat_base, true)
	_add_box_to_mod(gate_mod, Vector3(4.5, 1.8, 30.0), Vector3(0.9, 3.6, 0.9), mat_base, true)
	_add_box_to_mod(gate_mod, Vector3(0, 3.4, 30.0), Vector3(9.0, 0.4, 0.8), mat_base, true) # Gate header beam
	var plaque = Label3D.new()
	plaque.text = "私立桜ヶ丘学園\n(Sakuragaoka High)"
	plaque.font_size = 28
	plaque.outline_size = 8
	plaque.position = Vector3(-4.0, 2.0, 30.48)
	gate_mod.add_child(plaque)

	# Athletic Field Soccer Goals
	var goal_w = _create_module(school_root, "School_SoccerGoal_West", DestructibleProp.PropType.SCHOOL_FURNITURE, 60)
	_build_goal_post_to_mod(goal_w, Vector3(-13.5, 0.03, 19.0), mat_frame)

	var goal_e = _create_module(school_root, "School_SoccerGoal_East", DestructibleProp.PropType.SCHOOL_FURNITURE, 60)
	_build_goal_post_to_mod(goal_e, Vector3(13.5, 0.03, 19.0), mat_frame)

	# Bicycle Parking Rack
	var bike_mod = _create_module(school_root, "School_BicycleRack", DestructibleProp.PropType.SCHOOL_FURNITURE, 75)
	_add_box_to_mod(bike_mod, Vector3(-16.0, 1.2, 8.0), Vector3(6.5, 2.4, 3.2), mat_frame, true)

	# Perimeter Fences (West, East, Front)
	var fence_w = _create_module(school_root, "School_Fence_West", DestructibleProp.PropType.SCHOOL_FURNITURE, 85)
	_add_box_to_mod(fence_w, Vector3(-24.0, 1.2, 18.0), Vector3(0.1, 2.4, 24.0), mat_fence, true)

	var fence_e = _create_module(school_root, "School_Fence_East", DestructibleProp.PropType.SCHOOL_FURNITURE, 85)
	_add_box_to_mod(fence_e, Vector3(24.0, 1.2, 18.0), Vector3(0.1, 2.4, 24.0), mat_fence, true)

	var fence_front = _create_module(school_root, "School_Fence_Front", DestructibleProp.PropType.SCHOOL_FURNITURE, 90)
	_add_box_to_mod(fence_front, Vector3(-14.0, 1.2, 30.0), Vector3(18.0, 2.4, 0.1), mat_fence, true)
	_add_box_to_mod(fence_front, Vector3(14.0, 1.2, 30.0), Vector3(18.0, 2.4, 0.1), mat_fence, true)

	return school_root

static func _create_module(parent: Node3D, mod_name: String, p_type: DestructibleProp.PropType, hp: int) -> DestructibleProp:
	var d_prop = DestructibleProp.new()
	d_prop.name = mod_name
	d_prop.prop_type = p_type
	d_prop.max_health = hp
	d_prop.current_health = hp
	parent.add_child(d_prop)

	var sb = StaticBody3D.new()
	sb.name = "Collisions"
	d_prop.add_child(sb)
	sb.add_to_group("destructible_body")
	sb.set_meta("destructible_parent", d_prop)

	# Dedicated combat hurtbox for swift multi-angle attack detection
	var hb = Area3D.new()
	hb.name = "DestructibleHurtbox"
	d_prop.add_child(hb)
	hb.add_to_group("destructible_hurtbox")
	hb.set_meta("destructible_parent", d_prop)

	return d_prop

static func _add_box_to_mod(d_prop: DestructibleProp, pos: Vector3, size: Vector3, mat: Material, add_collision: bool) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	box.material = mat
	mi.mesh = box
	mi.position = pos
	d_prop.add_child(mi)

	if add_collision:
		var sb = d_prop.get_node_or_null("Collisions") as StaticBody3D
		if sb:
			var col = CollisionShape3D.new()
			var cs = BoxShape3D.new()
			cs.size = size
			col.shape = cs
			col.position = pos
			sb.add_child(col)

		var hb = d_prop.get_node_or_null("DestructibleHurtbox") as Area3D
		if hb:
			var hcol = CollisionShape3D.new()
			var hcs = BoxShape3D.new()
			hcs.size = size + Vector3(0.12, 0.12, 0.12)
			hcol.shape = hcs
			hcol.position = pos
			hb.add_child(hcol)

	return mi

static func _build_stair_flight_to_mod(d_prop: DestructibleProp, y_base: float, fl_h: float, mat_floor: Material, mat_frame: Material) -> void:
	var num_steps = 14
	var step_rise = fl_h / float(num_steps)
	var step_run = 4.2 / float(num_steps)
	for s in range(num_steps):
		var sy = y_base + (s + 0.5) * step_rise
		var sz = -5.2 + s * step_run
		_add_box_to_mod(d_prop, Vector3(-9.2, sy, sz), Vector3(2.4, step_rise, step_run + 0.05), mat_floor, true)
	# Railing
	_add_box_to_mod(d_prop, Vector3(-7.9, y_base + fl_h * 0.5, -3.1), Vector3(0.12, 1.0, 4.4), mat_frame, true)

static func _build_goal_post_to_mod(d_prop: DestructibleProp, pos: Vector3, mat: Material) -> void:
	# Crossbar
	_add_box_to_mod(d_prop, pos + Vector3(0, 2.2, 0), Vector3(0.15, 0.15, 3.8), mat, true)
	# Posts
	_add_box_to_mod(d_prop, pos + Vector3(0, 1.1, -1.9), Vector3(0.15, 2.2, 0.15), mat, true)
	_add_box_to_mod(d_prop, pos + Vector3(0, 1.1, 1.9), Vector3(0.15, 2.2, 0.15), mat, true)

static func _add_box(parent: Node3D, sb: StaticBody3D, pos: Vector3, size: Vector3, mat: Material, add_collision: bool) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	box.material = mat
	mi.mesh = box
	mi.position = pos
	parent.add_child(mi)

	if add_collision and sb:
		var col = CollisionShape3D.new()
		var cs = BoxShape3D.new()
		cs.size = size
		col.shape = cs
		col.position = pos
		sb.add_child(col)

	return mi

static func _make_mat(albedo: Color, rough: float, metal: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = clamp(rough, 0.72, 1.0)
	mat.metallic = metal
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return mat

static func _make_glass_mat() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.85, 0.98, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2
	mat.metallic = 0.2
	return mat
