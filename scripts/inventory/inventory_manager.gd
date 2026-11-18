extends Node
## Autoload "InventoryManager": isi tas, pilihan hotbar, dan registri semua ItemData.
## Slot 0-7 = hotbar (baris pertama tas), slot 8-23 = tas. Slot kosong bernilai null.

signal inventory_changed
signal selected_changed(index: int)
## Pesan singkat untuk toast di layar (dipasang ke HUD oleh Main).
signal message(text: String)

const SLOT_COUNT := 24
const HOTBAR_SIZE := 8
const ITEMS_DIR := "res://data/items/"
## Isi tas saat game baru: [id item, jumlah]. Urutan = urutan slot.
const STARTING_ITEMS: Array = [
	["hoe", 1], ["watering_can", 1],
	["seeds_carrot", 5], ["seeds_radish", 5], ["seeds_onion", 5],
	["seeds_tomato", 5], ["seeds_corn", 5], ["seeds_pumpkin", 5],
]
## Item untuk tombol debug F2 (uji tumpukan dan tas penuh).
const DEBUG_ITEMS: Array = [
	["seeds_carrot", 5], ["seeds_radish", 5], ["seeds_onion", 5],
	["seeds_tomato", 5], ["seeds_corn", 5], ["seeds_pumpkin", 5],
	["wood", 8], ["egg", 3], ["milk", 2],
	["carrot", 10], ["tomato", 5], ["pumpkin", 3],
	["animal_feed", 10], ["sapling_apple", 2], ["sapling_lemon", 2],  # Phase 15: bibit pohon
	["wood", 50], ["stone", 20], ["copper_ore", 6], ["iron_ore", 4],  # Phase 14: bahan kerajinan
]

var slots: Array[ItemStack] = []
var selected: int = 0

var _items: Dictionary = {}  # id -> ItemData


func _ready() -> void:
	_load_items()
	reset()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for i in HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			select(i)
			return
	if event.is_action_pressed("tool_next"):
		select(selected + 1)
	elif event.is_action_pressed("tool_previous"):
		select(selected - 1)
	elif event.is_action_pressed("debug_give_items"):
		for entry: Array in DEBUG_ITEMS:
			add_item_by_id(entry[0], entry[1])
		for tool_id: String in ["fishing_rod", "axe", "pickaxe"]:  # alat uji (Phase 8 & 10)
			if count_of(tool_id) == 0:
				add_item_by_id(tool_id, 1)
		message.emit("[Debug] Item uji ditambahkan.")


# ---------------------------------------------------------------- registri item

func _load_items() -> void:
	for file_name in DirAccess.get_files_at(ITEMS_DIR):
		# Di game hasil export, resource bisa terdaftar sebagai "xxx.tres.remap".
		var clean := file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var item := load(ITEMS_DIR + clean) as ItemData
		if item == null:
			push_warning("Bukan ItemData: %s" % clean)
			continue
		_items[item.id] = item


func get_item(id: String) -> ItemData:
	return _items.get(id) as ItemData


# ---------------------------------------------------------------- hotbar

func select(index: int) -> void:
	index = wrapi(index, 0, HOTBAR_SIZE)
	if index == selected:
		return
	selected = index
	selected_changed.emit(selected)


func current_stack() -> ItemStack:
	return slots[selected]


func current_item() -> ItemData:
	var stack := slots[selected]
	return stack.item if stack != null else null


## ToolData dari item terpilih (alat atau benih), null jika slot kosong / item biasa.
func current_tool() -> ToolData:
	var item := current_item()
	return item.tool_data if item != null else null


## Mengurangi item terpilih (dipakai saat menanam benih). False jika tidak cukup.
func consume_selected(amount: int = 1) -> bool:
	var stack := slots[selected]
	if stack == null or stack.count < amount:
		return false
	stack.count -= amount
	if stack.count <= 0:
		slots[selected] = null
	inventory_changed.emit()
	return true


# ---------------------------------------------------------------- tambah / kurangi

func count_of(id: String) -> int:
	var total := 0
	for stack in slots:
		if stack != null and stack.item.id == id:
			total += stack.count
	return total


## True jika seluruh `amount` item masih muat di tas.
func can_add(item: ItemData, amount: int = 1) -> bool:
	var room := 0
	for stack in slots:
		if stack == null:
			room += item.max_stack
		elif stack.item.id == item.id:
			room += stack.room()
		if room >= amount:
			return true
	return false


