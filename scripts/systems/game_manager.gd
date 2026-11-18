extends Node
## Autoload "GameManager".
## Phase 1: konstanta global + mendaftarkan Input Actions lewat kode
## (supaya tidak perlu mengisi Input Map manual dan tidak bergantung versi format file).
## Phase 7: ekonomi - Gold player, beli dari toko, jual ke toko. Gold tidak pernah negatif.
## Phase 12: stamina (energi) - alat memakai ToolData.stamina_cost, makan makanan menambah energi,
## tidur memulihkan penuh (pingsan jam 2 pagi = hanya setengah).

signal gold_changed(gold: int)
signal stamina_changed(value: int, max_value: int)
## Pesan untuk toast (dipasang Main).
signal message(text: String)
## Phase 18: bonus makanan berubah (mulai / habis).
signal buffs_changed

const TILE_SIZE := 16
const STARTING_GOLD := 500
const MAX_GOLD := 9_999_999
const MAX_STAMINA := 100

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E],
	"inventory": [KEY_I],
	"quest_log": [KEY_J],  # Phase 11: daftar tugas
	"world_map": [KEY_M],  # peta dunia (gulungan peta)
	"craft": [KEY_C],  # Phase 14: menu kerajinan
	"pause": [KEY_ESCAPE],
	"tool_use": [KEY_SPACE],
	"tool_next": [KEY_PERIOD],
	"tool_previous": [KEY_COMMA],
	"debug_next_day": [KEY_N],  # debug: langsung tidur (lewati sisa hari)
	"debug_give_items": [KEY_F2],  # debug: tambah item uji ke inventory
	"help": [KEY_F1],  # Phase 12: tampilkan / sembunyikan daftar kontrol
	"hotbar_1": [KEY_1],
	"hotbar_2": [KEY_2],
	"hotbar_3": [KEY_3],
	"hotbar_4": [KEY_4],
	"hotbar_5": [KEY_5],
	"hotbar_6": [KEY_6],
	"hotbar_7": [KEY_7],
	"hotbar_8": [KEY_8],
}


var gold: int = STARTING_GOLD
var stamina: int = MAX_STAMINA

## Phase 18: bonus makanan aktif. Kunci "speed" / "fishing" -> menit game absolut saat bonus habis.
const SPEED_BONUS := 1.35
var buff_until: Dictionary = {}


func _ready() -> void:
	_register_input_actions()


func _register_input_actions() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			continue  # sudah didefinisikan manual di Project Settings > Input Map
		InputMap.add_action(action)
		for keycode: int in ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode as Key
			InputMap.action_add_event(action, event)


# ---------------------------------------------------------------- ekonomi (Phase 7)

func can_afford(amount: int) -> bool:
	return amount >= 0 and gold >= amount


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold = mini(gold + amount, MAX_GOLD)
	gold_changed.emit(gold)


## Mengurangi Gold. False (dan Gold tidak berubah) jika tidak cukup.
func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


## Membeli `amount` item dari toko. Mengembalikan "" jika berhasil, atau pesan alasan gagal.
## Urutan cek: dijual? -> alat sudah punya? -> Gold cukup? -> tas muat? Baru Gold dikurangi.
func buy_item(item: ItemData, amount: int = 1) -> String:
	if item == null or item.buy_price <= 0 or amount <= 0:
		return "Barang ini tidak dijual."
	if item.category == ItemData.Category.TOOL:
		amount = 1
		if InventoryManager.count_of(item.id) > 0:
			return "Kamu sudah punya %s." % item.item_name
	var cost := item.buy_price * amount
	if not can_afford(cost):
		return "Gold tidak cukup (butuh %d)." % cost
	if not InventoryManager.can_add(item, amount):
		return "Tas penuh."
	spend_gold(cost)
	var left := InventoryManager.add_item(item, amount)
	if left > 0:
		add_gold(item.buy_price * left)  # pengaman: kembalikan Gold untuk item yang tidak muat
	return ""


## Harga jual satu item hari ini (Phase 11: acara bisa menaikkan harga kategori tertentu).
func sell_price_of(item: ItemData) -> int:
	if item == null:
		return 0
	return roundi(item.sell_price * EventManager.sell_multiplier(item))


