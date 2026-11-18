extends Node
## Autoload "TimeManager": jam, hari, musim, tahun, dan cuaca.
## 1 menit game = seconds_per_game_minute detik nyata (ubah di sini / lewat kode).
## Hari berjalan dari 06:00 sampai 02:00 (menit ke-1560); lewat itu player pingsan dan hari berganti.

signal time_changed(hour: int, minute: int)
signal day_started(total_day: int)
signal season_changed(season: int)
signal weather_changed(weather: int)
signal bedtime_reached

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
enum Weather { SUNNY, CLOUDY, RAIN, STORM }

const DAYS_PER_SEASON := 28
const DAY_START_MINUTE := 6 * 60
const BEDTIME_MINUTE := 26 * 60

const SEASON_NAMES: Array[String] = ["spring", "summer", "autumn", "winter"]
const WEATHER_NAMES: Array[String] = ["Sunny", "Cloudy", "Rain", "Storm"]
## Peluang cuaca per musim: [Sunny, Cloudy, Rain, Storm]
const WEATHER_WEIGHTS := {
	Season.SPRING: [0.50, 0.20, 0.25, 0.05],
	Season.SUMMER: [0.60, 0.15, 0.15, 0.10],
	Season.AUTUMN: [0.40, 0.30, 0.25, 0.05],
	Season.WINTER: [0.45, 0.30, 0.25, 0.00],
}

@export var seconds_per_game_minute: float = 1.0
var paused: bool = false
var total_day: int = 1
var minutes: int = DAY_START_MINUTE
var weather: Weather = Weather.SUNNY

var _accumulator := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta
	while _accumulator >= seconds_per_game_minute:
		_accumulator -= seconds_per_game_minute
		minutes += 1
		time_changed.emit(hour(), minute())
		if minutes >= BEDTIME_MINUTE:
			paused = true
			bedtime_reached.emit()
			return


func hour() -> int:
	return floori(minutes / 60.0)


func minute() -> int:
	return minutes % 60


func day_of_season() -> int:
	return (total_day - 1) % DAYS_PER_SEASON + 1


func season() -> Season:
	return (floori((total_day - 1) / float(DAYS_PER_SEASON)) % 4) as Season


func year() -> int:
	return floori((total_day - 1) / float(DAYS_PER_SEASON * 4)) + 1


func season_name() -> String:
	return SEASON_NAMES[season()]


func weather_name() -> String:
	return WEATHER_NAMES[weather]


func is_raining() -> bool:
	return weather == Weather.RAIN or weather == Weather.STORM


## "06:00 AM" (jam 24+ ditampilkan sebagai 12:00 AM, 01:00 AM, ...)
func clock_text() -> String:
	var h := hour() % 24
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%02d:%02d %s" % [h12, minute(), suffix]


## Pindah ke pagi hari berikutnya: ganti hari, musim, cuaca; lalu jam kembali 06:00.
func sleep() -> void:
	var old_season := season()
	total_day += 1
	minutes = DAY_START_MINUTE
	_accumulator = 0.0
	_roll_weather()
	if season() != old_season:
		season_changed.emit(season())
	day_started.emit(total_day)
	time_changed.emit(hour(), minute())
	paused = false


func _roll_weather() -> void:
	var weights: Array = WEATHER_WEIGHTS[season()]
	var roll := _rng.randf()
	var acc := 0.0
	var result := Weather.SUNNY
	for i in weights.size():
		acc += weights[i]
		if roll < acc:
			result = i as Weather
			break
	weather = result
	weather_changed.emit(weather)


# ---------------------------------------------------------------- simpan / game baru (Phase 12)

func reset() -> void:
	total_day = 1
	minutes = DAY_START_MINUTE
	weather = Weather.SUNNY
	paused = false
	_accumulator = 0.0


func to_save() -> Dictionary:
	return {"day": total_day, "minutes": minutes, "weather": int(weather)}


func from_save(d: Dictionary) -> void:
	total_day = maxi(int(d.get("day", 1)), 1)
	minutes = clampi(int(d.get("minutes", DAY_START_MINUTE)), DAY_START_MINUTE, BEDTIME_MINUTE - 1)
	weather = clampi(int(d.get("weather", 0)), 0, Weather.size() - 1) as Weather
	paused = false
	_accumulator = 0.0
