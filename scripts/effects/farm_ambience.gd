class_name FarmAmbience
extends Node2D
## Phase 21: suasana hidup di Farm seperti video referensi.
##   * Tetes air (Water_Drop_Outlined_16x16.png asli pack) melayang di atas tanaman yang BELUM disiram
##     hari ini, supaya pemain tahu mana yang perlu disiram. Hilang setelah disiram / dipanen.
##   * Daun gugur: sesekali pohon di sekitar layar menjatuhkan daun (Vfx.leaves) - siang hari.
##   * Kunang-kunang: titik cahaya kuning-hijau beterbangan di rumput saat malam (19:00 - 05:00).
## Dibuat FarmMap lewat kode (anak node FarmMap, di atas Objects).
## Phase 22: dipakai juga di Desa & Hutan (peta tanpa lahan: tetes air dilewati).

const DROP_TEX := preload("res://assets/modern_farm/effects/Water_Drop_Outlined_16x16.png")
const FIREFLY_COUNT := 14
const LEAF_EVERY := Vector2(2.5, 6.0)

## Peta pemilik (FarmMap / VillageMap / WildMap): harus punya `objects`. `soil` opsional (hanya Farm).
var farm: Node2D

var _drops: Dictionary = {}      # Vector2i -> Sprite2D
var _drop_timer := 0.0
var _leaf_timer := 3.0
var _t := 0.0
var _fireflies: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()


func setup(p_farm: Node2D) -> void:
	farm = p_farm
	_rng.randomize()
	z_index = 4
	_make_fireflies()


func _process(delta: float) -> void:
	if farm == null:
		return
	_t += delta
	_drop_timer -= delta
	if _drop_timer <= 0.0:
		_drop_timer = 0.4
		_refresh_drops()
	_bob_drops()
	_leaf_timer -= delta
	if _leaf_timer <= 0.0:
		_leaf_timer = _rng.randf_range(LEAF_EVERY.x, LEAF_EVERY.y)
		_drop_leaves()
	_update_fireflies(delta)


# ---------------------------------------------------------------- tetes air

func _refresh_drops() -> void:
	if not (farm is FarmMap):
		return
	var need: Dictionary = {}
	for cell: Vector2i in (farm as FarmMap).soil.thirsty_cells():
		need[cell] = true
	for cell: Vector2i in _drops.keys():
		if not need.has(cell):
			(_drops[cell] as Node).queue_free()
			_drops.erase(cell)
	for cell: Vector2i in need:
		if _drops.has(cell):
			continue
		var s := Sprite2D.new()
		s.texture = DROP_TEX
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(cell * TerrainTiles.TILE) + Vector2(8, -6)
		s.set_meta("phase", _rng.randf() * TAU)
		add_child(s)
		_drops[cell] = s


func _bob_drops() -> void:
	for cell: Vector2i in _drops:
		var s: Sprite2D = _drops[cell]
		var ph: float = s.get_meta("phase")
		s.offset.y = roundf(sin(_t * 3.0 + ph) * 1.5)
		# berkedip pelan agar tidak mengganggu
		s.modulate.a = 0.75 + 0.25 * sin(_t * 2.0 + ph)


# ---------------------------------------------------------------- daun gugur

func _drop_leaves() -> void:
	var h := TimeManager.hour()
	if h < 6 or h >= 19 or TimeManager.is_raining():
		return
	var view := _view_rect().grow(40.0)
	var objects: Node2D = farm.get("objects")
	var points: Array[Vector2] = []
	for node in objects.get_children():
		if not view.has_point((node as Node2D).global_position if node is Node2D else Vector2(-1e9, -1e9)):
			continue
		if node is TreeProp:
			points.append((node as TreeProp).canopy_point())
		elif node is ResourceNode and (node as ResourceNode).tool == ResourceNode.Tool.AXE and not (node as ResourceNode).broken:
			var res := node as ResourceNode
			points.append(res.global_position + res._canopy_point())
	if points.is_empty():
		return
	var pt: Vector2 = points[_rng.randi_range(0, points.size() - 1)]
	Vfx.leaves(objects, pt - objects.global_position + Vector2(_rng.randf_range(-12, 12), 0))


func _view_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return Rect2()
	var size := get_viewport_rect().size / cam.zoom
	return Rect2(cam.get_screen_center_position() - size / 2.0, size)


# ---------------------------------------------------------------- kunang-kunang

func _make_fireflies() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 32
	tex.height = 32
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	for i in FIREFLY_COUNT:
		var f := Node2D.new()
		var dot := Polygon2D.new()
		dot.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		dot.color = Color(0.85, 1.0, 0.45)
		f.add_child(dot)
		var light := PointLight2D.new()
		light.texture = tex
		light.color = Color(0.75, 1.0, 0.35)
		light.energy = 0.55
		light.texture_scale = 0.55
		f.add_child(light)
		f.set_meta("seed", _rng.randf() * 100.0)
		f.visible = false
		add_child(f)
		_fireflies.append(f)


func _update_fireflies(delta: float) -> void:
	var h := TimeManager.hour()
	var night := (h >= 19 or h < 5) and not TimeManager.is_raining()
	var view := _view_rect()
	for f in _fireflies:
		if not night:
			f.visible = false
			continue
		if not f.visible or not view.grow(24.0).has_point(f.position):
			f.position = view.position + Vector2(_rng.randf() * view.size.x, _rng.randf() * view.size.y)
			f.visible = true
		var sd: float = f.get_meta("seed")
		var dir := Vector2(sin(_t * 0.7 + sd), cos(_t * 0.9 + sd * 1.3))
		f.position += dir * 9.0 * delta
		var glow := 0.5 + 0.5 * sin(_t * 2.2 + sd * 3.0)
		f.modulate.a = 0.25 + 0.75 * glow
