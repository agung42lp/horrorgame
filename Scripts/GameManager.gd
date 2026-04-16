extends Node

func trigger_ending(ending_type: String) -> void:
	match ending_type:
		"escape":
			get_tree().change_scene_to_file("res://Scenes/Levels/Ending_Escape.tscn")
		"caught":
			get_tree().change_scene_to_file("res://Scenes/Levels/Ending_Caught.tscn")
