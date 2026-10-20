extends Node3D

@onready var player: Node3D = $ChibiPlayer
@onready var ui: CanvasLayer = $UI
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var env_node: WorldEnvironment = $WorldEnvironment
@onready var asian_world: Node3D = $AsianWorld

# Dynamic Day/Night Cycle in seconds (600s = 10 minutes full cycle)
@export var day_length_seconds: float = 600.0
var time_of_day: float = 0.25 # Starts at 06:00 AM (Glorious Dawn)

# Lazy Monster Spawner System
var pending_monsters: Array[Dictionary] = []
var spawned_monsters: Array[Node3D] = []
var stream_check_timer: float = 0.0

const MONSTER_SPAWN_RADIUS = 35.0

func _ready() -> void:
	if player and ui:
		player.stats_changed.connect(ui.update_stats)
		if player.has_signal("level_up_event"):
			player.level_up_event.connect(ui.show_level_up_banner)
		if player.has_signal("exp_gained_event"):
			player.exp_gained_event.connect(ui.show_exp_gain)
		if player.has_signal("skill_cooldown_updated"):
			player.skill_cooldown_updated.connect(ui.update_skill_cooldown)
		if player.has_signal("party_switched"):
			player.party_switched.connect(ui.on_party_switched)
		if player.has_signal("party_member_recruited"):
			player.party_member_recruited.connect(ui.on_party_member_recruited)
		player.emit_stats()

	_setup_window_branding()
	_init_monster_database()
	_spawn_world_chests()
	_spawn_companions()
	_setup_anime_sun()
	_update_monster_spawning(true)
	_setup_splash_screen()



