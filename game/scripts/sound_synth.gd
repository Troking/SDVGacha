extends Node

## Manages high quality audio streams, footsteps, ambient wind and Russian anime voice lines

signal hero_voice_started(stream: AudioStream)
signal hero_voice_finished()

var slash_stream: AudioStream = null
var slash_combo_streams: Array[AudioStream] = []
var slash_heavy_stream: AudioStream = null
var slash_charged_stream: AudioStream = null
var charge_hum_stream: AudioStream = null
var hit_stream: AudioStream = null
var jump_stream: AudioStream = null
var jump_streams: Array[AudioStream] = []
var dash_stream: AudioStream = null
var flame_burst_stream: AudioStream = null
var level_up_stream: AudioStream = null
var chest_open_stream: AudioStream = null
var chest_vanish_stream: AudioStream = null
var juicy_hit_stream: AudioStream = null
var glider_open_stream: AudioStream = null
var glider_wind_stream: AudioStream = null
var ui_hover_stream: AudioStream = null
var ui_click_stream: AudioStream = null
var ui_equip_stream: AudioStream = null
var glider_voices: Array[AudioStream] = []

# Asian Fantasy BGM & Water Sounds
var asian_bgm_stream: AudioStream = null
var asian_bgm_player: AudioStreamPlayer = null
var water_splash_enter_stream: AudioStream = null
var water_swim_stroke_stream: AudioStream = null
var water_splash_jump_stream: AudioStream = null

# Destructible Environment Audio Streams
var wood_chop_stream: AudioStream = null
var tree_fall_stream: AudioStream = null
var building_collapse_stream: AudioStream = null
var stone_crumble_stream: AudioStream = null

# Footstep sounds
var walk_steps: Array[AudioStream] = []
var run_steps: Array[AudioStream] = []

# Ambient
var ambient_stream: AudioStream = null
var ambient_player: AudioStreamPlayer = null

# Voice Language Mode
enum VoiceMode { HYBRID, JAPANESE_ONLY, RUSSIAN_ONLY }
var voice_mode: VoiceMode = VoiceMode.JAPANESE_ONLY
var music_volume_scale: float = 0.85
var sfx_volume_scale: float = 1.0

# Russian & Japanese Anime Girl Voice pools
var idle_voices: Array[AudioStream] = []
var attack_voices: Array[AudioStream] = []
var finisher_voices: Array[AudioStream] = []
var climb_voices: Array[AudioStream] = []
var hurt_voices: Array[AudioStream] = []
var jump_voices: Array[AudioStream] = []
var land_voices: Array[AudioStream] = []
var dash_voices: Array[AudioStream] = []
var menu_open_voices: Array[AudioStream] = []
var menu_close_voices: Array[AudioStream] = []
var lvlup_voices: Array[AudioStream] = []
var menu_idle_voices: Array[AudioStream] = []
var pyro_skill_voices: Array[AudioStream] = []
var pyro_idle_voices: Array[AudioStream] = []
var chest_voices: Array[AudioStream] = []

# Party Switch & Companion Voices (Ellen Joe & Hu Tao)
var ellen_switch_stream: AudioStream = null
var ht_switch_stream: AudioStream = null
var ellen_vn_greet_stream: AudioStream = null
var ellen_vn_accept_stream: AudioStream = null
var ellen_attack_voices: Array[AudioStream] = []
var ellen_idle_voices: Array[AudioStream] = []

# Heroine (Player) Dialogue Vocal Streams
var heroine_dialogue_start_stream: AudioStream = null
var heroine_choice_recruit_stream: AudioStream = null
var heroine_choice_battle_stream: AudioStream = null

# Material Hit Audio Streams
var hit_metal_stream: AudioStream = null
var hit_wood_stream: AudioStream = null
var hit_stone_stream: AudioStream = null
var hit_building_stream: AudioStream = null
var hit_cyber_stream: AudioStream = null
var hit_bone_stream: AudioStream = null
var hit_flesh_stream: AudioStream = null
var hit_slime_stream: AudioStream = null

# Biome BGMs
var current_biome_id: String = "asian"
var school_bgm_stream: AudioStream = null
var blight_bgm_stream: AudioStream = null
var cyber_bgm_stream: AudioStream = null
var bgm_players: Dictionary = {}

# Monster Audio Streams
var slime_hop_stream: AudioStream = null
var slime_alert_stream: AudioStream = null
var slime_charge_stream: AudioStream = null
var slime_attack_stream: AudioStream = null
var slime_hurt_streams: Array[AudioStream] = []
var slime_die_stream: AudioStream = null
var slime_splat_streams: Array[AudioStream] = []

var goblin_alert_stream: AudioStream = null
var goblin_charge_stream: AudioStream = null
var goblin_hurt_stream: AudioStream = null
var goblin_die_stream: AudioStream = null

var skel_alert_stream: AudioStream = null
var skel_die_stream: AudioStream = null

