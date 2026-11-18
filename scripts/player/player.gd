class_name Player
extends CharacterBody2D
## Player: CharacterBody2D, gerak 4 arah, animasi dari Farmer_1_16x16.png (frame 48x64).
## Sheet: baris 1 = idle, baris 2 = walk (24 frame = 4 arah x 6 frame),
## baris 5 = mencangkul (36 frame = 4 x 9), baris 7 = menyiram (56 frame = 4 x 14),
## baris 9 = mengayun kapak (40 frame = 4 x 10, dipakai Axe & Pickaxe).
## Urutan arah di tiap baris: kanan, atas, kiri, bawah.
## Phase 12: alat memakai stamina (GameManager), SPACE sambil memegang makanan = makan, suara langkah & alat.
## Phase 8: animasi memancing dari Farmer_1_Fishing_128_frames_16x16.png (32 frame per arah).
## Phase 17: di sheet asli, tubuh petani pada animasi aksi/memancing TIDAK berada di posisi yang sama
## dengan animasi idle (mis. cangkul geser 8 px ke kiri, memancing ke bawah naik 32 px). ANIM_OFFSETS
## menggeser AnimatedSprite2D.offset per animasi agar tubuh tetap diam di tempat (tidak "loncat").
## Efek (debu tanah, cipratan air, serpih kayu/batu, debu langkah) dari Vfx (scripts/effects/vfx.gd).

signal interact_requested(world_position: Vector2, facing: StringName)
## Dipancarkan saat alat mengenai tile target (pada hit_frame animasi, atau instan jika tanpa animasi).
signal tool_used(tool: ToolData, cell: Vector2i)
## Dipancarkan saat animasi panen mengenai tanaman di tile target (tombol E).
signal harvest_used(cell: Vector2i)
## Phase 14: SPACE sambil memegang item yang bisa dipasang (Sprinkler, Cheese Machine, Peti). Main yang memasang.
signal place_requested(item: ItemData, cell: Vector2i)
## Phase 8: SPACE ditekan sambil memegang Fishing Rod (ditangani FishingController lewat Main).
signal fish_requested
## Animasi memancing yang tidak berulang (fish_throw / fish_reel) selesai.
signal fishing_anim_finished(stage: StringName)

const SHEET_PATH := "res://assets/modern_farm/characters/Farmer_1_16x16.png"
const FISHING_SHEET_PATH := "res://assets/modern_farm/characters/Farmer_1_Fishing_128_frames_16x16.png"
const FISHING_FRAMES_PER_DIRECTION := 32
## Potongan sheet memancing per arah: frame awal, jumlah frame, fps, berulang?
##   0-8 Throw | 9-20 Idle (pelampung di air) | 21-22 Takes the bait | 23-31 Caught (tarik pancing)
const FISHING_ANIMS := {
	&"fish_throw": {"start": 0, "count": 9, "fps": 12.0, "loop": false},
	&"fish_wait": {"start": 9, "count": 12, "fps": 6.0, "loop": true},
	&"fish_bite": {"start": 21, "count": 2, "fps": 8.0, "loop": true},
	&"fish_reel": {"start": 23, "count": 9, "fps": 12.0, "loop": false},
}
const FRAME_SIZE := Vector2i(48, 64)
const FRAMES_PER_DIRECTION := 6
const ROW_IDLE := 1
const ROW_WALK := 2
const TILE := 16
## Animasi aksi: baris sheet, jumlah frame per arah, fps. Kunci = ToolData.animation.
const ACTION_ANIMS := {
	&"dig": {"row": 5, "frames": 9, "fps": 12.0},
	&"water": {"row": 7, "frames": 14, "fps": 14.0},
	&"harvest": {"row": 3, "frames": 9, "fps": 12.0},
	&"chop": {"row": 9, "frames": 10, "fps": 14.0},  # Phase 10: Axe & Pickaxe
}
const HARVEST_HIT_FRAME := 4
## Phase 17: geseran sprite (piksel) per animasi & arah agar tubuh sejajar dengan idle.
## Diukur dari sheet asli (template kepala dicocokkan dengan frame idle). Urutan: right, up, left, down.
const ANIM_OFFSETS := {
	&"dig": [Vector2(8, 0), Vector2(8, 2), Vector2(8, 0), Vector2(8, 7)],
	&"water": [Vector2(8, 2), Vector2(0, 1), Vector2(-8, 2), Vector2(0, 18)],
	&"chop": [Vector2(8, 5), Vector2(8, 5), Vector2(8, 5), Vector2(8, 8)],
	&"fish_throw": [Vector2(15, 10), Vector2(0, 0), Vector2(-15, 10), Vector2(0, 32)],
	&"fish_wait": [Vector2(15, 10), Vector2(0, 0), Vector2(-15, 10), Vector2(0, 32)],
	&"fish_bite": [Vector2(15, 10), Vector2(0, 0), Vector2(-15, 10), Vector2(0, 32)],
	&"fish_reel": [Vector2(15, 10), Vector2(0, 0), Vector2(-15, 10), Vector2(0, 32)],
}
## Phase 17: titik pelampung (relatif ke kaki player) saat menunggu ikan, sesudah ANIM_OFFSETS.
## Dipakai FishingController untuk mengecek air & memunculkan cipratan / riak tepat di pelampung.
const BOBBER_OFFSETS := {
	&"right": Vector2(34, 5),
	&"left": Vector2(-35, 5),
	&"up": Vector2(0, -42),
	&"down": Vector2(3, 27),
}
## Efek saat alat mengenai tile (ToolData.Kind -> Vfx.Kind).
const TOOL_FX := {
	ToolData.Kind.HOE: Vfx.Kind.DIRT,
	ToolData.Kind.WATERING_CAN: Vfx.Kind.WATER,
	ToolData.Kind.AXE: Vfx.Kind.WOOD,
	ToolData.Kind.PICKAXE: Vfx.Kind.STONE,
}
const FACING_VECTORS := {
	&"right": Vector2i(1, 0),
	&"left": Vector2i(-1, 0),
	&"up": Vector2i(0, -1),
	&"down": Vector2i(0, 1),
}
## Jika kiri/kanan terlihat terbalik di game, tukar "right" dan "left" di sini.
const DIRECTIONS: Array[StringName] = [&"right", &"up", &"left", &"down"]

