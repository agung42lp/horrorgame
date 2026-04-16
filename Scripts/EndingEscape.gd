extends CanvasLayer

@onready var label: Label = $Label
@onready var btn: Button = $Button
@onready var color_rect: ColorRect = $ColorRect

var lines := [
	"Kamu berhasil keluar dari hutan ini.",
	"Cindy Paulson melakukan hal yang sama\npada 13 Juni 1983.",
	"Kesaksiannya menghentikan semuanya.",
	"Setelah penangkapan Hansen,\ninvestigators menemukan peta dengan tanda X.",
	"Hanya 12 tubuh yang pernah ditemukan."
]

func _ready() -> void:
	AudioManager.stop_all_ambient()
	btn.visible = false
	label.text = ""
	color_rect.color = Color.BLACK
	var tw := create_tween()
	tw.tween_property(color_rect, "color", Color.WHITE, 2.0)
	await tw.finished
	await get_tree().create_timer(2.0).timeout
	for line in lines:
		label.text = line
		label.modulate.a = 0.0
		var tw2 := create_tween()
		tw2.tween_property(label, "modulate:a", 1.0, 1.5)
		await tw2.finished
		await get_tree().create_timer(3.0).timeout
	btn.visible = true

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/Level_01.tscn")
