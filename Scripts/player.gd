extends CharacterBody2D

# Kecepatan gerak (bisa diatur di Inspector)
@export var walk_speed: float = 220.0
@export var run_speed: float  = 420.0

# Status internal
var movement_enabled: bool = true
var is_running: bool = false
var is_hiding: bool = false
var near_hiding_spot: bool = false

# Timer untuk langkah kaki
var _step_timer: float = 0.0
const WALK_STEP_INTERVAL := 0.45
const RUN_STEP_INTERVAL  := 0.27

# Referensi ke node HidingView (akan dicari saat _ready)
var hiding_view: CanvasLayer = null

# Referensi ke node-node anak
@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var particle_trails: CPUParticles2D = $ParticleTrails

func _ready() -> void:
	add_to_group("Player")
	# Cari HidingView di scene tree menggunakan group
	hiding_view = get_tree().get_first_node_in_group("HidingView") as CanvasLayer
	if hiding_view:
		hiding_view.visible = false

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		return
	
	# Input horizontal
	var input_dir: float = Input.get_axis("Left", "Right")
	is_running = Input.is_action_pressed("Run") and abs(input_dir) > 0.1
	
	var speed: float = run_speed if is_running else walk_speed
	velocity.x = input_dir * speed
	velocity.y = 0  # Tidak ada gravitasi
	
	move_and_slide()
	
	# Update timer langkah kaki dan mainkan suara
	_update_footstep(delta, input_dir)

func _process(delta: float) -> void:
	player_animations()
	flip_player()
	_handle_hide_input()

func _update_footstep(delta: float, input_dir: float) -> void:
	if abs(input_dir) < 0.1 or is_hiding:
		_step_timer = 0.0
		return
	var interval: float = RUN_STEP_INTERVAL if is_running else WALK_STEP_INTERVAL
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = interval
		AudioManager.play_footstep(true, is_running)

func player_animations() -> void:
	particle_trails.emitting = false
	if is_hiding:
		return
	if abs(velocity.x) > 0:
		particle_trails.emitting = true
		if is_running:
			player_sprite.play("Run")
		else:
			player_sprite.play("Walk")
	else:
		player_sprite.play("Idle")

func flip_player() -> void:
	if velocity.x < 0:
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

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
		if hiding_view:
			hiding_view.visible = true
	else:
		movement_enabled = true
		if hiding_view:
			hiding_view.visible = false
