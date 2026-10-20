extends Node3D

@onready var character_rotator: Node3D = $CharacterRotator
@onready var particles: CPUParticles3D = $ElementalParticles
@onready var camera_node: Camera3D = $Camera3D

var anim_player: AnimationPlayer = null
var rotation_speed: float = 0.35
var is_dragging: bool = false

var idle_action_timer: float = 4.0
var is_performing_special: bool = false
var special_animations: Array[String] = ["Cheer", "Spellcast_Raise", "Use_Item", "Interact"]

var base_y: float = 0.0

# Genshin Zoom Parameters
var target_zoom: float = 2.35
var min_zoom: float = 1.10 # Close-up view of face, eyes, and hair
var max_zoom: float = 3.30 # Full length view with pedestal

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_y = character_rotator.position.y
	_setup_character_animation()

func _setup_character_animation() -> void:
	var players = character_rotator.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		anim_player = players[0]
		if anim_player.has_animation("Idle"):
			var anim = anim_player.get_animation("Idle")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play("Idle")
		anim_player.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	# Gentle breathing / floating bob
	var t = Time.get_ticks_msec() * 0.002
	character_rotator.position.y = base_y + sin(t) * 0.012

	# Smooth camera zoom and dynamic vertical framing
	if camera_node:
		camera_node.position.z = lerp(camera_node.position.z, target_zoom, delta * 10.0)
		var t_zoom = inverse_lerp(min_zoom, max_zoom, camera_node.position.z)
		var target_y = lerp(1.14, 0.88, t_zoom)
		camera_node.position.y = lerp(camera_node.position.y, target_y, delta * 10.0)

	# Periodic cute voice line in character sheet
	idle_action_timer -= delta
	if idle_action_timer <= 0.0:
		perform_special_idle_action()

func handle_zoom(direction: float) -> void:
	target_zoom = clamp(target_zoom + direction * 0.25, min_zoom, max_zoom)

func handle_drag(relative_x: float) -> void:
	character_rotator.rotation.y += relative_x * 0.01

func perform_special_idle_action() -> void:
	idle_action_timer = randf_range(7.0, 12.0)

	# If animated model has cheer or dance, play it
	if anim_player:
		var anim_name = special_animations[randi() % special_animations.size()]
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name, 0.25)

	# Play cute vocal reaction in the character window
	var synth = get_tree().root.get_node_or_null("SoundSynth")
	if synth:
		if randf() < 0.4:
			synth.play_voice_pyro_idle(self)
		else:
			synth.play_voice_menu_idle(self)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != "Idle":
		if anim_player and anim_player.has_animation("Idle"):
			anim_player.play("Idle", 0.35)
		is_performing_special = false

func reset_preview() -> void:
	is_performing_special = false
	idle_action_timer = randf_range(3.5, 6.0)
	target_zoom = 2.35
	if character_rotator:
		character_rotator.rotation.y = 0.0
	if camera_node:
		camera_node.position.z = 2.35
		camera_node.position.y = 0.9
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle", 0.2)
