class_name InteractHint
extends Node2D
## Phase 18: penanda interaksi seperti gambar referensi (kotak biru berisi ikon + tombol + panah ke bawah)
## yang melayang di atas benda yang sedang dihadap player:
##   pohon = ikon Axe, batu/bijih = ikon Pickaxe, tanaman siap panen = ikon hasil + [E],
##   tanaman belum siap = tanda dilarang merah, peti = tas, dapur = sup, mesin keju, pohon buah,
##   tempat pakan, NPC, dan air di depan pancing.
## Node ini anak Main (ruang dunia, ikut kamera). Main memanggil refresh() setiap frame.
## Tombol: "E" = tombol interaksi; ikon spasi (garis) = tombol alat SPACE.

const BOX := 20
const ARROW_H := 7
const COL_FILL := Color("2f6ad0")
const COL_FILL_DARK := Color("214e9e")
const COL_RIM := Color("bfe0ff")
const COL_OUTLINE := Color("172038")
const COL_WHITE := Color("f4f7ff")
const COL_RED := Color("e8403a")

const ICON_AXE := preload("res://assets/modern_farm/icons/Icons_16x16_Tools_Axe.png")
const ICON_PICKAXE := preload("res://assets/modern_farm/icons/Icons_16x16_Tools_Pickaxe_Custom.png")
const ICON_BAG := preload("res://assets/modern_farm/icons/Icons_16x16_Tools_Bag.png")
const ICON_ROD := preload("res://assets/modern_farm/icons/Icons_16x16_Tools_Fishing_Rod.png")
const ICON_COOK := preload("res://assets/modern_farm/icons/Icon_Dish_Veg_Soup_16x16.png")
const ICON_FEED := preload("res://assets/modern_farm/icons/Icons_16x16_Food_Grain_Bag.png")
const ICON_TALK := preload("res://assets/modern_farm/icons/Icons_16x16_Food_Coffee.png")
const ICON_TRACTOR := preload("res://assets/modern_farm/icons/Icon_Tractor.png")
const ICON_BOARD := preload("res://assets/modern_farm/icons/Icon_Farm_Board.png")
const ICON_STALL := preload("res://assets/modern_farm/icons/Icons_16x16_Crops_Tomato.png")
const ICON_HEART := preload("res://assets/modern_farm/icons/Icon_Heart_9x8.png")
const ICON_DOG_FOOD := preload("res://assets/modern_farm/icons/Icon_Dog_Food.png")

enum HintKey { E, SPACE }

## Diisi Main.
var main: Node

var _icon: Texture2D
var _key: HintKey = HintKey.E
var _blocked := false
var _target := Vector2.ZERO
var _alpha := 0.0
var _t := 0.0


func _ready() -> void:
	z_index = 100
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_t += delta
	var want := 1.0 if _icon != null else 0.0
	_alpha = move_toward(_alpha, want, delta * 8.0)
	visible = _alpha > 0.0
	if visible:
		queue_redraw()


## Tampilkan penanda: `pos` = titik di atas benda (ujung panah).
func show_hint(pos: Vector2, icon: Texture2D, key: HintKey = HintKey.E, blocked := false) -> void:
	if icon != _icon or (_target - pos).length() > 24.0:
		_alpha = minf(_alpha, 0.3)
	_icon = icon
	_key = key
	_blocked = blocked
	_target = pos.round()


func hide_hint() -> void:
	_icon = null


func _draw() -> void:
	if _icon == null and _alpha <= 0.0:
		return
	var bob := roundf(sin(_t * 4.0) * 1.5)
	var tip := _target + Vector2(0, bob)
	var box := Rect2(tip + Vector2(-BOX / 2.0, -ARROW_H - BOX - 1), Vector2(BOX, BOX))
	var a := _alpha
	# kotak: garis luar gelap, bingkai terang, isi biru dengan bayangan bawah
	draw_rect(box.grow(1), Color(COL_OUTLINE, a))
	draw_rect(box, Color(COL_RIM, a))
	draw_rect(box.grow(-1), Color(COL_FILL, a))
	draw_rect(Rect2(box.position + Vector2(1, box.size.y - 4), Vector2(box.size.x - 2, 3)), Color(COL_FILL_DARK, a))
	if _icon != null:
		var isz := _icon.get_size()
		var scale_k := minf(1.0, 16.0 / maxf(isz.x, isz.y))
		var draw_size := (isz * scale_k).floor()
		draw_texture_rect(_icon, Rect2((box.get_center() - draw_size / 2.0).floor(), draw_size), false, Color(1, 1, 1, a))
	if _blocked:
		var c := box.get_center()
		draw_arc(c, 7.0, 0.0, TAU, 20, Color(COL_RED, a), 2.0, false)
		draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Color(COL_RED, a), 2.0, false)
	_draw_key(box, a)
	_draw_arrow(tip, a)


