class_name Hotbar
extends Control
## Hotbar 8 slot di bawah layar (slot 0-7 InventoryManager). Memakai icon asli Modern_Farm.
## Menampilkan jumlah item, nomor tombol, dan nama item terpilih.
## Gaya: papan kayu + kotak slot dari asset RPG UI (UiTheme.UiSkin).

const SLOT := 20
const GAP := 2
const PAD := 3  # tepi papan kayu di sekeliling slot

var _skin: UiTheme.UiSkin


## Phase 13: slot bisa diketuk / diklik untuk memilih item (pengganti tombol 1-8 di HP).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var index := floori((event as InputEventMouseButton).position.x / float(SLOT + GAP))
		if index >= 0 and index < InventoryManager.HOTBAR_SIZE:
			InventoryManager.select(index)
			accept_event()


func _ready() -> void:
	_skin = UiTheme.UiSkin.new()
	InventoryManager.inventory_changed.connect(queue_redraw)
	InventoryManager.selected_changed.connect(func(_i: int) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := InventoryManager.HOTBAR_SIZE * (SLOT + GAP) - GAP
	draw_style_box(_skin.bar, Rect2(-PAD, -PAD, width + PAD * 2, SLOT + PAD * 2))
	for i in InventoryManager.HOTBAR_SIZE:
		var rect := Rect2(Vector2(i * (SLOT + GAP), 0), Vector2(SLOT, SLOT))
		UiTheme.draw_slot(self, _skin, rect, i == InventoryManager.selected)
		var stack := InventoryManager.slots[i]
		if stack != null and stack.item.icon != null:
			draw_texture(stack.item.icon, rect.position + Vector2(2, 2))
		draw_string_outline(font, rect.position + Vector2(2, 8), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, 2, Color(0.2, 0.1, 0.05))
		draw_string(font, rect.position + Vector2(2, 8), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, Color(1, 0.95, 0.8))
		if stack != null:
			UiTheme.draw_count(self, rect, stack.count)
	var current := InventoryManager.current_item()
	if current != null:
		var name_w := font.get_string_size(current.item_name, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS).x + 14
		var tag := Rect2(floorf((width - name_w) / 2.0), -PAD - 15, name_w, 13)
		draw_style_box(_skin.header, tag)
		draw_string(font, Vector2(tag.position.x, tag.position.y + 10), current.item_name, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, UiTheme.FS, UiTheme.TITLE)
