extends Node

## Accessibility Manager Singleton (Autoload)
## Handles Screen Reading / Text-To-Speech (TTS), High Contrast mode, and Spatial Audio Cues.
## Coordinated with SoundSynth so Heroine voice lines and TTS never talk over each other.

signal high_contrast_toggled(is_high_contrast: bool)
signal ui_visibility_toggled(is_visible: bool)

var tts_enabled: bool = true
var high_contrast: bool = false
var ui_visible: bool = true

var voices: Array = []
var selected_voice_id: String = ""

# Coordination timer so TTS never speaks simultaneously with Heroine's voice
var pending_tts_tween: Tween = null
var current_queued_text: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_tts()
	speak("Озвучка готова")

func _init_tts() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		voices = DisplayServer.tts_get_voices()
		if voices.size() > 0:
			# Try to find Russian voice if available, else pick first
			for v in voices:
				var lang = v.get("language", "").to_lower()
				if "ru" in lang:
					selected_voice_id = v.get("id", "")
					break
			if selected_voice_id == "":
				selected_voice_id = voices[0].get("id", "")
			print("[A11y] TTS initialized. Voices found: ", voices.size(), " Using: ", selected_voice_id)
		else:
			print("[A11y] No TTS voices available on system.")
	else:
		print("[A11y] Text-to-speech not supported on this platform.")

## Speak text with smart voice separation
## If defer_if_hero_speaking is true and Hero voice is actively playing,
## TTS waits until the hero's line finishes before speaking.
func speak(text: String, interrupt: bool = true, defer_if_hero_speaking: bool = true) -> void:
	if not tts_enabled or text.is_empty():
		return

	if defer_if_hero_speaking and SoundSynth.has_method("is_voice_playing") and SoundSynth.is_voice_playing():
		speak_after_voice(text, 0.25)
		return

	_execute_speak(text, interrupt)

## Queues speech to play after the active hero voice line finishes + a natural pause
func speak_after_voice(text: String, pause_delay: float = 0.25) -> void:
	if not tts_enabled or text.is_empty():
		return

	if not SoundSynth.has_method("is_voice_playing") or not SoundSynth.is_voice_playing():
		_execute_speak(text, true)
		return

	if pending_tts_tween:
		pending_tts_tween.kill()

	var wait_time = SoundSynth.get_voice_time_remaining() + pause_delay
	current_queued_text = text
	pending_tts_tween = create_tween()
	pending_tts_tween.tween_interval(wait_time)
	pending_tts_tween.tween_callback(func():
		if SoundSynth.is_voice_playing():
			speak_after_voice(current_queued_text, pause_delay)
		else:
			_execute_speak(current_queued_text, false)
	)

func _execute_speak(text: String, interrupt: bool = true) -> void:
	if not tts_enabled or text.is_empty():
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		if interrupt:
			DisplayServer.tts_stop()
		DisplayServer.tts_speak(text, selected_voice_id, 100, 1.0, 1.0)
	print("[TTS Speech]: ", text)

func toggle_tts() -> void:
	tts_enabled = !tts_enabled
	if tts_enabled:
		speak("Озвучка интерфейса включена")
	else:
		if pending_tts_tween:
			pending_tts_tween.kill()
		if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
			DisplayServer.tts_stop()
		print("[A11y] TTS disabled")

func toggle_high_contrast() -> void:
	high_contrast = !high_contrast
	high_contrast_toggled.emit(high_contrast)
	speak("Высокий контраст " + ("включен" if high_contrast else "выключен"))

func toggle_ui() -> void:
	ui_visible = !ui_visible
	ui_visibility_toggled.emit(ui_visible)
	speak("Интерфейс " + ("показан" if ui_visible else "скрыт"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_tts"):
		toggle_tts()
	elif event.is_action_pressed("toggle_contrast"):
		toggle_high_contrast()
	elif event.is_action_pressed("toggle_ui"):
		toggle_ui()

