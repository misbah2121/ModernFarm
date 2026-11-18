class_name PetDog
extends CharacterBody2D
## Phase 20: ANJING PELIHARAAN (Labrador coklat) di Farm. Data (nama, hati, makan) ada di AnimalManager.
## Sprite: Dog_Labrador_Brown_16x16.png asli pack, frame 48x32, 24 kolom (kanan, atas, kiri, bawah x 6):
##   y 64 = diam, 128 = jalan, 192 = lari, 256 = makan, 320 = menggonggong (3 frame per arah).
## Tidur: Dogs_Doghouse_Sleeping_16x16.png (frame 32x48, baris 0 = Labrador coklat) menggantikan gambar
## rumah anjing (node "Doghouse" di Objects) setiap malam (20:00 - 06:00) dan saat hujan.
## Perilaku siang: makan jika mangkuk terisi -> mengikuti player di Farm -> kalau player jauh, jalan-jalan
## di dekat rumahnya. Kadang menggonggong. E = elus (hati naik). Mangkuk: E sambil memegang Makanan Anjing.
## Hati >= 3: pagi hari kadang membawa barang temuan (jatuh di tanah sebagai ItemPickup).

const SHEET := preload("res://assets/modern_farm/animals/Dog_Labrador_Brown_16x16.png")
const SLEEP_SHEET := preload("res://assets/modern_farm/animals/dog/Dogs_Doghouse_Sleeping_16x16.png")
const BOWL_EMPTY := preload("res://assets/modern_farm/animals/dog/Dog_Bowl_Red_Empty_16x16.png")
const BOWL_FULL := preload("res://assets/modern_farm/animals/dog/Dog_Bowl_Red_Full_16x16.png")
const HEART := preload("res://assets/modern_farm/icons/Icon_Heart_9x8.png")
const FRAME := Vector2i(48, 32)
const DIRECTIONS: Array[StringName] = [&"right", &"up", &"left", &"down"]
## state, y di sheet, frame per arah, fps, berulang
const ANIMS := [
	[&"idle", 64, 6, 6.0, true], [&"walk", 128, 6, 9.0, true], [&"run", 192, 6, 12.0, true],
	[&"eat", 256, 6, 7.0, true], [&"bark", 320, 3, 8.0, false],
]
const WALK_SPEED := 40.0
const RUN_SPEED := 115.0
const FOLLOW_RANGE := 170.0      # player sejauh ini (px) = diikuti
const NEAR := 26.0               # jarak nyaman di samping player
const WANDER_RADIUS := 56.0
const SLEEP_FROM := 20
const WAKE_AT := 6

enum Mode { IDLE, WANDER, FOLLOW, GO_EAT, EAT, BARK, SLEEP }

var farm: FarmMap
var doghouse: Node2D
var bowl: Sprite2D

var _sprite: AnimatedSprite2D
var _shadow: Sprite2D
var _sleep_sprite: AnimatedSprite2D
var _mode: Mode = Mode.IDLE
var _facing: StringName = &"down"
var _timer := 1.0
var _bark_timer := 10.0
var _target := Vector2.ZERO
var _stuck := 0.0
var _last_pos := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2   # player (mask 1) bisa menembus anjing
	collision_mask = 1
	_shadow = Vfx.shadow(16, Vector2(0, -1))
	add_child(_shadow)
	_sprite = $AnimatedSprite2D
	_sprite.sprite_frames = _build_frames()
	_sprite.offset = Vector2(0, -16)
	_sprite.animation_finished.connect(_on_anim_finished)
	_play(&"idle")


## Dipanggil FarmMap setelah semua node siap.
func setup(p_farm: FarmMap) -> void:
	farm = p_farm
	doghouse = farm.objects.get_node_or_null("Doghouse") as Node2D
	if doghouse != null:
		_make_bowl()
		_make_sleep_sprite()
	AnimalManager.changed.connect(_refresh_bowl)
	TimeManager.day_started.connect(func(_d: int) -> void: _on_new_day())
	_refresh_bowl()
	_update_sleep(true)


func _make_bowl() -> void:
	bowl = Sprite2D.new()
	bowl.name = "DogBowl"
	bowl.centered = false
	bowl.position = doghouse.position + Vector2(18, -6)  # kanan depan rumah anjing
	farm.objects.add_child(bowl)