var voice_player: AudioStreamPlayer = null

# High-Performance Audio Player Pools (Zero-allocation audio architecture)
const POOL_SIZE_2D: int = 16
const POOL_SIZE_3D: int = 16
var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_idx_2d: int = 0
var _pool_idx_3d: int = 0

func _ready() -> void:
	slash_stream = _load_audio("res://assets/sounds/sword_slash_1.wav")
	var s1 = _load_audio("res://assets/sounds/sword_slash_1.wav")
	var s2 = _load_audio("res://assets/sounds/sword_slash_2.wav")
	var s3 = _load_audio("res://assets/sounds/sword_slash_3.wav")
	if s1: slash_combo_streams.append(s1)
	if s2: slash_combo_streams.append(s2)
	if s3: slash_combo_streams.append(s3)
	slash_heavy_stream = _load_audio("res://assets/sounds/sword_slash_heavy.wav")
	slash_charged_stream = _load_audio("res://assets/sounds/sword_slash_charged.wav")
	charge_hum_stream = _load_audio("res://assets/sounds/sword_charge_ready.wav")
	hit_stream = _load_audio("res://assets/sounds/sword_hit.wav")
	jump_stream = _load_audio("res://assets/sounds/jump.wav")
	var j1 = _load_audio("res://assets/sounds/jump_1.wav")
	var j2 = _load_audio("res://assets/sounds/jump_2.wav")
	var j3 = _load_audio("res://assets/sounds/jump_3.wav")
	if j1: jump_streams.append(j1)
	if j2: jump_streams.append(j2)
	if j3: jump_streams.append(j3)
	if jump_stream: jump_streams.append(jump_stream)
	dash_stream = _load_audio("res://assets/sounds/dash.wav")
	flame_burst_stream = _load_audio("res://assets/sounds/flame_burst.wav")
	level_up_stream = _load_audio("res://assets/sounds/level_up_chime.wav")
	chest_open_stream = _load_audio("res://assets/sounds/chest_open.wav")
	chest_vanish_stream = _load_audio("res://assets/sounds/chest_vanish.wav")
	juicy_hit_stream = _load_audio("res://assets/sounds/juicy_hit.wav")
	glider_open_stream = _load_audio("res://assets/sounds/glider_open.wav")
	glider_wind_stream = _load_audio("res://assets/sounds/glider_wind.wav")
	ui_hover_stream = _load_audio("res://assets/sounds/ui/ui_hover.wav")
	ui_click_stream = _load_audio("res://assets/sounds/ui/ui_click.wav")
	ui_equip_stream = _load_audio("res://assets/sounds/ui/ui_equip.wav")

	# Destructible Environment
	wood_chop_stream = _load_audio("res://assets/sounds/destruct/wood_chop.wav")
	tree_fall_stream = _load_audio("res://assets/sounds/destruct/tree_fall.wav")
	building_collapse_stream = _load_audio("res://assets/sounds/destruct/building_collapse.wav")
	stone_crumble_stream = _load_audio("res://assets/sounds/destruct/stone_crumble.wav")

	# Footsteps
	var ws1 = _load_audio("res://assets/sounds/voice/step_walk_1.wav")
	var ws2 = _load_audio("res://assets/sounds/voice/step_walk_2.wav")
	if ws1: walk_steps.append(ws1)
	if ws2: walk_steps.append(ws2)

	var rs1 = _load_audio("res://assets/sounds/voice/step_run_1.wav")
	var rs2 = _load_audio("res://assets/sounds/voice/step_run_2.wav")
	if rs1: run_steps.append(rs1)
	if rs2: run_steps.append(rs2)

	# Authentic Hu Tao Anime Voice & Vocalization Pools (Rie Takahashi & Natural Russian)
	# Playful Idle chatter
	_add_audio(idle_voices, "res://assets/sounds/voice/ht_idle_1.ogg")
	_add_audio(idle_voices, "res://assets/sounds/voice/ht_idle_2.ogg")
	_add_audio(idle_voices, "res://assets/sounds/voice/ht_idle_3.ogg")
	_add_audio(idle_voices, "res://assets/sounds/voice/ht_idle_4.ogg")
	_add_audio(idle_voices, "res://assets/sounds/voice/ht_idle_5.ogg")
	_add_audio(idle_voices, "res://assets/sounds/voice/ru_idle_1.mp3")
	_add_audio(idle_voices, "res://assets/sounds/voice/ru_idle_2.mp3")
	_add_audio(idle_voices, "res://assets/sounds/voice/ru_idle_3.mp3")
	_add_audio(idle_voices, "res://assets/sounds/voice/ru_idle_4.mp3")
	_add_audio(idle_voices, "res://assets/sounds/voice/ru_idle_5.mp3")

	# Attack effort grunts & battle shouts (Authentic Hu Tao)
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_atk_1.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_atk_2.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_atk_3.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_atk_4.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_light_atk_4.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_light_atk_5.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_mid_atk_2.ogg")
	_add_audio(attack_voices, "res://assets/sounds/voice/ht_mid_atk_3.ogg")

	# Finisher & Charged Attack shouts (Authentic Bursts & Finishers - 100% Hu Tao)
	_add_audio(finisher_voices, "res://assets/sounds/voice/ht_finisher_1.ogg")
	_add_audio(finisher_voices, "res://assets/sounds/voice/ht_finisher_2.ogg")
	_add_audio(finisher_voices, "res://assets/sounds/voice/ht_finisher_3.ogg")
	_add_audio(finisher_voices, "res://assets/sounds/voice/ht_burst_1.ogg")
	_add_audio(finisher_voices, "res://assets/sounds/voice/ht_burst_2.ogg")
	_add_audio(finisher_voices, "res://assets/sounds/voice/ht_burst_3.ogg")

	# Climbing tired anime sighs & exertion breaths (Authentic Hu Tao)
	_add_audio(climb_voices, "res://assets/sounds/voice/ht_climb_1.ogg")
	_add_audio(climb_voices, "res://assets/sounds/voice/ht_climb_2.ogg")
	_add_audio(climb_voices, "res://assets/sounds/voice/ht_climb_3.ogg")
	_add_audio(climb_voices, "res://assets/sounds/voice/ht_climb_4.ogg")

	# Hurt reactions (Authentic Hu Tao)
	_add_audio(hurt_voices, "res://assets/sounds/voice/ht_hurt_1.ogg")
	_add_audio(hurt_voices, "res://assets/sounds/voice/ht_hurt_2.ogg")
	_add_audio(hurt_voices, "res://assets/sounds/voice/ht_hurt_3.ogg")
	_add_audio(hurt_voices, "res://assets/sounds/voice/ht_hurt_4.ogg")

	# Jump hop vocalizations (Authentic Hu Tao)
	_add_audio(jump_voices, "res://assets/sounds/voice/ht_jump_1.ogg")
	_add_audio(jump_voices, "res://assets/sounds/voice/ht_jump_2.ogg")
	_add_audio(jump_voices, "res://assets/sounds/voice/ht_jump_3.ogg")
	_add_audio(jump_voices, "res://assets/sounds/voice/ht_jump_4.ogg")
	_add_audio(jump_voices, "res://assets/sounds/voice/ht_jump_5.ogg")

	# Landing impact breaths (Authentic Hu Tao)
	_add_audio(land_voices, "res://assets/sounds/voice/ht_land_1.ogg")
	_add_audio(land_voices, "res://assets/sounds/voice/ht_land_2.ogg")

	# Dash agile breaths (Authentic Hu Tao)
	_add_audio(dash_voices, "res://assets/sounds/voice/ht_dash_1.ogg")
	_add_audio(dash_voices, "res://assets/sounds/voice/ht_dash_2.ogg")
	_add_audio(dash_voices, "res://assets/sounds/voice/ht_dash_3.ogg")

	# Menu & Level-up voices
	_add_audio(menu_open_voices, "res://assets/sounds/voice/ht_chest_1.ogg")
	_add_audio(menu_open_voices, "res://assets/sounds/voice/ru_menu_open.mp3")

	_add_audio(menu_close_voices, "res://assets/sounds/voice/ht_dash_1.ogg")
	_add_audio(menu_close_voices, "res://assets/sounds/voice/ru_menu_close.mp3")

	_add_audio(lvlup_voices, "res://assets/sounds/voice/ht_chest_3.ogg")
	_add_audio(lvlup_voices, "res://assets/sounds/voice/ru_lvlup.mp3")

	_add_audio(menu_idle_voices, "res://assets/sounds/voice/ht_idle_1.ogg")
	_add_audio(menu_idle_voices, "res://assets/sounds/voice/ht_idle_3.ogg")
	_add_audio(menu_idle_voices, "res://assets/sounds/voice/ht_idle_5.ogg")
	_add_audio(menu_idle_voices, "res://assets/sounds/voice/ru_menu_idle_1.mp3")
	_add_audio(menu_idle_voices, "res://assets/sounds/voice/ru_menu_idle_2.mp3")
	_add_audio(menu_idle_voices, "res://assets/sounds/voice/ru_menu_idle_3.mp3")

	# Elemental Skill (Pyro Burst) Shouts
	_add_audio(pyro_skill_voices, "res://assets/sounds/voice/ht_pyro_skill_1.ogg")
	_add_audio(pyro_skill_voices, "res://assets/sounds/voice/ht_pyro_skill_2.ogg")
	_add_audio(pyro_skill_voices, "res://assets/sounds/voice/ht_pyro_skill_3.ogg")

	_add_audio(pyro_idle_voices, "res://assets/sounds/voice/ht_idle_2.ogg")
	_add_audio(pyro_idle_voices, "res://assets/sounds/voice/ht_idle_4.ogg")

	# Glider Voice Lines
	_add_audio(glider_voices, "res://assets/sounds/voice/ht_glider_1.ogg")
	_add_audio(glider_voices, "res://assets/sounds/voice/ht_glider_2.ogg")
	_add_audio(glider_voices, "res://assets/sounds/voice/ht_glider_3.ogg")
	_add_audio(glider_voices, "res://assets/sounds/voice/ru_glider_1.mp3")
	_add_audio(glider_voices, "res://assets/sounds/voice/ru_glider_2.mp3")
	_add_audio(glider_voices, "res://assets/sounds/voice/ru_glider_3.mp3")

	# Chest Opening Joyful Voices
	_add_audio(chest_voices, "res://assets/sounds/voice/ht_chest_1.ogg")
	_add_audio(chest_voices, "res://assets/sounds/voice/ht_chest_2.ogg")
	_add_audio(chest_voices, "res://assets/sounds/voice/ht_chest_3.ogg")

	# Ellen Joe & Switch Voicelines
	ellen_switch_stream = _load_audio("res://assets/sounds/voice/ellen_switch.mp3")
	ht_switch_stream = _load_audio("res://assets/sounds/voice/ht_switch.mp3")
	ellen_vn_greet_stream = _load_audio("res://assets/sounds/voice/ellen_vn_greet.mp3")
	ellen_vn_accept_stream = _load_audio("res://assets/sounds/voice/ellen_vn_accept.mp3")
	_add_audio(ellen_attack_voices, "res://assets/sounds/voice/ellen_attack_1.mp3")
	_add_audio(ellen_attack_voices, "res://assets/sounds/voice/ellen_attack_2.mp3")
	_add_audio(ellen_idle_voices, "res://assets/sounds/voice/ellen_idle.mp3")

	# Heroine Dialogue Voice Streams
	heroine_dialogue_start_stream = _load_audio("res://assets/sounds/voice/heroine_dialogue_start.mp3")
	heroine_choice_recruit_stream = _load_audio("res://assets/sounds/voice/heroine_choice_recruit.mp3")
	heroine_choice_battle_stream = _load_audio("res://assets/sounds/voice/heroine_choice_battle.mp3")

	# Material Hit Audio Streams
	hit_metal_stream = _load_audio("res://assets/sounds/hit_materials/hit_metal.wav")
	hit_wood_stream = _load_audio("res://assets/sounds/hit_materials/hit_wood.wav")
	hit_stone_stream = _load_audio("res://assets/sounds/hit_materials/hit_stone.wav")
	hit_building_stream = _load_audio("res://assets/sounds/hit_materials/hit_building.wav")
	hit_cyber_stream = _load_audio("res://assets/sounds/hit_materials/hit_cyber.wav")
	hit_bone_stream = _load_audio("res://assets/sounds/hit_materials/hit_bone.wav")
	hit_flesh_stream = _load_audio("res://assets/sounds/hit_materials/hit_flesh.wav")
	hit_slime_stream = _load_audio("res://assets/sounds/hit_materials/hit_slime.wav")

	# Biome BGM Streams
	school_bgm_stream = _load_audio("res://assets/sounds/bgm/anime_school_days.wav")
	blight_bgm_stream = _load_audio("res://assets/sounds/bgm/blighted_plaguelands.wav")
	cyber_bgm_stream = _load_audio("res://assets/sounds/bgm/cyber_city_pulse.wav")

	# Monsters audio loading
	slime_hop_stream = _load_audio("res://assets/sounds/monsters/slime_hop.wav")
	slime_alert_stream = _load_audio("res://assets/sounds/monsters/slime_alert.wav")
	slime_charge_stream = _load_audio("res://assets/sounds/monsters/slime_charge.wav")
	slime_attack_stream = _load_audio("res://assets/sounds/monsters/slime_attack.wav")
	_add_audio(slime_hurt_streams, "res://assets/sounds/monsters/slime_hurt_1.wav")
	_add_audio(slime_hurt_streams, "res://assets/sounds/monsters/slime_hurt_2.wav")
	slime_die_stream = _load_audio("res://assets/sounds/monsters/slime_die.wav")
	_add_audio(slime_splat_streams, "res://assets/sounds/monsters/slime_splat_1.wav")
	_add_audio(slime_splat_streams, "res://assets/sounds/monsters/slime_splat_2.wav")

	goblin_alert_stream = _load_audio("res://assets/sounds/monsters/goblin_alert.wav")
	goblin_charge_stream = _load_audio("res://assets/sounds/monsters/goblin_charge.wav")
	goblin_hurt_stream = _load_audio("res://assets/sounds/monsters/goblin_hurt.wav")
	goblin_die_stream = _load_audio("res://assets/sounds/monsters/goblin_die.wav")

	skel_alert_stream = _load_audio("res://assets/sounds/monsters/skel_alert.wav")
	skel_die_stream = _load_audio("res://assets/sounds/monsters/skel_die.wav")

	# Ambient Wind Player (continuous loop)
	ambient_stream = _load_audio("res://assets/sounds/ambient_wind.wav")
	if ambient_stream:
		ambient_player = AudioStreamPlayer.new()
		ambient_player.stream = ambient_stream
		ambient_player.volume_db = -16.0
		add_child(ambient_player)
		ambient_player.play()
		ambient_player.finished.connect(func(): ambient_player.play())

	# Multi-Biome BGM Players with seamless cross-fading
	asian_bgm_stream = _load_audio("res://assets/sounds/bgm/asian_fantasy_peace.mp3")
	var bgm_map = {
		"asian": asian_bgm_stream,
		"school": school_bgm_stream,
		"blight": blight_bgm_stream,
		"cyber": cyber_bgm_stream
	}
	for b_id in bgm_map:
		var st = bgm_map[b_id]
		if st:
			var p = AudioStreamPlayer.new()
			p.name = "BGM_" + b_id
			p.stream = st
			p.volume_db = -10.0 if b_id == "asian" else -80.0
			add_child(p)
			var capture_p = p
			p.finished.connect(func(): if is_instance_valid(capture_p) and capture_p.is_playing(): capture_p.play())
			bgm_players[b_id] = p
			# Only start playing the initial spawn biome (asian) to conserve audio mixer CPU
			if b_id == "asian":
				p.play()
	asian_bgm_player = bgm_players.get("asian", null)

	# Water interaction audio streams
	water_splash_enter_stream = _load_audio("res://assets/sounds/player/water_splash_enter.wav")
	water_swim_stroke_stream = _load_audio("res://assets/sounds/player/water_swim_stroke.wav")
	water_splash_jump_stream = _load_audio("res://assets/sounds/player/water_splash_jump.wav")

	voice_player = AudioStreamPlayer.new()
	voice_player.volume_db = 0.0
	add_child(voice_player)
	voice_player.finished.connect(func(): hero_voice_finished.emit())

	# Pre-allocate round-robin audio player pools to prevent dynamic GC pauses & memory leaks
	for i in range(POOL_SIZE_2D):
		var p = AudioStreamPlayer.new()
		p.name = "PooledPlayer2D_" + str(i)
		add_child(p)
		_pool_2d.append(p)

	for i in range(POOL_SIZE_3D):
		var p3d = AudioStreamPlayer3D.new()
		p3d.name = "PooledPlayer3D_" + str(i)
		p3d.max_distance = 35.0
		p3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p3d)
		_pool_3d.append(p3d)

