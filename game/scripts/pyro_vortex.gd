extends Area3D
class_name PyroVortex

## Hu Tao's Paramita Papilio / Butterfly Flame Vortex Skill
## Swirls glowing anime flame butterflies, a rotating runic magic seal,
## soft flame wisps, and golden embers, culminating in a floral flame detonation.

@export var damage_per_tick: int = 16
@export var final_burst_damage: int = 48
@export var pull_radius: float = 8.5
@export var vortex_duration: float = 1.6 # Active swirling and pulling duration
@export var explosion_fade_time: float = 0.70 # Graceful explosion fade out duration

var tick_timer: float = 0.0
var total_time: float = 0.0
var has_burst: bool = false
var cached_enemies: Array[Node] = []
var enemy_cache_timer: float = 0.0

@onready var ground_seal: MeshInstance3D = get_node_or_null("GroundSeal")
@onready var shockwave_ring: MeshInstance3D = get_node_or_null("ShockwaveRing")
@onready var butterflies: CPUParticles3D = get_node_or_null("PyroButterflies")
@onready var flame_wisps: CPUParticles3D = get_node_or_null("FlameWisps")
@onready var embers: CPUParticles3D = get_node_or_null("GoldenEmbers")
@onready var burst_particles: CPUParticles3D = get_node_or_null("BurstParticles")
@onready var light: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready() -> void:
	# Note: player.perform_elemental_skill() triggers the organic initial burst SFX
	# Initial expanding ground seal animation
	if ground_seal:
		ground_seal.scale = Vector3(0.1, 0.1, 0.1)
		var st = create_tween()
		st.tween_property(ground_seal, "scale", Vector3(1.0, 1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Expanding fiery shockwave ripple along the ground
	if shockwave_ring:
		shockwave_ring.scale = Vector3(0.2, 0.2, 0.2)
		var ring_mat = shockwave_ring.get_active_material(0)
		var rt = create_tween().set_parallel(true)
		rt.tween_property(shockwave_ring, "scale", Vector3(3.2, 3.2, 3.2), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if ring_mat:
			rt.tween_property(ring_mat, "albedo_color:a", 0.0, 0.45)

func _physics_process(delta: float) -> void:
	total_time += delta
	tick_timer += delta
	enemy_cache_timer += delta

	# Rotate ground magic seal with accelerating mystic energy
	if ground_seal:
		ground_seal.rotate_y(delta * 2.8)

	# Warm pulsing light during active vortex
	if light and not has_burst:
		light.light_energy = 3.2 + sin(total_time * 20.0) * 0.9

	# Periodic enemy refresh
	if enemy_cache_timer >= 0.12 or cached_enemies.is_empty():
		enemy_cache_timer = 0.0
		cached_enemies = get_tree().get_nodes_in_group("enemies")

	# Vacuum pull towards center with gentle swirl (only while active vortex)
	if not has_burst:
		for e in cached_enemies:
			if is_instance_valid(e) and e.is_inside_tree():
				var dist = global_position.distance_to(e.global_position)
				if dist < pull_radius:
					var pull_dir = (global_position - e.global_position).normalized()
					pull_dir.y = 0.28
					var pull_strength = (1.0 - (dist / pull_radius)) * 14.0
					e.global_position += pull_dir * pull_strength * delta

		# Periodic burning tick damage
		if tick_timer >= 0.26:
			tick_timer = 0.0
			_deal_tick_damage(damage_per_tick)

	# Final detonation: Floral butterfly explosion
	if total_time >= vortex_duration and not has_burst:
		has_burst = true
		_trigger_final_eruption()

	# Graceful completion after full burst particles and light have faded
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
	var bodies = get_overlapping_bodies()
	var hit_destructibles: Array[DestructibleProp] = []
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(dmg, true, false)
			# Small flame pop visual on hit
			if randf() < 0.5:
				_spawn_hit_spark(b.global_position)
		else:
			var d_prop = _find_destructible(b)
			if d_prop and not d_prop.is_destroyed and not d_prop in hit_destructibles:
				hit_destructibles.append(d_prop)
				d_prop.take_damage(dmg, true, false, global_position)
				if randf() < 0.5:
					_spawn_hit_spark(d_prop.global_position + Vector3(0, 0.8, 0))

func _trigger_final_eruption() -> void:
	# Stop continuous background particle emitters
	if butterflies:
		butterflies.emitting = false
	if flame_wisps:
		flame_wisps.emitting = false
	if embers:
		embers.emitting = false

	# Unleash one-shot floral burst particles
	if burst_particles:
		burst_particles.restart()
		burst_particles.emitting = true

	# Smoothly fade ground seal out
	if ground_seal:
		var s_mat = ground_seal.get_active_material(0)
		var fade_t = create_tween().set_parallel(true)
		fade_t.tween_property(ground_seal, "scale", Vector3(1.35, 1.35, 1.35), 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if s_mat:
			fade_t.tween_property(s_mat, "albedo_color:a", 0.0, 0.50)

	# Bright flash that gently decays
	if light:
		light.light_energy = 8.5
		var lt = create_tween()
		lt.tween_property(light, "light_energy", 0.0, 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	SoundSynth.play_flame_burst(self)

	var bodies = get_overlapping_bodies()
	var hit_destructibles: Array[DestructibleProp] = []
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(final_burst_damage, true, true)
			var knock_dir = (b.global_position - global_position).normalized()
			knock_dir.y = 0.45
			b.global_position += knock_dir * 4.0
		else:
			var d_prop = _find_destructible(b)
			if d_prop and not d_prop.is_destroyed and not d_prop in hit_destructibles:
				hit_destructibles.append(d_prop)
				d_prop.take_damage(final_burst_damage, true, true, global_position)

func _spawn_hit_spark(pos: Vector3) -> void:
	var sp = CPUParticles3D.new()
	sp.position = pos + Vector3(0, 0.6, 0)
	sp.amount = 10
	sp.lifetime = 0.25
	sp.one_shot = true
	sp.explosiveness = 0.9
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.8, 0.2, 0.95)
	var sm = SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	sm.material = mat
	sp.mesh = sm
	sp.direction = Vector3(0, 1, 0)
	sp.spread = 180.0
	sp.initial_velocity_min = 2.0
	sp.initial_velocity_max = 5.0
	get_parent().add_child(sp)
	sp.emitting = true
	get_tree().create_timer(0.3).timeout.connect(func(): if is_instance_valid(sp): sp.queue_free())
