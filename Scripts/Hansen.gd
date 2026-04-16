extends CharacterBody2D

var player: CharacterBody2D = null

func _ready() -> void:
	add_to_group("Hansen")
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	# Hubungkan sinyal dari CatchZone
	$CatchZone.body_entered.connect(_on_catch)

func _on_catch(body: Node) -> void:
	if body == player:
		GameManager.trigger_ending("caught")
