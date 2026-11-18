class_name KitchenStove
extends PlacedObject
## Phase 18: Dapur / Kompor Batu (Stone_Oven_1_16x16.png dari pack). E di depannya = buka panel MASAK
## (HUD/CookPanel, resep dengan station = "cook"). Saat berhasil memasak, cerobong mengeluarkan asap
## (Stone_Oven_Smoke_Effect_16x16.png, 8 frame 48x64).
## Satu Kompor Batu sudah dipasang di dekat rumah saat game baru; bisa juga dibuat (C) dan dipasang sendiri.

const SMOKE_SHEET := "res://assets/modern_farm/effects/Stone_Oven_Smoke_Effect_16x16.png"
const SMOKE_FRAME := Vector2i(48, 64)
const SMOKE_FRAMES := 8
const SMOKE_TIME := 3.0

@onready var smoke: AnimatedSprite2D = $Smoke

var _smoke_left := 0.0


func _ready() -> void:
	smoke.sprite_frames = _build_smoke()
	smoke.visible = false
	set_process(false)


func _build_smoke() -> SpriteFrames:
	var sheet: Texture2D = load(SMOKE_SHEET)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"smoke")
	frames.set_animation_speed(&"smoke", 8.0)
	frames.set_animation_loop(&"smoke", true)
	for i in SMOKE_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * SMOKE_FRAME.x, 0, SMOKE_FRAME.x, SMOKE_FRAME.y)
		frames.add_frame(&"smoke", atlas)
	return frames


## Main membuka panel masak; teks ini hanya dipakai jika panel tidak tersedia.
func interact() -> String:
	return "Dapur: tekan E untuk memasak."


## Asap mengepul beberapa detik (dipanggil Main setelah memasak).
func puff() -> void:
	_smoke_left = SMOKE_TIME
	smoke.visible = true
	smoke.modulate.a = 1.0
	smoke.play(&"smoke")
	set_process(true)


func _process(delta: float) -> void:
	_smoke_left -= delta
	if _smoke_left < 0.6:
		smoke.modulate.a = clampf(_smoke_left / 0.6, 0.0, 1.0)
	if _smoke_left <= 0.0:
		smoke.stop()
		smoke.visible = false
		set_process(false)


func display_name() -> String:
	return "Kompor Batu"
