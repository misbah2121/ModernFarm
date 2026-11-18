class_name ShopData
extends Resource
## Data satu toko (Resource). File .tres ada di res://data/shop/.
## Barang yang dijual = daftar id item di `stock`; harganya diambil dari ItemData.buy_price.
## Toko membeli item dari player jika kategorinya ada di `sell_categories` dan sell_price > 0.
## Harga jual = ItemData.sell_price (Gold += sell_price).

@export var id: String = ""
@export var shop_name: String = ""
## id NPC pemilik toko (NpcData.id). Hanya untuk informasi / dialog.
@export var owner_id: String = ""
## id item (ItemData.id) yang bisa dibeli player, sesuai urutan tampilan.
@export var stock: PackedStringArray = PackedStringArray()
## Phase 9: id hewan (AnimalData.id) yang dijual toko ini (mis. Peternakan Barnaby).
@export var animals: PackedStringArray = PackedStringArray()
## Phase 11: jam buka toko (jam game, 0-24). Di luar jam ini toko tutup.
@export var open_hour: int = 0
@export var close_hour: int = 24
## Kategori ItemData.Category yang mau dibeli toko dari player (nilai int enum).
@export var sell_categories: Array[int] = []


## Daftar ItemData yang dijual (id yang tidak dikenal / buy_price 0 dilewati).
func stock_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item_id in stock:
		var item := InventoryManager.get_item(item_id)
		if item == null:
			push_warning("Toko %s: item tidak dikenal '%s'" % [id, item_id])
			continue
		if item.buy_price <= 0:
			push_warning("Toko %s: item '%s' tidak punya buy_price" % [id, item_id])
			continue
		result.append(item)
	return result


func is_open() -> bool:
	var h := TimeManager.hour()
	return h >= open_hour and h < close_hour


func hours_text() -> String:
	return "%02d:00 - %02d:00" % [open_hour, close_hour]


## True jika toko mau membeli item ini dari player.
func accepts(item: ItemData) -> bool:
	return item != null and item.sell_price > 0 and int(item.category) in sell_categories


## Daftar AnimalData yang dijual (id yang tidak dikenal dilewati).
func animal_stock() -> Array[AnimalData]:
	var result: Array[AnimalData] = []
	for animal_id in animals:
		var data := AnimalManager.get_type(animal_id)
		if data == null:
			push_warning("Toko %s: hewan tidak dikenal '%s'" % [id, animal_id])
			continue
		result.append(data)
	return result