func _make_sleep_sprite() -> void:
	var house_sprite := doghouse.get_node_or_null("Sprite2D") as Sprite2D
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"sleep")
	frames.set_animation_speed(&"sleep", 3.0)
	for i in 8:
		var atlas := AtlasTexture.new()
		atlas.atlas = SLEEP_SHEET
		atlas.region = Rect2(i * 32, 0, 32, 48)
		frames.add_frame(&"sleep", atlas)
	_sleep_sprite = AnimatedSprite2D.new()
	_sleep_sprite.sprite_frames = frames
	_sleep_sprite.centered = false
	_sleep_sprite.position = (house_sprite.position if house_sprite != null else Vector2(-16, -48)) + Vector2(0, 1)
	_sleep_sprite.visible = false
	doghouse.add_child(_sleep_sprite)


func _refresh_bowl() -> void:
	if bowl != null:
		bowl.texture = BOWL_FULL if AnimalManager.bowl_full else BOWL_EMPTY


# ---------------------------------------------------------------- tidur

func should_sleep() -> bool:
	var h := TimeManager.hour()
	return h >= SLEEP_FROM or h < WAKE_AT or TimeManager.is_raining()


func _update_sleep(force := false) -> void:
	var sleep := should_sleep()
	if not force and sleep == (_mode == Mode.SLEEP):
		return
	if sleep:
		_mode = Mode.SLEEP
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		if doghouse != null:
			global_position = doghouse.global_position + Vector2(0, 14)
			_set_house_sleeping(true)
	else:
		_mode = Mode.IDLE
		_timer = 0.5
		visible = true
		$CollisionShape2D.set_deferred("disabled", false)
		_set_house_sleeping(false)
		_play(&"idle")


func _set_house_sleeping(on: bool) -> void:
	if _sleep_sprite == null:
		return
	_sleep_sprite.visible = on
	if on:
		_sleep_sprite.play(&"sleep")
	var house_sprite := doghouse.get_node_or_null("Sprite2D") as Sprite2D
	if house_sprite != null:
		house_sprite.visible = not on


func is_sleeping() -> bool:
	return _mode == Mode.SLEEP


# ---------------------------------------------------------------- perilaku

func _physics_process(delta: float) -> void:
	_update_sleep()
	if _mode == Mode.SLEEP or farm == null:
		return
	var player := farm.player
	var on_farm := player != null and player.is_inside_tree()
	match _mode:
		Mode.EAT, Mode.BARK:
			_timer -= delta
			if _timer <= 0.0 and _mode == Mode.EAT:
				AnimalManager.dog_eat()
				_mode = Mode.IDLE
			return
		Mode.GO_EAT:
			var spot := bowl.position + Vector2(8, 22)  # berdiri di depan mangkuk
			if global_position.distance_to(_last_pos) < 0.3:
				_stuck += delta
				if _stuck > 1.5:
					global_position = spot  # terhalang -> langsung ke mangkuk
			else:
				_stuck = 0.0
			_last_pos = global_position
			if _move_to(spot, WALK_SPEED * 1.6, delta):
				_facing = &"up"
				_stuck = 0.0
				_mode = Mode.EAT
				_timer = 3.0
				_play(&"eat")
			return
	# mangkuk terisi -> pergi makan
	if AnimalManager.bowl_full and not AnimalManager.dog_fed and bowl != null:
		_mode = Mode.GO_EAT
		return
	var dist := global_position.distance_to(player.global_position) if on_farm else INF
	if on_farm and dist < FOLLOW_RANGE and player.vehicle == null:
		_follow(player, dist, delta)
	else:
		_wander(delta)
	_bark_timer -= delta
	if _bark_timer <= 0.0 and (_mode == Mode.IDLE):
		_bark_timer = _rng.randf_range(12.0, 25.0)
		_bark()


