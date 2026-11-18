class_name StallPanel
extends Control
## Phase 22: panel KIOS PASAR (E di kios dekat jalan ke Desa).
## Atas = rak kios (6 slot, harga jual per barang), bawah = tas (24 slot).
## Klik barang di tas = taruh setumpuk di rak (klik kanan = 1). Klik barang di rak = ambil kembali.
## Info: kategori yang sedang DICARI hari ini (harga x1.6), jam buka, dan penghasilan hari ini.
## Digambar lewat _draw dengan gaya asset RPG UI (UiTheme), seperti ChestPanel.

signal opened
signal closed

const SLOT := 24
const GAP := 3
const COLS := 8
const ROWS := 3
const PAD := 10

var stall: MarketStall
var _mouse := Vector2.ZERO
var _skin: UiTheme.UiSkin


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	InventoryManager.inventory_changed.connect(func() -> void:
		if visible:
			queue_redraw())


func open(p_stall: MarketStall) -> void:
	if visible or p_stall == null:
		return
	stall = p_stall
	if not stall.changed.is_connected(queue_redraw):
		stall.changed.connect(queue_redraw)
	visible = true
	queue_redraw()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- tata letak

func _panel_size() -> Vector2:
	var gw := COLS * SLOT + (COLS - 1) * GAP
	return Vector2(gw + PAD * 2, 252)


func _origin() -> Vector2:
	return ((size - _panel_size()) / 2.0).floor()


func _shelf_rect(i: int) -> Rect2:
	var o := _origin()
	var w := (_panel_size().x - PAD * 2 - 5 * 6) / 6.0
	return Rect2(o + Vector2(PAD + i * (w + 6), 60), Vector2(w, 44)).abs()


func _bag_rect(i: int) -> Rect2:
	var o := _origin()
	var col := i % COLS
	var row := floori(i / float(COLS))
	return Rect2(o + Vector2(PAD + col * (SLOT + GAP), 142 + row * (SLOT + GAP)), Vector2(SLOT, SLOT))


func _hit(pos: Vector2) -> Vector2i:
	for i in MarketStall.SLOT_COUNT:
		if _shelf_rect(i).has_point(pos):
			return Vector2i(0, i)
	for i in COLS * ROWS:
		if _bag_rect(i).has_point(pos):
			return Vector2i(1, i)
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
	if hit.x < 0 or stall == null:
		return
	var one := mb.button_index == MOUSE_BUTTON_RIGHT
	if hit.x == 0:
		_shelf_to_bag(hit.y, one)
	else:
		_bag_to_shelf(hit.y, one)
	queue_redraw()


func _shelf_to_bag(i: int, one: bool) -> void:
	var s: ItemStack = stall.slots[i]
	if s == null:
		return
	var amount := 1 if one else s.count
	var moved := amount - InventoryManager.add_item(s.item, amount)
	s.count -= moved
	if s.count <= 0:
		stall.slots[i] = null
	stall.changed.emit()
	stall.queue_redraw()
	AudioManager.play_sfx("pickup", 0.0, -6.0)


func _bag_to_shelf(i: int, one: bool) -> void:
	var s := InventoryManager.slots[i]
	if s == null:
		return
	if s.item.sell_price <= 0 or s.item.category == ItemData.Category.TOOL:
		return
	var moved := stall.add_item(s.item, 1 if one else s.count)
	if moved > 0:
		InventoryManager.remove_from_slot(i, moved)
		AudioManager.play_sfx("pickup", 0.0, -6.0)


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	if stall == null:
		return
	var font := ThemeDB.fallback_font
	var fs := UiTheme.FS
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var o := _origin()
	var ps := _panel_size()
	UiTheme.draw_window(self, _skin, Rect2(o, ps), "KIOS PASAR")
	draw_string(font, o + Vector2(PAD, 32), "Dicari hari ini: %s (x1.6)" % stall.hot_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.ACCENT)
	draw_string(font, o + Vector2(PAD, 50), "Buka %02d:00-%02d:00  |  Hari ini +%d G" % [MarketStall.OPEN_HOUR, MarketStall.CLOSE_HOUR, stall.earned_today], HORIZONTAL_ALIGNMENT_LEFT, ps.x - PAD * 2, fs, UiTheme.TEXT_DIM)
	var hit := _hit(_mouse)
	for i in MarketStall.SLOT_COUNT:
		var r := _shelf_rect(i)
		draw_style_box(_skin.paper, r)
		if hit == Vector2i(0, i):
			draw_rect(r.grow(-2.0), UiTheme.SLOT_HOVER)
		var s: ItemStack = stall.slots[i]
		if s == null:
			continue
		if s.item.icon != null:
			draw_texture(s.item.icon, r.position + Vector2((r.size.x - 16) / 2.0, 4).floor())
		UiTheme.draw_count(self, Rect2(r.position + Vector2(0, 0), Vector2(r.size.x, 24)), s.count)
		var hot := int(s.item.category) == stall.hot_category
		draw_string(font, r.position + Vector2(0, 38), "%dG" % stall.price_of(s.item), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, UiTheme.GREEN if hot else UiTheme.PRICE)
	draw_string(font, o + Vector2(PAD, 134), "Tas  (klik: taruh di rak)", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.TEXT)
	for i in COLS * ROWS:
		var r := _bag_rect(i)
		var s := InventoryManager.slots[i]
		var sellable := s != null and s.item.sell_price > 0 and s.item.category != ItemData.Category.TOOL
		UiTheme.draw_slot(self, _skin, r, false, hit == Vector2i(1, i))
		if s == null:
			continue
		if s.item.icon != null:
			draw_texture(s.item.icon, r.position + Vector2(4, 4), Color.WHITE if sellable else Color(1, 1, 1, 0.3))
		UiTheme.draw_count(self, r, s.count)
	var info := "Kiri: setumpuk  Kanan: 1  E: tutup"
	if hit.x >= 0:
		var s: ItemStack = stall.slots[hit.y] if hit.x == 0 else InventoryManager.slots[hit.y]
		if s != null:
			info = "%s - harga kios %dG" % [s.item.item_name, stall.price_of(s.item)] if s.item.sell_price > 0 else "%s - tidak bisa dijual" % s.item.item_name
	draw_string(font, o + Vector2(PAD, ps.y - 9), UiTheme.fit(info, ps.x - PAD * 2), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.TEXT_DIM)