func is_voice_playing() -> bool:
	return voice_player != null and voice_player.is_playing()

func get_voice_time_remaining() -> float:
	if not is_voice_playing():
		return 0.0
	if voice_player.stream:
		var total_len = voice_player.stream.get_length()
		var curr_pos = voice_player.get_playback_position()
		return max(0.05, total_len - curr_pos)
	return 0.4

func _add_audio(arr: Array, path: String) -> void:
	var s = _load_audio(path)
	if s: arr.append(s)

func _load_audio(path: String) -> AudioStream:
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			stream = res
	if not stream:
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var bytes = file.get_buffer(file.get_length())
			if path.ends_with(".mp3"):
				var mp3 = AudioStreamMP3.new()
				mp3.data = bytes
				mp3.loop = false
				stream = mp3
			elif path.ends_with(".wav"):
				var wav = AudioStreamWAV.new()
				wav.format = AudioStreamWAV.FORMAT_16_BITS
				wav.mix_rate = 44100
				wav.stereo = false
				if bytes.size() > 44:
					wav.data = bytes.slice(44)
				stream = wav
			elif path.ends_with(".ogg"):
				stream = AudioStreamOggVorbis.load_from_buffer(bytes)
	if stream:
		stream.set_meta("origin_path", path)
	return stream

