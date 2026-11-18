class_name FruitTree
extends PlacedObject
## Phase 15: pohon buah. Ditanam dari bibit (SPACE sambil memegang bibit, hanya di Farm).
##   Bibit (Fruit_Tree_Small_*) tumbuh GROW_DAYS hari -> pohon dewasa.
##   Pohon dewasa pada musimnya: Fruitless -> Unripe (buah muda) -> setelah RIPEN_DAYS hari Ripe.
##   E di pohon matang = panen FRUIT_PER_HARVEST buah, lalu kembali Unripe.
##   Di luar musim pohon tidak berbuah (Fruitless).
##   Axe: bibit kembali ke tas; pohon dewasa ditebang menjadi kayu.
## Sprite dari assets/modern_farm/objects/fruit_trees/Fruit_Tree_<tree_key>_<tahap>_16x16.png.
## Satu script untuk semua jenis; tiap scene (fruit_tree_apple.tscn, ...) hanya mengisi variabel export.

const DIR := "res://assets/modern_farm/objects/fruit_trees/"
const GROW_DAYS := 7
const RIPEN_DAYS := 2
const FRUIT_PER_HARVEST := 3
const WOOD_FROM_TREE := 6

enum Fruit { NONE, UNRIPE, RIPE }

## Nama di file sprite: Apple / Banana / Lemon / Orange / Peach.
@export var tree_key := "Apple"
## id ItemData buah yang dipanen.
@export var fruit_id := "apple"
## Musim berbuah: spring / summer / autumn / winter.
@export var season := "autumn"

@onready var sprite: Sprite2D = $Sprite2D

var age := 0              # hari sejak ditanam
var fruit: Fruit = Fruit.NONE
var fruit_days := 0       # hari sejak buah muncul (Unripe)


func _ready() -> void:
	_refresh()


func is_mature() -> bool:
	return age >= GROW_DAYS


func _refresh() -> void:
	var stage := "Small_" + tree_key
	if is_mature():
		match fruit:
			Fruit.UNRIPE:
				stage = tree_key + "_Unripe"
			Fruit.RIPE:
				stage = tree_key + "_Ripe"
			_:
				stage = tree_key + "_Fruitless"
	var tex: Texture2D = load(DIR + "Fruit_Tree_%s_16x16.png" % stage)
	sprite.texture = tex
	# Titik asal = tengah bawah batang; gambar pohon digambar di atasnya.
	var size := tex.get_size()
	sprite.position = Vector2(-floorf(size.x / 2.0), -size.y + 1.0)


func on_day_started() -> void:
	if not is_mature():
		age += 1
		if is_mature() and _in_season():
			fruit = Fruit.UNRIPE
			fruit_days = 0
		_refresh()
		return
	if not _in_season():
		fruit = Fruit.NONE
	elif fruit == Fruit.NONE:
		fruit = Fruit.UNRIPE
		fruit_days = 0
	elif fruit == Fruit.UNRIPE:
		fruit_days += 1
		if fruit_days >= RIPEN_DAYS:
			fruit = Fruit.RIPE
	_refresh()


func _in_season() -> bool:
	return TimeManager.season_name() == season


func interact() -> String:
	var fruit_item := InventoryManager.get_item(fruit_id)
	var fruit_name := fruit_item.item_name if fruit_item != null else fruit_id
	if not is_mature():
		return "Bibit pohon %s. Dewasa dalam %d hari lagi." % [fruit_name, GROW_DAYS - age]
	match fruit:
		Fruit.RIPE:
			if fruit_item == null:
				return ""
			# Phase 18: buah jatuh dari pohon (asset Pickup) lalu diambil player.
			ItemPickup.drop(get_parent(), position + Vector2(0, 4), fruit_item, FRUIT_PER_HARVEST, 16.0)
			fruit = Fruit.UNRIPE
			fruit_days = 0
			_refresh()
			_shake()
			AudioManager.play_sfx("harvest")
			return "Panen %d %s!" % [FRUIT_PER_HARVEST, fruit_name]
		Fruit.UNRIPE:
			_shake()
			return "Buah %s masih muda. Matang dalam %d hari." % [fruit_name, maxi(RIPEN_DAYS - fruit_days, 1)]
	_shake()
	return "Pohon %s berbuah di musim %s." % [fruit_name, season.capitalize()]


## Goyang sebentar saat disentuh / dipanen. Phase 17: pohon dewasa menjatuhkan daun.
func _shake() -> void:
	if is_mature():
		Vfx.leaves(get_parent(), position + Vector2(0, -sprite.texture.get_height() * 0.6))
	var base := sprite.position
	var tween := create_tween()
	for dx in [2.0, -2.0, 1.0, -1.0, 0.0]:
		tween.tween_property(sprite, "position:x", base.x + dx, 0.05)


func display_name() -> String:
	var fruit_item := InventoryManager.get_item(fruit_id)
	return "Pohon %s" % (fruit_item.item_name if fruit_item != null else tree_key) if is_mature() else ""


func accepts_tool(kind: int) -> String:
	return "" if kind == ToolData.Kind.AXE else "Pakai Axe untuk menebang / memindahkan pohon."


## Bibit kembali ke tas; pohon dewasa menjadi kayu.
func returns_self() -> bool:
	return not is_mature()


func pick_up_items() -> Array:
	return [["wood", WOOD_FROM_TREE]] if is_mature() else []


func state_to_save() -> Dictionary:
	return {"age": age, "fruit": int(fruit), "fruit_days": fruit_days}


func state_from_save(d: Dictionary) -> void:
	age = maxi(int(d.get("age", 0)), 0)
	fruit = clampi(int(d.get("fruit", 0)), 0, Fruit.size() - 1) as Fruit
	fruit_days = int(d.get("fruit_days", 0))
	_refresh()