## Menambah item: mengisi tumpukan yang ada dulu, baru slot kosong. Mengembalikan sisa yang tidak muat.
func add_item(item: ItemData, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount
	var left := amount
	for i in SLOT_COUNT:
		var stack := slots[i]
		if stack != null and stack.item.id == item.id and stack.room() > 0:
			var moved := mini(left, stack.room())
			stack.count += moved
			left -= moved
			if left == 0:
				break
	if left > 0:
		for i in SLOT_COUNT:
			if slots[i] == null:
				var moved := mini(left, item.max_stack)
				slots[i] = ItemStack.new(item, moved)
				left -= moved
				if left == 0:
					break
	if left < amount:
		inventory_changed.emit()
	return left


func add_item_by_id(id: String, amount: int = 1) -> int:
	var item := get_item(id)
	if item == null:
		push_warning("Item tidak dikenal: %s" % id)
		return amount
	return add_item(item, amount)


## Mengurangi item berdasarkan id (dari slot mana saja). False jika jumlahnya tidak cukup.
func remove_item(id: String, amount: int = 1) -> bool:
	if count_of(id) < amount:
		return false
	var left := amount
	for i in SLOT_COUNT:
		var stack := slots[i]
		if stack == null or stack.item.id != id:
			continue
		var taken := mini(left, stack.count)
		stack.count -= taken
		left -= taken
		if stack.count <= 0:
			slots[i] = null
		if left == 0:
			break
	inventory_changed.emit()
	return true


## Mengurangi sampai `amount` item dari satu slot. Mengembalikan jumlah yang benar-benar diambil.
func remove_from_slot(index: int, amount: int = 1) -> int:
	if index < 0 or index >= SLOT_COUNT:
		return 0
	var stack := slots[index]
	if stack == null or amount <= 0:
		return 0
	var taken := mini(amount, stack.count)
	stack.count -= taken
	if stack.count <= 0:
		slots[index] = null
	inventory_changed.emit()
	return taken


# ---------------------------------------------------------------- operasi UI (klik mouse)

## Mengambil seluruh tumpukan dari slot.
func take_stack(index: int) -> ItemStack:
	var stack := slots[index]
	if stack == null:
		return null
	slots[index] = null
	inventory_changed.emit()
	return stack


## Mengambil setengah (dibulatkan ke atas) dari tumpukan.
func take_half(index: int) -> ItemStack:
	var stack := slots[index]
	if stack == null:
		return null
	var half := ceili(stack.count / 2.0)
	stack.count -= half
	if stack.count <= 0:
		slots[index] = null
	inventory_changed.emit()
	return ItemStack.new(stack.item, half)


## Menaruh tumpukan yang sedang dipegang ke slot: slot kosong = taruh, item sama = gabung,
## item lain = tukar. Mengembalikan sisa yang masih dipegang (null jika habis).
func place_stack(index: int, held: ItemStack) -> ItemStack:
	var target := slots[index]
	var result: ItemStack = null
	if target == null:
		slots[index] = held
	elif target.same_item(held):
		var moved := mini(held.count, target.room())
		target.count += moved
		held.count -= moved
		result = held if held.count > 0 else null
	else:
		slots[index] = held
		result = target
	inventory_changed.emit()
	return result


## Menaruh satu buah dari tumpukan yang dipegang. Mengembalikan tumpukan yang masih dipegang.
func place_one(index: int, held: ItemStack) -> ItemStack:
	var target := slots[index]
	if target == null:
		slots[index] = ItemStack.new(held.item, 1)
	elif target.same_item(held) and target.room() > 0:
		target.count += 1
	else:
		return held
	held.count -= 1
	inventory_changed.emit()
	return held if held.count > 0 else null


# ---------------------------------------------------------------- simpan / game baru (Phase 12)

func reset() -> void:
	slots.clear()
	slots.resize(SLOT_COUNT)
	selected = 0
	for entry: Array in STARTING_ITEMS:
		add_item_by_id(entry[0], entry[1])
	inventory_changed.emit()
	selected_changed.emit(selected)


func to_save() -> Dictionary:
	var list: Array = []
	for stack in slots:
		list.append([stack.item.id, stack.count] if stack != null else null)
	return {"slots": list, "selected": selected}


func from_save(d: Dictionary) -> void:
	slots.clear()
	slots.resize(SLOT_COUNT)
	var list: Array = d.get("slots", [])
	for i in mini(list.size(), SLOT_COUNT):
		var entry = list[i]
		if entry is Array and entry.size() == 2:
			var item := get_item(String(entry[0]))
			if item != null:
				slots[i] = ItemStack.new(item, clampi(int(entry[1]), 1, item.max_stack))
	selected = clampi(int(d.get("selected", 0)), 0, HOTBAR_SIZE - 1)
	inventory_changed.emit()
	selected_changed.emit(selected)
