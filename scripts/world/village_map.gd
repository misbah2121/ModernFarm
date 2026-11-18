class_name VillageMap
extends Node2D
## Peta VILLAGE. Semua isi peta TERSIMPAN di scenes/village/village.tscn dan bisa diedit di editor:
##   Ground   (TileMapLayer) : jalan, alun-alun, sungai (TileSet modern_farm_terrain.tres, tab Terrains).
##   Objects  (y-sort)       : rumah, Toko Serba Ada (kios), sumur, pohon, bunga, papan = instance scene
##                             dari res://scenes/world/props/.
##   Labels                  : tulisan di atas papan penunjuk (FARM >, FOREST ^, < MINE, TOKO [E]).
##   Areas    (ReferenceRect): ShopCounter = area konter toko (tekan E di sini = buka toko).
##   Markers  (Marker2D)     : SpawnFromFarm / SpawnFromForest / SpawnFromMine.
##   ExitToFarm / ExitToForest / ExitToMine (MapExit).
##   Places   (Marker2D)     : tempat jadwal NPC (Phase 11): HouseWest, MiraShop, Square, ...
##                             Marker di grup "indoor" = pintu rumah (NPC masuk dan tidak terlihat).
##                             Metadata "wander" = jarak jalan-jalan NPC di tempat itu.
## NPC TIDAK disimpan di scene: dibuat saat _ready dari data res://data/npc/*.tres, lalu bergerak
## sesuai jadwal (NpcData.schedule) memakai jalur AStarGrid2D yang menghindari bangunan & air.

signal exit_reached(target_map: String)

const TILE := TerrainTiles.TILE
## Phase 7: toko di kios pasar. Tombol E di konter (Areas/ShopCounter) membuka toko ini.
const GENERAL_STORE: ShopData = preload("res://data/shop/general_store.tres")

@onready var ground: TileMapLayer = $Ground
@onready var objects: Node2D = $Objects
## Phase 22: detail rumput + rumput hias bergoyang, suasana (daun gugur, kunang-kunang).
@onready var grass_detail: GrassDetail = get_node_or_null("GrassDetail") as GrassDetail
@onready var decor: TileMapLayer = get_node_or_null("Decor")
var ambience: FarmAmbience
@onready var player: Player = $Objects/Player
@onready var shop_counter: ReferenceRect = $Areas/ShopCounter
@onready var markers: Node2D = $Markers
@onready var places: Node2D = $Places

var npcs: Array[Npc] = []
## Ukuran peta dalam tile, dihitung dari tile yang digambar di Ground.
var map_w := 0
var map_h := 0

var _cells := PackedInt32Array()
var _astar := AStarGrid2D.new()

## Posisi tambahan saat beberapa NPC menuju tempat yang sama (agar tidak bertumpuk).
const CROWD_OFFSETS: Array[Vector2] = [
	Vector2(0, 0), Vector2(26, 0), Vector2(-26, 0), Vector2(0, 22), Vector2(26, 22), Vector2(-26, 22),
]


func _ready() -> void:
	player.can_use_tools = false  # cangkul/siram hanya di Farm
	_read_terrain()
	_build_navigation()
	_place_npcs()
	_build_world_bounds()
	_connect_exits()
	_setup_camera()
	_setup_style()
	_update_schedules(true)
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _update_schedules(false))
	TimeManager.day_started.connect(func(_d: int) -> void: _update_schedules(true))


## Saat player masuk desa lagi: NPC langsung berada di tempat jadwalnya.
func _enter_tree() -> void:
	if not npcs.is_empty():
		_update_schedules(true)


## Titik muncul player ketika datang dari peta lain (Marker2D "SpawnFrom<Nama>").
func get_spawn(from_map: String) -> Vector2:
	var marker := markers.get_node_or_null("SpawnFrom%s" % from_map.capitalize()) as Marker2D
	if marker == null:
		marker = markers.get_node("SpawnFromFarm") as Marker2D
	return marker.position


## Toko yang konternya ada di titik interaksi player, atau null.
func shop_at(world_pos: Vector2) -> ShopData:
	if Rect2(shop_counter.position, shop_counter.size).has_point(world_pos):
		return GENERAL_STORE
	return null


## Phase 8: id peta untuk data ikan (FishData.locations).
func map_id() -> String:
	return "village"


