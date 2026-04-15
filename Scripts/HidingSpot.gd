extends Area2D

# ─────────────────────────────────────────────────────────────────────────────
# HidingSpot.gd
# Attach ke setiap Area2D yang jadi tempat sembunyi (pohon besar, batu).
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.near_hiding_spot = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		body.near_hiding_spot = false
		# Kalau player keluar dari spot sambil masih hiding, paksa keluar
		if body.is_hiding:
			body.is_hiding = false
			body._apply_hiding_state()
