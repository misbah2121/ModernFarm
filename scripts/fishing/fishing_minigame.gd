class_name FishingMinigame
extends Control
## Mini game memancing (Phase 8). Bilah vertikal: ikan bergerak naik-turun, player menahan
## SPACE / E / klik kiri untuk menaikkan zona hijau (dilepas = zona turun).
## Selama ikan di dalam zona, meteran tangkap terisi; di luar zona meteran berkurang.
## Meteran penuh = ikan tertangkap, kosong = ikan lolos. ESC = menyerah.
## Digambar lewat _draw. Kesulitan diambil dari FishData.difficulty.

signal finished(success: bool)

const PANEL_SIZE := Vector2(84, 188)
const TRACK_H := 128.0
const TRACK_W := 20.0
const METER_W := 6.0
const ICON_SIZE := 16.0

const ZONE_UP_ACCEL := 320.0     # px/s^2 saat tombol ditahan
const ZONE_GRAVITY := 260.0      # px/s^2 saat dilepas
const ZONE_MAX_SPEED := 170.0
const START_PROGRESS := 0.35

const COL_TRACK := Color(0.12, 0.28, 0.42)
const COL_ZONE := Color(0.45, 0.95, 0.45, 0.55)
const COL_ZONE_ON := Color(0.6, 1.0, 0.6, 0.75)
const COL_GOLD := UiTheme.TITLE

var active := false

var _fish: FishData
var _difficulty := 0.0  # 0..1
var _zone_h := 36.0
var _zone_y := 0.0      # atas zona, 0 = puncak track
var _zone_vel := 0.0
var _fish_y := 0.0      # tengah ikan
var _fish_target := 0.0
var _fish_speed := 30.0
var _fish_timer := 0.0
var _progress := START_PROGRESS
var _in_zone := false
var _rng := RandomNumberGenerator.new()


var _skin: UiTheme.UiSkin  # gaya panel dari asset RPG UI

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	_rng.randomize()


func start(fish: FishData) -> void:
	_fish = fish
	_difficulty = clampf(fish.difficulty / 100.0, 0.0, 1.0)
	_zone_h = roundf(lerpf(44.0, 24.0, _difficulty))
	if GameManager.has_buff("fishing"):  # Phase 18: bonus makanan = zona hijau lebih besar
		_zone_h += 12.0
	_zone_y = TRACK_H - _zone_h
	_zone_vel = 0.0
	_fish_y = TRACK_H * 0.5
	_fish_target = _fish_y
	_fish_timer = 0.5
	_progress = START_PROGRESS
	active = true
	visible = true
	set_process(true)
	queue_redraw()


## Menghentikan mini game tanpa hasil (mis. player tertidur).
func stop() -> void:
	active = false
	visible = false
	set_process(false)


func _end(success: bool) -> void:
	stop()
	finished.emit(success)


func _holding() -> bool:
	return Input.is_action_pressed("tool_use") or Input.is_action_pressed("interact") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _process(delta: float) -> void:
	if not active:
		return
	_update_zone(delta)
	_update_fish(delta)
	_in_zone = _fish_y >= _zone_y and _fish_y <= _zone_y + _zone_h
	if _in_zone:
		_progress += lerpf(0.42, 0.26, _difficulty) * delta
	else:
		_progress -= lerpf(0.16, 0.30, _difficulty) * delta
	queue_redraw()
	if _progress >= 1.0:
		_end(true)
	elif _progress <= 0.0:
		_end(false)


func _update_zone(delta: float) -> void:
	_zone_vel += (-ZONE_UP_ACCEL if _holding() else ZONE_GRAVITY) * delta
	_zone_vel = clampf(_zone_vel, -ZONE_MAX_SPEED, ZONE_MAX_SPEED)
	_zone_y += _zone_vel * delta
	var bottom := TRACK_H - _zone_h
	if _zone_y > bottom:
		_zone_y = bottom
		_zone_vel = -_zone_vel * 0.3  # memantul sedikit di dasar
	elif _zone_y < 0.0:
		_zone_y = 0.0
		_zone_vel = 0.0


func _update_fish(delta: float) -> void:
	_fish_timer -= delta
	if _fish_timer <= 0.0:
		# Target baru: ikan sulit pindah lebih jauh, lebih cepat, dan lebih sering.
		var half := ICON_SIZE * 0.5
		var max_jump := lerpf(40.0, TRACK_H, _difficulty)
		_fish_target = clampf(_fish_y + _rng.randf_range(-max_jump, max_jump), half, TRACK_H - half)
		_fish_speed = _rng.randf_range(lerpf(18.0, 60.0, _difficulty), lerpf(40.0, 140.0, _difficulty))
		_fish_timer = _rng.randf_range(lerpf(1.2, 0.35, _difficulty), lerpf(2.4, 1.0, _difficulty))
	_fish_y = move_toward(_fish_y, _fish_target, _fish_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_end(false)


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	if not active:
		return
	var font := ThemeDB.fallback_font
	# Panel di sebelah kanan tengah layar (player selalu di tengah karena kamera mengikutinya).
	var origin := (Vector2(size.x * 0.5 + 48.0, (size.y - PANEL_SIZE.y) * 0.5)).floor()
	var panel := Rect2(origin, PANEL_SIZE)
	if _skin == null:
		_skin = UiTheme.UiSkin.new()
	UiTheme.draw_window(self, _skin, panel, "IKAN!")

	var track := Rect2(origin + Vector2(14, 18), Vector2(TRACK_W, TRACK_H))
	draw_rect(track, COL_TRACK)
	draw_rect(track, Color(1, 1, 1, 0.3), false, 1.0)

	var zone := Rect2(track.position + Vector2(1, roundf(_zone_y)), Vector2(TRACK_W - 2, _zone_h))
	draw_rect(zone, COL_ZONE_ON if _in_zone else COL_ZONE)
	draw_rect(zone, Color(0.8, 1, 0.8, 0.9), false, 1.0)

	if _fish != null and _fish.item != null and _fish.item.icon != null:
		var icon_pos := track.position + Vector2(roundf((TRACK_W - ICON_SIZE) * 0.5), roundf(_fish_y - ICON_SIZE * 0.5))
		draw_texture(_fish.item.icon, icon_pos)

	# Meteran tangkap (terisi dari bawah, merah -> kuning -> hijau).
	var meter := Rect2(track.end.x + 12, track.position.y, METER_W, TRACK_H)
	draw_rect(meter, Color(0, 0, 0, 0.5))
	var fill_h := roundf(TRACK_H * clampf(_progress, 0.0, 1.0))
	var fill_color := Color(1.0, 0.35, 0.3).lerp(Color(0.4, 1.0, 0.4), clampf(_progress, 0.0, 1.0))
	draw_rect(Rect2(meter.position.x, meter.end.y - fill_h, METER_W, fill_h), fill_color)
	draw_rect(meter, Color(1, 1, 1, 0.3), false, 1.0)

	draw_string(font, origin + Vector2(0, PANEL_SIZE.y - 19), "Tahan", HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, UiTheme.FS, UiTheme.TEXT)
	draw_string(font, origin + Vector2(0, PANEL_SIZE.y - 7), "SPACE/E", HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x, UiTheme.FS, UiTheme.TEXT)