func _follow(player: Player, dist: float, delta: float) -> void:
	# berdiri sedikit di belakang / samping player
	var side := Vector2(-24, 4) if player.facing != &"left" else Vector2(24, 4)
	var goal := player.global_position + side
	if dist > NEAR + 30.0 or (_mode == Mode.FOLLOW and global_position.distance_to(goal) > 6.0):
		_mode = Mode.FOLLOW
		var speed := RUN_SPEED if dist > 70.0 else WALK_SPEED * 1.4
		if _move_to(goal, speed, delta):
			_mode = Mode.IDLE
			_timer = 1.0
		# macet di balik pagar lama-lama -> lompat ke dekat player
		if global_position.distance_to(_last_pos) < 0.3:
			_stuck += delta
			if _stuck > 2.0 and dist > 60.0:
				global_position = goal
				_stuck = 0.0
		else:
			_stuck = 0.0
		_last_pos = global_position
	else:
		_mode = Mode.IDLE
		_face(player.global_position - global_position)
		_play(&"idle")


func _wander(delta: float) -> void:
	var home := doghouse.global_position + Vector2(0, 18) if doghouse != null else global_position
	if _mode == Mode.WANDER:
		if _move_to(_target, WALK_SPEED, delta) or get_slide_collision_count() > 0:
			_mode = Mode.IDLE
			_timer = _rng.randf_range(2.0, 5.0)
			_play(&"idle")
		return
	if _mode == Mode.FOLLOW:
		_mode = Mode.IDLE
	_timer -= delta
	_play(&"idle")
	if _timer <= 0.0:
		_target = home + Vector2(_rng.randf_range(-WANDER_RADIUS, WANDER_RADIUS), _rng.randf_range(0, WANDER_RADIUS * 0.6))
		_mode = Mode.WANDER


## Gerak menuju titik. true jika sudah sampai.
func _move_to(goal: Vector2, speed: float, _delta: float) -> bool:
	var to := goal - global_position
	if to.length() < 3.0:
		velocity = Vector2.ZERO
		return true
	velocity = to.normalized() * speed
	_face(velocity)
	move_and_slide()
	_play(&"run" if speed > 80.0 else &"walk")
	return false


func _bark() -> void:
	_mode = Mode.BARK
	_timer = 0.5
	_play(&"bark", true)


func _on_anim_finished() -> void:
	if _mode == Mode.BARK:
		_mode = Mode.IDLE
		_play(&"idle")


func _face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if absf(dir.x) >= absf(dir.y):
		_facing = &"right" if dir.x > 0.0 else &"left"
	else:
		_facing = &"down" if dir.y > 0.0 else &"up"


func _play(state: StringName, restart := false) -> void:
	var anim := StringName("%s_%s" % [state, _facing])
	if restart or _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for a: Array in ANIMS:
		var count: int = a[2]
		for d in DIRECTIONS.size():
			var anim := StringName("%s_%s" % [a[0], DIRECTIONS[d]])
			frames.add_animation(anim)
			frames.set_animation_speed(anim, a[3])
			frames.set_animation_loop(anim, a[4])
			for i in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = SHEET
				atlas.filter_clip = true
				atlas.region = Rect2((d * count + i) * FRAME.x, int(a[1]), FRAME.x, FRAME.y)
				frames.add_frame(anim, atlas)
	return frames


# ---------------------------------------------------------------- interaksi

## Titik interaksi player mengenai anjing?
func is_at(world_pos: Vector2) -> bool:
	return visible and (global_position + Vector2(0, -8)).distance_to(world_pos) < 16.0


func bowl_at(world_pos: Vector2) -> bool:
	return bowl != null and Rect2(bowl.global_position, Vector2(16, 16)).grow(3.0).has_point(world_pos)


func house_at(world_pos: Vector2) -> bool:
	return doghouse != null and Rect2(doghouse.global_position + Vector2(-16, -44), Vector2(32, 44)).has_point(world_pos)


## E: elus. Anjing menoleh ke player, menggonggong senang, dan muncul hati.
func pet(player_pos: Vector2) -> String:
	var first := not AnimalManager.dog_petted
	var text := AnimalManager.pet_dog()
	_face(player_pos - global_position)
	_bark()
	if first:
		Vfx.pop_icon(get_parent(), position + Vector2(0, -26), HEART)
	return text


func _on_new_day() -> void:
	var found := AnimalManager.dog_new_day()
	if found == null or doghouse == null:
		return
	var pos := doghouse.position + Vector2(_rng.randf_range(-14, 14), 22)
	ItemPickup.drop(farm.objects, pos, found, 1, 6.0)
	farm.soil.message.emit("%s membawa %s untukmu! (di dekat rumah anjing)" % [AnimalManager.dog_name, found.item_name])
