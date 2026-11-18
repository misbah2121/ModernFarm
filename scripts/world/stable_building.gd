class_name StableBuilding
extends Node2D
## Phase 21: kandang kecil (Stable) dengan ATAP TEMBUS PANDANG seperti video referensi Modern Farm.
##   Roof   (Sprite2D "Sprite2D") : Stable_Example_Outside_16x16.png - atap + dinding depan.
##   Floor  (Sprite2D)            : Stable_Example_Inside_16x16.png  - lantai, pagar, kotak tanaman, palung.
##   Front  (Sprite2D)            : potongan pagar depan dari gambar Inside, digambar di depan player.
##   Walls  (StaticBody2D)        : pagar keliling + sekat + perabot. Pintu di kiri bawah.
## Saat player masuk ke dalam (InsideArea), atap memudar (alpha 0) sehingga isi kandang terlihat,
## dan muncul lagi saat player keluar. Titik node = pojok kiri atas gambar (160x128).
## Root memakai Y Sort agar atap / pagar depan terurut benar dengan player.

const SIZE := Vector2(160, 128)
const INSIDE := Rect2(6, 26, 148, 96)   # area dalam (lokal) - player di sini = atap memudar
const FADE_SPEED := 5.0

@onready var roof: Sprite2D = $Sprite2D
@onready var front: Sprite2D = $Front

var _player: Node2D


func _ready() -> void:
	_player = get_parent().get_node_or_null("Player") as Node2D


func _process(delta: float) -> void:
	if _player == null:
		return
	var local := _player.global_position - global_position
	var inside := INSIDE.has_point(local)
	roof.modulate.a = move_toward(roof.modulate.a, 0.0 if inside else 1.0, FADE_SPEED * delta)
	front.visible = roof.modulate.a < 0.99


func is_player_inside() -> bool:
	return _player != null and INSIDE.has_point(_player.global_position - global_position)