func play_slash(node: Node) -> void:
	_play_clip(node, slash_stream, -6.0)

func play_sword_combo(node: Node, combo_index: int) -> void:
	if slash_combo_streams.size() > 0:
		var clip = slash_combo_streams[combo_index % slash_combo_streams.size()]
		_play_clip(node, clip, -5.0)
	else:
		_play_clip(node, slash_stream, -6.0)

func play_sword_heavy(node: Node) -> void:
	_play_clip(node, slash_heavy_stream, -2.0)

func play_sword_charged(node: Node) -> void:
	_play_clip(node, slash_charged_stream, 1.0, randf_range(0.98, 1.02))

func play_charge_hum(node: Node) -> void:
	_play_clip(node, charge_hum_stream, -3.5)

func play_hit(node: Node) -> void:
	_play_clip(node, hit_stream, -4.0)

func play_juicy_hit(node: Node) -> void:
	_play_clip(node, juicy_hit_stream, -2.5)

func play_ui_hover(node: Node = null) -> void:
	_play_clip(node if node else self, ui_hover_stream, -16.0)

func play_ui_click(node: Node = null) -> void:
	_play_clip(node if node else self, ui_click_stream, -10.0)

func play_ui_equip(node: Node = null) -> void:
	_play_clip(node if node else self, ui_equip_stream, -8.0)

