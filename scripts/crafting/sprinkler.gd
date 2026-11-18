class_name Sprinkler
extends PlacedObject
## Phase 14: Sprinkler. Setiap pagi otomatis menyiram 4 tile tanah olahan di sekitarnya
## (atas, bawah, kiri, kanan). Animasi dari Sprinkler_Anim_16x16.png (frame 48x48, baris 0):
##   0-5 menyala, 6-10 mulai menyemprot, 11-15 menyemprot (loop), 16-20 berhenti, 21-27 mati.
## E = lihat info + animasi menyemprot sebentar.

const SHEET := "res://assets/modern_farm/objects/machines/Sprinkler_Anim_16x16.png"
const FRAME := Vector2i(48, 48)
const SPRAY_TIME := 3.0
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _spray_left := 0.0


func _ready() -> void:
	sprite.sprite_frames = _build_frames()
	sprite.play(&"idle")


func _build_frames() -> SpriteFrames:
	var sheet: Texture2D = load(SHEET)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: Array in [[&"idle", 0, 1, 1.0, false], [&"start", 6, 5, 10.0, false], [&"spray", 11, 5, 10.0, true]]:
		frames.add_animation(anim[0])
		frames.set_animation_speed(anim[0], anim[3])
		frames.set_animation_loop(anim[0], anim[4])
		for i in int(anim[2]):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2((int(anim[1]) + i) * FRAME.x, 0, FRAME.x, FRAME.y)
			frames.add_frame(anim[0], atlas)
	return frames


## Tile yang disiram sprinkler ini.
func target_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in NEIGHBORS:
		result.append(anchor + d)
	return result


func on_day_started() -> void:
	var watered := 0
	for cell in target_cells():
		if farm.soil.water_cell(cell):
			watered += 1
	if watered > 0:
		spray()


func interact() -> String:
	spray()
	return "Sprinkler: menyiram 4 tile tanah di atas, bawah, kiri, dan kanannya setiap pagi."


## Animasi menyemprot beberapa detik.
func spray() -> void:
	_spray_left = SPRAY_TIME
	sprite.play(&"start")
	if not sprite.animation_finished.is_connected(_on_anim_finished):
		sprite.animation_finished.connect(_on_anim_finished)
	set_process(true)


func _on_anim_finished() -> void:
	if sprite.animation == &"start":
		sprite.play(&"spray")


func _process(delta: float) -> void:
	if _spray_left <= 0.0:
		set_process(false)
		return
	_spray_left -= delta
	if _spray_left <= 0.0:
		sprite.play(&"idle")
		set_process(false)
