class_name Tractor
extends Node2D
## Phase 19: traktor di Farm yang bisa dikendarai (upgrade tahap lanjut).
## Sprite: Tractor_16x16.png asli pack (frame 96x96, 6 kolom x 5 baris):
##   baris 1 = jalan ke kanan, 2 = ke atas, 3 = ke kiri, 4 = ke bawah (6 frame, ada asap knalpot).
## Awalnya RUSAK: perbaiki di PAPAN FARM (FarmServices.tractor_level).
##   E di dekat traktor = naik / turun.  WASD = jalan (lebih cepat dari jalan kaki).
##   SPACE = ganti alat: Mati -> Bajak (mencangkul 3 petak di belakang traktor)
##           -> Bajak + Siram (setelah upgrade penyiram) -> Mati.
## Hanya mencangkul di lahan pertanian (FarmMap.is_farm_plot) dan tidak memakai stamina.
## Saat dikendarai, node ini mengikuti posisi Player (sprite player disembunyikan).

const SHEET := preload("res://assets/modern_farm/objects/vehicles/Tractor_16x16.png")
const FRAME := Vector2i(96, 96)
const DRIVE_FRAMES := 6
const DIRECTIONS: Array[StringName] = [&"right", &"up", &"left", &"down"]
## Geser sprite agar roda menempel di titik node (diukur dari sheet).
const OFFSETS := {
	&"right": Vector2(-1, -44), &"left": Vector2(1, -44),
	&"up": Vector2(-1, -40), &"down": Vector2(-1, -40),
}
## Ukuran tabrakan saat diparkir (samping / depan-belakang).
const BODY_SIDE := Vector2(70, 18)
const BODY_FRONT := Vector2(40, 26)
const DRIVE_SPEED := 150.0
const REAR_DISTANCE := 26.0

enum Mode { OFF, PLOW, PLOW_WATER }
const MODE_NAMES := ["Alat mati", "Bajak", "Bajak + Siram"]

@export var facing: StringName = &"right"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body: StaticBody2D = $StaticBody2D
@onready var shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

var farm: FarmMap
var driver: Player
var mode: Mode = Mode.OFF
var _worked: Dictionary = {}  # tile yang baru saja dikerjakan (supaya tidak diulang tiap frame)


func _ready() -> void:
	sprite.sprite_frames = _build_frames()
	_park_visual()


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for i in DIRECTIONS.size():
		var row := i + 1
		for anim: String in ["idle", "drive"]:
			var anim_name := StringName("%s_%s" % [anim, DIRECTIONS[i]])
			frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, 10.0)
			frames.set_animation_loop(anim_name, true)
			var count := 1 if anim == "idle" else DRIVE_FRAMES
			for f in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = SHEET
				atlas.region = Rect2(f * FRAME.x, row * FRAME.y, FRAME.x, FRAME.y)
				frames.add_frame(anim_name, atlas)
	return frames


func is_driven() -> bool:
	return driver != null


## Titik interaksi player mengenai traktor yang diparkir?
func is_at(world_pos: Vector2) -> bool:
	if driver != null:
		return false
	var size := (BODY_SIDE if _is_side() else BODY_FRONT) + Vector2(12, 26)
	return Rect2(global_position + Vector2(-size.x / 2.0, -size.y + 6), size).has_point(world_pos)


func _is_side() -> bool:
	return facing == &"right" or facing == &"left"


func _park_visual() -> void:
	sprite.play(StringName("idle_%s" % facing))
	sprite.offset = OFFSETS[facing]
	var rect := RectangleShape2D.new()
	rect.size = BODY_SIDE if _is_side() else BODY_FRONT
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y / 2.0)
	shape.set_deferred("disabled", false)


# ---------------------------------------------------------------- naik / turun

func mount(player: Player) -> void:
	driver = player
	mode = Mode.OFF
	_worked.clear()
	shape.set_deferred("disabled", true)
	player.global_position = global_position
	player.facing = facing
	player.start_driving(self)


## Turun: player diletakkan di samping traktor. Mengembalikan posisi turun.
func dismount() -> Vector2:
	if driver == null:
		return global_position
	var p := driver
	driver = null
	mode = Mode.OFF
	facing = p.facing
	global_position = p.global_position.round()
	var side := Vector2(0, 14) if _is_side() else Vector2(26, 0)
	p.stop_driving()
	p.global_position = global_position + side
	_park_visual()
	return p.global_position


## Dipanggil Player tiap physics frame saat mengemudi.
func drive_update(player: Player, input: Vector2) -> void:
	global_position = player.global_position
	facing = player.facing
	var anim := StringName("%s_%s" % ["drive" if input != Vector2.ZERO else "idle", facing])
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.offset = OFFSETS[facing]
	if mode != Mode.OFF and input != Vector2.ZERO and farm != null:
		_work()


## SPACE: ganti alat. Mengembalikan teks untuk toast.
func toggle_mode() -> String:
	var max_mode := Mode.PLOW_WATER if FarmServices.tractor_level >= 2 else Mode.PLOW
	mode = ((int(mode) + 1) % (int(max_mode) + 1)) as Mode
	_worked.clear()
	AudioManager.play_sfx("ui_select")
	if mode == Mode.OFF:
		return "Traktor: alat dimatikan."
	return "Traktor: %s aktif. Jalan di lahan pertanian untuk mengolah tanah." % MODE_NAMES[mode]


## Cangkul (dan siram) 3 petak di belakang traktor: tengah + kiri + kanan (tegak lurus arah jalan).
func _work() -> void:
	var dir: Vector2i = Player.FACING_VECTORS[facing]
	var rear := global_position + Vector2(-dir) * REAR_DISTANCE + Vector2(0, -6)
	var center := Vector2i((rear / TerrainTiles.TILE).floor())
	var perp := Vector2i(absi(dir.y), absi(dir.x))
	for c: Vector2i in [center - perp, center, center + perp]:
		if _worked.has(c):
			continue
		_worked[c] = true
		var done := false
		if farm.soil.till_quiet(c):
			done = true
			Vfx.burst(get_parent(), Vector2(c * TerrainTiles.TILE) + Vector2(8, 10), Vfx.Kind.DIRT)
		if mode == Mode.PLOW_WATER and farm.soil.water_cell(c):
			done = true
			Vfx.burst(get_parent(), Vector2(c * TerrainTiles.TILE) + Vector2(8, 10), Vfx.Kind.WATER)
		if done:
			AudioManager.play_sfx("hoe", 0.15, -10.0)
	if _worked.size() > 60:
		_worked.clear()


# ---------------------------------------------------------------- simpan

func to_save() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y, "facing": String(facing)}


func from_save(d: Dictionary) -> void:
	if d.is_empty():
		return
	global_position = Vector2(float(d.get("x", global_position.x)), float(d.get("y", global_position.y)))
	facing = StringName(String(d.get("facing", "right")))
	if is_node_ready():
		_park_visual()
