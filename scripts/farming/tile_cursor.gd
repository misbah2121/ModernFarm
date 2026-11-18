class_name TileCursor
extends Node2D
## Kotak penanda tile yang akan terkena alat (tile di depan player).
## Phase 17: disembunyikan saat memancing (pelampung sudah menjadi penanda).

const TILE := 16

var player: Player
var _cell := Vector2i(-9999, -9999)


func _process(_delta: float) -> void:
	if player == null:
		return
	visible = not player.fishing
	var target := player.get_target_cell()
	if target != _cell:
		_cell = target
		position = Vector2(_cell * TILE)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(1.5, 1.5, 13, 13), Color(0, 0, 0, 0.5), false, 1.0)
	draw_rect(Rect2(0.5, 0.5, 15, 15), Color(1, 1, 1, 0.9), false, 1.0)