func _setup_splash_screen() -> void:
	if "--test-levelup" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.6)
		timer.timeout.connect(func():
			if player:
				if player.camera_pivot:
					player.camera_pivot.rotation_degrees.y = 165.0
					player.camera_pivot.rotation_degrees.x = -10.0
				if player.spring_arm:
					player.spring_arm.spring_length = 2.5
				player.level_up()
			var sub_timer = get_tree().create_timer(0.25)
			sub_timer.timeout.connect(func():
				var img = get_viewport().get_texture().get_image()
				if img:
					img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/levelup_vfx_preview.png")
					print("[MAIN] Saved levelup_vfx_preview.png")
				get_tree().quit(0)
			)
		)
		return

	if "--capture" in OS.get_cmdline_args():
		# Bypass splash for automated capture testing
		_on_splash_started()
		var timer = get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			var cam = player.find_child("Camera3D", true, false) if player else null
			if cam:
				cam.global_position = Vector3(14.0, 6.5, -2.0)
				cam.look_at(Vector3(32.0, 4.0, 22.0), Vector3.UP)
			var sub_timer = get_tree().create_timer(0.4)
			sub_timer.timeout.connect(func():
				var img = get_viewport().get_texture().get_image()
				if img:
					img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/new_world_detailed.png")
					print("[MAIN] Saved new_world_detailed.png")
				get_tree().quit(0)
			)
		)
		return

	if "--test-cover" in OS.get_cmdline_args():
		var timer = get_tree().create_timer(0.7)
		timer.timeout.connect(func():
			await RenderingServer.frame_post_draw
			var vp = get_viewport()
			if vp:
				var img = vp.get_texture().get_image()
				if img:
					img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/new_sdvgacha_cover.png")
					print("[COVER] Saved new_sdvgacha_cover.png")
			get_tree().quit(0)
		)
		return

	if "--test-mobile-hud" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.7)
		timer.timeout.connect(func():
			await RenderingServer.frame_post_draw
			var vp = get_viewport()
			if vp:
				var img = vp.get_texture().get_image()
				if img:
					img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/mobile_hud_preview.png")
					print("[MOBILE_HUD] Saved mobile_hud_preview.png")
			get_tree().quit(0)
		)
		return

	if "--test-ellen-spawn" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.7)
		timer.timeout.connect(func():
			await RenderingServer.frame_post_draw
			var vp = get_viewport()
			if vp:
				var img = vp.get_texture().get_image()
				if img:
					img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/ellen_model_showcase.png")
					print("[ELLEN_SPAWN] Saved ellen_model_showcase.png")
			get_tree().quit(0)
		)
		return

	if "--test-ellen-dialogue" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func():
			var npc = find_child("NPCCompanion", true, false)
			if npc and npc.has_method("_trigger_dialogue"):
				npc._trigger_dialogue()
			var sub_timer = get_tree().create_timer(1.0)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/ellen_dialogue_showcase.png")
						print("[ELLEN_DIALOGUE] Saved ellen_dialogue_showcase.png")
				get_tree().quit(0)
				OS.kill(OS.get_process_id())
			)
		)
		return

	if "--test-charsheet-v3" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func():
			if ui and ui.has_method("open_character_sheet"):
				ui.open_character_sheet()
			var sub_timer = get_tree().create_timer(1.0)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/charsheet_v3_showcase.png")
						print("[CHARSHEET] Saved charsheet_v3_showcase.png")
				get_tree().quit(0)
				OS.kill(OS.get_process_id())
			)
		)
		return

	if "--test-pause-menu" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func():
			if ui and ui.has_method("open_pause_menu"):
				ui.open_pause_menu()
			var sub_timer = get_tree().create_timer(1.0)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/pause_menu_preview.png")
						print("[PAUSE_MENU] Saved pause_menu_preview.png")
				get_tree().quit(0)
				OS.kill(OS.get_process_id())
			)
		)
		return

	if "--test-controls-guide" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func():
			if ui and ui.has_method("open_controls_guide"):
				ui.open_controls_guide()
			var sub_timer = get_tree().create_timer(1.0)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/controls_guide_preview.png")
						print("[CONTROLS_GUIDE] Saved controls_guide_preview.png")
				get_tree().quit(0)
				OS.kill(OS.get_process_id())
			)
		)
		return

	if "--test-school" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.4)
		timer.timeout.connect(func():
			if player:
				player.global_position = Vector3(30.0, AsianWorldBuilder.get_terrain_height(30.0, -34.0) + 0.1, -34.0)
				if player.camera_pivot:
					player.camera_pivot.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
				if player.spring_arm:
					player.spring_arm.spring_length = 7.0
			var sub_timer = get_tree().create_timer(0.8)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/school_showcase.png")
						print("[SCHOOL] Saved school_showcase.png")
				get_tree().quit(0)
				OS.kill(OS.get_process_id())
			)
		)
		return

	if "--test-chest" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.4)
		timer.timeout.connect(func():
			var chest_scene = preload("res://scenes/treasure_chest.tscn")
			var test_chest = chest_scene.instantiate() as TreasureChest
			test_chest.rarity = TreasureChest.ChestRarity.LUXURIOUS
			var spawn_pos = Vector3(14.0, AsianWorldBuilder.get_terrain_height(14.0, -14.0) + 0.05, -14.0)
			if player:
				player.global_position = spawn_pos + Vector3(0, 0, 2.2)
				if player.camera_pivot:
					player.camera_pivot.rotation_degrees = Vector3(-10.0, 180.0, 0.0)
				if player.spring_arm:
					player.spring_arm.spring_length = 3.6
			test_chest.position = spawn_pos
			test_chest.rotation_degrees.y = 0.0
			add_child(test_chest)

			var t_open = get_tree().create_timer(0.4)
			t_open.timeout.connect(func():
				test_chest.open_chest()

				# Shot 1: Opening animation, lid fling, sunburst pillar, ring, and spewing loot & EXP
				var t_shot1 = get_tree().create_timer(0.25)
				t_shot1.timeout.connect(func():
					await RenderingServer.frame_post_draw
					var vp = get_viewport()
					if vp:
						var img = vp.get_texture().get_image()
						if img:
							img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/chest_opening_vfx.png")
							print("[CHEST] Saved chest_opening_vfx.png")

					# Shot 2: Exactly ~1.15s after open (evaporation to particles after 1.0s)
					var t_shot2 = get_tree().create_timer(0.92)
					t_shot2.timeout.connect(func():
						await RenderingServer.frame_post_draw
						var vp2 = get_viewport()
						if vp2:
							var img2 = vp2.get_texture().get_image()
							if img2:
								img2.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/chest_dissolve_vfx.png")
								print("[CHEST] Saved chest_dissolve_vfx.png")
						get_tree().quit(0)
						OS.kill(OS.get_process_id())
					)
				)
			)
		)
		return

	if "--test-water" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.4)
		timer.timeout.connect(func():
			if player:
				player.global_position = Vector3(4.5, AsianWorldBuilder.get_terrain_height(4.5, 5.0) + 0.1, 5.0)
				if player.camera_pivot:
					player.camera_pivot.rotation_degrees = Vector3(-18.0, 140.0, 0.0)
			var sub_timer = get_tree().create_timer(0.6)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/new_water_showcase.png")
						print("[WATER] Saved new_water_showcase.png")
				get_tree().quit(0)
			)
		)
		return

	if "--test-charsheet" in OS.get_cmdline_args():
		_on_splash_started()
		var timer = get_tree().create_timer(0.35)
		timer.timeout.connect(func():
			if ui and ui.has_method("toggle_character_sheet"):
				ui.toggle_character_sheet()
			var sub_timer = get_tree().create_timer(0.65)
			sub_timer.timeout.connect(func():
				await RenderingServer.frame_post_draw
				var vp = get_viewport()
				if vp:
					var img = vp.get_texture().get_image()
					if img:
						img.save_png("C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17/new_charsheet_fixed.png")
						print("[CHARSHEET] Saved new_charsheet_fixed.png")
				get_tree().quit(0)
			)
		)
		return

	if "--showcase-all" in OS.get_cmdline_args():
		_on_splash_started()
		_run_showcase_sequence()
		return

	var splash_scene = preload("res://scenes/splash_screen.tscn")
	if splash_scene:
		var splash = splash_scene.instantiate()
		splash.started.connect(_on_splash_started)
		add_child(splash)
		get_tree().paused = true