const INTERACT_OFFSET := {
	&"right": Vector2(12, -6),
	&"left": Vector2(-12, -6),
	&"up": Vector2(0, -18),
	&"down": Vector2(0, 6),
}

@export var speed: float = 100.0
## Peta tanpa lahan (Village) mematikan alat lewat ini.
var can_use_tools: bool = true
@export var idle_fps: float = 6.0
@export var walk_fps: float = 10.0

var facing: StringName = &"down"
## Phase 19: traktor yang sedang dikendarai (null = jalan kaki).
var vehicle: Tractor
var _foot_shape: Shape2D
## True selama memancing: player diam dan input diatur FishingController.
var fishing: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

## Diisi FarmMap: Callable(cell: Vector2i) -> bool, true jika ada tanaman siap panen di tile itu.
var harvest_check: Callable

var _busy := false  # sedang memainkan animasi alat
var _action_hit_frame := 0
var _action_tool: ToolData
var _action_cell := Vector2i.ZERO
var _hit_done := false


func _ready() -> void:
	# Animasi tersimpan di farmer_1_frames.tres (lihat AnimatedSprite2D > Sprite Frames di editor).
	# Jika kosong, animasi dibuat ulang dari sheet lewat kode (_build_sprite_frames).
	if sprite.sprite_frames == null:
		sprite.sprite_frames = _build_sprite_frames()
	# Phase 18: bayangan elips di kaki (seperti gambar referensi), digambar di bawah sprite.
	var shadow := Vfx.shadow(12, Vector2(0, -1))
	add_child(shadow)
	move_child(shadow, 0)
	_update_interaction_area()
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_changed.connect(_apply_anim_offset)
	sprite.animation_finished.connect(_on_animation_finished)
	_play(&"idle")
	_apply_anim_offset()


## Phase 17: sejajarkan tubuh (lihat ANIM_OFFSETS). Dipanggil otomatis tiap animasi berganti.
func _apply_anim_offset() -> void:
	var anim := String(sprite.animation)
	var cut := anim.rfind("_")
	if cut < 0:
		sprite.offset = Vector2.ZERO
		return
	var state := StringName(anim.substr(0, cut))
	var dir_index := DIRECTIONS.find(StringName(anim.substr(cut + 1)))
	if ANIM_OFFSETS.has(state) and dir_index >= 0:
		sprite.offset = (ANIM_OFFSETS[state] as Array)[dir_index]
	else:
		sprite.offset = Vector2.ZERO


## Titik pelampung pancing (koordinat global) untuk arah hadap sekarang.
func bobber_position() -> Vector2:
	return global_position + (BOBBER_OFFSETS[facing] as Vector2)


## Jeda antar suara langkah (detik).
const STEP_INTERVAL := 0.32
## Suara alat (AudioManager.play_sfx) menurut ToolData.Kind.
const TOOL_SFX := {
	ToolData.Kind.HOE: "hoe",
	ToolData.Kind.WATERING_CAN: "water",
	ToolData.Kind.SEEDS: "seed",
	ToolData.Kind.AXE: "hit_wood",
	ToolData.Kind.PICKAXE: "hit_stone",
}

var _step_timer := 0.0


