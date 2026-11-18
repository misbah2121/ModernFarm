class_name InteriorMap
extends Node2D
## Phase 16: peta dalam ruangan (gudang / barn, nanti juga rumah). Semua isi TERSIMPAN di scene
## (mis. scenes/interiors/barn.tscn) sehingga bisa dilihat & diedit di editor:
##   Background (ColorRect)  : latar gelap di luar ruangan.
##   Room       (Node2D)     : potongan gambar ruangan (Sprite2D) dari asset Modern Farm.
##   Walls      (StaticBody2D): kotak tabrakan dinding (ubah CollisionShape2D di Inspector).
##   Objects    (y-sort)     : Player, perabot, Peti (StorageChest) yang bisa dibuka dengan E.
##   Markers    (Marker2D)   : SpawnFromFarm = titik muncul saat masuk.
##   ExitToFarm (MapExit)    : pintu keluar.
## Kamera dikunci di tengah ruangan (ruangan lebih kecil dari layar).

signal exit_reached(target_map: String)

## Nama peta: dipakai Main (maps), simpan, dan musik.
@export var map_name := "barn"
## Lokasi di Peta Dunia (tombol M) tempat ruangan ini berada.
@export var world_location := "farm"
## Ukuran ruangan dalam piksel (dipakai untuk kamera).
@export var room_size := Vector2(240, 272)

@onready var objects: Node2D = $Objects
@onready var player: Player = $Objects/Player
@onready var markers: Node2D = $Markers


func _ready() -> void:
	player.can_use_tools = false  # cangkul/siram/tanam hanya di Farm
	for node in get_children():
		if node is MapExit:
			(node as MapExit).player_entered.connect(func(target: String) -> void: exit_reached.emit(target))
	_setup_camera()


## Kamera tidak mengikuti player keluar ruangan: batasnya dibuat selebar layar dengan ruangan di tengah.
func _setup_camera() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	var view := get_viewport_rect().size if is_inside_tree() else Vector2(640, 360)
	var center := room_size / 2.0
	cam.limit_left = floori(center.x - maxf(view.x, room_size.x) / 2.0)
	cam.limit_right = ceili(center.x + maxf(view.x, room_size.x) / 2.0)
	cam.limit_top = floori(center.y - maxf(view.y, room_size.y) / 2.0)
	cam.limit_bottom = ceili(center.y + maxf(view.y, room_size.y) / 2.0)
	cam.reset_smoothing()


func map_id() -> String:
	return map_name


## Tidak ada air di dalam ruangan.
func is_fishable(_cell: Vector2i) -> bool:
	return false


func get_spawn(from_map: String) -> Vector2:
	var marker := markers.get_node_or_null("SpawnFrom%s" % from_map.capitalize()) as Marker2D
	if marker == null:
		marker = markers.get_child(0) as Marker2D
	return marker.position


## Peti di titik interaksi player, atau null.
func chest_at(world_pos: Vector2) -> StorageChest:
	for node in objects.get_children():
		if node is StorageChest:
			var chest := node as StorageChest
			var rect := Rect2(chest.position + Vector2(-16, -24), Vector2(32, 28))
			if rect.has_point(world_pos):
				return chest
	return null


## Isi peti-peti di ruangan ini (disimpan per nama node).
func to_save() -> Dictionary:
	var chests := {}
	for node in objects.get_children():
		if node is StorageChest:
			chests[String(node.name)] = (node as StorageChest).state_to_save()
	return {"chests": chests}


func from_save(d: Dictionary) -> void:
	var chests: Dictionary = d.get("chests", {})
	for chest_name: String in chests:
		var node := objects.get_node_or_null(NodePath(chest_name))
		if node is StorageChest:
			(node as StorageChest).state_from_save(chests[chest_name])
