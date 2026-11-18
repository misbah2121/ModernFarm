class_name InventoryPanel
extends Control
## Panel inventory (tombol I). Grid 8 x 3: baris pertama = hotbar.
## Klik kiri: ambil / taruh / tukar / gabung tumpukan.  Klik kanan: ambil setengah / taruh satu.
## Slot "BUANG" menghapus item yang dipegang (alat tidak bisa dibuang).
## Panel digambar lewat _draw dan dibuat sebagai Control layar penuh (tanpa node per slot).

signal opened
signal closed

const SLOT := 24
const GAP := 2
const COLS := 8
const ROWS := 3
const PAD := 8
const HEADER := 14
const HOTBAR_GAP := 4
const FOOTER := 36
const TRASH_SLOT := -2  # indeks khusus untuk slot buang
const NO_SLOT := -1

## Warna teks di atas kertas krem (asset RPG UI, lihat UiTheme).
const COL_GOLD := UiTheme.ACCENT
const COL_TEXT := UiTheme.TEXT
const COL_DIM := UiTheme.TEXT_DIM

var _held: ItemStack = null
var _mouse := Vector2.ZERO
var _skin: UiTheme.UiSkin


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	InventoryManager.inventory_changed.connect(_on_inventory_changed)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if visible:
		return
	_mouse = get_local_mouse_position()
	visible = true
	queue_redraw()
	opened.emit()


func close() -> void:
	if not visible:
		return
	if _held != null:
		# Item yang sedang dipegang dikembalikan ke tas.
		var left := InventoryManager.add_item(_held.item, _held.count)
		if left > 0:
			push_warning("Tas penuh saat menutup inventory, %d item hilang." % left)
		_held = null
	visible = false
	closed.emit()


func _on_inventory_changed() -> void:
	if visible:
		queue_redraw()


# ---------------------------------------------------------------- layout

func _panel_size() -> Vector2:
	var grid_w := COLS * SLOT + (COLS - 1) * GAP
	var grid_h := ROWS * SLOT + (ROWS - 1) * GAP + HOTBAR_GAP
	return Vector2(grid_w + PAD * 2, PAD + HEADER + grid_h + 6 + FOOTER + PAD)


func _panel_origin() -> Vector2:
	return ((size - _panel_size()) / 2.0).floor()


func _grid_origin() -> Vector2:
	return _panel_origin() + Vector2(PAD, PAD + HEADER)


func _slot_rect(index: int) -> Rect2:
	var col := index % COLS
	var row := floori(index / float(COLS))
	var y := row * (SLOT + GAP) + (HOTBAR_GAP if row > 0 else 0)
	return Rect2(_grid_origin() + Vector2(col * (SLOT + GAP), y), Vector2(SLOT, SLOT))


func _trash_rect() -> Rect2:
	var panel := _panel_origin()
	var ps := _panel_size()
	return Rect2(panel + Vector2(ps.x - PAD - SLOT, ps.y - PAD - SLOT), Vector2(SLOT, SLOT))


## Slot di bawah mouse: 0..23, TRASH_SLOT, atau NO_SLOT.
func _slot_at(pos: Vector2) -> int:
	if _trash_rect().has_point(pos):
		return TRASH_SLOT
	for i in InventoryManager.SLOT_COUNT:
		if _slot_rect(i).has_point(pos):
			return i
	return NO_SLOT


# ---------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		queue_redraw()
	elif event is InputEventMouseButton and event.is_pressed():
		var button := event as InputEventMouseButton
		_mouse = button.position
		var index := _slot_at(_mouse)
		if index == NO_SLOT:
			return
		if button.button_index == MOUSE_BUTTON_LEFT:
			_left_click(index)
		elif button.button_index == MOUSE_BUTTON_RIGHT:
			_right_click(index)
		queue_redraw()


func _left_click(index: int) -> void:
	if index == TRASH_SLOT:
		_trash_held()
	elif _held == null:
		_held = InventoryManager.take_stack(index)
	else:
		_held = InventoryManager.place_stack(index, _held)


