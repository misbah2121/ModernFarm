class_name ShopPanel
extends Control
## Panel toko (Phase 7). Dibuka dari dialog NPC pemilik toko ("Belanja") atau tombol E di
## konter toko. Dua tab:
##   BELI : daftar barang toko. Klik kiri = beli 1, klik kanan = beli 5 (alat selalu 1).
##   JUAL : isi tas (24 slot). Klik kiri = jual 1, klik kanan = jual setumpuk.
##          Tombol "Jual semua hasil panen" menjual semua item kategori Hasil Panen.
## Phase 9: toko bisa juga menjual hewan (ShopData.animals), tampil paling atas di tab BELI.
## A/D atau panah kiri/kanan = ganti tab, roda mouse = gulir daftar BELI, ESC = tutup.
## Digambar lewat _draw (tanpa node per baris), gaya sama dengan InventoryPanel.

signal opened
signal closed

enum Tab { BUY, SELL }

const PANEL_SIZE := Vector2(470, 260)
const PAD := 8
const TAB_SIZE := Vector2(64, 16)
const CONTENT_TOP := 44
const FOOTER := 42

const ROW_H := 30
const ROW_GAP := 2
const COLS := 2
const BUY_BULK := 5

const SLOT := 24
const GAP := 2
const GRID_COLS := 8
const HOTBAR_GAP := 4
const SELL_ALL_SIZE := Vector2(150, 18)

const STATUS_TIME := 2.5
const NO_HIT := -1
const HIT_SELL_ALL := -2

## Warna teks di atas kertas krem (asset RPG UI, lihat UiTheme).
const COL_GOLD := UiTheme.PRICE
const COL_RED := UiTheme.RED
const COL_GREEN := UiTheme.GREEN
const COL_DIM := UiTheme.TEXT_DIM
const COL_TEXT := UiTheme.TEXT

var shop: ShopData

var _tab: Tab = Tab.BUY
var _stock: Array[ItemData] = []
var _animals: Array[AnimalData] = []  # tampil sebelum _stock
var _scroll := 0  # baris pertama yang terlihat di tab BELI
var _mouse := Vector2.ZERO
var _status := ""
var _status_color := Color.WHITE
var _status_timer := 0.0
var _skin: UiTheme.UiSkin


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	set_process(false)
	InventoryManager.inventory_changed.connect(_redraw_if_visible)
	GameManager.gold_changed.connect(func(_g: int) -> void: _redraw_if_visible())


func open(p_shop: ShopData) -> void:
	if visible or p_shop == null:
		return
	shop = p_shop
	_stock = shop.stock_items()
	_animals = shop.animal_stock()
	_tab = Tab.BUY
	_scroll = 0
	_status = ""
	_mouse = get_local_mouse_position()
	visible = true
	set_process(true)
	queue_redraw()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	closed.emit()


func _redraw_if_visible() -> void:
	if visible:
		queue_redraw()


func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer <= 0.0:
			_status = ""
			queue_redraw()


func _set_status(text: String, color: Color) -> void:
	_status = text
	_status_color = color
	_status_timer = STATUS_TIME
	queue_redraw()


# ---------------------------------------------------------------- layout

func _origin() -> Vector2:
	return ((size - PANEL_SIZE) / 2.0).floor()


func _tab_rect(tab: Tab) -> Rect2:
	return Rect2(_origin() + Vector2(PAD + tab * (TAB_SIZE.x + 4), 24), TAB_SIZE)


func _content_rect() -> Rect2:
	var top := CONTENT_TOP
	return Rect2(_origin() + Vector2(PAD, top), Vector2(PANEL_SIZE.x - PAD * 2, PANEL_SIZE.y - top - FOOTER - PAD))


func _visible_rows() -> int:
	return floori((_content_rect().size.y + ROW_GAP) / float(ROW_H + ROW_GAP))


func _max_scroll() -> int:
	var rows := ceili(_entry_count() / float(COLS))
	return maxi(0, rows - _visible_rows())


## Kotak satu barang di tab BELI (index = urutan di _stock). Rect2() jika tidak terlihat.
func _row_rect(index: int) -> Rect2:
	var row := floori(index / float(COLS)) - _scroll
	if row < 0 or row >= _visible_rows():
		return Rect2()
	var content := _content_rect()
	var col_w := (content.size.x - ROW_GAP * (COLS - 1)) / COLS
	var col := index % COLS
	return Rect2(content.position + Vector2(col * (col_w + ROW_GAP), row * (ROW_H + ROW_GAP)), Vector2(col_w, ROW_H))


