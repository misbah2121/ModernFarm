extends Node
## Autoload "QuestManager" (Phase 11): status dan progres semua tugas.
## Status: AVAILABLE (bisa ditawarkan) -> ACTIVE -> COMPLETE (target tercapai, belum lapor) -> DONE.
## Kegiatan di game memanggil report(): panen (Main), ikan (Main), kumpul item (ResourceNode,
## AnimalManager). Tugas DELIVER dihitung dari isi tas saat bicara dengan pemberi tugas.

signal quest_changed(quest: QuestData)
## Pesan untuk toast (dipasang Main).
signal message(text: String)

enum Status { LOCKED, AVAILABLE, ACTIVE, COMPLETE, DONE }

const QUEST_DIR := "res://data/quests/"
const STATUS_NAMES: Array[String] = ["Terkunci", "Tersedia", "Aktif", "Selesai - laporkan", "Tuntas"]

var _quests: Array[QuestData] = []
var _status: Dictionary = {}    # id -> Status
var _progress: Dictionary = {}  # id -> int


func _ready() -> void:
	_load_quests()


func _load_quests() -> void:
	for file_name in DirAccess.get_files_at(QUEST_DIR):
		var clean := file_name.trim_suffix(".remap")  # hasil export
		if not clean.ends_with(".tres"):
			continue
		var quest := load(QUEST_DIR + clean) as QuestData
		if quest == null:
			push_warning("Bukan QuestData: %s" % clean)
			continue
		_quests.append(quest)
		_status[quest.id] = Status.LOCKED
		_progress[quest.id] = 0
	_quests.sort_custom(func(a: QuestData, b: QuestData) -> bool: return a.order < b.order)


func all_quests() -> Array[QuestData]:
	return _quests


func get_quest(id: String) -> QuestData:
	for q in _quests:
		if q.id == id:
			return q
	return null


func status(q: QuestData) -> Status:
	var s: Status = _status[q.id]
	if s == Status.LOCKED and _is_unlocked(q):
		return Status.AVAILABLE
	return s


func progress(q: QuestData) -> int:
	if q.kind == QuestData.Kind.DELIVER:
		return mini(InventoryManager.count_of(q.target_item), q.target_count)
	return int(_progress[q.id])


func status_name(q: QuestData) -> String:
	return STATUS_NAMES[status(q)]


func _is_unlocked(q: QuestData) -> bool:
	if q.requires != "" and _status.get(q.requires, Status.LOCKED) != Status.DONE:
		return false
	return q.season == "" or q.season == TimeManager.season_name()


## Tugas ACTIVE / COMPLETE (untuk daftar tugas dan HUD).
func active_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for q in _quests:
		var s := status(q)
		if s == Status.ACTIVE or s == Status.COMPLETE:
			result.append(q)
	return result


func done_count() -> int:
	var n := 0
	for q in _quests:
		if status(q) == Status.DONE:
			n += 1
	return n


# ---------------------------------------------------------------- dari dialog NPC

## Tugas pertama yang bisa ditawarkan NPC ini (null jika tidak ada).
func offer_from(npc_id: String) -> QuestData:
	for q in _quests:
		if q.giver_id == npc_id and status(q) == Status.AVAILABLE:
			return q
	return null


## Tugas aktif dari NPC ini yang bisa diselesaikan sekarang (lapor / serahkan), atau null.
func finishable_from(npc_id: String) -> QuestData:
	for q in _quests:
		if q.giver_id != npc_id:
			continue
		var s := status(q)
		if s == Status.COMPLETE:
			return q
		if s == Status.ACTIVE and q.kind == QuestData.Kind.DELIVER and progress(q) >= q.target_count:
			return q
	return null


func accept(q: QuestData) -> void:
	if status(q) != Status.AVAILABLE:
		return
	_status[q.id] = Status.ACTIVE
	_progress[q.id] = 0
	quest_changed.emit(q)
	message.emit("Tugas baru: %s" % q.title)


## Menyelesaikan tugas (mengambil item untuk DELIVER) dan memberi hadiah. True jika berhasil.
func finish(q: QuestData) -> bool:
	if finishable_from(q.giver_id) != q:
		return false
	if q.kind == QuestData.Kind.DELIVER and not InventoryManager.remove_item(q.target_item, q.target_count):
		return false
	_status[q.id] = Status.DONE
	if q.reward_gold > 0:
		GameManager.add_gold(q.reward_gold)
	if q.reward_item != "" and q.reward_amount > 0:
		var left := InventoryManager.add_item_by_id(q.reward_item, q.reward_amount)
		if left > 0:
			message.emit("Tas penuh: %d hadiah hilang." % left)
	if q.reward_friendship > 0:
		NpcManager.add_friendship(q.giver_id, q.reward_friendship)
	AudioManager.play_sfx("quest")
	quest_changed.emit(q)
	return true


# ---------------------------------------------------------------- laporan kegiatan

## kind = QuestData.Kind.HARVEST / FISH / GATHER, item_id = id tanaman / ikan / item.
func report(kind: QuestData.Kind, item_id: String, amount: int = 1) -> void:
	for q in _quests:
		if q.kind != kind or status(q) != Status.ACTIVE:
			continue
		if q.target_item != "" and q.target_item != item_id:
			continue
		_progress[q.id] = mini(int(_progress[q.id]) + amount, q.target_count)
		if int(_progress[q.id]) >= q.target_count:
			_status[q.id] = Status.COMPLETE
			var giver := NpcManager.get_npc(q.giver_id)
			message.emit("Tugas \"%s\" tercapai! Laporkan ke %s." % [q.title, giver.npc_name if giver != null else q.giver_id])
		else:
			message.emit("%s: %d/%d" % [q.title, int(_progress[q.id]), q.target_count])
		quest_changed.emit(q)


# ---------------------------------------------------------------- simpan / game baru (Phase 12)

func reset() -> void:
	for q in _quests:
		_status[q.id] = Status.LOCKED
		_progress[q.id] = 0


func to_save() -> Dictionary:
	var out := {}
	for q in _quests:
		out[q.id] = {"status": int(_status[q.id]), "progress": int(_progress[q.id])}
	return out


func from_save(d: Dictionary) -> void:
	reset()
	for id: String in d:
		if not _status.has(id):
			continue
		var v: Dictionary = d[id]
		_status[id] = clampi(int(v.get("status", 0)), 0, Status.size() - 1) as Status
		_progress[id] = int(v.get("progress", 0))