func _right_click(index: int) -> void:
	if index == TRASH_SLOT:
		return
	if _held == null:
		_held = InventoryManager.take_half(index)
	else:
		_held = InventoryManager.place_one(index, _held)


func _trash_held() -> void:
	if _held == null:
		return
	if _held.item.category == ItemData.Category.TOOL:
		InventoryManager.message.emit("Alat tidak bisa dibuang.")
		return
	InventoryManager.message.emit("Membuang %d %s." % [_held.count, _held.item.item_name])
	_held = null


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var panel := Rect2(_panel_origin(), _panel_size())
	UiTheme.draw_window(self, _skin, panel, "INVENTORY")

	var hover := _slot_at(_mouse)
	for i in InventoryManager.SLOT_COUNT:
		_draw_slot(font, _slot_rect(i), InventoryManager.slots[i], i == InventoryManager.selected, i == hover)
	_draw_trash(font, hover == TRASH_SLOT)
	_draw_footer(font, panel, hover)

	if _held != null:
		var pos := _mouse - Vector2(8, 8)
		draw_texture(_held.item.icon, pos)
		UiTheme.draw_count(self, Rect2(pos, Vector2(20, 19)), _held.count)


func _draw_slot(_font: Font, rect: Rect2, stack: ItemStack, is_selected: bool, is_hover: bool) -> void:
	UiTheme.draw_slot(self, _skin, rect, is_selected, is_hover)
	if stack == null:
		return
	if stack.item.icon != null:
		draw_texture(stack.item.icon, rect.position + Vector2(4, 4))
	UiTheme.draw_count(self, rect, stack.count)


func _draw_trash(font: Font, is_hover: bool) -> void:
	var rect := _trash_rect()
	UiTheme.draw_slot(self, _skin, rect, false, is_hover)
	draw_rect(rect.grow(-2.0), Color(0.7, 0.15, 0.1, 0.35 if is_hover else 0.2))
	var c := rect.get_center()
	draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), UiTheme.RED, 2.0)
	draw_line(c + Vector2(-4, 4), c + Vector2(4, -4), UiTheme.RED, 2.0)
	draw_string(font, rect.position + Vector2(-12, -3), "BUANG", HORIZONTAL_ALIGNMENT_CENTER, SLOT + 24, UiTheme.FS, COL_DIM)


func _draw_footer(font: Font, panel: Rect2, hover: int) -> void:
	var x := panel.position.x + PAD
	var y := panel.end.y - PAD - FOOTER
	var stack: ItemStack = null
	if hover >= 0:
		stack = InventoryManager.slots[hover]
	if stack != null:
		var item := stack.item
		draw_string(font, Vector2(x, y + 9), UiTheme.fit(item.item_name, size_hint_width()), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_GOLD)
		var info := item.category_name()
		if item.sell_price > 0:
			info += "  -  Jual: %d" % GameManager.sell_price_of(item)
		draw_string(font, Vector2(x, y + 20), UiTheme.fit(info, size_hint_width()), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.PRICE)
		draw_string(font, Vector2(x, y + 31), UiTheme.fit(item.description, size_hint_width()), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_TEXT)
	elif hover == TRASH_SLOT:
		draw_string(font, Vector2(x, y + 9), "Tempat sampah", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_GOLD)
		draw_string(font, Vector2(x, y + 20), "Klik sambil memegang item", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_TEXT)
		draw_string(font, Vector2(x, y + 31), "untuk membuangnya.", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_TEXT)
	else:
		draw_string(font, Vector2(x, y + 9), "Kiri: ambil / taruh", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
		draw_string(font, Vector2(x, y + 20), "Kanan: setengah / satu", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
		draw_string(font, Vector2(x, y + 31), "I / ESC: tutup", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)


## Lebar teks footer maksimum (sisakan tempat untuk slot buang di kanan).
func size_hint_width() -> float:
	return _panel_size().x - PAD * 2 - SLOT - 4
