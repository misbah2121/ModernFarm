class_name StorageChest
extends PlacedObject
## Phase 14: Peti penyimpanan (24 slot). E = buka panel peti (ChestPanel, dibuka oleh Main).
## Sprite: Trunk_Closed_1 (tertutup) / Trunk_Open_1 (terbuka saat panel tampil).
## Hanya bisa diambil (Pickaxe / Axe) jika isinya kosong.

const SLOT_COUNT := 24
const TEX_CLOSED := "res://assets/modern_farm/objects/machines/Trunk_Closed_1_16x16.png"
const TEX_OPEN := "res://assets/modern_farm/objects/machines/Trunk_Open_1_16x16.png"

@onready var sprite: Sprite2D = $Sprite2D

## Isi peti: Array berisi ItemStack atau null (sama seperti InventoryManager.slots).
var slots: Array = []
var is_open := false

var _tex_closed: Texture2D
var _tex_open: Texture2D


func _init() -> void:
	slots.resize(SLOT_COUNT)


func _ready() -> void:
	_tex_closed = load(TEX_CLOSED)
	_tex_open = load(TEX_OPEN)
	set_open(false)


## Ganti sprite tertutup / terbuka (gambar terbuka lebih tinggi 16 px).
func set_open(value: bool) -> void:
	is_open = value
	sprite.texture = _tex_open if value else _tex_closed
	sprite.position = Vector2(-16, -48 if value else -32)


func is_empty() -> bool:
	for stack in slots:
		if stack != null:
			return false
	return true


## Phase 19: masukkan barang (dipakai pekerja farm). Mengembalikan jumlah yang TIDAK muat.
func add_item(item: ItemData, amount: int) -> int:
	var left := amount
	for i in SLOT_COUNT:
		var s: ItemStack = slots[i]
		if s != null and s.item.id == item.id and s.room() > 0:
			var m := mini(left, s.room())
			s.count += m
			left -= m
			if left == 0:
				return 0
	for i in SLOT_COUNT:
		if slots[i] == null:
			var m := mini(left, item.max_stack)
			slots[i] = ItemStack.new(item, m)
			left -= m
			if left == 0:
				return 0
	return left


func interact() -> String:
	return ""  # Main membuka ChestPanel


func can_pick_up() -> String:
	return "" if is_empty() else "Kosongkan peti dulu sebelum diambil."


func state_to_save() -> Dictionary:
	var list: Array = []
	for i in SLOT_COUNT:
		var stack: ItemStack = slots[i]
		list.append({"id": stack.item.id, "count": stack.count} if stack != null else {})
	return {"slots": list}


func state_from_save(d: Dictionary) -> void:
	var list: Array = d.get("slots", [])
	for i in mini(list.size(), SLOT_COUNT):
		var entry: Dictionary = list[i]
		var item := InventoryManager.get_item(String(entry.get("id", "")))
		slots[i] = ItemStack.new(item, int(entry.get("count", 1))) if item != null else null