func play_chest_open(node: Node) -> void:
	_play_clip(node, chest_open_stream, 0.0)
	if randf() < 0.65:
		play_voice_chest(node)

func play_voice_chest(_node: Node = null) -> void:
	_play_voice_stream(chest_voices, true)

func play_chest_vanish(node: Node) -> void:
	_play_clip(node, chest_vanish_stream, -3.0)

func play_jump(node: Node) -> void:
	var clip = jump_stream
	if jump_streams.size() > 0:
		clip = jump_streams[randi() % jump_streams.size()]
	_play_clip(node, clip, -14.0, randf_range(0.95, 1.05))

func play_dash(node: Node) -> void:
	_play_clip(node, dash_stream, -6.0)

func play_flame_burst(node: Node) -> void:
	_play_clip(node, flame_burst_stream, -1.5)

func play_level_up_fanfare(node: Node) -> void:
	_play_clip(node, level_up_stream, -4.0)

func play_glider_open(node: Node) -> void:
	_play_clip(node, glider_open_stream, -10.0)

func play_voice_glider(_node: Node = null) -> void:
	_play_voice_stream(glider_voices, true)

func play_voice_pyro_skill(_node: Node = null) -> void:
	_play_voice_stream(pyro_skill_voices, true)

func play_voice_pyro_idle(_node: Node = null) -> void:
	_play_voice_stream(pyro_idle_voices, true)

