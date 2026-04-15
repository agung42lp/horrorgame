extends CharacterBody2D

# ─────────────────────────────────────────────────────────────────────────────
# player.gd — Cold Ground
# Walk = diam / tahan tombol gerak biasa
# Run  = tahan Shift + gerak → lebih cepat, suara lebih keras, noise naik cepat
# ─────────────────────────────────────────────────────────────────────────────

@export_category("Player Properties")
@export var walk_speed: float  = 220.0   # kecepatan jalan normal
@export var run_speed: float   = 420.0   # kecepatan lari (tahan Shift)
@export var jump_force: float  = 650.0
@export var gravity: float     = 1800.0
@export var max_jump_count: int = 2

var jump_count: int = 2
var movement_enabled: bool = true
var noise_level: float = 0.0

# ─── STATE ───────────────────────────────────────────────────────────────────
var is_running: bool = false   # true saat player tahan Shift

# ─── TERRAIN ─────────────────────────────────────────────────────────────────
var on_snow: bool = true  # di-set oleh TerrainZone.gd

# ─── FOOTSTEP TIMER ──────────────────────────────────────────────────────────
var _step_timer: float = 0.0
const WALK_STEP_INTERVAL := 0.45
const RUN_STEP_INTERVAL  := 0.27

# ─── HIDING ──────────────────────────────────────────────────────────────────
var is_hiding: bool = false
var near_hiding_spot: bool = false
var hiding_view: CanvasLayer = null

# ─── STANDING STILL (reset Alert Hansen) ────────────────────────────────────
var _still_timer: float = 0.0
const STILL_THRESHOLD := 4.0

# ─────────────────────────────────────────────────────────────────────────────

@onready var player_sprite   = $AnimatedSprite2D
@onready var spawn_point     = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

func _ready() -> void:
	add_to_group("Player")
	hiding_view = get_tree().get_first_node_in_group("HidingView") as CanvasLayer
	if hiding_view:
		hiding_view.visible = false

func _physics_process(delta: float) -> void:
	movement(delta)

func _process(delta: float) -> void:
	player_animations()
	flip_player()
	_handle_hide_input()
	_update_still_timer(delta)

# ─── MOVEMENT ────────────────────────────────────────────────────────────────
func movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump_count = max_jump_count

	handle_jumping()

	var inputAxis: float = 0.0
	if movement_enabled:
		inputAxis = Input.get_axis("Left", "Right")

	# Run: tahan Shift sambil bergerak
	is_running = Input.is_action_pressed("Run") and abs(inputAxis) > 0
	var current_speed: float = run_speed if is_running else walk_speed

	velocity.x = inputAxis * current_speed
	move_and_slide()

	# ─── Noise system ────────────────────────────────────────────────────────
	if is_hiding:
		noise_level = 0.0
	elif abs(inputAxis) > 0:
		# Lari = noise naik 3x lebih cepat
		var noise_rate: float = 0.04 if is_running else 0.015
		noise_level += noise_rate
	else:
		noise_level -= 0.025
	noise_level = clamp(noise_level, 0.0, 1.0)

	_update_footstep(delta, inputAxis)

func _update_footstep(delta: float, inputAxis: float) -> void:
	if not is_on_floor() or abs(inputAxis) < 0.1 or is_hiding:
		_step_timer = 0.0
		return
	var interval: float = RUN_STEP_INTERVAL if is_running else WALK_STEP_INTERVAL
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = interval
		AudioManager.play_footstep(on_snow, is_running)

func handle_jumping() -> void:
	if Input.is_action_just_pressed("Jump") and movement_enabled:
		if is_on_floor():
			jump()
		elif jump_count > 0:
			jump()
			jump_count -= 1

func jump() -> void:
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force

# ─── ANIMASI ─────────────────────────────────────────────────────────────────
func player_animations() -> void:
	particle_trails.emitting = false
	if is_hiding:
		return
	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			if is_running:
				player_sprite.play("Run")
			else:
				player_sprite.play("Walk")
		else:
			player_sprite.play("Idle")
	else:
		player_sprite.play("Idle")

func flip_player() -> void:
	if velocity.x < 0:
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

# ─── HIDING ──────────────────────────────────────────────────────────────────
func _handle_hide_input() -> void:
	if not Input.is_action_just_pressed("Hide"):
		return
	if not is_hiding and not near_hiding_spot:
		return
	is_hiding = !is_hiding
	_apply_hiding_state()

func _apply_hiding_state() -> void:
	if is_hiding:
		movement_enabled = false
		noise_level = 0.0
		if hiding_view:
			hiding_view.visible = true
	else:
		movement_enabled = true
		if hiding_view:
			hiding_view.visible = false

# ─── STANDING STILL ──────────────────────────────────────────────────────────
func _update_still_timer(delta: float) -> void:
	if abs(velocity.x) > 10.0 or is_hiding:
		_still_timer = 0.0
	else:
		_still_timer += delta

func is_standing_still() -> bool:
	return _still_timer >= STILL_THRESHOLD

# ─── DEATH / RESPAWN ─────────────────────────────────────────────────────────
func death_tween() -> void:
	if is_hiding:
		is_hiding = false
		_apply_hiding_state()
	movement_enabled = false
	var tween = create_tween()
	tween.tween_property(player_sprite, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	movement_enabled = true
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween() -> void:
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(player_sprite, "position", Vector2(0, -48), 0.15)

func jump_tween() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_collision_body_entered(body: Node) -> void:
	if body.is_in_group("Traps"):
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		death_tween()
