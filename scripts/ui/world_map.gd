class_name WorldMap
extends Control
## Peta dunia (tombol M / tombol PETA di HP). Memakai asset "Humble Gift - World Map Scroll"
## (assets/ui/world_map/): gulungan peta membuka (11 frame), lalu tampil pulau, jalan,
## kompas, dan 4 lokasi game (Farm, Desa, Hutan, Tambang) dengan penanda posisi player.
## M / ESC / klik = tutup (gulungan menggulung, 11 frame).
## Semua digambar lewat _draw (tanpa node anak). Main memanggil open(id_peta_aktif).

signal opened
signal closed

const DIR := "res://assets/ui/world_map/"
const FRAME_COUNT := 11
const FPS := 20.0
## Ukuran gambar gulungan (semua frame sudah dipotong ke ukuran yang sama).
const FRAME_SIZE := Vector2(474, 373)
## Posisi bagian peta di dalam gulungan (relatif ke pojok kiri atas gulungan).
const ISLAND_POS := Vector2(77, 79)
const ROADS_POS := Vector2(149, 109)
const COMPASS_POS := Vector2(341, 238)
const DECOR_POS := Vector2(77, 34)
const MOUNTAIN_POS := Vector2(140, 150)
## Lokasi = ujung jalan di gambar peta. Arah sesuai pintu keluar di game:
## Desa di tengah, Hutan di utara, Tambang di barat, Farm di timur.
const LOCATIONS := {
	"forest": {"name": "Hutan", "pos": Vector2(217, 129)},
	"mine": {"name": "Tambang", "pos": Vector2(165, 169)},
	"village": {"name": "Desa", "pos": Vector2(234, 181)},
	"farm": {"name": "Farm", "pos": Vector2(307, 195)},
}

enum State { CLOSED, OPENING, OPEN, CLOSING }

var current_map := "farm"

var _state: State = State.CLOSED
var _frame := 0.0
var _time := 0.0
var _appear: Array[Texture2D] = []
var _disappear: Array[Texture2D] = []
var _island: Texture2D
var _roads: Texture2D
var _compass: Array[Texture2D] = []  # 3 lapis: lingkaran, mata angin, huruf N/E/S/W
var _decor: Texture2D
var _mountain: Texture2D
var _dot: Texture2D
var _pin: Texture2D


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	for i in FRAME_COUNT:
		_appear.append(load(DIR + "appear/%d.png" % i))
		_disappear.append(load(DIR + "disappear/%d.png" % i))
	_island = load(DIR + "parts/map_0.png")
	_roads = load(DIR + "parts/items_0.png")
	for i in 3:
		_compass.append(load(DIR + "parts/compass_%d.png" % i))
	_decor = load(DIR + "parts/decorations_0.png")
	_mountain = load(DIR + "parts/items_1.png")
	_dot = load(DIR + "parts/items_2.png")
	_pin = load(DIR + "parts/highlighter_0.png")


func is_open() -> bool:
	return visible


func open(map_id: String) -> void:
	if visible:
		return
	current_map = map_id
	visible = true
	_state = State.OPENING
	_frame = 0.0
	set_process(true)
	queue_redraw()
	opened.emit()


## Tutup dengan animasi menggulung. instant = true langsung hilang (mis. saat tidur / pindah peta).
func close(instant: bool = false) -> void:
	if not visible:
		return
	if instant:
		_finish_close()
		return
	if _state == State.CLOSING:
		return
	_state = State.CLOSING
	_frame = 0.0


func _finish_close() -> void:
	_state = State.CLOSED
	visible = false
	set_process(false)
	closed.emit()


func _process(delta: float) -> void:
	_time += delta
	if _state == State.OPENING or _state == State.CLOSING:
		_frame += delta * FPS
		if _frame >= FRAME_COUNT - 1:
			if _state == State.OPENING:
				_state = State.OPEN
			else:
				_finish_close()
				return
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("world_map") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _state == State.OPEN:
		close()
		accept_event()


func _origin() -> Vector2:
	return ((size - FRAME_SIZE) / 2.0).floor()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
	var origin := _origin()
	var index := clampi(int(_frame), 0, FRAME_COUNT - 1)
	match _state:
		State.OPENING:
			draw_texture(_appear[index], origin)
		State.CLOSING:
			draw_texture(_disappear[index], origin)
		_:
			draw_texture(_appear[FRAME_COUNT - 1], origin)
			_draw_map(origin)


func _draw_map(origin: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var ink := Color(0.27, 0.20, 0.11)
	draw_string(font, origin + Vector2(0, 46), "PETA DUNIA", HORIZONTAL_ALIGNMENT_CENTER, FRAME_SIZE.x, UiTheme.FS, ink)
	draw_texture(_decor, origin + DECOR_POS + Vector2(0, 16))
	draw_texture(_island, origin + ISLAND_POS)
	draw_texture(_roads, origin + ROADS_POS)
	draw_texture(_mountain, origin + MOUNTAIN_POS)
	for layer in _compass:
		draw_texture(layer, origin + COMPASS_POS)
	for id: String in LOCATIONS:
		var loc: Dictionary = LOCATIONS[id]
		var pos: Vector2 = origin + loc["pos"]
		draw_texture(_dot, pos - Vector2(8, 8))
		var here := id == current_map
		var label: String = loc["name"]
		var color := Color(0.12, 0.38, 0.20) if here else ink
		draw_string_outline(font, pos + Vector2(-40, 18), label, HORIZONTAL_ALIGNMENT_CENTER, 80, UiTheme.FS, 3, Color(0.85, 0.79, 0.58))
		draw_string(font, pos + Vector2(-40, 18), label, HORIZONTAL_ALIGNMENT_CENTER, 80, UiTheme.FS, color)
		if here:
			var bob := roundf(sin(_time * 4.0) * 2.0)
			draw_texture(_pin, pos - Vector2(8, 30 + bob))
	var here_name: String = LOCATIONS.get(current_map, LOCATIONS["farm"])["name"]
	draw_string(font, origin + Vector2(44, 334), "Kamu di: %s" % here_name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, ink)
	draw_string(font, origin + Vector2(44, 334), "M / ESC: tutup", HORIZONTAL_ALIGNMENT_RIGHT, 290, UiTheme.FS, Color(ink, 0.7))