## Menjual sampai `amount` item dari slot inventory ke toko. Mengembalikan Gold yang didapat
## (0 jika toko tidak menerima item itu / slot kosong).
func sell_from_slot(shop: ShopData, index: int, amount: int = 1) -> int:
	var stack := InventoryManager.slots[index]
	if stack == null or not shop.accepts(stack.item):
		return 0
	var item := stack.item
	var sold := InventoryManager.remove_from_slot(index, amount)
	var earned := sold * sell_price_of(item)
	add_gold(earned)
	return earned


# ---------------------------------------------------------------- stamina (Phase 12)

## Mengurangi stamina. False (stamina tidak berubah) jika tidak cukup.
func use_stamina(amount: int) -> bool:
	if amount <= 0:
		return true
	if stamina < amount:
		message.emit("Terlalu lelah! Makan sesuatu atau tidur dulu.")
		return false
	stamina -= amount
	stamina_changed.emit(stamina, MAX_STAMINA)
	return true


func restore_stamina(amount: int) -> void:
	stamina = clampi(stamina + amount, 0, MAX_STAMINA)
	stamina_changed.emit(stamina, MAX_STAMINA)


## Makan item yang sedang dipilih (ItemData.energy > 0). True jika dimakan.
func eat_selected() -> bool:
	var item := InventoryManager.current_item()
	if item == null or item.energy <= 0:
		return false
	# Makanan dengan bonus tetap boleh dimakan walau stamina penuh.
	if stamina >= MAX_STAMINA and item.buff <= 0:
		message.emit("Kamu masih kenyang.")
		return true
	InventoryManager.consume_selected(1)
	restore_stamina(item.energy)
	var text := "Makan %s. Energi +%d" % [item.item_name, item.energy]
	if item.buff > 0 and item.buff_minutes > 0:
		_apply_food_buff(item)
		text += "  |  Bonus: %s" % item.buff_text()
	message.emit(text)
	return true


# ---------------------------------------------------------------- bonus makanan (Phase 18)

static func _now() -> int:
	return TimeManager.total_day * 1440 + TimeManager.minutes


func _apply_food_buff(item: ItemData) -> void:
	var until := _now() + item.buff_minutes
	if item.buff == 1 or item.buff == 3:
		buff_until["speed"] = maxi(int(buff_until.get("speed", 0)), until)
	if item.buff == 2 or item.buff == 3:
		buff_until["fishing"] = maxi(int(buff_until.get("fishing", 0)), until)
	buffs_changed.emit()


## Bonus "speed" / "fishing" sedang aktif?
func has_buff(kind: String) -> bool:
	return int(buff_until.get(kind, 0)) > _now()


## Pengali kecepatan jalan player.
func speed_multiplier() -> float:
	return SPEED_BONUS if has_buff("speed") else 1.0


## Sisa menit bonus (0 = tidak aktif).
func buff_minutes_left(kind: String) -> int:
	return maxi(int(buff_until.get(kind, 0)) - _now(), 0)


## Dipanggil HUD tiap menit game: hapus bonus yang sudah habis.
func update_buffs() -> void:
	var expired := false
	for kind: String in buff_until.keys():
		if int(buff_until[kind]) <= _now():
			buff_until.erase(kind)
			expired = true
	if expired:
		message.emit("Bonus makanan sudah habis.")
		buffs_changed.emit()


static func duration_text(minutes: int) -> String:
	if minutes >= 60:
		var h := floori(minutes / 60.0)
		var m := minutes % 60
		return "%d jam" % h if m == 0 else "%d jam %d mnt" % [h, m]
	return "%d mnt" % minutes


# ---------------------------------------------------------------- simpan / game baru (Phase 12)

func reset() -> void:
	gold = STARTING_GOLD
	stamina = MAX_STAMINA
	buff_until.clear()
	buffs_changed.emit()
	gold_changed.emit(gold)
	stamina_changed.emit(stamina, MAX_STAMINA)


func to_save() -> Dictionary:
	return {"gold": gold, "stamina": stamina, "buffs": buff_until.duplicate()}


func from_save(d: Dictionary) -> void:
	gold = clampi(int(d.get("gold", STARTING_GOLD)), 0, MAX_GOLD)
	stamina = clampi(int(d.get("stamina", MAX_STAMINA)), 0, MAX_STAMINA)
	buff_until.clear()
	var buffs: Dictionary = d.get("buffs", {})
	for kind: String in buffs:
		buff_until[kind] = int(buffs[kind])
	buffs_changed.emit()
	gold_changed.emit(gold)
	stamina_changed.emit(stamina, MAX_STAMINA)
