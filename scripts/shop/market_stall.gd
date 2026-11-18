class_name MarketStall
extends Node2D
## Phase 22: KIOS PASAR di Farm (Market_Stand_Yellow_Small asli pack, dekat jalan ke Desa).
##   E di depan kios = buka panel kios (HUD/StallPanel): taruh barang dari tas ke rak (6 slot).
##   Pukul 09:00 - 17:00 warga desa (sprite NPC asli) datang dari arah Desa, berhenti di kios,
##   membeli 1 barang, lalu pulang. Gold langsung masuk.
##   Harga = harga jual x 1.25 (lebih untung dari toko) x permintaan harian:
##     setiap pagi satu kategori sedang "DICARI" (harga x1.6), kategori lain x1.0.
##   Barang di rak tampil di meja kios (3 barang pertama).
## Script ini dipasang pada instance MarketStand di farm.tscn. Isi rak disimpan Main (data dunia "stall").

signal message(text: String)
signal changed

const SLOT_COUNT := 6
const BASE_MULT := 1.25
const HOT_MULT := 1.6
const OPEN_HOUR := 9
const CLOSE_HOUR := 17
const HOT_CATEGORIES: Array[int] = [ItemData.Category.CROP, ItemData.Category.FISH, ItemData.Category.FOOD, ItemData.Category.MATERIAL, ItemData.Category.ORE]
const COUNTER_SLOTS: Array[Vector2] = [Vector2(-20, -32), Vector2(-8, -32), Vector2(4, -32)]
const CUSTOMER_SHEETS: Array[String] = [
	"res://assets/modern_farm/characters/npc/Npc_Mira_16x16.png",
	"res://assets/modern_farm/characters/npc/Npc_Lila_16x16.png",
	"res://assets/modern_farm/characters/npc/Npc_Toby_16x16.png",
	"res://assets/modern_farm/characters/npc/Npc_Barnaby_16x16.png",
]
const CUSTOMER_NAMES: Array[String] = ["Mira", "Lila", "Toby", "Barnaby"]

## Isi rak: ItemStack atau null.
var slots: Array = []
## Kategori yang sedang dicari hari ini (ItemData.Category).
var hot_category: int = ItemData.Category.CROP
var earned_today := 0

var _next_minute := 0          # menit game absolut kedatangan pembeli berikutnya
var _customer: Node2D
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	slots.resize(SLOT_COUNT)


func _ready() -> void:
	_rng.randomize()
	# gambar barang (_draw) harus di DEPAN gambar kios
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.show_behind_parent = true
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _on_time())
	TimeManager.day_started.connect(func(_d: int) -> void: new_day())
	_schedule_next()


## Titik interaksi player mengenai kios?
func is_at(world_pos: Vector2) -> bool:
	return Rect2(global_position + Vector2(-26, -40), Vector2(52, 52)).has_point(world_pos)


func price_of(item: ItemData) -> int:
	if item == null or item.sell_price <= 0:
		return 0
	var mult := BASE_MULT * (HOT_MULT if int(item.category) == hot_category else 1.0)
	return maxi(1, roundi(item.sell_price * mult))


func hot_name() -> String:
	return ItemData.CATEGORY_NAMES[hot_category]


func item_count() -> int:
	var n := 0
	for s in slots:
		if s != null:
			n += (s as ItemStack).count
	return n


## Masukkan barang ke rak. Mengembalikan jumlah yang masuk.
func add_item(item: ItemData, amount: int) -> int:
	var left := amount
	for i in SLOT_COUNT:
		var s: ItemStack = slots[i]
		if s != null and s.item.id == item.id and s.room() > 0:
			var m := mini(left, s.room())
			s.count += m
			left -= m
	for i in SLOT_COUNT:
		if left <= 0:
			break
		if slots[i] == null:
			var m := mini(left, item.max_stack)
			slots[i] = ItemStack.new(item, m)
			left -= m
	changed.emit()
	queue_redraw()
	return amount - left


func new_day() -> void:
	hot_category = HOT_CATEGORIES[_rng.randi_range(0, HOT_CATEGORIES.size() - 1)]
	earned_today = 0
	changed.emit()


# ---------------------------------------------------------------- pembeli

func _now() -> int:
	return TimeManager.total_day * 1440 + TimeManager.minutes


func _schedule_next() -> void:
	_next_minute = _now() + _rng.randi_range(35, 80)


func _on_time() -> void:
	var h := TimeManager.hour()
	if h < OPEN_HOUR or h >= CLOSE_HOUR or item_count() <= 0:
		return
	if _now() < _next_minute or is_instance_valid(_customer):
		return
	_schedule_next()
	var who := _rng.randi_range(0, CUSTOMER_NAMES.size() - 1)
	if is_inside_tree() and get_parent() != null:
		_spawn_customer(who)
	else:
		sell_one(CUSTOMER_NAMES[who])  # player sedang di peta lain: penjualan tetap terjadi


## Jual 1 barang acak dari rak. Mengembalikan item yang terjual (atau null).
func sell_one(buyer: String) -> ItemData:
	var filled: Array[int] = []
	for i in SLOT_COUNT:
		if slots[i] != null:
			filled.append(i)
	if filled.is_empty():
		return null
	# pembeli lebih suka barang yang sedang dicari
	var pick := filled[_rng.randi_range(0, filled.size() - 1)]
	for i in filled:
		if int((slots[i] as ItemStack).item.category) == hot_category and _rng.randf() < 0.6:
			pick = i
			break
	var stack: ItemStack = slots[pick]
	var item := stack.item
	var price := price_of(item)
	stack.count -= 1
	if stack.count <= 0:
		slots[pick] = null
	GameManager.add_gold(price)
	earned_today += price
	AudioManager.play_sfx("pickup", 0.1, -4.0)
	message.emit("%s membeli %s di kiosmu (+%d Gold)" % [buyer, item.item_name, price])
	changed.emit()
	queue_redraw()
	return item


func _spawn_customer(who: int) -> void:
	var c := StallCustomer.new()
	c.setup(load(CUSTOMER_SHEETS[who]), CUSTOMER_NAMES[who], self)
	get_parent().add_child(c)
	_customer = c


## Titik berdiri pembeli di depan kios.
func front_point() -> Vector2:
	return position + Vector2(0, 16)


# ---------------------------------------------------------------- gambar barang di meja

func _draw() -> void:
	var shown := 0
	for s in slots:
		if s == null or shown >= COUNTER_SLOTS.size():
			continue
		var item: ItemData = (s as ItemStack).item
		var tex := item.pickup_texture if item.pickup_texture != null else item.icon
		if tex != null:
			draw_texture(tex, COUNTER_SLOTS[shown])
		shown += 1


# ---------------------------------------------------------------- simpan

func state_to_save() -> Dictionary:
	var list: Array = []
	for s in slots:
		list.append({"id": (s as ItemStack).item.id, "count": (s as ItemStack).count} if s != null else {})
	return {"slots": list, "hot": hot_category, "earned": earned_today}


func state_from_save(d: Dictionary) -> void:
	slots.clear()
	slots.resize(SLOT_COUNT)
	var list: Array = d.get("slots", [])
	for i in mini(list.size(), SLOT_COUNT):
		var e: Dictionary = list[i]
		var item := InventoryManager.get_item(String(e.get("id", "")))
		if item != null:
			slots[i] = ItemStack.new(item, maxi(1, int(e.get("count", 1))))
	hot_category = int(d.get("hot", ItemData.Category.CROP))
	earned_today = int(d.get("earned", 0))
	changed.emit()
	queue_redraw()