func _grid_origin() -> Vector2:
	var content := _content_rect()
	var grid_w := GRID_COLS * SLOT + (GRID_COLS - 1) * GAP
	return Vector2(floorf(content.position.x + (content.size.x - grid_w) / 2.0), content.position.y + 2)


func _slot_rect(index: int) -> Rect2:
	var col := index % GRID_COLS
	var row := floori(index / float(GRID_COLS))
	var y := row * (SLOT + GAP) + (HOTBAR_GAP if row > 0 else 0)
	return Rect2(_grid_origin() + Vector2(col * (SLOT + GAP), y), Vector2(SLOT, SLOT))


func _sell_all_rect() -> Rect2:
	var content := _content_rect()
	var last := _slot_rect(InventoryManager.SLOT_COUNT - 1)
	return Rect2(Vector2(floorf(content.get_center().x - SELL_ALL_SIZE.x / 2.0), last.end.y + 8), SELL_ALL_SIZE)


## Barang (BELI) atau slot (JUAL) di bawah mouse.
func _hit_at(pos: Vector2) -> int:
	if _tab == Tab.BUY:
		for i in _entry_count():
			var rect := _row_rect(i)
			if rect.size != Vector2.ZERO and rect.has_point(pos):
				return i
		return NO_HIT
	if _sell_all_rect().has_point(pos):
		return HIT_SELL_ALL
	for i in InventoryManager.SLOT_COUNT:
		if _slot_rect(i).has_point(pos):
			return i
	return NO_HIT


# ---------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		queue_redraw()
	elif event is InputEventMouseButton and event.is_pressed():
		var button := event as InputEventMouseButton
		_mouse = button.position
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_scroll = maxi(_scroll - 1, 0)
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll = mini(_scroll + 1, _max_scroll())
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				var bulk := button.button_index == MOUSE_BUTTON_RIGHT
				if _tab_rect(Tab.BUY).has_point(_mouse):
					_switch_tab(Tab.BUY)
				elif _tab_rect(Tab.SELL).has_point(_mouse):
					_switch_tab(Tab.SELL)
				else:
					_click(_hit_at(_mouse), bulk)
		queue_redraw()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		close()
	elif event.is_action_pressed("move_left"):
		_switch_tab(Tab.BUY)
	elif event.is_action_pressed("move_right"):
		_switch_tab(Tab.SELL)
	else:
		return
	get_viewport().set_input_as_handled()


func _switch_tab(tab: Tab) -> void:
	if _tab == tab:
		return
	_tab = tab
	queue_redraw()


func _click(hit: int, bulk: bool) -> void:
	if hit == NO_HIT:
		return
	if _tab == Tab.BUY:
		if _animal_at(hit) != null:
			_buy_animal(_animal_at(hit))
		else:
			_buy(_item_at(hit), BUY_BULK if bulk else 1)
	elif hit == HIT_SELL_ALL:
		_sell_all_crops()
	else:
		var stack := InventoryManager.slots[hit]
		if stack != null:
			_sell(hit, stack.count if bulk else 1)


## Daftar BELI = hewan dulu, lalu item.
func _entry_count() -> int:
	return _animals.size() + _stock.size()


func _animal_at(index: int) -> AnimalData:
	return _animals[index] if index >= 0 and index < _animals.size() else null


func _item_at(index: int) -> ItemData:
	var i := index - _animals.size()
	return _stock[i] if i >= 0 and i < _stock.size() else null


func _buy_animal(data: AnimalData) -> void:
	var error := AnimalManager.buy(data)
	if error != "":
		_set_status(error, COL_RED)
	else:
		var newest = AnimalManager.animals.back()
		var color: String = newest.color_name()
		var kind := data.animal_name + (" " + color if color != "" else "")
		_set_status("%s '%s' dibeli! Ia menunggu di kandang Farm. (-%d Gold)" % [kind, newest.animal_name, data.price], COL_GREEN)
		AudioManager.play_sfx("coin")


func _buy(item: ItemData, amount: int) -> void:
	if item.category == ItemData.Category.TOOL:
		amount = 1
	var error := GameManager.buy_item(item, amount)
	if error != "":
		_set_status(error, COL_RED)
	else:
		_set_status("Membeli %d %s  (-%d Gold)" % [amount, item.item_name, item.buy_price * amount], COL_GREEN)
		AudioManager.play_sfx("coin")


