class_name ItemData
extends Resource
## Data satu jenis item (Resource). File .tres ada di res://data/items/ dan dimuat otomatis
## oleh InventoryManager. Alat dan benih menautkan ToolData lewat tool_data supaya
## logika cangkul / siram / tanam dari Phase 2-3 tetap dipakai.

## Phase 19: DECOR = hiasan / furnitur yang dipasang untuk menata farm.
## Phase 14: MACHINE = barang hasil kerajinan yang bisa dipasang di Farm (Sprinkler, Cheese Machine, Peti).
enum Category { TOOL, SEED, CROP, FISH, WOOD, STONE, ORE, FOOD, MATERIAL, MACHINE, DECOR }

const CATEGORY_NAMES: Array[String] = [
	"Alat", "Benih", "Hasil Panen", "Ikan", "Kayu", "Batu", "Bijih", "Makanan", "Bahan", "Mesin", "Dekorasi",
]

@export var id: String = ""
@export var item_name: String = ""
@export var category: Category = Category.MATERIAL
@export var icon: Texture2D
## Phase 18: gambar saat barang jatuh di tanah (asset Pickup_*_16x16.png). Kosong = pakai icon.
@export var pickup_texture: Texture2D
## Jumlah maksimum per slot (alat = 1).
@export var max_stack: int = 99
## Harga jual ke toko (dipakai Phase 7).
@export var sell_price: int = 0
## Harga beli dari toko, 0 = tidak dijual (dipakai Phase 7).
@export var buy_price: int = 0
@export_multiline var description: String = ""
## Phase 12: energi yang didapat saat dimakan (SPACE sambil memegang item). 0 = tidak bisa dimakan.
@export var energy: int = 0
## Phase 18: bonus sementara saat dimakan. 0 = tidak ada, 1 = jalan cepat, 2 = mudah memancing, 3 = keduanya.
@export_enum("Tidak ada", "Jalan cepat", "Mudah memancing", "Keduanya") var buff: int = 0
## Lama bonus dalam menit game (60 = 1 jam game).
@export var buff_minutes: int = 0
## Hanya untuk kategori TOOL dan SEED: data alat yang dipakai Player saat tombol SPACE.
@export var tool_data: ToolData
## Phase 14: scene objek yang dipasang di Farm saat SPACE (kategori MACHINE). Kosong = tidak bisa dipasang.
@export var placeable: PackedScene


func is_placeable() -> bool:
	return placeable != null


## Teks bonus untuk keterangan item, mis. "Jalan cepat 2 jam". "" jika tidak ada.
func buff_text() -> String:
	if buff <= 0 or buff_minutes <= 0:
		return ""
	var names := ["", "Jalan cepat", "Mudah memancing", "Jalan cepat + mudah memancing"]
	return "%s %s" % [names[buff], GameManager.duration_text(buff_minutes)]


func category_name() -> String:
	return CATEGORY_NAMES[category]
