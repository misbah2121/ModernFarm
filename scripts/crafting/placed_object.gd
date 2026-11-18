class_name PlacedObject
extends Node2D
## Phase 14: dasar semua mesin / objek yang dipasang player di Farm (Sprinkler, Cheese Machine, Peti).
## Titik asal node = tengah bawah area footprint (agar y-sort benar di layer Objects).
## FarmMap yang memasang, mencatat tile yang ditempati, menyimpan, dan memuat objek ini.
## Turunan menimpa: interact(), on_day_started(), can_pick_up(), pick_up_items(), state_to_save(), state_from_save().

## Tile yang ditempati, relatif ke tile jangkar (tile di depan player saat dipasang).
@export var footprint := Rect2i(0, 0, 1, 1)

var item_id := ""          # id ItemData objek ini (untuk dikembalikan ke tas saat diambil)
var anchor := Vector2i.ZERO
var farm: FarmMap


## Tile-tile yang ditempati objek ini.
func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in footprint.size.y:
		for x in footprint.size.x:
			result.append(anchor + footprint.position + Vector2i(x, y))
	return result


## Posisi node untuk tile jangkar tertentu (tengah bawah footprint).
func position_for(cell: Vector2i) -> Vector2:
	var tile := TerrainTiles.TILE
	var top_left := Vector2((cell + footprint.position) * tile)
	return top_left + Vector2(footprint.size.x * tile * 0.5, footprint.size.y * tile)


## Tombol E. Kembalikan teks untuk toast ("" = tidak ada pesan).
func interact() -> String:
	return ""


## Dipanggil FarmMap setiap pagi (setelah tanah dikeringkan).
func on_day_started() -> void:
	pass


## Bisa diambil dengan Pickaxe / Axe?
func can_pick_up() -> String:
	return ""  # "" = boleh; selain itu alasan


## Phase 15: alat yang boleh dipakai mengambil objek ini (ToolData.Kind). "" = boleh, selain itu alasan.
func accepts_tool(_kind: int) -> String:
	return ""


## Nama untuk pesan (mis. "Pohon Apple"). "" = pakai nama item.
func display_name() -> String:
	return ""


## Phase 15: item objek ini sendiri ikut kembali ke tas saat diambil? (pohon besar: tidak, jadi kayu)
func returns_self() -> bool:
	return true


## Item tambahan yang ikut kembali saat diambil (isi mesin): Array of [item_id, jumlah].
func pick_up_items() -> Array:
	return []


func state_to_save() -> Dictionary:
	return {}


func state_from_save(_d: Dictionary) -> void:
	pass


## Menit game absolut (hari * 1440 + menit hari ini) untuk menghitung lama proses mesin.
static func now_minutes() -> int:
	return TimeManager.total_day * 1440 + TimeManager.minutes
