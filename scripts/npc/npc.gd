class_name Npc
extends CharacterBody2D
## NPC di peta: sprite dari sheet NpcData, jalan-jalan acak di sekitar titik jangkar (anchor),
## berhenti dan menghadap player saat diajak bicara. Dibuat lewat kode: Npc.new() lalu setup().
## Phase 11: mengikuti jadwal. VillageMap memanggil travel() (berjalan mengikuti jalur AStarGrid2D)
## atau snap() (langsung pindah). Tempat "indoor" = NPC masuk rumah dan tidak terlihat.

const FRAME_SIZE := Vector2i(16, 32)
const FRAMES_PER_DIRECTION := 6
const ROW_IDLE := 1
const ROW_WALK := 2
## Urutan arah di tiap baris sheet sama dengan sheet Farmer: kanan, atas, kiri, bawah.
const DIRECTIONS: Array[StringName] = [&"right", &"up", &"left", &"down"]
const SPEED := 28.0
const TRAVEL_SPEED := 42.0
const IDLE_FPS := 6.0
const WALK_FPS := 8.0

enum State { IDLE, WALK, TALK, TRAVEL, INSIDE }

var data: NpcData
var facing: StringName = &"down"
## Nama tempat jadwal saat ini (diatur VillageMap).
var place: String = ""
## Titik pusat jalan-jalan dan jaraknya.
var anchor := Vector2.ZERO
var wander_radius := 0.0

var _path := PackedVector2Array()
var _path_index := 0
var _arrive_inside := false
var _stuck_time := 0.0
var _resume_state: State = State.IDLE
var _shape: CollisionShape2D
var _sprite: AnimatedSprite2D
var _state: State = State.IDLE
var _timer := 1.0
var _target := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func setup(p_data: NpcData) -> void:
	data = p_data
	name = data.id
	position = data.home
	anchor = data.home
	wander_radius = data.wander_radius
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_rng.randomize()
	_timer = _rng.randf_range(0.5, 2.5)

	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 6)
	_shape.shape = rect
	_shape.position = Vector2(0, -3)
	add_child(_shape)

	add_child(Vfx.shadow(12, Vector2(0, -1)))  # Phase 18: bayangan di kaki
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.position = Vector2(0, -FRAME_SIZE.y / 2.0)  # kaki di titik node
	add_child(_sprite)
	_play(&"idle")


## Titik tengah badan, dipakai untuk mengecek apakah player menghadap NPC ini.
func center() -> Vector2:
	return global_position + Vector2(0, -8)


## Bisa diajak bicara (tidak sedang di dalam rumah).
func is_available() -> bool:
	return _state != State.INSIDE


## Berjalan mengikuti titik-titik jalur ke tempat jadwal.
func travel(path: PackedVector2Array, inside_on_arrive: bool, radius: float) -> void:
	if _state == State.INSIDE:
		_set_inside(false)  # keluar rumah lewat pintu
	_path = path
	_path_index = 0
	_arrive_inside = inside_on_arrive
	wander_radius = radius
	if not path.is_empty():
		anchor = path[path.size() - 1]
	_stuck_time = 0.0
	if _state == State.TALK:
		_resume_state = State.TRAVEL  # lanjut berjalan setelah percakapan
		return
	_state = State.TRAVEL
	_play(&"walk")


## Langsung berada di tempat (dipakai saat pagi hari / saat player masuk desa).
func snap(pos: Vector2, inside: bool, radius: float) -> void:
	global_position = pos
	anchor = pos
	wander_radius = radius
	_path = PackedVector2Array()
	_set_inside(inside)
	if not inside:
		_enter_idle()


func _set_inside(value: bool) -> void:
	visible = not value
	_shape.set_deferred("disabled", value)
	if value:
		_state = State.INSIDE
		velocity = Vector2.ZERO
	elif _state == State.INSIDE:
		_state = State.IDLE


