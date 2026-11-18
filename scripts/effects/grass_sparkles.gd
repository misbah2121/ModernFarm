class_name GrassSparkles
extends Node2D
## Phase 18: kilau kecil (bintang 4 sudut biru-putih) yang muncul-hilang di rumput, seperti gambar referensi.
## Dipasang FarmMap tepat di atas layer Decor (di bawah Objects) agar tidak menutupi player / pohon.
## Hanya muncul di tile rumput kosong di sekitar layar, siang hari, dan tidak saat hujan.

const SPAWN_EVERY := 0.18
const LIFE := 1.1
const MAX_ALIVE := 14
const COLORS: Array[Color] = [Color("bfefff"), Color("ffffff"), Color("8fd8ff")]

## Diisi FarmMap.
var farm: FarmMap

var _sparkles: Array = []   # [pos: Vector2, age: float, color: Color]
var _timer := 0.0


func _process(delta: float) -> void:
	if farm == null:
		return
	for s: Array in _sparkles:
		s[1] += delta
	_sparkles = _sparkles.filter(func(s: Array) -> bool: return s[1] < LIFE)
	_timer -= delta
	if _timer <= 0.0:
		_timer = SPAWN_EVERY
		if _sparkles.size() < MAX_ALIVE and _active():
			_spawn()
	queue_redraw()


func _active() -> bool:
	var h := TimeManager.hour()
	return h >= 6 and h < 18 and not TimeManager.is_raining()


func _spawn() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var view := get_viewport_rect().size / cam.zoom
	var center := cam.get_screen_center_position()
	for _try in 6:
		var pos := center + Vector2(randf_range(-0.5, 0.5) * view.x, randf_range(-0.5, 0.5) * view.y)
		var cell := Vector2i((pos / TerrainTiles.TILE).floor())
		if farm.get_terrain(cell) != TerrainTiles.Terrain.GRASS or farm.is_cell_blocked(cell) or farm.object_at(pos) != null:
			continue
		_sparkles.append([pos.round(), 0.0, COLORS[randi() % COLORS.size()]])
		return


func _draw() -> void:
	for s: Array in _sparkles:
		var k: float = s[1] / LIFE
		var size := 2 if k < 0.25 or k > 0.75 else 3   # membesar lalu mengecil
		var c: Color = s[2]
		c.a = 0.9 * sin(k * PI)
		var p: Vector2 = s[0]
		draw_rect(Rect2(p, Vector2(1, 1)), c)
		for i in range(1, size):
			draw_rect(Rect2(p + Vector2(i, 0), Vector2(1, 1)), c)
			draw_rect(Rect2(p + Vector2(-i, 0), Vector2(1, 1)), c)
			draw_rect(Rect2(p + Vector2(0, i), Vector2(1, 1)), c)
			draw_rect(Rect2(p + Vector2(0, -i), Vector2(1, 1)), c)
