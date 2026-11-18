extends Node
## Autoload "NpcManager": registri NpcData + status friendship tiap NPC.
## Bicara +1 (sekali sehari), hadiah disukai +10, tidak disukai -5, netral +2 (sekali sehari).

signal friendship_changed(npc_id: String, value: int)

enum GiftResult { LIKED, NEUTRAL, DISLIKED, ALREADY_GIFTED, REFUSED }

const NPC_DIR := "res://data/npc/"
const MAX_FRIENDSHIP := 1000
const POINTS_PER_HEART := 100
const TALK_POINTS := 1
const LIKE_POINTS := 10
const NEUTRAL_POINTS := 2
const DISLIKE_POINTS := -5
## Friendship minimal agar NPC memakai friend_lines.
const FRIEND_THRESHOLD := 30

class State:
	var friendship: int = 0
	var talked_today: bool = false
	var gifted_today: bool = false

var _npcs: Array[NpcData] = []
var _by_id: Dictionary = {}  # id -> NpcData
var _states: Dictionary = {}  # id -> State


func _ready() -> void:
	_load_npcs()
	TimeManager.day_started.connect(_on_day_started)


func _load_npcs() -> void:
	for file_name in DirAccess.get_files_at(NPC_DIR):
		var clean := file_name.trim_suffix(".remap")  # hasil export
		if not clean.ends_with(".tres"):
			continue
		var npc := load(NPC_DIR + clean) as NpcData
		if npc == null:
			push_warning("Bukan NpcData: %s" % clean)
			continue
		_npcs.append(npc)
		_by_id[npc.id] = npc
		_states[npc.id] = State.new()


func all_npcs() -> Array[NpcData]:
	return _npcs


func get_npc(id: String) -> NpcData:
	return _by_id.get(id) as NpcData


func friendship(id: String) -> int:
	return (_states[id] as State).friendship if _states.has(id) else 0


func hearts(id: String) -> int:
	return floori(friendship(id) / float(POINTS_PER_HEART))


## Bicara: +TALK_POINTS sekali per hari. True jika poin bertambah.
func talk(id: String) -> bool:
	if not _states.has(id):
		return false
	var state: State = _states[id]
	if state.talked_today:
		return false
	state.talked_today = true
	_add_friendship(id, TALK_POINTS * EventManager.talk_multiplier())
	return true


## Menambah / mengurangi friendship dari sistem lain (mis. hadiah tugas).
func add_friendship(id: String, amount: int) -> void:
	if _states.has(id):
		_add_friendship(id, amount)


# ---------------------------------------------------------------- jadwal (Phase 11)

## Jam acara: semua NPC berkumpul di tempat acara pada jam ini.
const GATHER_START := 9 * 60
const GATHER_END := 20 * 60


## Nama tempat yang seharusnya didatangi NPC sekarang ("" = tidak punya jadwal).
func current_place(npc: NpcData) -> String:
	var minutes := TimeManager.minutes
	var gather := EventManager.gather_place()
	if gather != "" and minutes >= GATHER_START and minutes < GATHER_END:
		return gather
	var list := npc.schedule
	if TimeManager.is_raining() and not npc.rain_schedule.is_empty():
		list = npc.rain_schedule
	var place := ""
	for entry in list:
		var parts := entry.strip_edges().split(" ", false, 1)
		if parts.size() < 2:
			continue
		var hm := parts[0].split(":")
		var at := int(hm[0]) * 60 + (int(hm[1]) if hm.size() > 1 else 0)
		if place == "" or at <= minutes:
			place = parts[1].strip_edges()
		if at > minutes:
			break
	return place


## Memberi hadiah. Item TIDAK dikurangi di sini; pemanggil yang mengurangi jika hasilnya
## bukan REFUSED / ALREADY_GIFTED.
func give_gift(npc: NpcData, item: ItemData) -> GiftResult:
	if item.category == ItemData.Category.TOOL:
		return GiftResult.REFUSED
	var state: State = _states[npc.id]
	if state.gifted_today:
		return GiftResult.ALREADY_GIFTED
	state.gifted_today = true
	if item.id in npc.favorite_items:
		_add_friendship(npc.id, LIKE_POINTS)
		return GiftResult.LIKED
	if item.id in npc.disliked_items:
		_add_friendship(npc.id, DISLIKE_POINTS)
		return GiftResult.DISLIKED
	_add_friendship(npc.id, NEUTRAL_POINTS)
	return GiftResult.NEUTRAL


func _add_friendship(id: String, amount: int) -> void:
	var state: State = _states[id]
	state.friendship = clampi(state.friendship + amount, 0, MAX_FRIENDSHIP)
	friendship_changed.emit(id, state.friendship)


func _on_day_started(_total_day: int) -> void:
	for id: String in _states:
		var state: State = _states[id]
		state.talked_today = false
		state.gifted_today = false


# ---------------------------------------------------------------- simpan / game baru (Phase 12)

func reset() -> void:
	for id: String in _states:
		_states[id] = State.new()


func to_save() -> Dictionary:
	var out := {}
	for id: String in _states:
		var s: State = _states[id]
		out[id] = {"friendship": s.friendship, "talked": s.talked_today, "gifted": s.gifted_today}
	return out


func from_save(d: Dictionary) -> void:
	reset()
	for id: String in d:
		if not _states.has(id):
			continue
		var s: State = _states[id]
		var v: Dictionary = d[id]
		s.friendship = clampi(int(v.get("friendship", 0)), 0, MAX_FRIENDSHIP)
		s.talked_today = bool(v.get("talked", false))
		s.gifted_today = bool(v.get("gifted", false))