func _on_splash_started() -> void:
	get_tree().paused = false
	if player and player.has_method("activate_game_controls"):
		player.activate_game_controls()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_anime_sun() -> void:
	if sun:
		_update_day_night_cycle(0.0)

func _process(delta: float) -> void:
	# Advance 10-Minute Day/Night Cycle (600 seconds)
	time_of_day = fposmod(time_of_day + delta / day_length_seconds, 1.0)
	_update_day_night_cycle(delta)

	stream_check_timer += delta
	if stream_check_timer >= 0.3:
		stream_check_timer = 0.0
		_update_monster_spawning()

func _update_day_night_cycle(_delta: float) -> void:
	if not sun or not env_node or not env_node.environment:
		return

	var env = env_node.environment
	# 0.0 - 1.0 cycle:
	# 0.20 - 0.30 = Dawn / Sunrise (04:48 - 07:12)
	# 0.30 - 0.70 = Daytime (07:12 - 16:48)
	# 0.70 - 0.82 = Sunset / Dusk (16:48 - 19:40)
	# 0.82 - 0.20 = Night (19:40 - 04:48)

	var cycle_rad = (time_of_day - 0.25) * TAU
	var sun_y = sin(cycle_rad)
	var is_day = sun_y > -0.08

	var light_col: Color
	var light_e: float
	var ambient_col: Color
	var ambient_e: float
	var fog_col: Color
	var fog_d: float
	var sky_e: float
	var night_factor: float = 0.0

	if time_of_day >= 0.20 and time_of_day < 0.30:
		# 1. Рассвет (Dawn / Sunrise)
		var p = (time_of_day - 0.20) / 0.10
		light_col = Color(1.0, 0.62, 0.40).lerp(Color(1.0, 0.94, 0.84), p)
		light_e = lerp(0.85, 1.30, p)
		ambient_col = Color(0.85, 0.70, 0.78).lerp(Color(0.72, 0.82, 0.96), p)
		ambient_e = lerp(0.70, 0.85, p)
		fog_col = Color(0.92, 0.76, 0.68).lerp(Color(0.72, 0.84, 0.98), p)
		fog_d = lerp(0.0022, 0.0014, p)
		sky_e = lerp(0.85, 1.15, p)
		night_factor = lerp(0.5, 0.0, p)
	elif time_of_day >= 0.30 and time_of_day < 0.70:
		# 2. День (Daytime)
		light_col = Color(1.0, 0.96, 0.88)
		light_e = 1.30
		ambient_col = Color(0.72, 0.82, 0.96)
		ambient_e = 0.85
		fog_col = Color(0.72, 0.84, 0.98)
		fog_d = 0.0014
		sky_e = 1.15
		night_factor = 0.0
	elif time_of_day >= 0.70 and time_of_day < 0.82:
		# 3. Закат / Вечер (Golden Hour & Sunset)
		var p = (time_of_day - 0.70) / 0.12
		light_col = Color(1.0, 0.82, 0.45).lerp(Color(1.0, 0.42, 0.18), p)
		light_e = lerp(1.25, 0.45, p)
		ambient_col = Color(0.82, 0.72, 0.88).lerp(Color(0.68, 0.42, 0.58), p)
		ambient_e = lerp(0.85, 0.58, p)
		fog_col = Color(0.95, 0.65, 0.45).lerp(Color(0.88, 0.38, 0.32), p)
		fog_d = lerp(0.0014, 0.0020, p)
		sky_e = lerp(1.15, 0.65, p)
		night_factor = p
	else:
		# 4. Ночь (Night / Moonlight)
		light_col = Color(0.58, 0.72, 0.98)
		light_e = 0.38
		ambient_col = Color(0.24, 0.28, 0.48)
		ambient_e = 0.42
		fog_col = Color(0.12, 0.16, 0.32)
		fog_d = 0.0018
		sky_e = 0.35
		night_factor = 1.0

	var pitch_deg: float
	var yaw_deg: float
	if is_day:
		pitch_deg = -clamp(sun_y * 72.0, 10.0, 72.0)
		yaw_deg = lerp_angle(deg_to_rad(45.0), deg_to_rad(225.0), (time_of_day - 0.25) / 0.50)
	else:
		pitch_deg = -45.0
		yaw_deg = deg_to_rad(135.0)

	sun.rotation = Vector3(deg_to_rad(pitch_deg), yaw_deg, 0.0)
	sun.light_color = light_col
	sun.light_energy = light_e

	env.ambient_light_color = ambient_col
	env.ambient_light_energy = ambient_e
	env.fog_light_color = fog_col
	env.fog_density = fog_d

	if env.sky and env.sky.sky_material and env.sky.sky_material is PanoramaSkyMaterial:
		(env.sky.sky_material as PanoramaSkyMaterial).energy_multiplier = sky_e

	if asian_world and asian_world.has_method("update_lantern_time_of_day"):
		asian_world.update_lantern_time_of_day(night_factor)

