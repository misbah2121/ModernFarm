class_name FarmWorkerNpc
extends Node2D
## Phase 19: sosok pekerja farm yang berjalan-jalan di lahan pertanian siang hari (06:00 - 18:00).
## Hanya tampilan; pekerjaannya dilakukan sekaligus tiap pagi oleh FarmWorkers.
## Sprite: Farmer_2_16x16.png asli pack (Budi) dan versi warna topi lain (Sari, Joko) di
## assets/modern_farm/characters/workers/. Tata letak sheet sama dengan Player (frame 48x64):
## baris 1 diam, 2 jalan, 3 panen, 7 menyiram. Urutan arah: kanan, atas, kiri, bawah.

const FRAME := Vector2i(48, 64)
const DIRECTIONS: Array[StringName] = [&"right", &"up", &"left", &"down"]
const SPEED := 22.0
const WORK_HOURS := Vector2i(6, 18)

var worker_id := ""
var farm: FarmMap

var _sprite: AnimatedSprite2D
var _facing: StringName = &"down"
var _target := Vector2.ZERO
var _timer := 1.0
var _walking := false
var _rng := RandomNumberGenerator.new()


func setup(id: String, sheet: Texture2D, p_farm: FarmMap) -> void:
	worker_id = id
	farm = p_farm
	name = "Worker_%s" % id
	_rng.randomize()
	add_child(Vfx.shadow(12, Vector2(0, -1)))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames(sheet)
	_sprite.position = Vector2(0, -32)
	_sprite.animation_finished.connect(func() -> void: _play(&"idle"))
	add_child(_sprite)
	position = _random_point()
	_play(&"idle")


func _process(delta: float) -> void:
	var h := TimeManager.hour()
	visible = h >= WORK_HOURS.x and h < WORK_HOURS.y
	if not visible:
		return
	if _walking:
		var to := _target - position
		if to.length() < 1.5:
			_walking = false
			_timer = _rng.randf_range(1.5, 4.0)
			_maybe_work()
			return
		var step := to.normalized() * SPEED * delta
		position += step
		_face(step)
		_play(&"walk")
		return
	_timer -= delta
	if _timer <= 0.0:
		_target = _random_point()
		_walking = true


## Kadang memainkan animasi kerja sesuai peran (siram / panen).
func _maybe_work() -> void:
	if _rng.randf() < 0.55:
		_play(&"water" if worker_id == "waterer" else &"harvest", true)
	else:
		_play(&"idle")


func _random_point() -> Vector2:
	if farm == null:
		return position
	var rects: Array[Rect2i] = farm.farm_plot_rects()
	if rects.is_empty():
		return position
	var r: Rect2i = rects[_rng.randi_range(0, rects.size() - 1)]
	var cell := Vector2i(_rng.randi_range(r.position.x + 1, r.end.x - 2), _rng.randi_range(r.position.y + 1, r.end.y - 2))
	return Vector2(cell * TerrainTiles.TILE) + Vector2(8, 12)


func _face(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		_facing = &"right" if dir.x > 0.0 else &"left"
	else:
		_facing = &"down" if dir.y > 0.0 else &"up"


func _play(state: StringName, restart := false) -> void:
	var anim := StringName("%s_%s" % [state, _facing])
	if restart or _sprite.animation != anim:
		_sprite.play(anim)
	# animasi aksi di sheet bergeser dari posisi idle (lihat Player.ANIM_OFFSETS)
	_sprite.offset = (Player.ANIM_OFFSETS[state] as Array)[DIRECTIONS.find(_facing)] if Player.ANIM_OFFSETS.has(state) else Vector2.ZERO


func _build_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	# state, baris, jumlah frame per arah, fps, berulang
	for a: Array in [[&"idle", 1, 6, 6.0, true], [&"walk", 2, 6, 8.0, true], [&"harvest", 3, 9, 10.0, false], [&"water", 7, 14, 12.0, false]]:
		for d in DIRECTIONS.size():
			var anim := StringName("%s_%s" % [a[0], DIRECTIONS[d]])
			frames.add_animation(anim)
			frames.set_animation_speed(anim, a[3])
			frames.set_animation_loop(anim, a[4])
			var count: int = a[2]
			for i in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.filter_clip = true
				atlas.region = Rect2((d * count + i) * FRAME.x, int(a[1]) * FRAME.y, FRAME.x, FRAME.y)
				frames.add_frame(anim, atlas)
	return frames


## Untuk tombol E: titik interaksi dekat pekerja?
func is_at(world_pos: Vector2) -> bool:
	return visible and (global_position + Vector2(0, -10)).distance_to(world_pos) < 14.0
