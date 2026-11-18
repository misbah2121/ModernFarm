class_name FarmBoardPanel
extends Control
## Phase 19: panel PAPAN FARM (E di Papan Farm dekat rumah).
##   3 baris pekerja : nama, peran, level, tugas, gaji + tombol REKRUT / BERHENTI.
##   1 baris traktor : status + biaya perbaikan / upgrade + tombol.
## Mouse: klik tombol.  Keyboard: W/S pilih baris, E / SPACE tekan tombol, ESC tutup.
## Digambar lewat _draw dengan gaya asset RPG UI (UiTheme), seperti panel lain.

signal opened
signal closed
signal message(text: String)

const PANEL_SIZE := Vector2(480, 268)
const PAD := 10
const ROW_H := 50.0
const BUTTON_SIZE := Vector2(104, 20)
const FACE_REGION := Rect2(18 * 48 + 16, 64 + 38, 16, 16)  # kepala di frame idle (menghadap bawah)
const ICON_TRACTOR := preload("res://assets/modern_farm/icons/Icon_Tractor.png")

var _selected := 0
var _mouse := Vector2.ZERO
var _skin: UiTheme.UiSkin
var _faces: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	for id: String in FarmWorkers.SHEETS:
		var face := AtlasTexture.new()
		face.atlas = load(FarmWorkers.SHEETS[id])
		face.region = FACE_REGION
		_faces[id] = face
	FarmServices.changed.connect(queue_redraw)
	GameManager.gold_changed.connect(func(_g: int) -> void:
		if visible:
			queue_redraw())


func open() -> void:
	if visible:
		return
	visible = true
	queue_redraw()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _row_count() -> int:
	return FarmServices.WORKERS.size() + 1


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("move_up"):
		_selected = wrapi(_selected - 1, 0, _row_count())
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		_selected = wrapi(_selected + 1, 0, _row_count())
		queue_redraw()
	elif event.is_action_pressed("interact") or event.is_action_pressed("tool_use"):
		_press(_selected)
	else:
		return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		for i in _row_count():
			if _button_rect(i).has_point((event as InputEventMouseButton).position):
				_selected = i
				_press(i)
				break
		accept_event()


func _press(row: int) -> void:
	if row < FarmServices.WORKERS.size():
		var w: Dictionary = FarmServices.WORKERS[row]
		var id: String = w["id"]
		var hire := not FarmServices.is_hired(id)
		FarmServices.set_hired(id, hire)
		AudioManager.play_sfx("ui_select")
		if hire:
			message.emit("%s (%s) mulai bekerja besok pagi. Gaji %d Gold/hari." % [w["name"], w["role"], FarmServices.wage_of(id)])
		else:
			message.emit("%s berhenti bekerja." % w["name"])
	else:
		var was := FarmServices.tractor_level
		var reason := FarmServices.tractor_upgrade()
		if reason != "":
			message.emit(reason)
			return
		AudioManager.play_sfx("pickup")
		message.emit("Traktor diperbaiki! E di dekat traktor untuk naik, SPACE ganti alat." if was == 0 \
			else "Alat penyiram terpasang! Traktor bisa membajak sambil menyiram.")
	queue_redraw()


# ---------------------------------------------------------------- tata letak

func _origin() -> Vector2:
	return ((size - PANEL_SIZE) / 2.0).floor()


func _row_rect(i: int) -> Rect2:
	return Rect2(_origin() + Vector2(PAD, 22 + i * (ROW_H + 4)), Vector2(PANEL_SIZE.x - PAD * 2, ROW_H))


