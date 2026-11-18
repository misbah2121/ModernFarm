class_name RippleFx
extends Node2D
## Phase 17: riak air (lingkaran pipih) yang membesar lalu hilang. Dibuat lewat Vfx.ripple().
## Digambar dengan garis 1 piksel tanpa antialias agar sesuai pixel art.

const DURATION := 0.7
const COLOR := Color(0.85, 0.97, 1.0, 0.9)

var max_radius := 6.0
var _t := 0.0


func _ready() -> void:
	z_index = 1


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var r := roundf(lerpf(2.0, max_radius, k))
	var c := Color(COLOR, COLOR.a * (1.0 - k))
	# Lingkaran digepengkan (skala y 0.5) agar terlihat seperti riak dari samping atas.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, c, 1.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
