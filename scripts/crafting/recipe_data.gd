class_name RecipeData
extends Resource
## Phase 14: satu resep kerajinan (file .tres di res://data/recipes/, dimuat otomatis oleh CraftPanel).
## Bahan: ingredients[i] sebanyak amounts[i]. Hasil: result sebanyak result_count.

@export var id: String = ""
@export var result: ItemData
@export var result_count: int = 1
@export var ingredients: Array[ItemData] = []
@export var amounts: Array[int] = []
## Urutan tampil di daftar (kecil = atas).
@export var order: int = 0
## Phase 18: tempat membuat. "craft" = panel kerajinan (tombol C), "cook" = dapur (Kompor Batu).
@export_enum("craft", "cook") var station: String = "craft"


func amount_of(index: int) -> int:
	return amounts[index] if index < amounts.size() else 1


## Semua bahan cukup di tas?
func has_ingredients() -> bool:
	for i in ingredients.size():
		if InventoryManager.count_of(ingredients[i].id) < amount_of(i):
			return false
	return true


## Alasan tidak bisa dibuat, atau "" jika bisa.
func check() -> String:
	if not has_ingredients():
		return "Bahan belum cukup."
	if not InventoryManager.can_add(result, result_count):
		return "Tas penuh."
	return ""


## Ambil bahan dari tas lalu tambahkan hasil. true jika berhasil.
func craft() -> bool:
	if check() != "":
		return false
	for i in ingredients.size():
		InventoryManager.remove_item(ingredients[i].id, amount_of(i))
	InventoryManager.add_item(result, result_count)
	return true