func begin_talk(player_position: Vector2) -> void:
	if _state == State.TRAVEL:
		_resume_state = State.TRAVEL
	else:
		_resume_state = State.IDLE
	_state = State.TALK
	velocity = Vector2.ZERO
	_update_facing(player_position - global_position)
	_play(&"idle")


func end_talk() -> void:
	if _resume_state == State.TRAVEL and _path_index < _path.size():
		_state = State.TRAVEL
		_play(&"walk")
	else:
		_enter_idle()


func _physics_process(delta: float) -> void:
	match _state:
		State.TALK, State.INSIDE:
			velocity = Vector2.ZERO
		State.TRAVEL:
			_follow_path(delta)
		State.IDLE:
			_timer -= delta
			if _timer <= 0.0:
				_pick_target()
		State.WALK:
			_timer -= delta
			var to_target := _target - global_position
			if to_target.length() < 2.0 or _timer <= 0.0:
				_enter_idle()
				return
			velocity = to_target.normalized() * SPEED
			_update_facing(velocity)
			move_and_slide()
			if get_slide_collision_count() > 0:
				_enter_idle()  # menabrak sesuatu: berhenti dulu
				return
			_play(&"walk")


func _follow_path(delta: float) -> void:
	if _path_index >= _path.size():
		_arrive()
		return
	var target := _path[_path_index]
	var to_target := target - global_position
	if to_target.length() < 2.0:
		_path_index += 1
		_stuck_time = 0.0
		return
	var before := global_position
	velocity = to_target.normalized() * TRAVEL_SPEED
	_update_facing(velocity)
	move_and_slide()
	_play(&"walk")
	# Terhalang (mis. oleh player): setelah 1 detik lompat ke titik berikutnya.
	if global_position.distance_to(before) < TRAVEL_SPEED * delta * 0.3:
		_stuck_time += delta
		if _stuck_time > 1.0:
			global_position = target
			_path_index += 1
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0


func _arrive() -> void:
	_path = PackedVector2Array()
	if _arrive_inside:
		_set_inside(true)
	else:
		_enter_idle()


func _enter_idle() -> void:
	_state = State.IDLE
	velocity = Vector2.ZERO
	_timer = _rng.randf_range(1.5, 4.0)
	_play(&"idle")


func _pick_target() -> void:
	if wander_radius <= 0.0:
		_timer = 3.0
		return
	var angle := _rng.randf_range(0.0, TAU)
	var dist := _rng.randf_range(4.0, maxf(wander_radius, 4.0))
	_target = anchor + Vector2.from_angle(angle) * dist
	_state = State.WALK
	_timer = 4.0


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) >= absf(direction.y):
		facing = &"right" if direction.x > 0.0 else &"left"
	else:
		facing = &"down" if direction.y > 0.0 else &"up"


func _play(state_name: StringName) -> void:
	var anim_name := StringName("%s_%s" % [state_name, facing])
	if _sprite.animation != anim_name or not _sprite.is_playing():
		_sprite.play(anim_name)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	_add_animations(frames, "idle", ROW_IDLE, IDLE_FPS)
	_add_animations(frames, "walk", ROW_WALK, WALK_FPS)
	return frames


func _add_animations(frames: SpriteFrames, state_name: String, row: int, fps: float) -> void:
	for dir_index in DIRECTIONS.size():
		var anim_name := StringName("%s_%s" % [state_name, DIRECTIONS[dir_index]])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, true)
		for i in FRAMES_PER_DIRECTION:
			var atlas := AtlasTexture.new()
			atlas.atlas = data.sheet
			atlas.filter_clip = true
			atlas.region = Rect2(
				(dir_index * FRAMES_PER_DIRECTION + i) * FRAME_SIZE.x,
				row * FRAME_SIZE.y,
				FRAME_SIZE.x,
				FRAME_SIZE.y
			)
			frames.add_frame(anim_name, atlas)
