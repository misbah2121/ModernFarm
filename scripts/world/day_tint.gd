extends CanvasModulate
## Warna dunia mengikuti jam (fajar, siang, senja, malam) dan cuaca. HUD tidak ikut berubah.

## [jam, warna]; jam 26 = 02:00 dini hari.
const KEYS := [
	[6.0, Color(1.0, 0.86, 0.78)],
	[8.0, Color(1, 1, 1)],
	[17.0, Color(1, 1, 1)],
	[19.0, Color(1.0, 0.74, 0.58)],
	[21.0, Color(0.5, 0.55, 0.85)],
	[26.0, Color(0.32, 0.36, 0.62)],
]
const WEATHER_TINT := [
	Color(1, 1, 1),
	Color(0.88, 0.9, 0.94),
	Color(0.74, 0.8, 0.9),
	Color(0.58, 0.62, 0.76),
]


func _ready() -> void:
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _refresh())
	TimeManager.weather_changed.connect(func(_w: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	var t := TimeManager.minutes / 60.0
	var base: Color = KEYS[KEYS.size() - 1][1]
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if t >= a[0] and t <= b[0]:
			base = (a[1] as Color).lerp(b[1], (t - a[0]) / (b[0] - a[0]))
			break
	color = base * (WEATHER_TINT[TimeManager.weather] as Color)
