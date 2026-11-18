class_name ChestPanel
extends Control
## Phase 14: panel Peti Kayu (StorageChest). Atas = isi peti (24 slot), bawah = tas (24 slot).
## Klik kiri = pindahkan setumpuk ke sisi lain, klik kanan = pindahkan 1. E / ESC = tutup.
## Digambar lewat _draw dengan gaya asset RPG UI (UiTheme).

signal opened
signal closed

const SLOT := 22
const GAP := 2
const COLS := 8
const ROWS := 3
const PAD := 10
const SECTION_GAP := 18

var chest: StorageChest
var _mouse := Vector2.ZERO
var _skin: UiTheme.UiSkin


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	InventoryManager.inventory_changed.connect(func() -> void:
		if visible:
			queue_redraw())


func open(p_chest: StorageChest) -> void:
	if visible or p_chest == null:
		return
	chest = p_chest
	chest.set_open(true)
	visible = true
	queue_redraw()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	if is_instance_valid(chest):
		chest.set_open(false)
	chest = null
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- tata letak

func _grid_size() -> Vector2:
	return Vector2(COLS * SLOT + (COLS - 1) * GAP, ROWS * SLOT + (ROWS - 1) * GAP)


func _panel_size() -> Vector2:
	var g := _grid_size()
	return Vector2(g.x + PAD * 2, 22 + 12 + g.y + SECTION_GAP + 12 + g.y + 22)


func _origin() -> Vector2:
	return ((size - _panel_size()) / 2.0).floor()


## side 0 = peti, 1 = tas.
func _slot_rect(side: int, index: int) -> Rect2:
	var o := _origin()
	var g := _grid_size()
	var top: float = 34.0 if side == 0 else 34.0 + g.y + SECTION_GAP + 12.0
	var col := index % COLS
	var row := floori(index / float(COLS))
	return Rect2(o + Vector2(PAD + col * (SLOT + GAP), top + row * (SLOT + GAP)), Vector2(SLOT, SLOT))


func _hit(pos: Vector2) -> Vector2i:
	for side in 2:
		for i in COLS * ROWS:
			if _slot_rect(side, i).has_point(pos):
				return Vector2i(side, i)
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- pindah barang

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		queue_redraw()
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	accept_event()
	var hit := _hit(mb.position)
	if hit.x < 0 or chest == null:
		return
	var one := mb.button_index == MOUSE_BUTTON_RIGHT
	if hit.x == 0:
		_chest_to_bag(hit.y, one)
	else:
		_bag_to_chest(hit.y, one)
	queue_redraw()


func _chest_to_bag(index: int, one: bool) -> void:
	var stack: ItemStack = chest.slots[index]
	if stack == null:
		return
	var amount := 1 if one else stack.count
	var left := InventoryManager.add_item(stack.item, amount)
	var moved := amount - left
	stack.count -= moved
	if stack.count <= 0:
		chest.slots[index] = null
	if moved > 0:
		AudioManager.play_sfx("pickup", 0.0, -6.0)


func _bag_to_chest(index: int, one: bool) -> void:
	var stack := InventoryManager.slots[index]
	if stack == null:
		return
	var amount := 1 if one else stack.count
	var moved := _add_to_chest(stack.item, amount)
	if moved > 0:
		InventoryManager.remove_from_slot(index, moved)
		AudioManager.play_sfx("pickup", 0.0, -6.0)


## Masukkan ke peti (isi tumpukan sama dulu, lalu slot kosong). Kembalikan jumlah yang masuk.
func _add_to_chest(item: ItemData, amount: int) -> int:
	var left := amount
	for i in StorageChest.SLOT_COUNT:
		var s: ItemStack = chest.slots[i]
		if s != null and s.item.id == item.id and s.room() > 0:
			var m := mini(left, s.room())
			s.count += m
			left -= m
			if left == 0:
				return amount
	for i in StorageChest.SLOT_COUNT:
		if chest.slots[i] == null:
			var m := mini(left, item.max_stack)
			chest.slots[i] = ItemStack.new(item, m)
			left -= m
			if left == 0:
				break
	return amount - left


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	if chest == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var o := _origin()
	var ps := _panel_size()
	UiTheme.draw_window(self, _skin, Rect2(o, ps), "PETI KAYU")
	var hit := _hit(_mouse)
	draw_string(font, o + Vector2(PAD, 30), "Isi peti", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.TEXT)
	var bag_label_y := _slot_rect(1, 0).position.y - 4
	draw_string(font, Vector2(o.x + PAD, bag_label_y), "Tas", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.TEXT)
	for side in 2:
		for i in COLS * ROWS:
			var rect := _slot_rect(side, i)
			var stack: ItemStack = chest.slots[i] if side == 0 else InventoryManager.slots[i]
			UiTheme.draw_slot(self, _skin, rect, false, hit == Vector2i(side, i))
			if stack == null:
				continue
			if stack.item.icon != null:
				draw_texture(stack.item.icon, rect.position + Vector2(3, 3))
			UiTheme.draw_count(self, rect, stack.count)
	var info := "Kiri: semua  Kanan: 1"
	if hit.x >= 0:
		var stack: ItemStack = chest.slots[hit.y] if hit.x == 0 else InventoryManager.slots[hit.y]
		if stack != null:
			info = "%s x%d  -  %s" % [stack.item.item_name, stack.count, stack.item.category_name()]
	draw_string(font, o + Vector2(PAD, ps.y - 9), UiTheme.fit(info, ps.x - PAD * 2), HORIZONTAL_ALIGNMENT_LEFT, ps.x - PAD * 2, UiTheme.FS, UiTheme.TEXT_DIM)
