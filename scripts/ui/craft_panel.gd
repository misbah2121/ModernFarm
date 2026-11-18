class_name CraftPanel
extends Control
## Phase 14: panel kerajinan (tombol C / tombol BUAT di HP). Resep dimuat dari res://data/recipes/.
## Kiri: daftar resep. Kanan: detail (bahan punya/butuh) + tombol BUAT.
## Mouse: klik resep = pilih, klik BUAT = buat.  Keyboard: W/S pilih, E / SPACE buat, C / ESC tutup.
## Digambar lewat _draw dengan gaya asset RPG UI (UiTheme).
## Phase 18: script yang sama dipakai panel MASAK (node HUD/CookPanel, station = "cook"):
## hanya resep dengan RecipeData.station yang sama yang ditampilkan.

signal opened
signal closed
signal message(text: String)
## Phase 18: resep berhasil dibuat (dapur memakai ini untuk animasi asap).
signal crafted(recipe: RecipeData)

const RECIPES_DIR := "res://data/recipes/"
const PANEL_SIZE := Vector2(420, 236)
const PAD := 10
const LIST_W := 150.0
const ROW_H := 22.0
const BUTTON_SIZE := Vector2(110, 18)

## "craft" (tombol C) atau "cook" (dapur). Atur di Inspector.
@export_enum("craft", "cook") var station: String = "craft"
## Judul jendela.
@export var title: String = "KERAJINAN"
## Kata kerja tombol & pesan.
@export var verb: String = "BUAT"

var recipes: Array[RecipeData] = []
var _selected := 0
var _mouse := Vector2.ZERO
var _skin: UiTheme.UiSkin


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	_load_recipes()
	InventoryManager.inventory_changed.connect(func() -> void:
		if visible:
			queue_redraw())