## Phase 8: true jika tile berisi air (sungai selatan) dan masih di dalam peta.
func is_fishable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= map_w or cell.y < 0 or cell.y >= map_h:
		return false
	return _cells[cell.y * map_w + cell.x] == TerrainTiles.Terrain.WATER


## NPC yang berada di depan player (dekat titik interaksi), atau null.
func npc_at(world_pos: Vector2) -> Npc:
	var best: Npc = null
	var best_dist := 22.0
	for npc in npcs:
		if not npc.is_available():
			continue
		var dist := npc.center().distance_to(world_pos)
		if dist < best_dist:
			best_dist = dist
			best = npc
	return best


# ---------------------------------------------------------------- baca isi scene

## Terrain tiap tile = nomor terrain tile di TileSet (tile kosong dianggap rumput).
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


func _place_npcs() -> void:
	for data in NpcManager.all_npcs():
		var npc := Npc.new()
		objects.add_child(npc)
		npc.setup(data)
		npcs.append(npc)


# ---------------------------------------------------------------- batas, exit, kamera

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


## Semua node MapExit (anak langsung peta) diteruskan ke signal exit_reached.
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


# ---------------------------------------------------------------- jadwal NPC (Phase 11)

## Grid navigasi: tile air dan tile yang tertutup collision objek (bangunan, pohon, batu) = tidak bisa dilewati.
func _build_navigation() -> void:
	_astar.region = Rect2i(0, 0, map_w, map_h)
	_astar.cell_size = Vector2(TILE, TILE)
	_astar.offset = Vector2(TILE / 2.0, TILE / 2.0)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for y in map_h:
		for x in map_w:
			if _cells[y * map_w + x] == TerrainTiles.Terrain.WATER:
				_astar.set_point_solid(Vector2i(x, y))
	for node in objects.find_children("*", "CollisionShape2D", true, false):
		var shape := node as CollisionShape2D
		if not shape.get_parent() is StaticBody2D:
			continue
		var rect_shape := shape.shape as RectangleShape2D
		if rect_shape == null:
			continue
		var rect := Rect2(shape.global_position - global_position - rect_shape.size / 2.0, rect_shape.size).grow(-1.0)
		var from := Vector2i((rect.position / TILE).floor())
		var to := Vector2i((rect.end / TILE).floor())
		for y in range(from.y, to.y + 1):
			for x in range(from.x, to.x + 1):
				if _astar.is_in_boundsv(Vector2i(x, y)):
					_astar.set_point_solid(Vector2i(x, y))


func _nearest_free(cell: Vector2i) -> Vector2i:
	cell = cell.clamp(Vector2i.ZERO, Vector2i(map_w - 1, map_h - 1))
	if not _astar.is_point_solid(cell):
		return cell
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var c := cell + Vector2i(dx, dy)
				if _astar.is_in_boundsv(c) and not _astar.is_point_solid(c):
					return c
	return cell


## Jalur (titik-titik piksel) dari `from` ke `to` yang menghindari bangunan dan air.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _nearest_free(Vector2i((from / TILE).floor()))
	var b := _nearest_free(Vector2i((to / TILE).floor()))
	var path := _astar.get_point_path(a, b)
	if path.is_empty():
		return PackedVector2Array([to])
	path[path.size() - 1] = to
	return path


func place_position(place_name: String) -> Vector2:
	var marker := places.get_node_or_null(place_name) as Marker2D
	return marker.position if marker != null else Vector2.ZERO


func has_place(place_name: String) -> bool:
	return place_name != "" and places.has_node(place_name)


## Memperbarui tujuan setiap NPC. instant = langsung dipindah (pagi hari / player baru masuk desa).
func _update_schedules(instant: bool) -> void:
	var crowd: Dictionary = {}  # nama tempat -> jumlah NPC yang sudah diberi tempat
	for npc in npcs:
		var place := NpcManager.current_place(npc.data)
		if not has_place(place):
			continue
		var index: int = crowd.get(place, 0)
		crowd[place] = index + 1
		if place == npc.place and not instant:
			continue
		npc.place = place
		var marker := places.get_node(place) as Marker2D
		var indoor := marker.is_in_group(&"indoor")
		var radius := float(marker.get_meta(&"wander", 20.0))
		var pos := marker.position
		if not indoor:
			pos += CROWD_OFFSETS[index % CROWD_OFFSETS.size()]
		if instant or not is_inside_tree():
			npc.snap(pos, indoor, radius)
		else:
			npc.travel(find_path(npc.position, pos), indoor, radius)


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