func _sell(index: int, amount: int) -> void:
	var item := InventoryManager.slots[index].item
	if not shop.accepts(item):
		_set_status("%s tidak bisa dijual di sini." % item.item_name, COL_RED)
		return
	var before := InventoryManager.slots[index].count
	var earned := GameManager.sell_from_slot(shop, index, amount)
	var after_stack := InventoryManager.slots[index]
	var sold := before - (after_stack.count if after_stack != null else 0)
	_set_status("Menjual %d %s  (+%d Gold)" % [sold, item.item_name, earned], COL_GREEN)
	AudioManager.play_sfx("coin")


func _sell_all_crops() -> void:
	var total := 0
	var count := 0
	for i in InventoryManager.SLOT_COUNT:
		var stack := InventoryManager.slots[i]
		if stack == null or stack.item.category != ItemData.Category.CROP or not shop.accepts(stack.item):
			continue
		count += stack.count
		total += GameManager.sell_from_slot(shop, i, stack.count)
	if count == 0:
		_set_status("Tidak ada hasil panen yang bisa dijual di sini.", COL_RED)
	else:
		_set_status("Menjual %d hasil panen  (+%d Gold)" % [count, total], COL_GREEN)
		AudioManager.play_sfx("coin")


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var origin := _origin()
	var panel := Rect2(origin, PANEL_SIZE)
	var title := shop.shop_name.to_upper() if shop != null else "TOKO"
	UiTheme.draw_window(self, _skin, panel, title)
	var gold_text := "GOLD: %d" % GameManager.gold
	draw_string(font, origin + Vector2(PAD, 11), gold_text, HORIZONTAL_ALIGNMENT_RIGHT, PANEL_SIZE.x - PAD * 2, UiTheme.FS, UiTheme.TITLE)

	_draw_tab(font, Tab.BUY, "BELI")
	_draw_tab(font, Tab.SELL, "JUAL")
	draw_string(font, origin + Vector2(PAD + TAB_SIZE.x * 2 + 14, 36), "A / D: ganti tab   ESC: tutup", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)

	var hit := _hit_at(_mouse)
	if _tab == Tab.BUY:
		_draw_buy(font, hit)
	else:
		_draw_sell(font, hit)
	_draw_footer(font, hit)


func _draw_tab(font: Font, tab: Tab, text: String) -> void:
	var rect := _tab_rect(tab)
	var active := _tab == tab
	draw_style_box(_skin.header if active else _skin.wood, rect)
	draw_string(font, rect.position + Vector2(0, 12), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTheme.FS,
		UiTheme.TITLE if active else Color(0.95, 0.88, 0.7))


