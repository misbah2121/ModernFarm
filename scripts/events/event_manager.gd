extends Node
## Autoload "EventManager" (Phase 11): acara kalender harian.
## Setiap hari baru (dan saat game dimulai) mencari EventData untuk musim + tanggal hari ini,
## memberi hadiah pagi (jika ada), lalu memancarkan event_started (Main menampilkan pengumuman).
## Efek acara dibaca sistem lain: harga jual (GameManager), friendship bicara (NpcManager),
## tempat berkumpul NPC (NpcManager.current_place).

signal event_started(event: EventData)

const EVENT_DIR := "res://data/events/"

## Acara hari ini (null = hari biasa).
var today: EventData

var _events: Array[EventData] = []


func _ready() -> void:
	_load_events()
	TimeManager.day_started.connect(func(_d: int) -> void: _start_day())


## Dipanggil Main saat game dimulai. new_game = true: acara hari ini dijalankan (hadiah + pengumuman).
## Dari save: acara hari ini hanya dibaca ulang (hadiah tidak diberikan dua kali).
func begin(new_game: bool) -> void:
	if new_game:
		_start_day()
	else:
		today = event_on(TimeManager.season_name(), TimeManager.day_of_season())


func _load_events() -> void:
	for file_name in DirAccess.get_files_at(EVENT_DIR):
		var clean := file_name.trim_suffix(".remap")  # hasil export
		if not clean.ends_with(".tres"):
			continue
		var event := load(EVENT_DIR + clean) as EventData
		if event == null:
			push_warning("Bukan EventData: %s" % clean)
			continue
		_events.append(event)


func all_events() -> Array[EventData]:
	return _events


func event_on(season: String, day: int) -> EventData:
	for e in _events:
		if e.season == season and e.day == day:
			return e
	return null


## Acara berikutnya dalam musim ini (untuk info kalender), atau null.
func next_event() -> EventData:
	var best: EventData = null
	for e in _events:
		if e.season == TimeManager.season_name() and e.day > TimeManager.day_of_season():
			if best == null or e.day < best.day:
				best = e
	return best


func _start_day() -> void:
	today = event_on(TimeManager.season_name(), TimeManager.day_of_season())
	if today == null:
		return
	if today.gift_gold > 0:
		GameManager.add_gold(today.gift_gold)
	if today.gift_item != "" and today.gift_amount > 0:
		InventoryManager.add_item_by_id(today.gift_item, today.gift_amount)
	event_started.emit(today)


# ---------------------------------------------------------------- efek

func sell_multiplier(item: ItemData) -> float:
	if today != null and today.sell_category >= 0 and item != null and int(item.category) == today.sell_category:
		return today.sell_bonus
	return 1.0


func talk_multiplier() -> int:
	return maxi(today.talk_bonus, 1) if today != null else 1


func gather_place() -> String:
	return today.gather_place if today != null else ""
