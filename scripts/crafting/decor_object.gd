class_name DecorObject
extends PlacedObject
## Phase 19: hiasan / furnitur luar ruangan yang bisa dipasang pemain untuk menata farm
## (lampu taman, bangku, meja, labu hias, jerami, peti, rumah anjing, sumur, kios, bunga, ...).
## Dibeli di Toko Serba Ada (Mira), dipasang dengan SPACE seperti mesin (Phase 14),
## diambil kembali dengan Pickaxe / Axe. Satu script untuk semua hiasan; tiap scene di
## res://scenes/decor/ hanya berisi Sprite2D (+ StaticBody2D jika menghalangi, + PointLight2D untuk lampu).
## Lampu (punya node PointLight2D bernama "Light") menyala otomatis jam 18:00 - 06:00.

const LIGHT_ON_HOUR := 18
const LIGHT_OFF_HOUR := 6

@onready var light: PointLight2D = get_node_or_null("Light")
@onready var glow: Sprite2D = get_node_or_null("Glow")


func _ready() -> void:
	if light != null:
		TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _update_light())
		_update_light()


func _update_light() -> void:
	var h := TimeManager.hour()
	var on := h >= LIGHT_ON_HOUR or h < LIGHT_OFF_HOUR
	light.enabled = on
	if glow != null:
		glow.visible = on


func interact() -> String:
	if light != null:
		return "Lampu taman: menyala otomatis saat malam (18:00 - 06:00)."
	return ""


## Hiasan boleh diambil dengan Pickaxe maupun Axe.
func accepts_tool(_kind: int) -> String:
	return ""
