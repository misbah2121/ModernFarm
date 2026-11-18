class_name TreeProp
extends Node2D
## Phase 21: pohon hiasan di peta (oak bulat besar, pinus). Titik node = pangkal batang.
##   * Tembus pandang: saat player berdiri DI BELAKANG tajuk pohon, tajuk menjadi transparan
##     (seperti video referensi) supaya player tetap terlihat.
##   * Bergoyang: sheet "Shake" asli pack (3 frame berjajar) dimainkan sesekali seperti tertiup angin,
##     dan selalu bergoyang saat player menabrak / lewat dekat batang.
##   * Daun gugur: kadang menjatuhkan daun (Vfx.leaves) - diatur oleh FarmAmbience.
## Sprite2D dengan region_rect selebar 1 frame. Grup "tree" tetap dipakai FarmMap untuk batang yang menghalangi.

const FADE_ALPHA := 0.45
const FADE_SPEED := 6.0
const TRUNK_HALF := 10.0

@onready var sprite: Sprite2D = $Sprite2D

var _player: Node2D
var _frame_w := 0.0
var _shake_t := -1.0
var _idle_timer := 0.0
var _was_near := false


func _ready() -> void:
	_player = get_parent().get_node_or_null("Player") as Node2D
	if sprite.region_enabled and sprite.texture != null:
		_frame_w = sprite.region_rect.size.x
	_idle_timer = randf_range(4.0, 18.0)


func _process(delta: float) -> void:
	if _player == null or not _player.is_inside_tree():
		return
	var p := _player.global_position
	var rect := Rect2(global_position + sprite.position, sprite.get_rect().size)
	# di belakang tajuk = di dalam gambar pohon, di atas pangkal batang (lebih "jauh" dari kamera)
	var behind := rect.grow(-6.0).has_point(p + Vector2(0, -10)) and p.y < global_position.y - 2.0
	var target := FADE_ALPHA if behind else 1.0
	sprite.modulate.a = move_toward(sprite.modulate.a, target, FADE_SPEED * delta)
	# goyang saat player menyentuh batang
	var near := absf(p.x - global_position.x) < TRUNK_HALF + 6.0 and absf(p.y - global_position.y) < 10.0
	if near and not _was_near:
		shake()
	_was_near = near
	# goyang angin sesekali
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_idle_timer = randf_range(8.0, 24.0)
		shake()
	if _shake_t >= 0.0:
		_shake_t += delta
		var frames := [1, 2, 1, 0]
		var idx := int(_shake_t / 0.09)
		if idx >= frames.size():
			_shake_t = -1.0
			_set_frame(0)
		else:
			_set_frame(frames[idx])


func shake() -> void:
	if _frame_w > 0.0 and sprite.texture.get_width() >= _frame_w * 3.0:
		_shake_t = 0.0


func _set_frame(i: int) -> void:
	if _frame_w > 0.0:
		sprite.region_rect.position.x = _frame_w * i


## Titik tengah tajuk (untuk daun gugur).
func canopy_point() -> Vector2:
	var r := sprite.get_rect()
	return global_position + sprite.position + Vector2(r.size.x * 0.5, r.size.y * 0.35)