func _setup_window_branding() -> void:
	DisplayServer.window_set_title("SDVGacha — Anime Action RPG")
	var icon_tex = load("res://icon.png") as Texture2D
	if not icon_tex:
		icon_tex = load("res://assets/textures/player_portrait.png") as Texture2D
	if icon_tex:
		var img = icon_tex.get_image()
		if img:
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert(Image.FORMAT_RGBA8)
			DisplayServer.set_icon(img)

func _init_monster_database() -> void:
	pending_monsters = [
		# 1. Sakura Blossom Valley & Lotus Lake
		{"name": "Сакуровый Слайм", "pos": Vector3(-18.0, 1.4, -8.0), "hp": 45, "atk": 8, "exp": 28, "scale": 1.0, "spawned": false, "instance": null},
		{"name": "Лазурный Слизнюк", "pos": Vector3(-28.0, 1.8, -14.0), "hp": 50, "atk": 9, "exp": 30, "scale": 1.05, "spawned": false, "instance": null},
		{"name": "Водяной Слайм", "pos": Vector3(-6.0, 0.2, 2.0), "hp": 40, "atk": 7, "exp": 25, "scale": 0.95, "spawned": false, "instance": null},
		{"name": "Цветочный Слизнюк", "pos": Vector3(-36.0, 2.4, -20.0), "hp": 45, "atk": 8, "exp": 28, "scale": 1.0, "spawned": false, "instance": null},

		# 2. Emerald Bamboo Forest
		{"name": "Бамбуковый Гоблин-Охотник", "pos": Vector3(-24.0, 2.2, 36.0), "hp": 55, "atk": 13, "exp": 38, "scale": 1.0, "spawned": false, "instance": null},
		{"name": "Гоблин-Разведчик", "pos": Vector3(-38.0, 2.8, 48.0), "hp": 60, "atk": 14, "exp": 42, "scale": 1.05, "spawned": false, "instance": null},
		{"name": "Изумрудный Слизнюк", "pos": Vector3(-20.0, 2.0, 56.0), "hp": 48, "atk": 10, "exp": 30, "scale": 1.0, "spawned": false, "instance": null},
		{"name": "Гоблин-Головорез", "pos": Vector3(-46.0, 3.4, 52.0), "hp": 75, "atk": 16, "exp": 52, "scale": 1.15, "spawned": false, "instance": null},

		# 3. Mountain Pass & Karst Spires
		{"name": "Костяной Страж Скал", "pos": Vector3(30.0, 2.2, 26.0), "hp": 65, "atk": 14, "exp": 45, "scale": 1.05, "spawned": false, "instance": null},
		{"name": "Скелет-Дозорный", "pos": Vector3(40.0, 5.2, 40.0), "hp": 70, "atk": 16, "exp": 48, "scale": 1.1, "spawned": false, "instance": null},
		{"name": "Огненный Слайм", "pos": Vector3(46.0, 6.8, 52.0), "hp": 60, "atk": 13, "exp": 40, "scale": 1.1, "spawned": false, "instance": null},
		{"name": "Лавовый Слизнюк", "pos": Vector3(36.0, 3.8, 56.0), "hp": 65, "atk": 14, "exp": 42, "scale": 1.15, "spawned": false, "instance": null},

		# 4. Dragon Sanctum Boss Arena (Mountain Peak)
		{"name": "👑 Владыка Слаймов (Босс Алтаря)", "pos": Vector3(52.0, 8.8, 66.0), "hp": 260, "atk": 26, "exp": 150, "scale": 2.5, "spawned": false, "instance": null},

		# 5. POI Guards: Bandit Camp & Ancient Ruins
		{"name": "Гоблин-Мародёр Лагеря", "pos": Vector3(38.0, 2.2, 21.0), "hp": 70, "atk": 15, "exp": 45, "scale": 1.1, "spawned": false, "instance": null},
		{"name": "Призрак Древних Руин", "pos": Vector3(-28.0, 2.6, 52.0), "hp": 80, "atk": 18, "exp": 55, "scale": 1.15, "spawned": false, "instance": null},

		# 6. Чумные Земли Нежити (Warcraft Scourge Undead Lands)
		{"name": "Чумной Вурдалак", "pos": Vector3(-42.0, 2.2, -68.0), "hp": 90, "atk": 19, "exp": 65, "scale": 1.1, "spawned": false, "instance": null},
		{"name": "Скелет-Могильщик", "pos": Vector3(-55.0, 2.5, -78.0), "hp": 105, "atk": 21, "exp": 75, "scale": 1.15, "spawned": false, "instance": null},
		{"name": "Некромант Тьмы", "pos": Vector3(-35.0, 2.1, -85.0), "hp": 85, "atk": 24, "exp": 80, "scale": 1.05, "spawned": false, "instance": null},
		{"name": "Гнилостный Мясник", "pos": Vector3(-62.0, 2.8, -92.0), "hp": 140, "atk": 23, "exp": 95, "scale": 1.35, "spawned": false, "instance": null},
		{"name": "👑 Ануб'Рек (Лорд Склепа)", "pos": Vector3(-48.0, 2.6, -80.0), "hp": 380, "atk": 32, "exp": 220, "scale": 2.5, "spawned": false, "instance": null},

		# 7. Кибер-Город и Неоновый Сектор (Cyberpunk Metropolis)
		{"name": "Кибер-Дрон «Оса-4»", "pos": Vector3(32.0, 3.2, 74.0), "hp": 75, "atk": 18, "exp": 60, "scale": 0.95, "spawned": false, "instance": null},
		{"name": "Штурмовой Механоид", "pos": Vector3(48.0, 3.4, 82.0), "hp": 120, "atk": 22, "exp": 85, "scale": 1.2, "spawned": false, "instance": null},
		{"name": "Кибер-Ниндзя «Спектр»", "pos": Vector3(25.0, 3.1, 90.0), "hp": 95, "atk": 25, "exp": 90, "scale": 1.05, "spawned": false, "instance": null},
		{"name": "Энергетический Синт-Страж", "pos": Vector3(60.0, 3.5, 95.0), "hp": 110, "atk": 20, "exp": 80, "scale": 1.15, "spawned": false, "instance": null},
		{"name": "👑 Кибер-Титан «Прометей»", "pos": Vector3(45.0, 3.6, 92.0), "hp": 420, "atk": 34, "exp": 250, "scale": 2.4, "spawned": false, "instance": null}
	]

