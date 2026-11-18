extends Node
## Autoload "SaveManager" (Phase 12): game baru, simpan / muat (JSON), dan pengaturan.
##   Simpan : user://savegame.json  (otomatis setiap pagi setelah tidur + tombol SAVE di menu pause)
##   Setting: user://settings.cfg   (volume, layar penuh, kecepatan waktu)
## Data autoload (gold, waktu, tas, NPC, hewan, tugas) langsung dipasang ke autoload.
## Data dunia (posisi player, tanah & tanaman, batu/pohon yang dipecah) disimpan di `pending_world`
## lalu dipasang oleh Main setelah semua peta dibuat (apply_world).

signal saved
signal settings_changed

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 1
const MAIN_SCENE := "res://scenes/main/main.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Pilihan kecepatan waktu: detik nyata per 1 menit game.
const TIME_SPEEDS := {"Cepat": 0.7, "Normal": 1.0, "Lambat": 1.5}

## true = game baru (acara hari pertama dijalankan), false = dari file simpanan.
var is_new_game := true
## Data dunia dari file simpanan, menunggu dipasang Main. Kosong = tidak ada.
var pending_world: Dictionary = {}

var settings := {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"ambient_volume": 0.6,
	"fullscreen": false,
	"time_speed": "Normal",
	"touch_controls": "Otomatis",  # Phase 13: Otomatis / Selalu / Mati
}
const TOUCH_MODES: Array[String] = ["Otomatis", "Selalu", "Mati"]


func _ready() -> void:
	load_settings()


# ---------------------------------------------------------------- game baru / muat

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Ringkasan simpanan untuk tombol LOAD ("Spring 3 - Tahun 1, 820 Gold"), "" jika tidak ada.
func save_summary() -> String:
	var data := _read_save()
	if data.is_empty():
		return ""
	var time: Dictionary = data.get("time", {})
	var day := int(time.get("day", 1))
	var season: String = TimeManager.SEASON_NAMES[floori((day - 1) / float(TimeManager.DAYS_PER_SEASON)) % 4]
	var day_of_season := (day - 1) % TimeManager.DAYS_PER_SEASON + 1
	var year := floori((day - 1) / float(TimeManager.DAYS_PER_SEASON * 4)) + 1
	var gold := int((data.get("game", {}) as Dictionary).get("gold", 0))
	return "%s %d - Tahun %d, %d Gold" % [season.capitalize(), day_of_season, year, gold]


func _reset_all() -> void:
	get_tree().paused = false
	GameManager.reset()
	TimeManager.reset()
	InventoryManager.reset()
	NpcManager.reset()
	AnimalManager.reset()
	QuestManager.reset()
	FarmServices.reset()  # Phase 19: traktor & pekerja
	TimeManager.seconds_per_game_minute = float(TIME_SPEEDS.get(settings["time_speed"], 1.0))


func start_new_game() -> void:
	_reset_all()
	is_new_game = true
	pending_world = {}
	get_tree().change_scene_to_file(MAIN_SCENE)


## Memuat file simpanan lalu membuka scene Main. False jika file tidak ada / rusak.
func load_game() -> bool:
	var data := _read_save()
	if data.is_empty():
		return false
	_reset_all()
	GameManager.from_save(data.get("game", {}))
	TimeManager.from_save(data.get("time", {}))
	InventoryManager.from_save(data.get("inventory", {}))
	NpcManager.from_save(data.get("npcs", {}))
	AnimalManager.from_save(data.get("animals", {}))
	QuestManager.from_save(data.get("quests", {}))
	FarmServices.from_save(data.get("farm_services", {}))
	is_new_game = false
	pending_world = data.get("world", {})
	get_tree().change_scene_to_file(MAIN_SCENE)
	return true


func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("File simpanan rusak: %s" % SAVE_PATH)
		return {}
	return parsed


# ---------------------------------------------------------------- simpan

## Menyimpan seluruh game. `world` = data dunia dari Main.collect_world().
func save_game(world: Dictionary) -> bool:
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"game": GameManager.to_save(),
		"time": TimeManager.to_save(),
		"inventory": InventoryManager.to_save(),
		"npcs": NpcManager.to_save(),
		"animals": AnimalManager.to_save(),
		"quests": QuestManager.to_save(),
		"farm_services": FarmServices.to_save(),
		"world": world,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Gagal menyimpan: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	saved.emit()
	return true


# ---------------------------------------------------------------- pengaturan

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for key: String in settings:
			settings[key] = cfg.get_value("settings", key, settings[key])
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in settings:
		cfg.set_value("settings", key, settings[key])
	cfg.save(SETTINGS_PATH)


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	save_settings()


func apply_settings() -> void:
	AudioManager.set_bus_volume("Master", float(settings["master_volume"]))
	AudioManager.set_bus_volume("Music", float(settings["music_volume"]))
	AudioManager.set_bus_volume("SFX", float(settings["sfx_volume"]))
	AudioManager.set_bus_volume("Ambient", float(settings["ambient_volume"]))
	TimeManager.seconds_per_game_minute = float(TIME_SPEEDS.get(settings["time_speed"], 1.0))
	if not DisplayServer.get_name() == "headless":
		var want_full := bool(settings["fullscreen"])
		var mode := DisplayServer.window_get_mode()
		var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if want_full != is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if want_full else DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit()