func play_voice_idle(_node: Node = null) -> void:
	_play_voice_stream(idle_voices)

func play_voice_attack(_node: Node = null) -> void:
	_play_voice_stream(attack_voices, true)

func play_voice_finisher(_node: Node = null) -> void:
	_play_voice_stream(finisher_voices, true)

func play_voice_climb(_node: Node = null) -> void:
	_play_voice_stream(climb_voices)

func play_voice_hurt(_node: Node = null) -> void:
	_play_voice_stream(hurt_voices, true)

func play_voice_jump(_node: Node = null) -> void:
	_play_voice_stream(jump_voices)

func play_voice_land(_node: Node = null) -> void:
	_play_voice_stream(land_voices)

func play_voice_dash(_node: Node = null) -> void:
	_play_voice_stream(dash_voices)

func play_voice_menu_open(_node: Node = null) -> void:
	_play_voice_stream(menu_open_voices, true)

func play_voice_menu_close(_node: Node = null) -> void:
	_play_voice_stream(menu_close_voices, true)

func play_voice_lvlup(_node: Node = null) -> void:
	_play_voice_stream(lvlup_voices, true)

func play_voice_menu_idle(_node: Node = null) -> void:
	_play_voice_stream(menu_idle_voices, true)

func _play_voice_stream(pool: Array, interrupt: bool = false) -> void:
	if pool.is_empty():
		return
	if voice_player.is_playing() and not interrupt:
		return
	var valid_candidates: Array[AudioStream] = []
	for s in pool:
		if s is AudioStream:
			var p = s.get_meta("origin_path", "") as String
			if voice_mode == VoiceMode.JAPANESE_ONLY:
				if p.ends_with(".ogg") or "ht_" in p:
					valid_candidates.append(s)
			elif voice_mode == VoiceMode.RUSSIAN_ONLY:
				if p.ends_with(".mp3") or "ru_" in p:
					valid_candidates.append(s)
			else:
				valid_candidates.append(s)
	if valid_candidates.is_empty():
		valid_candidates = pool
	var stream = valid_candidates[randi() % valid_candidates.size()]
	voice_player.stream = stream
	voice_player.play()
	hero_voice_started.emit(stream)

func play_voice_character_switch(char_id: String) -> void:
	if char_id == "ellen":
		if ellen_switch_stream:
			_play_direct_voice(ellen_switch_stream)
	else:
		if ht_switch_stream:
			_play_direct_voice(ht_switch_stream)

func play_voice_ellen_greet() -> void:
	if ellen_vn_greet_stream:
		_play_direct_voice(ellen_vn_greet_stream)

func play_voice_ellen_accept() -> void:
	if ellen_vn_accept_stream:
		_play_direct_voice(ellen_vn_accept_stream)

func play_voice_ellen_attack() -> void:
	_play_voice_stream(ellen_attack_voices, true)

func play_voice_ellen_idle() -> void:
	_play_voice_stream(ellen_idle_voices, false)

func _play_direct_voice(stream: AudioStream) -> void:
	if not stream or not voice_player:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()
	hero_voice_started.emit(stream)

func set_voice_mode(mode: VoiceMode) -> void:
	voice_mode = mode