## Tombol kecil di pojok kanan bawah kotak: "E" atau tombol spasi.
func _draw_key(box: Rect2, a: float) -> void:
	var w := 7.0 if _key == HintKey.E else 11.0
	var r := Rect2(Vector2(box.end.x - w + 2, box.end.y - 6), Vector2(w, 8))
	draw_rect(r.grow(1), Color(COL_OUTLINE, a))
	draw_rect(r, Color(COL_WHITE, a))
	var ink := Color(COL_OUTLINE, a)
	if _key == HintKey.E:
		# huruf E piksel 3x5
		var o := r.position + Vector2(2, 1.5)
		draw_rect(Rect2(o, Vector2(1, 5)), ink)
		draw_rect(Rect2(o, Vector2(3, 1)), ink)
		draw_rect(Rect2(o + Vector2(0, 2), Vector2(2, 1)), ink)
		draw_rect(Rect2(o + Vector2(0, 4), Vector2(3, 1)), ink)
	else:
		# simbol spasi: garis dengan dua kaki
		var o := r.position + Vector2(2, 3)
		draw_rect(Rect2(o + Vector2(0, 2), Vector2(w - 4, 1)), ink)
		draw_rect(Rect2(o, Vector2(1, 2)), ink)
		draw_rect(Rect2(o + Vector2(w - 5, 0), Vector2(1, 2)), ink)


## Panah putih ke bawah dengan garis luar gelap.
func _draw_arrow(tip: Vector2, a: float) -> void:
	var top := tip.y - ARROW_H
	var outline := PackedVector2Array([
		Vector2(tip.x - 3, top - 1), Vector2(tip.x + 3, top - 1), Vector2(tip.x + 3, top + 2),
		Vector2(tip.x + 6, top + 2), Vector2(tip.x, tip.y + 1), Vector2(tip.x - 6, top + 2), Vector2(tip.x - 3, top + 2),
	])
	draw_colored_polygon(outline, Color(COL_OUTLINE, a))
	var inner := PackedVector2Array([
		Vector2(tip.x - 2, top), Vector2(tip.x + 2, top), Vector2(tip.x + 2, top + 3),
		Vector2(tip.x + 4, top + 3), Vector2(tip.x, tip.y - 1), Vector2(tip.x - 4, top + 3), Vector2(tip.x - 2, top + 3),
	])
	draw_colored_polygon(inner, Color(COL_WHITE, a))


# ---------------------------------------------------------------- mencari target

## Dipanggil Main setiap frame. Mencari benda di depan player dan menampilkan penanda yang cocok.
func refresh(player: Player, map: Node2D, can_show: bool) -> void:
	if not can_show or player == null or map == null or player.fishing:
		hide_hint()
		return
	var point := player.global_position + (Player.INTERACT_OFFSET[player.facing] as Vector2)
	var cell := player.get_target_cell()
	if not _find(player, map, point, cell):
		hide_hint()


