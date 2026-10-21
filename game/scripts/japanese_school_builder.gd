extends Node3D
class_name JapaneseSchoolBuilder

## Builds a fully detailed 3-story Japanese High School (桜ヶ丘学園)
## with interior classrooms, shoe lockers (genkan), stairs to all 3 floors,
## rooftop terrace with safety fencing, sports ground, and solid collisions.

static func build_school(parent: Node3D, origin: Vector3) -> Node3D:
	var school_root = Node3D.new()
	school_root.name = "JapaneseHighSchool"
	school_root.position = origin
	parent.add_child(school_root)

	var sb = StaticBody3D.new()
	sb.name = "SchoolCollisions"
	school_root.add_child(sb)

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

	# ==================== 1. FLOORS & CEILINGS ====================
	for f in range(4): # 0: Ground, 1: 2nd, 2: 3rd, 3: Roof
		var y = f * fl_h
		var m_f = mat_roof if f == 3 else mat_floor
		_add_box(school_root, sb, Vector3(0, y + 0.1, 0), Vector3(b_w, 0.22, b_d), m_f, true)

	# Foundation podium
	_add_box(school_root, sb, Vector3(0, -0.3, 0), Vector3(b_w + 1.2, 0.6, b_d + 1.2), mat_base, true)

	# ==================== 2. EXTERIOR WALLS & WINDOW BANDS ====================
	# Back Wall (Solid with corridor windows)
	_add_box(school_root, sb, Vector3(0, total_h * 0.5, -b_d * 0.5), Vector3(b_w, total_h, 0.35), mat_wall, true)

	# Left & Right Outer Walls
	_add_box(school_root, sb, Vector3(-b_w * 0.5, total_h * 0.5, 0), Vector3(0.35, total_h, b_d), mat_wall, true)
	_add_box(school_root, sb, Vector3(b_w * 0.5, total_h * 0.5, 0), Vector3(0.35, total_h, b_d), mat_wall, true)

	# Front Facade: Pillars, Entrance Arch, and Classroom Window Strips
	for f in range(3):
		var y_base = f * fl_h
		# Lower sill
		_add_box(school_root, sb, Vector3(0, y_base + 0.6, b_d * 0.5), Vector3(b_w, 1.2, 0.35), mat_wall, true)
		# Upper lintel
		_add_box(school_root, sb, Vector3(0, y_base + fl_h - 0.4, b_d * 0.5), Vector3(b_w, 0.8, 0.35), mat_wall, true)
		# Window glass band (with solid frame)
		_add_box(school_root, sb, Vector3(0, y_base + 1.8, b_d * 0.5), Vector3(b_w - 0.6, 1.4, 0.08), mat_window, false)

	# Structural Vertical Pillars on Facade
	for px in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		_add_box(school_root, sb, Vector3(px, total_h * 0.5, b_d * 0.5 + 0.15), Vector3(0.7, total_h, 0.6), mat_base, true)

	# ==================== 3. GRAND ENTRANCE & CANOPY ====================
	# Overhanging Entrance Canopy (Non-passable solid overhang)
	_add_box(school_root, sb, Vector3(0, 3.4, b_d * 0.5 + 2.2), Vector3(7.4, 0.4, 4.4), mat_base, true)
	# Canopy support columns
	_add_box(school_root, sb, Vector3(-3.2, 1.6, b_d * 0.5 + 4.0), Vector3(0.4, 3.2, 0.4), mat_frame, true)
	_add_box(school_root, sb, Vector3(3.2, 1.6, b_d * 0.5 + 4.0), Vector3(0.4, 3.2, 0.4), mat_frame, true)
	# School Entrance Steps
	for st in range(3):
		var sy = st * 0.12
		var sz = b_d * 0.5 + 4.2 + (2 - st) * 0.4
		_add_box(school_root, sb, Vector3(0, sy + 0.06, sz), Vector3(6.8, 0.12, 0.45), mat_roof, true)

	# School Clock Tower on Entrance Roof
	_add_box(school_root, sb, Vector3(0, total_h + 1.6, b_d * 0.5), Vector3(3.2, 3.2, 0.8), mat_wall, true)
	_add_box(school_root, null, Vector3(0, total_h + 1.6, b_d * 0.5 + 0.45), Vector3(1.4, 1.4, 0.1), mat_frame, false) # Clock face

	# ==================== 4. INTERIOR CORRIDORS, DOORS & PARTITIONS ====================
	for f in range(3):
		var y_base = f * fl_h
		# Central longitudinal corridor wall dividing classrooms from hallway
		# Hallway is along Z [-5.8, -2.6], Classrooms are along Z [-2.6, 5.8]
		# Wall with door cutouts
		_add_box(school_root, sb, Vector3(-7.0, y_base + fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
		_add_box(school_root, sb, Vector3(7.0, y_base + fl_h * 0.5, -2.4), Vector3(10.0, fl_h, 0.25), mat_wall, true)
		# Dividing wall between Left & Right Classroom
		_add_box(school_root, sb, Vector3(0, y_base + fl_h * 0.5, 1.7), Vector3(0.25, fl_h, 8.2), mat_wall, true)

	# ==================== 5. STAIRWELL (Walkable to All 3 Floors & Roof) ====================
	# Positioned in the corridor at X: [-11.0, -7.5]
	for f in range(3):
		var y_base = f * fl_h
		var num_steps = 14
		var step_rise = fl_h / float(num_steps)
		var step_run = 4.2 / float(num_steps)
		for s in range(num_steps):
			var sy = y_base + (s + 0.5) * step_rise
			var sz = -5.2 + s * step_run
			_add_box(school_root, sb, Vector3(-9.2, sy, sz), Vector3(2.4, step_rise, step_run + 0.05), mat_floor, true)
		# Stair railing
		_add_box(school_root, sb, Vector3(-7.9, y_base + fl_h * 0.5, -3.1), Vector3(0.12, 1.0, 4.4), mat_frame, true)

	# ==================== 6. GENKAN (1st Floor Entrance & Shoe Lockers) ====================
	# Rows of wooden shoe lockers (Getabako / 下駄箱)
	for gx in [-2.4, 2.4]:
		for gz in [0.0, 2.4]:
			_add_box(school_root, sb, Vector3(gx, 0.8, gz), Vector3(2.6, 1.4, 0.6), mat_door, true)
	# Entry mat / stepping boundary
	_add_box(school_root, null, Vector3(0, 0.22, 4.2), Vector3(5.4, 0.02, 1.8), mat_base, false)

	# ==================== 7. CLASSROOM FURNITURE (2nd Floor) ====================
	var f2_y = fl_h
	# Chalkboard on front wall of Classroom 1 & 2
	_add_box(school_root, null, Vector3(-5.5, f2_y + 1.8, 5.6), Vector3(4.8, 1.4, 0.06), mat_bb, false)
	_add_box(school_root, null, Vector3(5.5, f2_y + 1.8, 5.6), Vector3(4.8, 1.4, 0.06), mat_bb, false)
	# Teacher podiums
	_add_box(school_root, sb, Vector3(-5.5, f2_y + 0.5, 4.2), Vector3(1.4, 0.9, 0.8), mat_door, true)
	_add_box(school_root, sb, Vector3(5.5, f2_y + 0.5, 4.2), Vector3(1.4, 0.9, 0.8), mat_door, true)
	# Student Desks & Chairs (2 rows in each classroom)
	for cx_offset in [-8.5, -2.5, 2.5, 8.5]:
		for dz in [0.5, 2.2]:
			_add_box(school_root, sb, Vector3(cx_offset, f2_y + 0.45, dz), Vector3(1.0, 0.75, 0.65), mat_door, true)

	# ==================== 8. ROOFTOP TERRACE & SAFETY CHAIN-LINK FENCE ====================
	var r_y = total_h
	# Roof perimeter solid curb
	_add_box(school_root, sb, Vector3(0, r_y + 0.3, b_d * 0.5), Vector3(b_w + 0.4, 0.6, 0.4), mat_base, true)
	_add_box(school_root, sb, Vector3(0, r_y + 0.3, -b_d * 0.5), Vector3(b_w + 0.4, 0.6, 0.4), mat_base, true)
	_add_box(school_root, sb, Vector3(b_w * 0.5, r_y + 0.3, 0), Vector3(0.4, 0.6, b_d + 0.4), mat_base, true)
	_add_box(school_root, sb, Vector3(-b_w * 0.5, r_y + 0.3, 0), Vector3(0.4, 0.6, b_d + 0.4), mat_base, true)

	# Rooftop High Safety Fence (2.2m tall steel mesh, fully solid so player cannot fall)
	_add_box(school_root, sb, Vector3(0, r_y + 1.7, b_d * 0.5), Vector3(b_w, 2.2, 0.1), mat_fence, true)
	_add_box(school_root, sb, Vector3(0, r_y + 1.7, -b_d * 0.5), Vector3(b_w, 2.2, 0.1), mat_fence, true)
	_add_box(school_root, sb, Vector3(b_w * 0.5, r_y + 1.7, 0), Vector3(0.1, 2.2, b_d), mat_fence, true)
	_add_box(school_root, sb, Vector3(-b_w * 0.5, r_y + 1.7, 0), Vector3(0.1, 2.2, b_d), mat_fence, true)

	# Rooftop HVAC ventilation machinery & water tank
	_add_box(school_root, sb, Vector3(4.5, r_y + 1.2, -2.5), Vector3(2.4, 2.2, 2.4), mat_frame, true)
	_add_box(school_root, sb, Vector3(8.5, r_y + 0.9, -2.5), Vector3(3.2, 1.6, 1.8), mat_frame, true)
	# Rooftop Benches for eating lunch
	_add_box(school_root, sb, Vector3(-4.0, r_y + 0.35, 2.0), Vector3(2.2, 0.5, 0.7), mat_door, true)
	_add_box(school_root, sb, Vector3(4.0, r_y + 0.35, 2.0), Vector3(2.2, 0.5, 0.7), mat_door, true)

	# ==================== 9. SCHOOL GROUNDS & COURTYARD ====================
	# Paved School Campus Podium & Courtyard (covers the entire campus cleanly)
	_add_box(school_root, sb, Vector3(0, -0.05, 12.0), Vector3(56.0, 0.12, 52.0), mat_asphalt, true)

	# Running Track / Athletic Field (placed cleanly on top of campus plaza)
	_add_box(school_root, null, Vector3(0, 0.02, 19.0), Vector3(38.0, 0.02, 18.0), mat_track, false)
	# Track inner soccer lawn
	_add_box(school_root, null, Vector3(0, 0.03, 19.0), Vector3(30.0, 0.02, 11.0), mat_grass, false)

	# Athletic Field White Field Markings
	var mat_line = _make_mat(Color(0.95, 0.95, 0.95), 0.85, 0.0)
	_add_box(school_root, null, Vector3(0, 0.035, 19.0), Vector3(0.12, 0.01, 10.8), mat_line, false) # Halfway line
	_add_box(school_root, null, Vector3(0, 0.035, 19.0), Vector3(29.6, 0.01, 0.12), mat_line, false) # Center touchline

	# Soccer Goal Posts
	_add_goal_post(school_root, sb, Vector3(-13.5, 0.03, 19.0), mat_frame)
	_add_goal_post(school_root, sb, Vector3(13.5, 0.03, 19.0), mat_frame)

	# Main School Gate (Pillars + Sign)
	_add_box(school_root, sb, Vector3(-4.5, 1.8, 30.0), Vector3(0.9, 3.6, 0.9), mat_base, true)
	_add_box(school_root, sb, Vector3(4.5, 1.8, 30.0), Vector3(0.9, 3.6, 0.9), mat_base, true)
	# Plaque on Gate Pillar
	var plaque = Label3D.new()
	plaque.text = "私立桜ヶ丘学園\n(Sakuragaoka High)"
	plaque.font_size = 28
	plaque.outline_size = 8
	plaque.position = Vector3(-4.0, 2.0, 30.48)
	plaque.rotation_degrees = Vector3(0, 0, 0)
	school_root.add_child(plaque)

	# Entrance Paved Promenade connecting School Gate to City Avenue
	_add_box(school_root, null, Vector3(0, 0.01, 36.0), Vector3(9.0, 0.02, 14.0), mat_asphalt, false)

	# Perimeter Schoolyard Fence
	_add_box(school_root, sb, Vector3(0, 1.2, 30.0), Vector3(38.0, 2.4, 0.1), mat_fence, true)
	_add_box(school_root, sb, Vector3(-24.0, 1.2, 18.0), Vector3(0.1, 2.4, 24.0), mat_fence, true)
	_add_box(school_root, sb, Vector3(24.0, 1.2, 18.0), Vector3(0.1, 2.4, 24.0), mat_fence, true)

	# Bicycle Parking Rack
	_add_box(school_root, sb, Vector3(-16.0, 1.2, 8.0), Vector3(6.5, 2.4, 3.2), mat_frame, true)

	return school_root

static func _add_goal_post(parent: Node3D, sb: StaticBody3D, pos: Vector3, mat: Material) -> void:
	# Crossbar
	_add_box(parent, sb, pos + Vector3(0, 2.2, 0), Vector3(0.15, 0.15, 3.8), mat, true)
	# Posts
	_add_box(parent, sb, pos + Vector3(0, 1.1, -1.9), Vector3(0.15, 2.2, 0.15), mat, true)
	_add_box(parent, sb, pos + Vector3(0, 1.1, 1.9), Vector3(0.15, 2.2, 0.15), mat, true)

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