func cycle_voice_mode() -> String:
	match voice_mode:
		VoiceMode.JAPANESE_ONLY:
			voice_mode = VoiceMode.HYBRID
		VoiceMode.HYBRID:
			voice_mode = VoiceMode.RUSSIAN_ONLY
		VoiceMode.RUSSIAN_ONLY:
			voice_mode = VoiceMode.JAPANESE_ONLY
	return get_voice_mode_name()

func get_voice_mode_name() -> String:
	match voice_mode:
		VoiceMode.JAPANESE_ONLY:
			return "Японский оригинал (Риэ Такахаси)"
		VoiceMode.RUSSIAN_ONLY:
			return "Русский аниме (Ху Тао)"
		VoiceMode.HYBRID:
			return "Гибридный (Оригинал + Русские реплики)"
	return "Гибридный"

func _play_voice_single(stream: AudioStream, interrupt: bool = false) -> void:
	if not stream:
		return
	if voice_player.is_playing() and not interrupt:
		return
	voice_player.stream = stream
	voice_player.play()
	hero_voice_started.emit(stream)

# FOOTSTEPS (Organic, soft)
func play_step_walk(node: Node) -> void:
	if walk_steps.size() > 0:
		var stream = walk_steps[randi() % walk_steps.size()]
		_play_clip(node, stream, -14.0, 0.95 + randf() * 0.1)

func play_step_run(node: Node) -> void:
	if run_steps.size() > 0:
		var stream = run_steps[randi() % run_steps.size()]
		_play_clip(node, stream, -12.0, 0.98 + randf() * 0.08)

func play_chime_rarity(node: Node, rarity: int) -> void:
	var pitches = [1.0, 1.25, 1.5, 2.0]
	var p = pitches[clamp(rarity, 0, pitches.size() - 1)]
	_play_clip(node, level_up_stream if level_up_stream else jump_stream, -6.0, p)

func _play_clip(_node: Node, stream: AudioStream, vol: float = 0.0, pitch: float = 1.0) -> void:
	if not stream or _pool_2d.is_empty():
		return
	var player = _pool_2d[_pool_idx_2d]
	_pool_idx_2d = (_pool_idx_2d + 1) % POOL_SIZE_2D
	player.stream = stream
	player.volume_db = vol
	player.pitch_scale = pitch
	player.play()

# ==================== MONSTER AUDIO (3D Positional) ====================

func play_slime_hop(node: Node3D) -> void:
	_play_clip_3d(node, slime_hop_stream, -6.0, 0.95 + randf() * 0.1)

func play_slime_alert(node: Node3D) -> void:
	_play_clip_3d(node, slime_alert_stream, -1.0, 0.98 + randf() * 0.05)

func play_slime_charge(node: Node3D) -> void:
	_play_clip_3d(node, slime_charge_stream, -1.0, 1.0)

func play_slime_attack(node: Node3D) -> void:
	_play_clip_3d(node, slime_attack_stream, 1.0, 0.95 + randf() * 0.1)

func play_slime_hurt(node: Node3D) -> void:
	if slime_hurt_streams.size() > 0:
		var s = slime_hurt_streams[randi() % slime_hurt_streams.size()]
		_play_clip_3d(node, s, 0.0, 0.95 + randf() * 0.1)

func play_slime_die(node: Node3D) -> void:
	_play_clip_3d(node, slime_die_stream, 3.0, 1.0, true)

func play_slime_splat(node: Node3D) -> void:
	if slime_splat_streams.size() > 0:
		var s = slime_splat_streams[randi() % slime_splat_streams.size()]
		_play_clip_3d(node, s, -1.0, 0.95 + randf() * 0.15, true)

func play_goblin_alert(node: Node3D) -> void:
	_play_clip_3d(node, goblin_alert_stream, 2.0, 1.0)

func play_goblin_charge(node: Node3D) -> void:
	_play_clip_3d(node, goblin_charge_stream, 2.0, 1.0)

func play_goblin_attack(node: Node3D) -> void:
	_play_clip_3d(node, hit_stream, 1.0, 1.25)

func play_goblin_hurt(node: Node3D) -> void:
	_play_clip_3d(node, goblin_hurt_stream, 2.0, 1.0)

func play_goblin_die(node: Node3D) -> void:
	_play_clip_3d(node, goblin_die_stream, 2.0, 1.0, true)

func play_skeleton_alert(node: Node3D) -> void:
	_play_clip_3d(node, skel_alert_stream, 0.0, 0.95 + randf() * 0.1)

func play_skeleton_die(node: Node3D) -> void:
	_play_clip_3d(node, skel_die_stream, 1.0, 1.0, true)

func _play_clip_3d(node: Node3D, stream: AudioStream, vol: float = 0.0, pitch: float = 1.0, _is_global: bool = false) -> void:
	if not stream or _pool_3d.is_empty():
		return
	var player3d = _pool_3d[_pool_idx_3d]
	_pool_idx_3d = (_pool_idx_3d + 1) % POOL_SIZE_3D
	player3d.stream = stream
	player3d.volume_db = vol
	player3d.pitch_scale = pitch
	if is_instance_valid(node) and node.is_inside_tree():
		player3d.global_position = node.global_position
	player3d.play()

