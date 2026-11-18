class_name FarmAnimal
extends CharacterBody2D
## Hewan ternak di peta Farm (Phase 9). Dibuat FarmMap lewat kode: FarmAnimal.new() lalu setup().
## Jalan-jalan acak di dalam kandang terbuka (Areas/AnimalPen), kadang berhenti makan rumput.
## Saat produk siap, icon produk muncul melayang di atas kepala.
## Data (nama, friendship, makan, produk) ada di AnimalManager.AnimalState.
## Phase 23: sheet sesuai WARNA (state.variant) dan ANAK (state.baby). Saat anak tumbuh dewasa
## (atau anak ayam menjadi ayam jago), tampilan dibangun ulang otomatis.
## Frame yang kosong di sheet dilewati, dan foot_offset -1 dihitung dari piksel terbawah sheet.

const DIRECTIONS: Array[StringName] = [&"right", &"up", &"left", &"down"]
const FRAMES_PER_DIRECTION := 6
const IDLE_FPS := 5.0
const WALK_FPS := 8.0
const EAT_FPS := 5.0

enum State { IDLE, WALK, EAT }

## Cache per sheet: Image (untuk cek frame kosong & kaki).
static var _images: Dictionary = {}

var state  # AnimalManager.AnimalState
var data: AnimalData
var facing: StringName = &"down"

var _pen := Rect2()
var _sprite: AnimatedSprite2D
var _shadow: Node2D
var _shape: CollisionShape2D
var _bubble: Sprite2D
var _mode: State = State.IDLE
var _timer := 1.0
var _target := Vector2.ZERO
var _bob := 0.0
var _rng := RandomNumberGenerator.new()
var _built_key := ""
var _frame := Vector2i(16, 16)
var _foot := 1
var _speed := 16.0


func setup(p_state, pen: Rect2) -> void:
	state = p_state
	data = state.data
	_pen = pen
	name = "%s_%d" % [data.id, state.uid]
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Layer 2: player (mask 1) bisa menembus hewan, hewan tetap menabrak dunia & player.
	collision_layer = 2
	collision_mask = 1
	# Phase 23: seed unik per hewan (randomize() di frame yang sama memberi seed kembar -> hewan bergerombol)
	_rng.seed = hash("%d_%d" % [state.uid, randi()])
	position = Vector2(
		_rng.randf_range(pen.position.x + 8.0, pen.end.x - 8.0),
		_rng.randf_range(pen.position.y + 8.0, pen.end.y - 8.0)
	).round()
	_timer = _rng.randf_range(0.5, 2.0)

	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_sprite = AnimatedSprite2D.new()
	add_child(_sprite)
	_bubble = Sprite2D.new()
	_bubble.z_index = 10
	add_child(_bubble)
	AnimalManager.changed.connect(refresh)
	refresh()
	_play(&"idle")


## Membangun ulang sprite / collision / bayangan sesuai jenis, warna, dan umur.
func _rebuild() -> void:
	data = state.data
	var baby: bool = state.baby
	_frame = data.frame_for(baby)
	var sheet := data.sheet_for(state.variant, baby)
	var rows := data.rows_for(baby)
	_foot = data.foot_offset if data.foot_offset >= 0 and not baby else _auto_foot(sheet, rows.x)
	var body := data.body_size * (0.6 if baby else 1.0)
	_speed = data.walk_speed * (0.8 if baby else 1.0)
	(_shape.shape as RectangleShape2D).size = body
	_shape.position = Vector2(0, -body.y / 2.0)
	if _shadow != null:
		_shadow.queue_free()
	_shadow = Vfx.shadow(int(body.x) + 4, Vector2(0, -1))  # Phase 18: bayangan di kaki
	add_child(_shadow)
	move_child(_shadow, 0)
	_sprite.sprite_frames = _build_frames(sheet, rows)
	_sprite.position = Vector2(0, -_frame.y / 2.0 + _foot)
	_sprite.play(StringName("idle_%s" % facing))


## Titik tengah badan, untuk mengecek apakah player menghadap hewan ini.
func center() -> Vector2:
	return global_position + Vector2(0, -(_frame.y - _foot) * 0.4)


## Jarak maksimum titik interaksi player ke center() (hewan besar lebih mudah dikenai).
func reach() -> float:
	return 10.0 + data.body_size.x * (0.3 if state.baby else 0.5)


func refresh() -> void:
	if state == null:
		return
	var key := "%s|%d|%s" % [state.data.id, state.variant, state.baby]
	if key != _built_key:
		_built_key = key
		_rebuild()
	var item: ItemData = state.ready_item()
	var show: bool = item != null and not state.baby
	_bubble.visible = show
	if show:
		_bubble.texture = item.icon


func _process(delta: float) -> void:
	if _bubble.visible:
		_bob += delta * 4.0
		var top := -_frame.y + _foot - 6.0
		_bubble.position = Vector2(0, roundf(top + sin(_bob) * 2.0))