func _physics_process(delta: float) -> void:
	if vehicle != null:
		_drive()
		return
	if _busy or fishing:
		velocity = Vector2.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed * GameManager.speed_multiplier()  # Phase 18: bonus makanan
	move_and_slide()

	if input_vector != Vector2.ZERO:
		_update_facing(input_vector)
		_play(&"walk")
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = STEP_INTERVAL
			AudioManager.play_sfx("step", 0.1, -8.0)
			Vfx.burst(get_parent(), position + Vector2(0, -1), Vfx.Kind.STEP)  # debu langkah halus
	else:
		_play(&"idle")


func _unhandled_input(event: InputEvent) -> void:
	if fishing:
		return
	if vehicle != null:  # Phase 19: di atas traktor: E = turun (Main), SPACE = ganti alat
		if event.is_action_pressed("interact"):
			interact_requested.emit(global_position + INTERACT_OFFSET[facing], facing)
		elif event.is_action_pressed("tool_use"):
			InventoryManager.message.emit(vehicle.toggle_mode())
		return
	if event.is_action_pressed("interact"):
		interact_requested.emit(global_position + INTERACT_OFFSET[facing], facing)
		_try_harvest()
	elif event.is_action_pressed("tool_use"):
		_use_current_tool()


# ---------------------------------------------------------------- traktor (Phase 19)

## Mulai mengemudi: sprite & bayangan player disembunyikan, badan tabrakan dibesarkan selebar traktor.
func start_driving(tractor: Tractor) -> void:
	vehicle = tractor
	velocity = Vector2.ZERO
	sprite.visible = false
	var shadow := get_node_or_null("Shadow")
	if shadow != null:
		shadow.visible = false
	var col := get_node("CollisionShape2D") as CollisionShape2D
	_foot_shape = col.shape
	var big := RectangleShape2D.new()
	big.size = Vector2(28, 12)
	col.shape = big


func stop_driving() -> void:
	vehicle = null
	sprite.visible = true
	var shadow := get_node_or_null("Shadow")
	if shadow != null:
		shadow.visible = true
	var col := get_node("CollisionShape2D") as CollisionShape2D
	if _foot_shape != null:
		col.shape = _foot_shape
	_play(&"idle")


func _drive() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Traktor hanya bergerak lurus 4 arah (tidak diagonal) agar sesuai sprite.
	if absf(input_vector.x) >= absf(input_vector.y):
		input_vector.y = 0.0
	else:
		input_vector.x = 0.0
	input_vector = input_vector.normalized()
	velocity = input_vector * Tractor.DRIVE_SPEED * GameManager.speed_multiplier()
	move_and_slide()
	if input_vector != Vector2.ZERO:
		_update_facing(input_vector)
	vehicle.drive_update(self, input_vector)


## Tile (koordinat grid) tepat di depan player.
func get_target_cell() -> Vector2i:
	var body_center := global_position + Vector2(0, -4)
	var cell := Vector2i((body_center / TILE).floor())
	return cell + FACING_VECTORS[facing]


func _try_harvest() -> void:
	if _busy or not harvest_check.is_valid():
		return
	var cell := get_target_cell()
	if not harvest_check.call(cell):
		return
	_start_action(null, cell, HARVEST_HIT_FRAME, StringName("harvest_%s" % facing))


func _start_action(tool: ToolData, cell: Vector2i, hit_frame: int, anim_name: StringName) -> void:
	if not sprite.sprite_frames.has_animation(anim_name):
		push_warning("Animasi tidak ada: %s" % anim_name)
		return
	_action_tool = tool
	_action_cell = cell
	_action_hit_frame = hit_frame
	_hit_done = false
	_busy = true
	velocity = Vector2.ZERO
	sprite.play(anim_name)


func _emit_hit() -> void:
	_hit_done = true
	if _action_tool != null:
		AudioManager.play_sfx(TOOL_SFX.get(_action_tool.kind, ""))
		_play_hit_fx(_action_tool.kind)
		tool_used.emit(_action_tool, _action_cell)
	else:
		AudioManager.play_sfx("harvest")
		harvest_used.emit(_action_cell)


## Phase 17: efek di titik kena alat. Cangkul & siram = tengah tile target; Axe / Pickaxe = titik interaksi.
func _play_hit_fx(kind: int) -> void:
	if not TOOL_FX.has(kind):
		return
	var pos := Vector2(_action_cell * TILE) + Vector2(TILE / 2.0, TILE / 2.0 + 2.0)
	if kind == ToolData.Kind.AXE or kind == ToolData.Kind.PICKAXE:
		pos = position + (INTERACT_OFFSET[facing] as Vector2) + Vector2(0, -4)
	var up := Vector2.UP
	if facing == &"right":
		up = Vector2(0.5, -1).normalized()
	elif facing == &"left":
		up = Vector2(-0.5, -1).normalized()
	Vfx.burst(get_parent(), pos, TOOL_FX[kind], up)