func play_water_splash_enter(node: Node3D) -> void:
	_play_clip_3d(node, water_splash_enter_stream, -9.0, randf_range(0.92, 1.08))

func play_water_swim_stroke(node: Node3D) -> void:
	_play_clip_3d(node, water_swim_stroke_stream, -15.0, randf_range(0.90, 1.10))

func play_water_splash_jump(node: Node3D) -> void:
	_play_clip_3d(node, water_splash_jump_stream, -10.0, randf_range(0.95, 1.05))

func play_voice_water_splash(_node: Node3D = null) -> void:
	# Hu Tao cute surprise exclamation when hitting water ("Оп!", "Ух!")
	_play_voice_stream(jump_voices, true)

# ==================== DESTRUCTIBLE ENVIRONMENT AUDIO ====================

func play_wood_chop(node: Node3D) -> void:
	_play_clip_3d(node, wood_chop_stream, 2.0, randf_range(0.92, 1.08), true)

func play_tree_fall(node: Node3D) -> void:
	_play_clip_3d(node, tree_fall_stream, 4.0, randf_range(0.95, 1.05), true)

func play_building_collapse(node: Node3D) -> void:
	_play_clip_3d(node, building_collapse_stream, 5.0, randf_range(0.94, 1.06), true)

func play_stone_crumble(node: Node3D) -> void:
	_play_clip_3d(node, stone_crumble_stream, 3.0, randf_range(0.93, 1.07), true)

# ==================== MATERIAL IMPACT & HIT SOUNDS ====================

func play_material_hit(node: Node, mat_type: String) -> void:
	var stream = hit_flesh_stream
	var vol = -3.5
	match mat_type:
		"metal":
			stream = hit_metal_stream
			vol = -4.0
		"wood":
			stream = hit_wood_stream
			vol = -3.0
		"stone":
			stream = hit_stone_stream
			vol = -2.5
		"building":
			stream = hit_building_stream
			vol = -2.5
		"cyber":
			stream = hit_cyber_stream
			vol = -3.5
		"bone":
			stream = hit_bone_stream
			vol = -3.5
		"slime":
			stream = hit_slime_stream
			vol = -3.0
		_:
			stream = hit_flesh_stream
			vol = -3.5

	if stream:
		_play_clip(node if node else self, stream, vol, randf_range(0.95, 1.05))

# ==================== HEROINE (PLAYER) DIALOGUE VOCALS ====================

func play_heroine_dialogue_start() -> void:
	if heroine_dialogue_start_stream:
		_play_direct_voice(heroine_dialogue_start_stream)

func play_heroine_choice_recruit() -> void:
	if heroine_choice_recruit_stream:
		_play_direct_voice(heroine_choice_recruit_stream)

func play_heroine_choice_battle() -> void:
	if heroine_choice_battle_stream:
		_play_direct_voice(heroine_choice_battle_stream)

# ==================== BIOME BGM CROSS-FADING ====================

func set_music_volume_scale(scale_val: float) -> void:
	music_volume_scale = clampf(scale_val, 0.0, 1.0)
	for b_id in bgm_players:
		var p = bgm_players[b_id]
		if is_instance_valid(p):
			if b_id == current_biome_id:
				var base_vol = 0.32 if b_id == "asian" else 0.28
				p.volume_db = -80.0 if music_volume_scale <= 0.01 else linear_to_db(music_volume_scale * base_vol)
			else:
				p.volume_db = -80.0

func set_sfx_volume_scale(scale_val: float) -> void:
	sfx_volume_scale = clampf(scale_val, 0.0, 1.0)

func update_biome_bgm(new_biome: String) -> void:
	if new_biome == current_biome_id or not bgm_players.has(new_biome):
		return
	var old_p = bgm_players.get(current_biome_id)
	var new_p = bgm_players.get(new_biome)
	current_biome_id = new_biome

	if old_p and is_instance_valid(old_p):
		var tw_out = create_tween()
		tw_out.tween_property(old_p, "volume_db", -80.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Stop old player after fadeout to free up Web Audio decoding & software mixer channels
		tw_out.finished.connect(func():
			if is_instance_valid(old_p) and current_biome_id != old_p.name.trim_prefix("BGM_"):
				old_p.stop()
		)
	if new_p and is_instance_valid(new_p):
		if not new_p.is_playing():
			new_p.volume_db = -80.0
			new_p.play()
		var base_vol = 0.32 if new_biome == "asian" else 0.28
		var target_vol = -80.0 if music_volume_scale <= 0.01 else linear_to_db(music_volume_scale * base_vol)
		var tw_in = create_tween()
		tw_in.tween_property(new_p, "volume_db", target_vol, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