func _load_recipes() -> void:
	recipes.clear()
	var dir := DirAccess.open(RECIPES_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		var path := RECIPES_DIR + file.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var recipe := load(path) as RecipeData
		if recipe != null and recipe.result != null and recipe.station == station:
			recipes.append(recipe)
	recipes.sort_custom(func(a: RecipeData, b: RecipeData) -> bool: return a.order < b.order)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


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


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (station == "craft" and event.is_action_pressed("craft")) or event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("move_up"):
		_select(_selected - 1)
	elif event.is_action_pressed("move_down"):
		_select(_selected + 1)
	elif event.is_action_pressed("interact") or event.is_action_pressed("tool_use"):
		_craft_selected()
	else:
		return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var pos := (event as InputEventMouseButton).position
		_mouse = pos
		for i in recipes.size():
			if _row_rect(i).has_point(pos):
				_select(i)
				accept_event()
				return
		if _button_rect().has_point(pos):
			_craft_selected()
		accept_event()


func _select(index: int) -> void:
	if recipes.is_empty():
		return
	_selected = wrapi(index, 0, recipes.size())
	AudioManager.play_sfx("ui_select", 0.0, -6.0)
	queue_redraw()


func _craft_selected() -> void:
	if recipes.is_empty():
		return
	var recipe := recipes[_selected]
	var reason := recipe.check()
	if reason != "":
		message.emit(reason)
		return
	recipe.craft()
	AudioManager.play_sfx("pickup")
	var did := "memasak" if station == "cook" else "membuat"
	message.emit("Berhasil %s %s! (di tas: %d)" % [did, recipe.result.item_name, InventoryManager.count_of(recipe.result.id)])
	crafted.emit(recipe)
	queue_redraw()


# ---------------------------------------------------------------- tata letak

func _origin() -> Vector2:
	return ((size - PANEL_SIZE) / 2.0).floor()


func _row_rect(index: int) -> Rect2:
	var o := _origin()
	return Rect2(o + Vector2(PAD, 22 + index * (ROW_H + 2)), Vector2(LIST_W, ROW_H))


func _detail_rect() -> Rect2:
	var o := _origin()
	var x := PAD + LIST_W + 8
	return Rect2(o + Vector2(x, 22), Vector2(PANEL_SIZE.x - x - PAD, PANEL_SIZE.y - 22 - PAD))


func _button_rect() -> Rect2:
	var d := _detail_rect()
	return Rect2(Vector2(d.end.x - BUTTON_SIZE.x - 8, d.end.y - BUTTON_SIZE.y - 8), BUTTON_SIZE)


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var origin := _origin()
	UiTheme.draw_window(self, _skin, Rect2(origin, PANEL_SIZE), title)
	draw_string(font, origin + Vector2(PAD, 11), "C / ESC: tutup" if station == "craft" else "ESC: tutup", HORIZONTAL_ALIGNMENT_RIGHT, PANEL_SIZE.x - PAD * 2, UiTheme.FS, UiTheme.TITLE)
	if recipes.is_empty():
		draw_string(font, origin + Vector2(PAD, 40), "Belum ada resep.", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.TEXT)
		return
	for i in recipes.size():
		_draw_row(font, i)
	_draw_detail(font, recipes[_selected])


func _draw_row(font: Font, index: int) -> void:
	var recipe := recipes[index]
	var rect := _row_rect(index)
	draw_style_box(_skin.paper, rect)
	if index == _selected:
		draw_rect(rect.grow(-1.0), UiTheme.SELECT, false, 2.0)
	elif rect.has_point(_mouse):
		draw_rect(rect.grow(-2.0), UiTheme.SLOT_HOVER)
	if recipe.result.icon != null:
		draw_texture(recipe.result.icon, rect.position + Vector2(4, 3))
	var color := UiTheme.TEXT if recipe.has_ingredients() else UiTheme.TEXT_DIM
	draw_string(font, rect.position + Vector2(24, 14), recipe.result.item_name, HORIZONTAL_ALIGNMENT_LEFT, LIST_W - 28, UiTheme.FS, color)


func _draw_detail(font: Font, recipe: RecipeData) -> void:
	var d := _detail_rect()
	draw_style_box(_skin.paper, d)
	var item := recipe.result
	# ikon besar 2x (kelipatan bulat, tetap tajam)
	var icon_rect := Rect2(d.position + Vector2(8, 8), Vector2(36, 36))
	UiTheme.draw_slot(self, _skin, icon_rect)
	if item.icon != null:
		draw_texture_rect(item.icon, Rect2(icon_rect.position + Vector2(2, 2), Vector2(32, 32)), false)
	var title_text := item.item_name
	if recipe.result_count > 1:
		title_text += " x%d" % recipe.result_count
	draw_string(font, d.position + Vector2(52, 20), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.ACCENT)
	draw_string(font, d.position + Vector2(52, 32), "Di tas: %d" % InventoryManager.count_of(item.id), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.TEXT_DIM)
	var desc := item.description
	if item.energy > 0:
		desc = "Energi +%d. " % item.energy + desc
	if item.buff_text() != "":
		desc = "Bonus: %s. " % item.buff_text() + desc
	draw_multiline_string(font, d.position + Vector2(8, 54), desc, HORIZONTAL_ALIGNMENT_LEFT, d.size.x - 16, UiTheme.FS, 2, UiTheme.TEXT)

	draw_string(font, d.position + Vector2(8, 92), "Bahan:", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.TEXT)
	for i in recipe.ingredients.size():
		var ing := recipe.ingredients[i]
		var need := recipe.amount_of(i)
		var have := InventoryManager.count_of(ing.id)
		var y := d.position.y + 97 + i * 21
		var slot := Rect2(Vector2(d.position.x + 8, y), Vector2(20, 20))
		UiTheme.draw_slot(self, _skin, slot)
		if ing.icon != null:
			draw_texture(ing.icon, slot.position + Vector2(2, 2))
		draw_string(font, Vector2(slot.end.x + 6, y + 14), ing.item_name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.TEXT)
		draw_string(font, Vector2(slot.end.x + 6, y + 14), "%d / %d" % [have, need], HORIZONTAL_ALIGNMENT_RIGHT, d.size.x - 50, UiTheme.FS,
			UiTheme.GREEN if have >= need else UiTheme.RED)

	var button := _button_rect()
	var ok := recipe.check() == ""
	if ok:
		UiTheme.draw_button(self, _skin, button, verb, button.has_point(_mouse), 10)
	else:
		draw_style_box(_skin.button_disabled, button)
		draw_string(font, button.position + Vector2(0, 12), verb, HORIZONTAL_ALIGNMENT_CENTER, button.size.x, UiTheme.FS, Color(UiTheme.TITLE, 0.5))
		draw_string(font, Vector2(d.position.x + 8, button.position.y - 5), recipe.check(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.RED)