func _use_current_tool() -> void:
	if _busy:
		return
	var tool := InventoryManager.current_tool()
	var held := InventoryManager.current_item()
	if tool == null and held != null and held.is_placeable():
		place_requested.emit(held, get_target_cell())  # Phase 14: pasang mesin
		return
	if tool == null:
		if GameManager.eat_selected():  # makanan: SPACE = makan
			AudioManager.play_sfx("eat")
		return
	# Alat pertanian hanya di Farm; pancing, Axe, Pickaxe boleh di mana saja.
	var farm_tool := tool.kind == ToolData.Kind.HOE or tool.kind == ToolData.Kind.WATERING_CAN or tool.kind == ToolData.Kind.SEEDS
	if farm_tool and not can_use_tools:
		return
	var cell := get_target_cell()
	if tool.kind == ToolData.Kind.FISHING_ROD:
		fish_requested.emit()  # memancing boleh di peta mana pun yang punya air (stamina dipotong saat melempar)
		return
	if not GameManager.use_stamina(tool.stamina_cost):
		return
	if tool.animation == &"":
		tool_used.emit(tool, cell)
		return
	_start_action(tool, cell, tool.hit_frame, StringName("%s_%s" % [tool.animation, facing]))


func _on_frame_changed() -> void:
	if _busy and not _hit_done and sprite.frame >= _action_hit_frame:
		_emit_hit()


## Memainkan animasi memancing (fish_throw / fish_wait / fish_bite / fish_reel) ke arah hadap.
func play_fishing(stage: StringName) -> void:
	fishing = true
	velocity = Vector2.ZERO
	sprite.play(StringName("%s_%s" % [stage, facing]))


func stop_fishing() -> void:
	fishing = false
	_play(&"idle")


func _on_animation_finished() -> void:
	if fishing:
		var anim := String(sprite.animation)
		fishing_anim_finished.emit(StringName(anim.substr(0, anim.rfind("_"))))
		return
	if not _busy:
		return
	if not _hit_done:
		_emit_hit()
	_busy = false
	_action_tool = null
	_play(&"idle")


func _update_facing(input_vector: Vector2) -> void:
	var new_facing: StringName
	if absf(input_vector.x) >= absf(input_vector.y):
		new_facing = &"right" if input_vector.x > 0.0 else &"left"
	else:
		new_facing = &"down" if input_vector.y > 0.0 else &"up"
	if new_facing != facing:
		facing = new_facing
		_update_interaction_area()


func _update_interaction_area() -> void:
	interaction_area.position = INTERACT_OFFSET[facing]


func _play(state: StringName) -> void:
	var anim_name := StringName("%s_%s" % [state, facing])
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)


func _build_sprite_frames() -> SpriteFrames:
	var sheet: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	_add_animations(frames, sheet, "idle", ROW_IDLE, FRAMES_PER_DIRECTION, idle_fps, true)
	_add_animations(frames, sheet, "walk", ROW_WALK, FRAMES_PER_DIRECTION, walk_fps, true)
	for action: StringName in ACTION_ANIMS:
		var info: Dictionary = ACTION_ANIMS[action]
		_add_animations(frames, sheet, String(action), info["row"], info["frames"], info["fps"], false)
	_add_fishing_animations(frames)
	return frames


func _add_fishing_animations(frames: SpriteFrames) -> void:
	var sheet: Texture2D = load(FISHING_SHEET_PATH)
	for stage: StringName in FISHING_ANIMS:
		var info: Dictionary = FISHING_ANIMS[stage]
		for dir_index in DIRECTIONS.size():
			var anim_name := StringName("%s_%s" % [stage, DIRECTIONS[dir_index]])
			frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, info["fps"])
			frames.set_animation_loop(anim_name, info["loop"])
			for i in int(info["count"]):
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.filter_clip = true
				var frame_index: int = dir_index * FISHING_FRAMES_PER_DIRECTION + int(info["start"]) + i
				atlas.region = Rect2(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
				frames.add_frame(anim_name, atlas)


func _add_animations(frames: SpriteFrames, sheet: Texture2D, state: String, row: int, count: int, fps: float, loop: bool) -> void:
	for dir_index in DIRECTIONS.size():
		var anim_name := StringName("%s_%s" % [state, DIRECTIONS[dir_index]])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, loop)
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.filter_clip = true
			atlas.region = Rect2(
				(dir_index * count + i) * FRAME_SIZE.x,
				row * FRAME_SIZE.y,
				FRAME_SIZE.x,
				FRAME_SIZE.y
			)
			frames.add_frame(anim_name, atlas)
