class_name FarmWorkers
extends Node
## Phase 19: pekerjaan harian para pekerja farm (dibuat FarmMap lewat kode, anak node FarmMap).
## Setiap pagi (setelah tanah dikeringkan & hewan diberi makan otomatis), tiap pekerja yang direkrut:
##   1. dibayar gajinya (FarmServices.wage_of). Gold kurang = pekerja libur hari itu.
##   2. bekerja sesuai level:
##      Penyiram (Budi) : menyiram 12 / 30 / semua petak kering (tanaman lebih dulu). Hari hujan = libur, tidak dibayar.
##      Pemanen  (Sari) : memanen 6 / 15 / semua tanaman matang (+ pohon buah di Lv 3).
##      Peternak (Joko) : Lv1 membeli & mengisi pakan untuk hewan lapar, Lv2 + mengambil hasil ternak,
##                        Lv3 + mengelus semua hewan.
##   Hasil panen / ternak dimasukkan ke Peti Kayu di Farm; jika penuh / tidak ada peti -> ke tas.
##   3. hari kerja +1 (naik level di hari ke-7 dan ke-21).
## Ringkasan pekerjaan muncul sebagai pesan (toast) pagi hari.
## Juga menampilkan sosok pekerja (FarmWorkerNpc) di lahan pertanian.

const SHEETS := {
	"waterer": "res://assets/modern_farm/characters/workers/Worker_Budi_16x16.png",
	"harvester": "res://assets/modern_farm/characters/workers/Worker_Sari_16x16.png",
	"rancher": "res://assets/modern_farm/characters/workers/Worker_Joko_16x16.png",
}
const WATER_LIMIT: Array[int] = [12, 30, 9999]
const HARVEST_LIMIT: Array[int] = [6, 15, 9999]
const FEED_ITEM := "animal_feed"

var farm: FarmMap
var _npcs: Dictionary = {}  # id -> FarmWorkerNpc


func setup(p_farm: FarmMap) -> void:
	farm = p_farm
	TimeManager.day_started.connect(func(_d: int) -> void: run_day())
	FarmServices.changed.connect(refresh_npcs)
	refresh_npcs()


## Tampilkan / hapus sosok pekerja sesuai status rekrut.
func refresh_npcs() -> void:
	for w: Dictionary in FarmServices.WORKERS:
		var id: String = w["id"]
		var hired := FarmServices.is_hired(id)
		if hired and not _npcs.has(id):
			var npc := FarmWorkerNpc.new()
			npc.setup(id, load(SHEETS[id]), farm)
			farm.objects.add_child(npc)
			_npcs[id] = npc
		elif not hired and _npcs.has(id):
			(_npcs[id] as Node).queue_free()
			_npcs.erase(id)


## Pekerja di titik interaksi (untuk tombol E), atau "".
func worker_at(world_pos: Vector2) -> String:
	for id: String in _npcs:
		if (_npcs[id] as FarmWorkerNpc).is_at(world_pos):
			return id
	return ""


func run_day() -> void:
	var report: Array[String] = []
	var paid := 0
	for w: Dictionary in FarmServices.WORKERS:
		var id: String = w["id"]
		if not FarmServices.is_hired(id):
			continue
		var who: String = w["name"]
		if id == "waterer" and TimeManager.is_raining():
			report.append("%s libur (hujan menyiram tanah)" % who)
			continue
		var wage := FarmServices.wage_of(id)
		if not GameManager.spend_gold(wage):
			report.append("%s libur (Gold kurang untuk gaji %d)" % [who, wage])
			continue
		paid += wage
		var lvl := FarmServices.level_of(id)
		var text := ""
		match id:
			"waterer":
				text = _do_water(lvl)
			"harvester":
				text = _do_harvest(lvl)
			"rancher":
				text = _do_ranch(lvl)
		if FarmServices.add_day(id):
			text += " - NAIK ke Lv %d!" % FarmServices.level_of(id)
		report.append("%s %s" % [who, text])
	if report.is_empty():
		return
	var summary := "Pekerja: " + "; ".join(report)
	if paid > 0:
		summary += ". Gaji -%d Gold" % paid
	farm.soil.message.emit(summary)


func _do_water(lvl: int) -> String:
	var n := 0
	for cell in farm.soil.dry_cells():
		if n >= WATER_LIMIT[lvl - 1]:
			break
		if farm.soil.water_cell(cell):
			n += 1
	return "menyiram %d petak" % n


func _do_harvest(lvl: int) -> String:
	var n := 0
	var full := false
	for cell in farm.soil.ripe_cells():
		if n >= HARVEST_LIMIT[lvl - 1]:
			break
		var crop_data := farm.soil.get_crop(cell).data
		var crop_item := InventoryManager.get_item(crop_data.id)
		if crop_item == null or not _has_room(crop_item):
			full = true
			break
		_store(farm.soil.take_harvest(cell), 1)
		n += 1
	if lvl >= 3:
		for node in farm.objects.get_children():
			if node is FruitTree and (node as FruitTree).fruit == FruitTree.Fruit.RIPE:
				var tree := node as FruitTree
				var fruit := InventoryManager.get_item(tree.fruit_id)
				if fruit == null or not _has_room(fruit):
					full = true
					break
				tree.fruit = FruitTree.Fruit.UNRIPE
				tree.fruit_days = 0
				tree._refresh()
				_store(fruit, FruitTree.FRUIT_PER_HARVEST)
				n += FruitTree.FRUIT_PER_HARVEST
	return "memanen %d hasil%s" % [n, " (peti & tas penuh!)" if full else ""]


func _do_ranch(lvl: int) -> String:
	var parts: Array[String] = []
	var hungry := AnimalManager.hungry_count()
	if hungry > 0:
		var feed := InventoryManager.get_item(FEED_ITEM)
		var price := feed.buy_price if feed != null else 20
		var can_buy := mini(hungry, floori(GameManager.gold / float(maxi(price, 1))))
		var added := AnimalManager.add_feed(can_buy) if can_buy > 0 else 0
		if added > 0:
			GameManager.spend_gold(added * price)
			parts.append("memberi pakan %d hewan (-%d Gold)" % [added, added * price])
	if lvl >= 2:
		var got := 0
		for a in AnimalManager.animals:
			if a.ready_item() == null or not _has_room(a.ready_item()):
				continue
			var product := AnimalManager.worker_collect(a)
			if product != null:
				_store(product, 1)
				got += 1
		if got > 0:
			parts.append("mengambil %d hasil ternak" % got)
	if lvl >= 3:
		var pet := AnimalManager.worker_pet_all()
		if pet > 0:
			parts.append("mengelus %d hewan" % pet)
	return ", ".join(parts) if not parts.is_empty() else "mengecek kandang (semua beres)"


# ---------------------------------------------------------------- simpan hasil

func _chests() -> Array[StorageChest]:
	var result: Array[StorageChest] = []
	for node in farm.objects.get_children():
		if node is StorageChest:
			result.append(node as StorageChest)
	return result


func _has_room(item: ItemData) -> bool:
	for chest in _chests():
		for s in chest.slots:
			if s == null or (s.item.id == item.id and s.room() > 0):
				return true
	return InventoryManager.can_add(item, 1)


## Peti dulu, sisanya ke tas.
func _store(item: ItemData, amount: int) -> void:
	if item == null:
		return
	var left := amount
	for chest in _chests():
		left = chest.add_item(item, left)
		if left == 0:
			return
	InventoryManager.add_item(item, left)
