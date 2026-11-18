class_name CropData
extends Resource
## Data tanaman (Resource). File .tres ada di res://data/crops/.
## Sheet pertumbuhan Modern_Farm: 7 frame selebar 16 px berjajar. Di bawah area sprite ada
## strip label bernomor (tinggi 16 px) yang TIDAK boleh ikut digambar, jadi tinggi sprite
## disimpan per tanaman di frame_height (16 untuk tanaman pendek, 32 untuk tanaman tinggi).
##   frame 0     = tunas kecil
##   frame 1-3   = tumbuh (animasi goyang)
##   frame 4-6   = matang / siap panen (animasi goyang)
## stage_frames memetakan 5 tahap logika (Seed, Sprout, Growing, Mature, Harvest) ke nomor frame.

const FRAME_W := 16
const STAGE_COUNT := 5
const STAGE_HARVEST := 4

@export var id: String = ""
@export var crop_name: String = ""
@export var seed_price: int = 10
@export var sell_price: int = 20
@export var growth_days: int = 4
## "spring", "summer", "autumn", "winter" (dipakai mulai Phase 4)
@export var season: String = "spring"
@export var sheet: Texture2D
## Tinggi satu frame sprite (px), tanpa strip label.
@export var frame_height: int = 16
@export var stage_frames: PackedInt32Array = PackedInt32Array([0, 1, 2, 3, 5])
@export var seed_icon: Texture2D

var _stage_cache: Dictionary = {}


func sprite_height() -> int:
	return frame_height


func get_stage_texture(stage: int) -> AtlasTexture:
	stage = clampi(stage, 0, STAGE_COUNT - 1)
	if _stage_cache.has(stage):
		return _stage_cache[stage]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.filter_clip = true
	atlas.region = Rect2(stage_frames[stage] * FRAME_W, 0, FRAME_W, sprite_height())
	_stage_cache[stage] = atlas
	return atlas


## Tahap tumbuh (0..4) untuk jumlah hari tumbuh tertentu. Tahap 4 = siap panen.
func stage_for_days(days_grown: int) -> int:
	if days_grown >= growth_days:
		return STAGE_HARVEST
	return clampi(floori(days_grown * STAGE_HARVEST / float(growth_days)), 0, STAGE_HARVEST - 1)
