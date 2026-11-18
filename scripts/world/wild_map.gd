class_name WildMap
extends Node2D
## Peta alam liar (Phase 10): FOREST dan MINE memakai script yang sama.
## Semua isi peta TERSIMPAN di scene (scenes/forest/forest.tscn, scenes/mine/mine.tscn):
##   Ground   (TileMapLayer) : tile terrain (TileSet modern_farm_terrain.tres, tab Terrains).
##   Objects  (y-sort)       : Player, pohon & batu yang bisa dipukul, barang pungut
##                             (instance dari res://scenes/world/resources/), dan hiasan (props).
##   Labels                  : tulisan papan penunjuk.
##   Markers  (Marker2D)     : SpawnFromVillage dst. = titik muncul dari peta lain.
##   ExitTo... (MapExit)     : pintu keluar.
## Script ini membaca terrain (untuk memancing), memasang batas dunia, pintu keluar, dan kamera.

signal exit_reached(target_map: String)

const TILE := TerrainTiles.TILE

## Nama peta untuk data ikan (FishData.locations) dan pindah peta: "forest" / "mine".
@export var map_name: String = "forest"

@onready var ground: TileMapLayer = $Ground
@onready var objects: Node2D = $Objects
## Phase 22: detail rumput + rumput hias bergoyang, suasana (daun gugur, kunang-kunang).
@onready var grass_detail: GrassDetail = get_node_or_null("GrassDetail") as GrassDetail
@onready var decor: TileMapLayer = get_node_or_null("Decor")
var ambience: FarmAmbience
@onready var player: Player = $Objects/Player
@onready var markers: Node2D = $Markers

var map_w := 0
var map_h := 0

var _cells := PackedInt32Array()


func _ready() -> void:
	player.can_use_tools = false  # cangkul/siram/tanam hanya di Farm (Axe & Pickaxe tetap bisa)
	_read_terrain()
	_build_world_bounds()
	_connect_exits()
	_setup_camera()
	_setup_style()


func map_id() -> String:
	return map_name


## Titik muncul player ketika datang dari peta lain (Marker2D "SpawnFrom<Nama>").
func get_spawn(from_map: String) -> Vector2:
	var marker := markers.get_node_or_null("SpawnFrom%s" % from_map.capitalize()) as Marker2D
	if marker == null:
		marker = markers.get_child(0) as Marker2D
	return marker.position


func is_fishable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= map_w or cell.y < 0 or cell.y >= map_h:
		return false
	return _cells[cell.y * map_w + cell.x] == TerrainTiles.Terrain.WATER


## ResourceNode (pohon / batu / barang pungut) di titik itu, atau null.
func resource_at(world_pos: Vector2) -> ResourceNode:
	for node in objects.get_children():
		if node is ResourceNode and (node as ResourceNode).is_at(world_pos):
			return node as ResourceNode
	return null


func _read_terrain() -> void:
	var used := ground.get_used_rect()
	map_w = used.end.x
	map_h = used.end.y
	_cells.resize(map_w * map_h)
	for y in map_h:
		for x in map_w:
			var data := ground.get_cell_tile_data(Vector2i(x, y))
			var terrain: int = TerrainTiles.Terrain.GRASS
			if data != null and data.terrain >= 0:
				terrain = data.terrain
			_cells[y * map_w + x] = terrain


func _build_world_bounds() -> void:
	var body := StaticBody2D.new()
	body.name = "WorldBounds"
	var w := float(map_w * TILE)
	var h := float(map_h * TILE)
	var t := 32.0
	var walls: Array[Rect2] = [
		Rect2(-t, -t, w + 2.0 * t, t),
		Rect2(-t, h, w + 2.0 * t, t),
		Rect2(-t, 0.0, t, h),
		Rect2(w, 0.0, t, h),
	]
	for wall in walls:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall.size
		shape.shape = rect
		shape.position = wall.get_center()
		body.add_child(shape)
	add_child(body)


func _connect_exits() -> void:
	for node in get_children():
		if node is MapExit:
			(node as MapExit).player_entered.connect(func(target: String) -> void: exit_reached.emit(target))


func _setup_camera() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map_w * TILE
	cam.limit_bottom = map_h * TILE
	cam.reset_smoothing()


# ---------------------------------------------------------------- Phase 22: gaya peta seperti Farm

## Terrain satu tile (dipakai GrassDetail).
func get_terrain(cell: Vector2i) -> int:
	if cell.x < 0 or cell.x >= map_w or cell.y < 0 or cell.y >= map_h:
		return TerrainTiles.Terrain.WATER
	return _cells[cell.y * map_w + cell.x]


## Hanya peta luar ruangan yang punya node GrassDetail (Desa, Hutan) - Tambang tidak.
func _setup_style() -> void:
	if grass_detail == null:
		return
	if grass_detail != null:
		grass_detail.setup(self)
		if decor != null:
			decor.material = grass_detail.shared_material
	ambience = FarmAmbience.new()
	ambience.name = "Ambience"
	add_child(ambience)
	ambience.setup(self)


func _process(_delta: float) -> void:
	if grass_detail != null and player != null:
		grass_detail.update_pushers(player.global_position, Vector2(-9999, -9999))