func _physics_process(delta: float) -> void:
	match _mode:
		State.IDLE, State.EAT:
			_timer -= delta
			if _timer <= 0.0:
				_choose_next()
		State.WALK:
			_timer -= delta
			var to_target := _target - global_position
			if to_target.length() < 2.0 or _timer <= 0.0:
				_enter(State.IDLE)
				return
			velocity = to_target.normalized() * _speed
			_update_facing(velocity)
			move_and_slide()
			if get_slide_collision_count() > 0:
				_enter(State.IDLE)
				return
			_play(&"walk")


func _choose_next() -> void:
	var roll := _rng.randf()
	if roll < 0.55:
		_target = Vector2(
			_rng.randf_range(_pen.position.x + 8.0, _pen.end.x - 8.0),
			_rng.randf_range(_pen.position.y + 8.0, _pen.end.y - 8.0)
		)
		_enter(State.WALK)
	elif roll < 0.8 and _sprite.sprite_frames.has_animation(&"eat_right"):
		_enter(State.EAT)
	else:
		_enter(State.IDLE)


func _enter(mode: State) -> void:
	_mode = mode
	velocity = Vector2.ZERO
	match mode:
		State.WALK:
			_timer = 6.0
			_play(&"walk")
		State.EAT:
			_timer = _rng.randf_range(2.0, 4.0)
			# Animasi makan hanya tampak bagus dari samping.
			if facing == &"up" or facing == &"down":
				facing = &"right" if _rng.randf() < 0.5 else &"left"
			_play(&"eat")
		_:
			_timer = _rng.randf_range(1.5, 4.0)
			_play(&"idle")


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) >= absf(direction.y):
		facing = &"right" if direction.x > 0.0 else &"left"
	else:
		facing = &"down" if direction.y > 0.0 else &"up"


func _play(anim_state: StringName) -> void:
	var anim_name := StringName("%s_%s" % [anim_state, facing])
	if not _sprite.sprite_frames.has_animation(anim_name):
		anim_name = StringName("idle_%s" % facing)
	if _sprite.animation != anim_name or not _sprite.is_playing():
		_sprite.play(anim_name)


# ---------------------------------------------------------------- sprite

static func _image_of(sheet: Texture2D) -> Image:
	if sheet == null:
		return null
	var key := sheet.resource_path
	if not _images.has(key):
		var img := sheet.get_image()
		if img != null and img.is_compressed():
			img.decompress()
		_images[key] = img
	return _images[key] as Image


func _frame_rect(dir_index: int, i: int, row: int) -> Rect2i:
	return Rect2i((dir_index * FRAMES_PER_DIRECTION + i) * _frame.x, row * _frame.y, _frame.x, _frame.y)


func _frame_empty(img: Image, rect: Rect2i) -> bool:
	if img == null:
		return false
	if rect.end.x > img.get_width() or rect.end.y > img.get_height():
		return true
	return img.get_region(rect).is_invisible()


## Piksel kosong di bawah kaki: dari frame diam menghadap kanan.
func _auto_foot(sheet: Texture2D, row: int) -> int:
	var img := _image_of(sheet)
	if img == null:
		return 1
	var rect := _frame_rect(0, 0, row)
	for y in range(rect.size.y - 1, -1, -1):
		for x in rect.size.x:
			if img.get_pixel(rect.position.x + x, rect.position.y + y).a > 0.1:
				return rect.size.y - 1 - y
	return 1


func _build_frames(sheet: Texture2D, rows: Vector3i) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	var img := _image_of(sheet)
	_add_animations(frames, sheet, img, "idle", rows.x, IDLE_FPS)
	_add_animations(frames, sheet, img, "walk", rows.y, WALK_FPS)
	if rows.z >= 0:
		_add_animations(frames, sheet, img, "eat", rows.z, EAT_FPS)
	return frames


func _add_animations(frames: SpriteFrames, sheet: Texture2D, img: Image, anim_state: String, row: int, fps: float) -> void:
	for dir_index in DIRECTIONS.size():
		var rects: Array[Rect2i] = []
		for i in FRAMES_PER_DIRECTION:
			var r := _frame_rect(dir_index, i, row)
			if not _frame_empty(img, r):
				rects.append(r)
		# Baris tidak lengkap (sebagian frame kosong) dilewati, kecuali idle/walk yang wajib ada.
		if anim_state == "eat" and rects.size() < FRAMES_PER_DIRECTION:
			for d in dir_index:
				frames.remove_animation(StringName("eat_%s" % DIRECTIONS[d]))
			return
		if rects.is_empty():
			rects.append(_frame_rect(dir_index, 0, row))
		var anim_name := StringName("%s_%s" % [anim_state, DIRECTIONS[dir_index]])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, true)
		for r in rects:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.filter_clip = true
			atlas.region = Rect2(r)
			frames.add_frame(anim_name, atlas)