func _button_rect(i: int) -> Rect2:
	var r := _row_rect(i)
	return Rect2(Vector2(r.end.x - BUTTON_SIZE.x - 8, r.position.y + (ROW_H - BUTTON_SIZE.y) / 2.0).floor(), BUTTON_SIZE)


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var fs := UiTheme.FS
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	UiTheme.draw_window(self, _skin, Rect2(_origin(), PANEL_SIZE), "PAPAN FARM")
	for i in FarmServices.WORKERS.size():
		var w: Dictionary = FarmServices.WORKERS[i]
		var id: String = w["id"]
		var r := _row_rect(i)
		_draw_row_base(r, i)
		var icon_rect := Rect2(r.position + Vector2(6, (ROW_H - 24) / 2.0), Vector2(24, 24))
		UiTheme.draw_slot(self, _skin, icon_rect)
		draw_texture(_faces[id], icon_rect.position + Vector2(4, 4))
		var hired := FarmServices.is_hired(id)
		var lvl := FarmServices.level_of(id)
		var title := "%s - %s  Lv %d" % [w["name"], w["role"], lvl]
		draw_string(font, r.position + Vector2(38, 20), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.ACCENT if hired else UiTheme.TEXT)
		var sub := "%s | Gaji %d/hari" % [FarmServices.task_of(id), FarmServices.wage_of(id)]
		draw_string(font, r.position + Vector2(38, 38), UiTheme.fit(sub, r.size.x - 38 - BUTTON_SIZE.x - 14, fs), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.TEXT_DIM)
		var b := _button_rect(i)
		UiTheme.draw_button(self, _skin, b, "BERHENTI" if hired else "REKRUT", b.has_point(_mouse), fs)
	# traktor
	var ti := FarmServices.WORKERS.size()
	var tr := _row_rect(ti)
	_draw_row_base(tr, ti)
	var t_icon := Rect2(tr.position + Vector2(6, (ROW_H - 24) / 2.0), Vector2(24, 24))
	UiTheme.draw_slot(self, _skin, t_icon)
	draw_texture(ICON_TRACTOR, t_icon.position + Vector2(4, 4))
	var lvl_t := FarmServices.tractor_level
	draw_string(font, tr.position + Vector2(38, 20), "Traktor: %s" % FarmServices.TRACTOR_LEVEL_NAMES[lvl_t], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.ACCENT if lvl_t > 0 else UiTheme.RED)
	var b2 := _button_rect(ti)
	if FarmServices.TRACTOR_COSTS.has(lvl_t + 1):
		var cost: Array = FarmServices.TRACTOR_COSTS[lvl_t + 1]
		var item := InventoryManager.get_item(String(cost[1]))
		var cost_text := "%d Gold + %d %s (punya %d)" % [int(cost[0]), int(cost[2]), item.item_name if item != null else String(cost[1]), InventoryManager.count_of(String(cost[1]))]
		draw_string(font, tr.position + Vector2(38, 38), UiTheme.fit(cost_text, tr.size.x - 38 - BUTTON_SIZE.x - 14, fs), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.PRICE)
		var label := "PERBAIKI" if lvl_t == 0 else "UPGRADE"
		if FarmServices.tractor_upgrade_check() == "":
			UiTheme.draw_button(self, _skin, b2, label, b2.has_point(_mouse), fs)
		else:
			draw_style_box(_skin.button_disabled, b2)
			draw_string(font, Vector2(b2.position.x, b2.position.y + 15), label, HORIZONTAL_ALIGNMENT_CENTER, b2.size.x, fs, Color(UiTheme.TITLE, 0.5))
	else:
		draw_string(font, tr.position + Vector2(38, 38), "Sudah maksimal: bajak + siram", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.TEXT_DIM)
	draw_string(font, _origin() + Vector2(PAD, PANEL_SIZE.y - 8), "W/S pilih  E pilih tombol  ESC tutup", HORIZONTAL_ALIGNMENT_LEFT, PANEL_SIZE.x - PAD * 2, fs, UiTheme.TEXT_DIM)


func _draw_row_base(r: Rect2, i: int) -> void:
	draw_style_box(_skin.paper, r)
	if i == _selected:
		draw_rect(r.grow(-1.0), UiTheme.SELECT, false, 2.0)
