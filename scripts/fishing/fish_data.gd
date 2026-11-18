class_name FishData
extends Resource
## Data satu jenis tangkapan (Resource). File .tres ada di res://data/fish/ dan dimuat otomatis
## oleh FishingController. Item yang masuk tas = `item` (ItemData), harga jual = item.sell_price.
## Rarity JUNK (sampah) langsung didapat tanpa mini game.

enum Rarity { COMMON, UNCOMMON, RARE, JUNK }

const RARITY_NAMES: Array[String] = ["Biasa", "Langka", "Sangat Langka", "Sampah"]

@export var id: String = ""
@export var fish_name: String = ""
@export var item: ItemData
@export var rarity: Rarity = Rarity.COMMON
## 0 (mudah) - 100 (sangat sulit). Mengatur kecepatan ikan dan ukuran zona di mini game.
@export_range(0, 100) var difficulty: int = 20
## Bobot peluang muncul dibanding tangkapan lain yang tersedia.
@export var weight: float = 10.0
## Musim ("spring", "summer", "autumn", "winter"). Kosong = semua musim.
@export var seasons: PackedStringArray = PackedStringArray()
## Jam muncul: start_hour <= jam < end_hour (jam 24-26 = lewat tengah malam).
@export var start_hour: int = 6
@export var end_hour: int = 26
## True = hanya muncul saat hujan / badai.
@export var rain_only: bool = false
## Peta tempat muncul ("farm", "village"). Kosong = semua tempat berair.
@export var locations: PackedStringArray = PackedStringArray()


func sell_price() -> int:
	return item.sell_price if item != null else 0


func rarity_name() -> String:
	return RARITY_NAMES[rarity]


func is_available(season: String, hour: int, raining: bool, location: String) -> bool:
	if item == null:
		return false
	if not seasons.is_empty() and not season in seasons:
		return false
	if hour < start_hour or hour >= end_hour:
		return false
	if rain_only and not raining:
		return false
	if not locations.is_empty() and not location in locations:
		return false
	return true
