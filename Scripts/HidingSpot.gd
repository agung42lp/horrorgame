extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	# Periksa apakah body yang masuk adalah player
	if body.is_in_group("Player"):
		body.near_hiding_spot = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		body.near_hiding_spot = false
