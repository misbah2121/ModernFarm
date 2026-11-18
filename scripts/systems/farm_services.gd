extends Node
## Autoload "FarmServices" (Phase 19): upgrade tahap lanjut yang dikelola lewat PAPAN FARM.
##   * Traktor : level 0 = rusak, 1 = diperbaiki (bajak 3 petak), 2 = + alat penyiram.
##   * Pekerja : warga yang bisa direkrut (digaji harian). Makin lama bekerja, level naik
##               (hari ke-7 = Lv 2, hari ke-21 = Lv 3) dan tugasnya makin banyak.
## Hanya menyimpan DATA (ikut disimpan SaveManager). Pekerjaan hariannya dilakukan FarmWorkers (anak FarmMap).

signal changed

## Biaya traktor per level tujuan: [gold, item_id, jumlah].
const TRACTOR_COSTS := {
	1: [2000, "iron_ore", 5],
	2: [5000, "gold_ore", 5],
}
const TRACTOR_LEVEL_NAMES := ["Rusak", "Bajak", "Bajak + Penyiram"]
const LEVEL_DAYS: Array[int] = [0, 7, 21]

## Data pekerja. wage = gaji per hari untuk Lv 1/2/3. tasks = keterangan tugas per level.
const WORKERS := [
	{
		"id": "waterer", "name": "Budi", "role": "Penyiram", "wage": [60, 90, 120],
		"tasks": ["Menyiram 12 petak tiap pagi", "Menyiram 30 petak tiap pagi", "Menyiram SEMUA petak tiap pagi"],
	},
	{
		"id": "harvester", "name": "Sari", "role": "Pemanen", "wage": [80, 110, 150],
		"tasks": ["Memanen 6 tanaman matang", "Memanen 15 tanaman matang", "Memanen semua tanaman + pohon buah"],
	},
	{
		"id": "rancher", "name": "Joko", "role": "Peternak", "wage": [70, 100, 130],
		"tasks": ["Mengisi pakan ternak yang lapar", "Pakan + mengambil telur, susu, wol", "Pakan + hasil ternak + mengelus semua hewan"],
	},
]

var tractor_level := 0
var hired: Dictionary = {}       # id -> bool
var days_worked: Dictionary = {} # id -> int


func reset() -> void:
	tractor_level = 0
	hired.clear()
	days_worked.clear()
	changed.emit()


# ---------------------------------------------------------------- pekerja

func worker(id: String) -> Dictionary:
	for w: Dictionary in WORKERS:
		if w["id"] == id:
			return w
	return {}


func is_hired(id: String) -> bool:
	return bool(hired.get(id, false))


func level_of(id: String) -> int:
	var days := int(days_worked.get(id, 0))
	var lvl := 1
	for i in LEVEL_DAYS.size():
		if days >= LEVEL_DAYS[i]:
			lvl = i + 1
	return lvl


func wage_of(id: String) -> int:
	var w := worker(id)
	return int((w["wage"] as Array)[level_of(id) - 1]) if not w.is_empty() else 0


func task_of(id: String) -> String:
	var w := worker(id)
	return String((w["tasks"] as Array)[level_of(id) - 1]) if not w.is_empty() else ""


## Hari kerja sampai level berikutnya (0 = sudah maksimal).
func days_to_next(id: String) -> int:
	var lvl := level_of(id)
	if lvl >= LEVEL_DAYS.size():
		return 0
	return LEVEL_DAYS[lvl] - int(days_worked.get(id, 0))


func set_hired(id: String, value: bool) -> void:
	hired[id] = value
	changed.emit()


func add_day(id: String) -> bool:
	var before := level_of(id)
	days_worked[id] = int(days_worked.get(id, 0)) + 1
	return level_of(id) > before  # true = naik level


# ---------------------------------------------------------------- traktor

## Alasan tidak bisa upgrade, atau "" jika bisa.
func tractor_upgrade_check() -> String:
	if not TRACTOR_COSTS.has(tractor_level + 1):
		return "Traktor sudah maksimal."
	var cost: Array = TRACTOR_COSTS[tractor_level + 1]
	if GameManager.gold < int(cost[0]):
		return "Gold kurang (butuh %d)." % int(cost[0])
	if InventoryManager.count_of(String(cost[1])) < int(cost[2]):
		var item := InventoryManager.get_item(String(cost[1]))
		return "Butuh %d %s." % [int(cost[2]), item.item_name if item != null else String(cost[1])]
	return ""


func tractor_upgrade() -> String:
	var reason := tractor_upgrade_check()
	if reason != "":
		return reason
	var cost: Array = TRACTOR_COSTS[tractor_level + 1]
	GameManager.spend_gold(int(cost[0]))
	InventoryManager.remove_item(String(cost[1]), int(cost[2]))
	tractor_level += 1
	changed.emit()
	return ""


# ---------------------------------------------------------------- simpan

func to_save() -> Dictionary:
	return {"tractor_level": tractor_level, "hired": hired.duplicate(), "days": days_worked.duplicate()}


func from_save(d: Dictionary) -> void:
	tractor_level = clampi(int(d.get("tractor_level", 0)), 0, TRACTOR_LEVEL_NAMES.size() - 1)
	hired.clear()
	days_worked.clear()
	var h: Dictionary = d.get("hired", {})
	for id: String in h:
		hired[id] = bool(h[id])
	var dw: Dictionary = d.get("days", {})
	for id: String in dw:
		days_worked[id] = int(dw[id])
	changed.emit()
