extends Node

# ─── COLD GROUND AUDIO STREAMS (Assign di Inspector) ────────────────────────
@export_group("Cold Ground SFX")
@export var wind_stream: AudioStream            ## Loop angin
@export var footstep_snow_stream: AudioStream   ## Langkah salju
@export var hansen_step_stream: AudioStream     ## Langkah Hansen
@export var heartbeat_stream: AudioStream       ## Heartbeat loop
@export var breathing_stream: AudioStream       ## Napas loop
@export var gunshot_stream: AudioStream         ## Suara tembakan

# ─── AUDIO PLAYERS (dibuat otomatis) ────────────────────────────────────────
var wind_player: AudioStreamPlayer
var footstep_snow_player: AudioStreamPlayer
var hansen_footstep_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var breathing_player: AudioStreamPlayer
var gunshot_player: AudioStreamPlayer

# Konstanta volume
const WIND_NORMAL_DB  := -8.0
const WIND_SILENT_DB  := -80.0
const WIND_LERP_SPEED := 0.04

var _hansen: CharacterBody2D = null
var _player: CharacterBody2D = null
var _prev_chase_state: bool = false

func _ready() -> void:
	_create_players()
	call_deferred("_init_refs")

func _create_players() -> void:
	wind_player            = _new_player("WindAmbient")
	footstep_snow_player   = _new_player("FootstepSnow")
	hansen_footstep_player = _new_player("HansenFootstep")
	heartbeat_player       = _new_player("Heartbeat")
	breathing_player       = _new_player("Breathing")
	gunshot_player         = _new_player("Gunshot")

func _new_player(node_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	add_child(p)
	return p

func _init_refs() -> void:
	_find_refs()
	_start_wind()

func _find_refs() -> void:
	_hansen = get_tree().get_first_node_in_group("Hansen") as CharacterBody2D
	_player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

func _start_wind() -> void:
	if not wind_stream:
		return
	wind_player.stream = wind_stream
	wind_player.volume_db = WIND_NORMAL_DB
	wind_player.play()
	if not wind_player.finished.is_connected(wind_player.play):
		wind_player.finished.connect(wind_player.play)

func _process(_delta: float) -> void:
	if not is_instance_valid(_hansen) or not is_instance_valid(_player):
		_find_refs()
		_start_wind()
		return
	_update_wind_volume()
	_update_chase_audio()

func _update_wind_volume() -> void:
	if not wind_player.playing:
		return
	var dist: float = _hansen.global_position.distance_to(_player.global_position)
	var hearing_r: float = 500.0  # Default, bisa di-export nanti
	var ratio: float = clamp(
		(dist - hearing_r * 0.25) / (hearing_r * 0.75),
		0.0, 1.0
	)
	var target_db: float = lerp(WIND_SILENT_DB, WIND_NORMAL_DB, ratio)
	wind_player.volume_db = lerp(wind_player.volume_db, target_db, WIND_LERP_SPEED)

func _update_chase_audio() -> void:
	# Karena Hansen scripted, kita bisa memicu chase audio dari AnimationPlayer
	# Untuk sementara, fungsi ini tetap ada untuk kompatibilitas
	pass

func _ensure_looping(p: AudioStreamPlayer, stream: AudioStream, start_db: float) -> void:
	if p.playing or not stream:
		return
	p.stream = stream
	p.volume_db = start_db
	p.play()
	if not p.finished.is_connected(p.play):
		p.finished.connect(p.play)

func _fade_out_and_stop(p: AudioStreamPlayer, duration: float) -> void:
	if p.get_meta("fading", false) or not p.playing:
		return
	p.set_meta("fading", true)
	var tw := create_tween()
	tw.tween_property(p, "volume_db", WIND_SILENT_DB, duration)
	tw.tween_callback(func():
		p.stop()
		p.remove_meta("fading")
		if p.finished.is_connected(p.play):
			p.finished.disconnect(p.play)
	)

# ─── PUBLIC API ──────────────────────────────────────────────────────────────
func play_footstep(is_snow: bool, is_running: bool) -> void:
	if not footstep_snow_stream or footstep_snow_player.playing:
		return
	footstep_snow_player.stream      = footstep_snow_stream
	footstep_snow_player.volume_db   = 0.0 if is_running else -7.0
	footstep_snow_player.pitch_scale = randf_range(0.92, 1.08)
	footstep_snow_player.play()

func play_hansen_step(volume_db: float = -4.0) -> void:
	if not hansen_step_stream or hansen_footstep_player.playing:
		return
	hansen_footstep_player.stream      = hansen_step_stream
	hansen_footstep_player.volume_db   = volume_db
	hansen_footstep_player.pitch_scale = randf_range(0.88, 1.05)
	hansen_footstep_player.play()

func stop_hansen_step() -> void:
	hansen_footstep_player.stop()

func play_gunshot() -> void:
	if not gunshot_stream:
		return
	gunshot_player.stream = gunshot_stream
	gunshot_player.play()

func set_wind_volume(volume_db: float) -> void:
	var tw := create_tween()
	tw.tween_property(wind_player, "volume_db", volume_db, 1.0)

func stop_all_ambient() -> void:
	wind_player.stop()
	heartbeat_player.stop()
	breathing_player.stop()
	hansen_footstep_player.stop()
