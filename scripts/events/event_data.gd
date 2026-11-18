class_name EventData
extends Resource
## Data satu acara kalender (Resource). File .tres ada di res://data/events/ dan dimuat otomatis
## oleh EventManager. Acara aktif sepanjang hari pada `season` + `day` (hari ke-1..28 musim itu).
## Pagi harinya muncul pengumuman (judul + teks). Efek yang bisa dipakai:
##   gather_place  : semua NPC berkumpul di tempat ini (nama Marker2D di Village > Places) sepanjang hari
##   sell_category : kategori ItemData yang harganya naik (-1 = tidak ada), sell_bonus = pengali harga
##   talk_bonus    : pengali poin friendship saat bicara
##   gift_item / gift_amount / gift_gold : hadiah yang langsung diterima pagi itu

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var season: String = "spring"
@export_range(1, 28) var day: int = 1

@export_group("Efek")
@export var gather_place: String = ""
@export var sell_category: int = -1
@export var sell_bonus: float = 1.0
@export var talk_bonus: int = 1
@export var gift_item: String = ""
@export var gift_amount: int = 0
@export var gift_gold: int = 0
