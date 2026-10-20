extends CanvasLayer

signal started()

var is_starting: bool = false
var prompt_tween: Tween = null
var bg_tween: Tween = null

@onready var root_control: Control = $RootControl
@onready var bg_texture: TextureRect = $RootControl/Background
@onready var prompt_label: Label = $RootControl/CenterContainer/VBoxContainer/PromptLabel
@onready var title_label: Label = $RootControl/CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $RootControl/CenterContainer/VBoxContainer/SubtitleLabel
@onready var embers: CPUParticles2D = $RootControl/Embers

func _ready() -> void:
	# Ensure splash screen processes input and animations while the game world is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	root_control.modulate.a = 0.0

	# Keep mouse cursor visible and responsive for title screen interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if prompt_label:
		prompt_label.text = "[ ENTER / ПРОБЕЛ / ТАП ПО ЭКРАНУ ] — Войти в мир"

	# Gentle cinematic fade-in (immune to pause)
	var in_tween = create_tween()
	in_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	in_tween.tween_property(root_control, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_start_bg_breathing()
	_start_prompt_pulse()

	# Accessibility voice announcement
	AccessibilityManager.speak("SDV Gacha. Нажмите для начала игры.", true, false)

func _start_bg_breathing() -> void:
	if not bg_texture:
		return
	bg_texture.pivot_offset = Vector2(960, 540)
	bg_tween = create_tween().set_loops()
	bg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bg_tween.tween_property(bg_texture, "scale", Vector2(1.04, 1.04), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bg_tween.tween_property(bg_texture, "scale", Vector2(1.0, 1.0), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_prompt_pulse() -> void:
	if not prompt_label:
		return
	prompt_tween = create_tween().set_loops()
	prompt_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	prompt_tween.tween_property(prompt_label, "modulate:a", 0.35, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if is_starting:
		return

	var is_trigger = false
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		# Supports Enter, Space, Escape, or any key
		is_trigger = true
	elif event is InputEventMouseButton and event.is_pressed():
		is_trigger = true
	elif event is InputEventJoypadButton and event.is_pressed():
		# Gamepad A / Cross / Start buttons
		is_trigger = true
	elif event is InputEventScreenTouch and event.is_pressed():
		# Mobile touch alternative
		is_trigger = true

	if is_trigger:
		start_game()

func start_game() -> void:
	if is_starting:
		return
	is_starting = true

	if prompt_tween: prompt_tween.kill()
	if bg_tween: bg_tween.kill()

	# Audio feedback: triumphant fanfare and cheerful heroine voice shout
	SoundSynth.play_level_up_fanfare(self)
	SoundSynth.play_voice_menu_close(self)

	# Highlight prompt on press
	if prompt_label:
		prompt_label.modulate = Color(1.0, 0.95, 0.7, 1.0)
		var flash_tween = create_tween()
		flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		flash_tween.tween_property(prompt_label, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		flash_tween.tween_property(prompt_label, "scale", Vector2(1.0, 1.0), 0.18)

	# Unpause the game world & signal main scene
	get_tree().paused = false
	started.emit()

	# Smooth cinematic fade out
	var out_tween = create_tween().set_parallel(true)
	out_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out_tween.tween_property(root_control, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(bg_texture, "scale", Vector2(1.08, 1.08), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await out_tween.finished
	queue_free()