func _spawn_companions() -> void:
	var companion_scene = load("res://scenes/npc_companion.tscn")
	if not companion_scene:
		return

	# Spawn Ellen Joe directly in front of the player upon entering the game (Player starts at 18.0, 3.4, -6.0)
	var ellen = companion_scene.instantiate() as Node3D
	var ellen_pos = Vector3(20.4, 0.0, -5.2)
	ellen_pos.y = AsianWorldBuilder.get_terrain_height(ellen_pos.x, ellen_pos.z)
	ellen.position = ellen_pos
	ellen.rotation_degrees = Vector3(0, -115.0, 0) # Facing the player directly
	add_child(ellen)

func _spawn_world_chests() -> void:
	var chest_scene = preload("res://scenes/treasure_chest.tscn")
	var chest_locations = [
		# --- Sakura Valley & Lakeside ---
		{"pos": Vector3(-22.0, 1.8, -2.0), "rarity": 0, "rot": 45.0}, # Sakura Lake Meditation Chest (Common)
		{"pos": Vector3(-32.0, 2.5, -16.0), "rarity": 2, "rot": 45.0}, # Kitsune Shrine Sacred Chest (Precious)
		{"pos": Vector3(-14.0, 1.9, 12.0), "rarity": 0, "rot": -15.0}, # Blossom Grove Clearing Chest (Common)
		{"pos": Vector3(-3.5, 0.5, -30.0), "rarity": 0, "rot": 90.0}, # Riverside Fishing Pier Chest (Common)
		{"pos": Vector3(3.8, 0.45, 17.5), "rarity": 0, "rot": 0.0}, # River Fisherman's Wharf Chest (Common)
		{"pos": Vector3(0.0, 3.6, -6.0), "rarity": 1, "rot": 90.0, "fixed_y": true}, # Grand Moon Bridge Arch Chest (Exquisite)

		# --- Asian City & Market District ---
		{"pos": Vector3(18.0, 3.2, -18.0), "rarity": 0, "rot": 35.0}, # Merchant Alley Nook Chest (Common)
		{"pos": Vector3(44.0, 4.8, 2.0), "rarity": 1, "rot": -30.0}, # Pagoda Lower Terrace Chest (Exquisite)
		{"pos": Vector3(46.0, 9.8, -6.0), "rarity": 3, "rot": -90.0, "fixed_y": true}, # Pagoda Grand Spire Balcony Chest (Luxurious)
		{"pos": Vector3(25.0, 3.1, 10.5), "rarity": 1, "rot": 180.0}, # Southern Promenade Gate Chest (Exquisite)

		# --- 3-Story Japanese High School (桜ヶ丘学園) ---
		{"pos": Vector3(30.0, 14.1, -48.0), "rarity": 3, "rot": 0.0, "fixed_y": true}, # School Rooftop Observatory Chest (Luxurious)
		{"pos": Vector3(24.5, 6.9, -46.0), "rarity": 1, "rot": 90.0, "fixed_y": true}, # School 2nd Floor Classroom 2-A Chest (Exquisite)
		{"pos": Vector3(35.5, 10.5, -46.0), "rarity": 2, "rot": -90.0, "fixed_y": true}, # School 3rd Floor Student Council Chest (Precious)
		{"pos": Vector3(30.0, 3.3, -44.0), "rarity": 1, "rot": 0.0, "fixed_y": true}, # School Entrance Genkan Lockers Chest (Exquisite)
		{"pos": Vector3(16.5, 3.2, -29.0), "rarity": 0, "rot": 45.0}, # School Athletic Track Goal Chest (Common)
		{"pos": Vector3(14.0, 3.2, -40.0), "rarity": 0, "rot": -45.0}, # School Bicycle Parking Shelter Chest (Common)

		# --- Bamboo Forest, Karst Peaks & Dragon Sanctum ---
		{"pos": Vector3(-40.0, 3.0, 56.0), "rarity": 1, "rot": 75.0}, # Bamboo Forest Grove Chest (Exquisite)
		{"pos": Vector3(-12.0, 0.6, 32.0), "rarity": 2, "rot": 120.0}, # Hidden Waterfall Basin Cavern Chest (Precious)
		{"pos": Vector3(22.0, 3.2, 40.5), "rarity": 1, "rot": 90.0}, # Mountain Teahouse Vista Chest (Exquisite)
		{"pos": Vector3(39.5, 2.2, 19.5), "rarity": 1, "rot": -25.0}, # Bandit Camp Fortress Chest (Exquisite)
		{"pos": Vector3(-28.0, 2.6, 51.0), "rarity": 2, "rot": 30.0}, # Ancient Stone Ruins Altar Chest (Precious)
		{"pos": Vector3(44.0, 8.0, 54.0), "rarity": 2, "rot": -15.0}, # Karst Mountain Summit Pass Chest (Precious)
		{"pos": Vector3(52.0, 8.8, 70.0), "rarity": 3, "rot": 0.0}, # Dragon Sanctum Inner Hoard Chest (Luxurious)

		# --- Outer Frontiers: Undead Plaguelands & Cyber City ---
		{"pos": Vector3(-48.0, 2.6, -74.0), "rarity": 2, "rot": 0.0}, # Undead Crypt Mausoleum Chest (Precious)
		{"pos": Vector3(-58.0, 3.2, -85.0), "rarity": 3, "rot": -35.0}, # Lich King's Obsidian Sepulcher Chest (Luxurious)
		{"pos": Vector3(32.0, 3.4, 90.0), "rarity": 1, "rot": 60.0}, # Cyber City Neon Backalley Chest (Exquisite)
		{"pos": Vector3(45.0, 3.5, 96.0), "rarity": 3, "rot": 180.0} # Cyber City Central Plaza Tower Chest (Luxurious)
	]
	for c_data in chest_locations:
		var chest = chest_scene.instantiate() as TreasureChest
		var pos: Vector3 = c_data["pos"]
		if not c_data.get("fixed_y", false):
			var th = AsianWorldBuilder.get_terrain_height(pos.x, pos.z)
			if th > -1.5:
				pos.y = th + c_data.get("y_offset", 0.05)
		chest.position = pos
		chest.rarity = c_data["rarity"] as TreasureChest.ChestRarity
		chest.rotation_degrees.y = c_data.get("rot", 0.0)
		add_child(chest)

