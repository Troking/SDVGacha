extends Area3D
class_name CryoVortex

## Ellen Joe's Signature Elemental Skill: Frost Shredder (Крио Шквал)
## Swirls sharp crystal snowflakes, glacial frost spikes, a runic ice seal,
## sub-zero blizzard mist, culminating in a shattering glacial glacier eruption.

@export var damage_per_tick: int = 22
@export var final_burst_damage: int = 65
@export var pull_radius: float = 9.0
@export var vortex_duration: float = 1.7
@export var explosion_fade_time: float = 0.75

var tick_timer: float = 0.0
var total_time: float = 0.0
var has_burst: bool = false
var cached_enemies: Array[Node] = []
var enemy_cache_timer: float = 0.0

@onready var ground_seal: MeshInstance3D = get_node_or_null("GroundSeal")
@onready var shockwave_ring: MeshInstance3D = get_node_or_null("ShockwaveRing")
@onready var snowflakes: CPUParticles3D = get_node_or_null("Snowflakes")
@onready var frost_mist: CPUParticles3D = get_node_or_null("FrostMist")
@onready var ice_spikes: CPUParticles3D = get_node_or_null("IceSpikes")
@onready var burst_particles: CPUParticles3D = get_node_or_null("BurstParticles")
@onready var light: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready() -> void:
	# Initial expanding ground seal animation
	if ground_seal:
		ground_seal.scale = Vector3(0.1, 0.1, 0.1)
		var st = create_tween()
		st.tween_property(ground_seal, "scale", Vector3(1.0, 1.0, 1.0), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Expanding glacial shockwave ripple along the ground
	if shockwave_ring:
		shockwave_ring.scale = Vector3(0.2, 0.2, 0.2)
		var ring_mat = shockwave_ring.get_active_material(0)
		var rt = create_tween().set_parallel(true)
		rt.tween_property(shockwave_ring, "scale", Vector3(3.6, 3.6, 3.6), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if ring_mat:
			rt.tween_property(ring_mat, "albedo_color:a", 0.0, 0.42)

func _physics_process(delta: float) -> void:
	total_time += delta
	tick_timer += delta
	enemy_cache_timer += delta

	# Fast crystalline rotation of ground seal
	if ground_seal:
		ground_seal.rotate_y(-delta * 3.4)

	# Pulsing cyan glacial light
	if light and not has_burst:
		light.light_energy = 3.4 + sin(total_time * 24.0) * 1.0

	# Periodic enemy refresh
	if enemy_cache_timer >= 0.12 or cached_enemies.is_empty():
		enemy_cache_timer = 0.0
		cached_enemies = get_tree().get_nodes_in_group("enemies")

	# Vacuum pull towards center with frost swirl
	if not has_burst:
		for e in cached_enemies:
			if is_instance_valid(e) and e.is_inside_tree():
				var dist = global_position.distance_to(e.global_position)
				if dist < pull_radius:
					var pull_dir = (global_position - e.global_position).normalized()
					pull_dir.y = 0.25
					var pull_strength = (1.0 - (dist / pull_radius)) * 15.0
					e.global_position += pull_dir * pull_strength * delta

		# Periodic Cryo tick damage
		if tick_timer >= 0.25:
			tick_timer = 0.0
			_deal_tick_damage(damage_per_tick)

	# Final detonation: Glacial Ice Eruption
	if total_time >= vortex_duration and not has_burst:
		has_burst = true
		_trigger_final_eruption()

	# Cleanup
	if total_time >= vortex_duration + explosion_fade_time:
		queue_free()

func _find_destructible(node: Node) -> DestructibleProp:
	if not node:
		return null
	if node.has_meta("destructible_parent"):
		var p = node.get_meta("destructible_parent")
		if p is DestructibleProp and is_instance_valid(p):
			return p
	var curr = node
	var depth = 0
	while curr and depth < 10:
		depth += 1
		if curr is DestructibleProp:
			return curr
		if curr.has_meta("destructible_parent"):
			var p = curr.get_meta("destructible_parent")
			if p is DestructibleProp and is_instance_valid(p):
				return p
		curr = curr.get_parent()
	return null

func _deal_tick_damage(dmg: int) -> void:
	for e in cached_enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist <= pull_radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg, false, false, true)

	# Damage destructible props in radius
	var hit_destructibles: Array[DestructibleProp] = []
	for body in get_tree().get_nodes_in_group("destructible_body"):
		if is_instance_valid(body) and body is Node3D:
			if global_position.distance_to(body.global_position) <= pull_radius:
				var dp = _find_destructible(body)
				if dp and is_instance_valid(dp) and not hit_destructibles.has(dp):
					hit_destructibles.append(dp)

	for dp in hit_destructibles:
		if is_instance_valid(dp) and dp.has_method("take_damage"):
			dp.take_damage(dmg, false, false, global_position)

func _trigger_final_eruption() -> void:
	SoundSynth.play_ice_shatter(self)

	# Stop tick particles
	if snowflakes: snowflakes.emitting = false
	if frost_mist: frost_mist.emitting = false
	if ice_spikes: ice_spikes.emitting = false

	# Fire massive glacial burst explosion
	if burst_particles:
		burst_particles.restart()
		burst_particles.emitting = true

	# Fade ground seal
	if ground_seal:
		var st = create_tween().set_parallel(true)
		st.tween_property(ground_seal, "scale", Vector3(1.6, 1.6, 1.6), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var mat = ground_seal.get_active_material(0)
		if mat:
			st.tween_property(mat, "albedo_color:a", 0.0, 0.35)

	# Deal final massive burst damage + radial knockback
	var burst_radius = pull_radius + 2.0
	for e in cached_enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist <= burst_radius:
				if e.has_method("take_damage"):
					var is_crit = randf() < 0.35
					var final_dmg = int(final_burst_damage * 1.5) if is_crit else final_burst_damage
					e.take_damage(final_dmg, false, is_crit, true)

				# Explosive radial launch away from glacier
				var blast_dir = (e.global_position - global_position).normalized()
				blast_dir.y = 0.65
				var blast_force = clamp(1.0 - (dist / burst_radius), 0.3, 1.0) * 16.0
				if "velocity" in e:
					e.velocity += blast_dir * blast_force

	# Shatter any remaining destructibles in burst
	var burst_destructibles: Array[DestructibleProp] = []
	for body in get_tree().get_nodes_in_group("destructible_body"):
		if is_instance_valid(body) and body is Node3D:
			if global_position.distance_to(body.global_position) <= burst_radius:
				var dp = _find_destructible(body)
				if dp and is_instance_valid(dp) and not burst_destructibles.has(dp):
					burst_destructibles.append(dp)

	for dp in burst_destructibles:
		if is_instance_valid(dp) and dp.has_method("take_damage"):
			dp.take_damage(final_burst_damage * 2, false, true, global_position)

	# Fade light
	if light:
		var lt = create_tween()
		lt.tween_property(light, "light_energy", 0.0, explosion_fade_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
