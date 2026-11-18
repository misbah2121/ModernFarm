class_name QuestData
extends Resource
## Data satu tugas (Resource). File .tres ada di res://data/quests/ dan dimuat otomatis
## oleh QuestManager. Tugas diberikan NPC `giver_id` lewat dialog ("Tugas: ...").
##   HARVEST : panen `target_count` tanaman (`target_item` = id tanaman, kosong = tanaman apa saja)
##   FISH    : tangkap `target_count` ikan (target_item = id ikan, kosong = ikan apa saja; sampah tidak dihitung)
##   GATHER  : kumpulkan item dari pohon/batu/barang pungut/hewan (target_item = id item, wajib)
##   DELIVER : bawa `target_count` item `target_item` ke pemberi tugas lalu pilih "Serahkan"
## Tugas HARVEST/FISH/GATHER yang sudah tercapai dilaporkan ke pemberi tugas untuk mengambil hadiah.

enum Kind { HARVEST, FISH, GATHER, DELIVER }

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
## Kalimat NPC saat menawarkan tugas (halaman dipisah "|").
@export_multiline var offer_text: String = ""
## Kalimat NPC saat tugas selesai.
@export_multiline var thanks_text: String = ""
@export var giver_id: String = ""
@export var kind: Kind = Kind.HARVEST
@export var target_item: String = ""
@export var target_count: int = 1
@export var reward_gold: int = 100
## id item hadiah ("" = tidak ada).
@export var reward_item: String = ""
@export var reward_amount: int = 0
@export var reward_friendship: int = 20
## id tugas yang harus selesai dulu ("" = tidak ada).
@export var requires: String = ""
## Musim tugas boleh ditawarkan ("" = kapan saja).
@export var season: String = ""
## Urutan tampil (kecil = lebih dulu).
@export var order: int = 0


## Teks target untuk daftar tugas, mis. "Panen 5 tanaman" / "Serahkan 3 Egg".
func target_text() -> String:
	var item := InventoryManager.get_item(target_item) if target_item != "" else null
	var item_name := item.item_name if item != null else ""
	match kind:
		Kind.HARVEST:
			return "Panen %d %s" % [target_count, item_name if item_name != "" else "tanaman apa saja"]
		Kind.FISH:
			return "Tangkap %d %s" % [target_count, item_name if item_name != "" else "ikan apa saja"]
		Kind.GATHER:
			return "Kumpulkan %d %s" % [target_count, item_name]
		_:
			return "Serahkan %d %s" % [target_count, item_name]


func reward_text() -> String:
	var parts: Array[String] = []
	if reward_gold > 0:
		parts.append("%d Gold" % reward_gold)
	if reward_item != "" and reward_amount > 0:
		var item := InventoryManager.get_item(reward_item)
		parts.append("%d %s" % [reward_amount, item.item_name if item != null else reward_item])
	if reward_friendship > 0:
		parts.append("Friendship +%d" % reward_friendship)
	return ", ".join(parts)