func _draw_buy(font: Font, hit: int) -> void:
	for i in _entry_count():
		var rect := _row_rect(i)
		if rect.size == Vector2.ZERO:
			continue
		draw_style_box(_skin.paper, rect)
		if i == hit:
			draw_rect(rect.grow(-1.0), UiTheme.SELECT, false, 2.0)
		var animal := _animal_at(i)
		if animal != null:
			_draw_animal_row(font, rect, animal)
			continue
		var item := _item_at(i)
		if item.icon != null:
			draw_texture(item.icon, rect.position + Vector2(3, 7))
		draw_string(font, rect.position + Vector2(23, 13), UiTheme.fit(item.item_name, rect.size.x - 76), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_TEXT)
		var owned := InventoryManager.count_of(item.id)
		var sub := "Punya: %d" % owned
		if item.category == ItemData.Category.TOOL and owned > 0:
			sub = "Sudah punya"
		draw_string(font, rect.position + Vector2(23, 26), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
		var price_color := COL_GOLD if GameManager.can_afford(item.buy_price) else COL_RED
		draw_string(font, rect.position + Vector2(0, 19), "%d G" % item.buy_price, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 4, UiTheme.FS, price_color)

	# indikator gulir
	var content := _content_rect()
	if _scroll > 0:
		draw_string(font, Vector2(content.position.x, content.position.y - 2), "^", HORIZONTAL_ALIGNMENT_RIGHT, content.size.x, UiTheme.FS, COL_GOLD)
	if _scroll < _max_scroll():
		draw_string(font, Vector2(content.position.x, content.end.y + 6), "v (gulir)", HORIZONTAL_ALIGNMENT_RIGHT, content.size.x, UiTheme.FS, COL_GOLD)


func _draw_animal_row(font: Font, rect: Rect2, animal: AnimalData) -> void:
	if animal.icon != null:
		draw_texture(animal.icon, rect.position + Vector2(3, 6))
	draw_string(font, rect.position + Vector2(25, 13), animal.animal_name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_TEXT)
	var building_name: String = AnimalManager.BUILDING_NAMES.get(animal.building, animal.building)
	var sub := "%s: %d/%d" % [building_name, AnimalManager.count_in(animal.building), AnimalManager.capacity_of(animal.building)]
	draw_string(font, rect.position + Vector2(25, 26), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
	var price_color := COL_GOLD if GameManager.can_afford(animal.price) else COL_RED
	draw_string(font, rect.position + Vector2(0, 19), "%d G" % animal.price, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 4, UiTheme.FS, price_color)


func _draw_sell(font: Font, hit: int) -> void:
	for i in InventoryManager.SLOT_COUNT:
		var rect := _slot_rect(i)
		var stack := InventoryManager.slots[i]
		var sellable := stack != null and shop.accepts(stack.item)
		UiTheme.draw_slot(self, _skin, rect, false, i == hit and sellable)
		if stack == null:
			continue
		if stack.item.icon != null:
			# Item yang tidak bisa dijual digambar redup.
			draw_texture(stack.item.icon, rect.position + Vector2(4, 4), Color.WHITE if sellable else Color(1, 1, 1, 0.3))
		UiTheme.draw_count(self, rect, stack.count)

	UiTheme.draw_button(self, _skin, _sell_all_rect(), "Jual semua hasil panen", hit == HIT_SELL_ALL)


func _draw_footer(font: Font, hit: int) -> void:
	var origin := _origin()
	var x := origin.x + PAD
	var y := origin.y + PANEL_SIZE.y - PAD - FOOTER
	var width := PANEL_SIZE.x - PAD * 2
	draw_line(Vector2(x, y), Vector2(x + width, y), Color(UiTheme.COL_BORDER, 0.4))

	var item: ItemData = null
	var line2 := ""
	if _tab == Tab.BUY and _animal_at(hit) != null:
		var animal := _animal_at(hit)
		var product := animal.product.item_name if animal.product != null else "-"
		draw_string(font, Vector2(x, y + 11), animal.animal_name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_GOLD)
		draw_string(font, Vector2(x, y + 21), "Hewan  -  Harga: %d Gold  -  Produk: %s" % [animal.price, product], HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, UiTheme.PRICE)
		draw_string(font, Vector2(x, y + 31), animal.description, HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, COL_TEXT)
	elif _tab == Tab.BUY and hit >= 0:
		item = _item_at(hit)
		line2 = "%s  -  Harga: %d Gold" % [item.category_name(), item.buy_price]
	elif _tab == Tab.SELL and hit >= 0 and InventoryManager.slots[hit] != null:
		var stack := InventoryManager.slots[hit]
		item = stack.item
		if shop.accepts(item):
			var price := GameManager.sell_price_of(item)
			line2 = "Jual: %d Gold / buah   (setumpuk: %d Gold)" % [price, price * stack.count]
			if price > item.sell_price:
				line2 += "   Harga acara!"
		else:
			line2 = "Toko tidak membeli item ini."

	if item != null:
		draw_string(font, Vector2(x, y + 11), item.item_name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_GOLD)
		draw_string(font, Vector2(x, y + 21), line2, HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, UiTheme.PRICE)
		draw_string(font, Vector2(x, y + 31), item.description, HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, COL_TEXT)
	elif _tab == Tab.BUY and _animal_at(hit) == null:
		draw_string(font, Vector2(x, y + 11), "Klik kiri: beli 1  |  Klik kanan: beli %d" % BUY_BULK, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
		draw_string(font, Vector2(x, y + 21), "Alat hanya bisa dibeli satu kali.", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
	elif _tab == Tab.SELL:
		draw_string(font, Vector2(x, y + 11), "Klik kiri: jual 1  |  Klik kanan: setumpuk", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)
		draw_string(font, Vector2(x, y + 21), "Item redup (alat) tidak bisa dijual.", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)

	if _status != "":
		draw_string(font, Vector2(x, y + 41), _status, HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, _status_color)