func _update_monster_spawning(force: bool = false) -> void:
	if not player or not is_instance_valid(player):
		return
	var player_pos = player.global_position
	var enemy_scene = preload("res://scenes/enemy.tscn")

	for m_data in pending_monsters:
		var dist = player_pos.distance_to(m_data["pos"])
		if (dist <= MONSTER_SPAWN_RADIUS or force) and not m_data["spawned"]:
			var enemy = enemy_scene.instantiate()
			enemy.position = m_data["pos"]
			enemy.enemy_name = m_data["name"]
			enemy.max_hp = m_data["hp"]
			enemy.current_hp = m_data["hp"]
			enemy.attack_damage = m_data["atk"]
			enemy.exp_reward = m_data["exp"]
			if m_data.has("scale") and m_data["scale"] != 1.0:
				enemy.scale = Vector3.ONE * m_data["scale"]
			add_child(enemy)
			m_data["spawned"] = true
			m_data["instance"] = enemy
		elif dist > MONSTER_SPAWN_RADIUS + 10.0 and m_data["spawned"]:
			if is_instance_valid(m_data["instance"]):
				m_data["instance"].queue_free()
			m_data["instance"] = null
			m_data["spawned"] = false

func _run_showcase_sequence() -> void:
	var brain_dir = "C:/Users/troki/.gemini/antigravity/brain/347d3171-74d4-4c12-8caf-29af6064aa17"

	# Step 1: Sakura Trees Grounded (viewing slope where trees are planted)
	await get_tree().create_timer(1.0).timeout
	if player:
		player.global_position = Vector3(14.0, AsianWorldBuilder.get_terrain_height(14.0, -14.0) + 0.1, -14.0)
		if player.camera_pivot:
			player.camera_pivot.rotation_degrees = Vector3(-12.0, 50.0, 0.0)
	await get_tree().create_timer(0.4).timeout
	await _capture_screenshot(brain_dir + "/showcase_01_sakura_grounded.png")

	# Step 2: Character Sheet & Hu Tao 3D Model Preview
	if ui and ui.has_method("toggle_character_sheet"):
		ui.toggle_character_sheet()
	await get_tree().create_timer(0.6).timeout
	await _capture_screenshot(brain_dir + "/showcase_02_hu_tao_sheet.png")

	# Step 3: Ellen Joe NPC in World
	if ui and ui.character_sheet and ui.character_sheet.visible:
		ui.toggle_character_sheet()
	if player:
		var ellen_spawn = Vector3(-18.5, AsianWorldBuilder.get_terrain_height(-18.5, -4.0) + 0.1, -4.0)
		player.global_position = ellen_spawn
		if player.camera_pivot:
			player.camera_pivot.rotation_degrees = Vector3(-8.0, -125.0, 0.0)
	await get_tree().create_timer(0.4).timeout
	await _capture_screenshot(brain_dir + "/showcase_03_ellen_joe_world.png")

	# Step 4: Ellen Joe VN Dialogue Cutscene
	var ellen = find_child("NPCCompanion_ellen_joe", true, false)
	if not ellen:
		var npcs = get_tree().get_nodes_in_group("npcs")
		if npcs.size() > 0:
			ellen = npcs[0]
	if ellen and ellen.has_method("_trigger_dialogue"):
		ellen._trigger_dialogue()
	await get_tree().create_timer(0.5).timeout
	await _capture_screenshot(brain_dir + "/showcase_04_ellen_vn_dialogue.png")

	# Step 5: Blighted Undead Plaguelands
	if ui and ui.has_method("hide_vn_dialogue"):
		ui.hide_vn_dialogue()
	if player:
		var blight_pos = Vector3(-44.0, AsianWorldBuilder.get_terrain_height(-44.0, -70.0) + 0.1, -70.0)
		player.global_position = blight_pos
		if player.camera_pivot:
			player.camera_pivot.rotation_degrees = Vector3(-10.0, -145.0, 0.0)
	_update_monster_spawning(true)
	await get_tree().create_timer(0.5).timeout
	await _capture_screenshot(brain_dir + "/showcase_05_blighted_undead.png")

	# Step 6: Cyber City
	if player:
		var cyber_pos = Vector3(40.0, AsianWorldBuilder.get_terrain_height(40.0, 82.0) + 0.1, 82.0)
		player.global_position = cyber_pos
		if player.camera_pivot:
			player.camera_pivot.rotation_degrees = Vector3(-12.0, 35.0, 0.0)
	_update_monster_spawning(true)
	await get_tree().create_timer(0.5).timeout
	await _capture_screenshot(brain_dir + "/showcase_06_cyber_city.png")

	# Step 7: Weapon Attack Combo
	if player and player.has_method("perform_attack"):
		player.perform_attack()
	await get_tree().create_timer(0.18).timeout
	await _capture_screenshot(brain_dir + "/showcase_07_weapon_attack.png")

	print("[SHOWCASE] All 7 showcase images successfully saved!")
	get_tree().quit(0)

func _capture_screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var vp = get_viewport()
	if vp:
		var img = vp.get_texture().get_image()
		if img and not img.is_empty():
			img.save_png(path)
			print("[SHOWCASE] Saved screenshot: ", path)