func _find(player: Player, map: Node2D, point: Vector2, cell: Vector2i) -> bool:
	# Farm: objek pasang, tanaman, tempat pakan
	if map is FarmMap:
		var farm := map as FarmMap
		var obj := farm.object_at(point)
		if obj != null:
			return _hint_placed(obj)
		# Phase 22: kios pasar
		if farm.stall != null and farm.stall.is_at(point):
			show_hint(farm.stall.global_position + Vector2(0, -66), ICON_STALL)
			return true
		# Phase 20: anjing (hati = elus; dilarang = sudah dielus hari ini), mangkuk
		if farm.dog != null:
			if farm.dog.is_at(point):
				show_hint(farm.dog.global_position + Vector2(0, -26), ICON_HEART, HintKey.E, AnimalManager.dog_petted)
				return true
			if farm.dog.bowl_at(point):
				show_hint(farm.dog.bowl.global_position + Vector2(8, 0), ICON_DOG_FOOD, HintKey.E, AnimalManager.bowl_full or AnimalManager.dog_fed)
				return true
		# Phase 19: traktor (dilarang = masih rusak) & pekerja
		if farm.tractor != null and farm.tractor.is_at(point):
			show_hint(farm.tractor.global_position + Vector2(0, -46), ICON_TRACTOR, HintKey.E, FarmServices.tractor_level <= 0)
			return true
		if farm.workers != null and farm.workers.worker_at(point) != "":
			var npc := farm.objects.get_node_or_null("Worker_%s" % farm.workers.worker_at(point)) as Node2D
			if npc != null:
				show_hint(npc.global_position + Vector2(0, -34), ICON_TALK)
				return true
		var crop := farm.soil.get_crop(cell)
		if crop != null:
			var item := InventoryManager.get_item(crop.data.id)
			show_hint(crop.position + Vector2(0, -crop.data.sprite_height() + 2),
				item.icon if item != null else ICON_BAG, HintKey.E, not crop.is_harvestable())
			return true
		if farm.is_feeder(point):
			show_hint(farm.feeder.global_position + Vector2(0, -20), ICON_FEED)
			return true
	# Semua peta: pohon / batu / barang pungut
	var objects := map.get_node_or_null("Objects")
	if objects != null:
		for node in objects.get_children():
			if node is ResourceNode and (node as ResourceNode).is_at(point):
				var res := node as ResourceNode
				var top := res.global_position + Vector2(0, res.hit_area.position.y - 2)
				match res.tool:
					ResourceNode.Tool.AXE:
						show_hint(top, ICON_AXE, HintKey.SPACE)
					ResourceNode.Tool.PICKAXE:
						show_hint(top, ICON_PICKAXE, HintKey.SPACE)
					_:
						show_hint(top, res.drop_item.icon if res.drop_item != null else ICON_BAG, HintKey.E)
				return true
	# Village: NPC
	if map is VillageMap:
		var npc := (map as VillageMap).npc_at(point)
		if npc != null:
			show_hint(npc.global_position + Vector2(0, -34), ICON_TALK)
			return true
	# Dalam ruangan: peti
	if map is InteriorMap:
		var chest := (map as InteriorMap).chest_at(point)
		if chest != null:
			show_hint(chest.global_position + Vector2(0, -26), ICON_BAG)
			return true
	# Pancing di depan air: penanda tepat di titik jatuh pelampung
	var tool := InventoryManager.current_tool()
	if tool != null and tool.kind == ToolData.Kind.FISHING_ROD and main != null and main.fishing.can_cast(player, map):
		show_hint(player.bobber_position(), ICON_ROD, HintKey.SPACE)
		return true
	return false


func _hint_placed(obj: PlacedObject) -> bool:
	var top := obj.global_position + Vector2(0, -obj.footprint.size.y * 16 - 14)
	if obj is FarmBoard:
		show_hint(obj.global_position + Vector2(0, -20), ICON_BOARD)
	elif obj is KitchenStove:
		show_hint(obj.global_position + Vector2(-14, -36), ICON_COOK)
	elif obj is StorageChest:
		show_hint(obj.global_position + Vector2(0, -30), ICON_BAG)
	elif obj is DecorObject:
		hide_hint()  # hiasan: tidak perlu penanda
	elif obj is CheeseMachine:
		var machine := obj as CheeseMachine
		var cheese := InventoryManager.get_item(machine.output_id())
		var milk := InventoryManager.get_item(CheeseMachine.INPUT_ITEM)
		match machine.state:
			CheeseMachine.State.READY:
				show_hint(obj.global_position + Vector2(0, -44), cheese.icon if cheese != null else ICON_BAG)
			CheeseMachine.State.WORKING:
				show_hint(obj.global_position + Vector2(0, -44), cheese.icon if cheese != null else ICON_BAG, HintKey.E, true)
			_:
				show_hint(obj.global_position + Vector2(0, -44), milk.icon if milk != null else ICON_BAG)
	elif obj is FruitTree:
		var tree := obj as FruitTree
		var fruit := InventoryManager.get_item(tree.fruit_id)
		if not tree.is_mature() or fruit == null:
			show_hint(top, ICON_AXE, HintKey.SPACE)
		else:
			show_hint(obj.global_position + Vector2(0, -40), fruit.icon, HintKey.E, tree.fruit != FruitTree.Fruit.RIPE)
	else:
		show_hint(top, ICON_PICKAXE, HintKey.SPACE)  # mesin lain: pukul Pickaxe untuk mengambil
	return true
