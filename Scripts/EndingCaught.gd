extends CanvasLayer

@onready var label: Label = $Label
@onready var btn: Button = $Button

func _ready() -> void:
	AudioManager.stop_all_ambient()
	btn.visible = false
	label.modulate.a = 0.0
	label.text = "Kamu tidak akan pernah ditemukan."
	await get_tree().create_timer(5.0).timeout
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 2.0)
	await tw.finished
	await get_tree().create_timer(3.0).timeout
	var names := ["Eklutna Annie", "Horseshoe Harriet", "dan korban-korban lain yang tidak pernah diidentifikasi..."]
	for victim in names:
		label.text += "\n" + victim
		await get_tree().create_timer(2.0).timeout
	btn.visible = true

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/Level_01.tscn")
