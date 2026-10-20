extends Area3D
class_name ExpOrb

@export var exp_value: int = 10

var player: Node3D = null
var velocity: Vector3 = Vector3.ZERO
var is_homing: bool = false
var life_time: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var particles: CPUParticles3D = $CPUParticles3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Initial burst upwards and outwards
	velocity = Vector3(
		randf_range(-2.0, 2.0),
		randf_range(2.5, 4.5),
		randf_range(-2.0, 2.0)
	)

func _physics_process(delta: float) -> void:
	life_time += delta

	if not is_homing:
		# Arc trajectory before homing
		velocity.y -= 9.8 * delta
		global_position += velocity * delta
		if life_time > 0.35:
			is_homing = true
			player = get_tree().get_first_node_in_group("player")
	else:
		if is_instance_valid(player):
			var target_pos = player.global_position + Vector3(0, 0.8, 0)
			var dir = (target_pos - global_position).normalized()
			var dist = global_position.distance_to(target_pos)
			var target_speed = clamp(dist * 6.0 + 8.0, 10.0, 24.0)
			velocity = velocity.lerp(dir * target_speed, 12.0 * delta)
			global_position += velocity * delta

			# Collect on proximity
			if dist < 0.8:
				collect()
		else:
			global_position += velocity * delta

	# Orb gentle spin
	rotate_y(5.0 * delta)

func collect() -> void:
	if is_instance_valid(player) and player.has_method("add_exp"):
		player.add_exp(exp_value)
		SoundSynth.play_chime_rarity(player, 1)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if is_homing and body.is_in_group("player"):
		collect()
