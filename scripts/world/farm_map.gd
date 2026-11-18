class_name FarmMap
extends Node2D
## Peta FARM. Semua isi peta TERSIMPAN di scenes/farm/farm.tscn, jadi bisa dilihat dan diedit
## langsung di editor Godot:
##   Ground   (TileMapLayer) : tile rumput / jalan / air / pasir. Gambar dengan panel TileMap >
##                             tab Terrains (autotile) memakai TileSet modern_farm_terrain.tres.
##   SoilWet  (TileMapLayer) : tanah yang sudah disiram (tile asli Soil_Wet_1..4; diisi otomatis saat main).
##   SoilEdge (TileMapLayer) : rumbai rumput di sekitar tanah olahan (diisi otomatis saat main).
##   Decor    (TileMapLayer) : rumput hias & bunga (modern_farm_decor.tres). Digambar DI BAWAH Objects
##                             dan tanpa y-sort, jadi tidak pernah menutupi player.
##   Objects  (y-sort)       : rumah, barn, pohon, batu = instance scene dari res://scenes/world/props/.
##                             Drag file .tscn dari FileSystem ke dalam Objects untuk menambah objek.
##   Fences   (TileMapLayer di dalam Objects): pagar kayu (2_Fences_16x16.png) yang punya collision.
##                             Gambar/hapus pagar dengan panel TileMap memakai modern_farm_fences.tres.
##   Areas    (ReferenceRect): FarmPlot, FarmPlot2, ... (semua kotak yang namanya diawali "FarmPlot"
##                             = lahan yang boleh dicangkul), HouseDoor (tekan E = tidur),
##                             AnimalPen (Phase 9: area jalan-jalan hewan ternak).
##                             Kotak ini hanya terlihat di editor; ubah posisi/ukurannya di Inspector.
##   Markers  (Marker2D)     : SpawnFromVillage = titik muncul saat datang dari Village.
##   ExitToVillage (MapExit) : area pintu keluar ke Village.
##   ExitToBarn    (MapExit) : Phase 16, pintu barn -> peta dalam gudang (scenes/interiors/barn.tscn).
##                             Markers/SpawnFromBarn = titik muncul saat keluar dari gudang.
## Script ini hanya MEMBACA isi scene saat _ready (terrain tiap tile, objek penghalang, ukuran peta),
## lalu memasang batas dunia, pintu keluar, kamera, sistem pertanian, dan hewan ternak.
## Hewan (FarmAnimal) TIDAK disimpan di scene: dibuat dari AnimalManager saat game berjalan.

signal exit_reached(target_map: String)

const TILE := TerrainTiles.TILE
## Area batang pohon relatif terhadap titik kaki pohon (tile di sini tidak bisa dicangkul).
const TREE_TRUNK := Rect2(-14, -12, 28, 14)

@onready var ground: TileMapLayer = $Ground
@onready var objects: Node2D = $Objects
@onready var player: Player = $Objects/Player
@onready var soil: FarmSoil = $Soil
@onready var cursor: TileCursor = $Cursor
@onready var farm_plot: ReferenceRect = $Areas/FarmPlot
@onready var house_door: ReferenceRect = $Areas/HouseDoor
@onready var spawn_from_village: Marker2D = $Markers/SpawnFromVillage
@onready var animal_pen: ReferenceRect = $Areas/AnimalPen
@onready var feeder: AnimalFeeder = $Objects/Feeder
## Phase 19: traktor yang bisa dikendarai (scenes/world/props/tractor.tscn).
@onready var tractor: Tractor = get_node_or_null("Objects/Tractor")
## Phase 20: anjing peliharaan (scenes/world/props/dog_labrador.tscn, node Objects/Dog).
@onready var dog: PetDog = get_node_or_null("Objects/Dog") as PetDog
## Phase 22: kios pasar (instance MarketStand di Objects dengan script market_stall.gd).
@onready var stall: MarketStall = get_node_or_null("Objects/MarketStand") as MarketStall
## Lapisan gelap untuk tanah yang sudah disiram (TileMapLayer tepat di atas Ground).
@onready var soil_wet: TileMapLayer = get_node_or_null("SoilWet")
## Rumbai rumput di tepi tanah olahan (TileMapLayer di atas SoilWet).
@onready var soil_edge: TileMapLayer = get_node_or_null("SoilEdge")
## Rumput hias / bunga (TileMapLayer di bawah Objects, tanpa y-sort) - tidak pernah menutupi player.
@onready var decor: TileMapLayer = get_node_or_null("Decor")
## Phase 21: detail rumput (GrassDetail) di atas Ground.
@onready var grass_detail: GrassDetail = get_node_or_null("GrassDetail") as GrassDetail

var animals: Array[FarmAnimal] = []
## Phase 14: mesin / objek yang dipasang player. tile -> PlacedObject (objek besar mengisi beberapa tile).
var _placed: Dictionary = {}

## Ukuran peta dalam tile, dihitung dari tile yang digambar di Ground.
var map_w := 0
var map_h := 0

var _cells := PackedInt32Array()      # terrain tiap tile (TerrainTiles.Terrain)
var _blocked_rects: Array[Rect2] = []  # bangunan/objek + batang pohon (tidak bisa dicangkul)


func _ready() -> void:
	_read_terrain()
	_read_props()
	_build_world_bounds()
	_connect_exits()
	_setup_camera()
	_setup_farming()
	_setup_animals()
	_setup_placed()
	_setup_sparkles()
	_setup_ambience()
	if grass_detail != null:
		grass_detail.setup(self)
		if decor != null:
			decor.material = grass_detail.shared_material  # rumput hias ikut bergoyang
	if tractor != null:
		tractor.farm = self
	_setup_workers()
	if dog != null:
		dog.setup(self)


## Phase 19: pekerja farm (dihubungkan setelah FarmSoil, jadi bekerja sesudah tanah dikeringkan pagi hari).
var workers: FarmWorkers


func _setup_workers() -> void:
	workers = FarmWorkers.new()
	workers.name = "FarmWorkers"
	add_child(workers)
	workers.setup(self)


## Phase 21: tetes air di tanaman yang belum disiram, daun gugur, kunang-kunang malam.
var ambience: FarmAmbience


func _setup_ambience() -> void:
	ambience = FarmAmbience.new()
	ambience.name = "FarmAmbience"
	add_child(ambience)
	ambience.setup(self)


## Phase 18: kilau kecil di rumput (GrassSparkles), tepat di atas layer Decor dan di bawah Objects.
func _setup_sparkles() -> void:
	var sparkles := GrassSparkles.new()
	sparkles.name = "GrassSparkles"
	sparkles.farm = self
	add_child(sparkles)
	move_child(sparkles, objects.get_index())


# ---------------------------------------------------------------- hewan (Phase 9)

func _setup_animals() -> void:
	for state in AnimalManager.animals:
		_spawn_animal(state)
	AnimalManager.animal_added.connect(_spawn_animal)
	# Phase 18: barang temuan hewan (truffle) yang tergeletak di kandang.
	for entry: Dictionary in AnimalManager.ground_items:
		_spawn_ground_item(entry)
	AnimalManager.forage_found.connect(_on_forage_found)


## Phase 18: babi menemukan truffle -> barang muncul di tanah dekat babi itu (di dalam kandang).
func _on_forage_found(state, item: ItemData) -> void:
	var origin := Vector2(animal_pen.position + animal_pen.size / 2.0)
	for animal in animals:
		if animal.state == state:
			origin = animal.position
	var pen := Rect2(animal_pen.position, animal_pen.size).grow(-8.0)
	var pos := (origin + Vector2(randf_range(-12, 12), randf_range(-6, 10))).clamp(pen.position, pen.end).round()
	var entry := {"id": item.id, "x": pos.x, "y": pos.y}
	AnimalManager.ground_items.append(entry)
	_spawn_ground_item(entry)
	soil.message.emit("%s menemukan %s di kandang!" % [state.animal_name, item.item_name])


func _spawn_ground_item(entry: Dictionary) -> void:
	var item := InventoryManager.get_item(String(entry.get("id", "")))
	if item == null:
		return
	var pickup := ItemPickup.new()
	pickup.item = item
	pickup.persistent = true
	pickup.position = Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
	pickup.collected.connect(func(_p: ItemPickup) -> void: AnimalManager.ground_items.erase(entry))
	objects.add_child(pickup)


func _spawn_animal(state) -> void:
	var animal := FarmAnimal.new()
	objects.add_child(animal)
	animal.setup(state, Rect2(animal_pen.position, animal_pen.size))
	animals.append(animal)


## Hewan di depan player (dekat titik interaksi), atau null.
func animal_at(world_pos: Vector2) -> FarmAnimal:
	var best: FarmAnimal = null
	var best_dist := INF
	for animal in animals:
		var dist := animal.center().distance_to(world_pos)
		if dist < animal.reach() and dist < best_dist:
			best_dist = dist
			best = animal
	return best


func is_feeder(world_pos: Vector2) -> bool:
	return feeder != null and feeder.is_at(world_pos)


# ---------------------------------------------------------------- baca isi scene

## Membaca terrain tiap tile dari TileMapLayer. Terrain = nomor terrain tile di TileSet
## (0 Grass, 1 Path, 2 Water, 3 Sand, 4 Soil Dry, 5 Soil Wet). Tile kosong dianggap rumput.
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


## Objek di grup "solid_prop" (bangunan, batu, sumur, ...) menghalangi seluruh area sprite-nya;
## objek di grup "tree" hanya menghalangi area batangnya.
func _read_props() -> void:
	for node in objects.get_children():
		if not node is Node2D:
			continue
		var prop := node as Node2D
		if prop.is_in_group("tree"):
			_blocked_rects.append(Rect2(prop.position + TREE_TRUNK.position, TREE_TRUNK.size))
		elif prop.is_in_group("solid_prop"):
			var sprite := prop.get_node_or_null("Sprite2D") as Sprite2D
			if sprite != null:
				var rect := sprite.get_rect()
				_blocked_rects.append(Rect2(prop.position + sprite.position + rect.position, rect.size))


# ---------------------------------------------------------------- terrain (dipakai FarmSoil & memancing)

func _neighbor_mask(cell: Vector2i, terrain: int) -> int:
	var mask := 0
	for i in TerrainTiles.NEIGHBORS.size():
		var n: Vector2i = cell + TerrainTiles.NEIGHBORS[i]
		var same := true  # di luar peta dianggap terrain yang sama
		if _in_bounds(n):
			same = TerrainTiles.same_family(_cells[n.y * map_w + n.x], terrain)
		if same:
			mask |= 1 << i
	return mask


func _paint_cell(cell: Vector2i) -> void:
	var terrain: int = _cells[cell.y * map_w + cell.x]
	var info := TerrainTiles.tile_for(terrain, _neighbor_mask(cell, terrain))
	ground.set_cell(cell, info["source"], info["coords"], info["alt"])
	_paint_soil_layers(cell, terrain)


## Layer SoilWet: tanah yang sudah disiram = tile asli Soil_Wet_1..4 (variasi per tile) di atas Ground.
## Layer SoilEdge: rumbai rumput di tile rumput yang bersebelahan dengan tanah olahan,
## jadi petak tanah menyatu dengan rumput seperti di asset asli.
func _paint_soil_layers(cell: Vector2i, terrain: int) -> void:
	if soil_wet != null:
		if terrain == TerrainTiles.Terrain.SOIL_WET:
			soil_wet.set_cell(cell, TerrainTiles.soil_wet_source(cell), Vector2i.ZERO)
		else:
			soil_wet.erase_cell(cell)
	if soil_edge == null:
		return
	var mask := 0
	if terrain == TerrainTiles.Terrain.GRASS:
		for i in TerrainTiles.NEIGHBORS.size():
			var n: Vector2i = cell + TerrainTiles.NEIGHBORS[i]
			if _in_bounds(n) and _is_soil(_cells[n.y * map_w + n.x]):
				mask |= 1 << i
	if mask == 0:
		soil_edge.erase_cell(cell)
	else:
		soil_edge.set_cell(cell, 0, TerrainTiles.soil_edge_coords(mask))


func _is_soil(terrain: int) -> bool:
	return terrain == TerrainTiles.Terrain.SOIL_DRY or terrain == TerrainTiles.Terrain.SOIL_WET


## Terrain di satu tile (GRASS, SOIL_DRY, ...). Di luar peta dianggap WATER (tidak bisa dipakai).
func get_terrain(cell: Vector2i) -> int:
	if not _in_bounds(cell):
		return TerrainTiles.Terrain.WATER
	return _cells[cell.y * map_w + cell.x]


## Mengubah terrain satu tile lalu menggambar ulang tile itu dan 8 tetangganya (autotile).
func set_terrain(cell: Vector2i, terrain: int) -> void:
	if not _in_bounds(cell):
		return
	_cells[cell.y * map_w + cell.x] = terrain
	if decor != null and terrain != TerrainTiles.Terrain.GRASS:
		decor.erase_cell(cell)  # rumput hias hilang saat tile dicangkul
	if grass_detail != null:
		grass_detail.paint(cell)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c := cell + Vector2i(dx, dy)
			if _in_bounds(c):
				_paint_cell(c)


## True jika tile tertimpa bangunan/objek/batang pohon/mesin yang dipasang.
func is_cell_blocked(cell: Vector2i) -> bool:
	if _placed.has(cell):
		return true
	var rect := Rect2(Vector2(cell * TILE), Vector2(TILE, TILE))
	for r in _blocked_rects:
		if r.intersects(rect):
			return true
	return false


## Lahan pertanian utama (dalam tile), dari kotak Areas/FarmPlot.
func farm_plot_rect() -> Rect2i:
	return _rect_to_cells(Rect2(farm_plot.position, farm_plot.size))


## Semua lahan pertanian (dalam tile): setiap ReferenceRect di Areas yang namanya diawali "FarmPlot".
## Untuk menambah lahan baru cukup duplikat FarmPlot di editor (Ctrl+D) lalu geser kotaknya.
func farm_plot_rects() -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	for node in farm_plot.get_parent().get_children():
		if node is ReferenceRect and String(node.name).begins_with("FarmPlot"):
			var r := node as ReferenceRect
			result.append(_rect_to_cells(Rect2(r.position, r.size)))
	return result


## True jika tile berada di salah satu lahan pertanian.
func is_farm_plot(cell: Vector2i) -> bool:
	for rect in farm_plot_rects():
		if rect.has_point(cell):
			return true
	return false


func _rect_to_cells(r: Rect2) -> Rect2i:
	var from := Vector2i((r.position / TILE).floor())
	var to := Vector2i((r.end / TILE).ceil())
	return Rect2i(from, to - from)


## Phase 8: id peta untuk data ikan (FishData.locations).
func map_id() -> String:
	return "farm"


## Phase 8: true jika tile berisi air (sungai / kolam) dan masih di dalam peta.
func is_fishable(cell: Vector2i) -> bool:
	return _in_bounds(cell) and _cells[cell.y * map_w + cell.x] == TerrainTiles.Terrain.WATER


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_w and cell.y >= 0 and cell.y < map_h


# ---------------------------------------------------------------- batas, exit, kamera

## Dinding tak terlihat di sekeliling peta (ukurannya mengikuti tile yang digambar).
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


# ---------------------------------------------------------------- farming (Phase 2)

func _setup_farming() -> void:
	soil.setup(self)
	cursor.player = player
	player.tool_used.connect(soil.use_tool)
	player.harvest_used.connect(soil.harvest)
	player.harvest_check = soil.can_harvest


## Titik muncul player ketika datang dari peta lain (Marker2D "SpawnFrom<Nama>", default Village).
func get_spawn(from_map: String) -> Vector2:
	var marker := spawn_from_village.get_parent().get_node_or_null("SpawnFrom%s" % from_map.capitalize()) as Marker2D
	return marker.position if marker != null else spawn_from_village.position


## Tombol E di depan pintu rumah (kotak Areas/HouseDoor) = tidur.
## Phase 18: Kompor Batu pemberian awal sudah dipasang? (disimpan Main di data dunia)
var kitchen_given := false
## Phase 19: Papan Farm (pekerja & traktor) pemberian awal sudah dipasang?
var board_given := false
## Phase 21: kebun buah awal (seperti video) sudah ditanam?
var orchard_given := false

## Phase 21: tile jangkar pohon buah awal: satu baris di jalur rumput antara halaman dan jalan ke kebun.
const ORCHARD_CELLS: Array[Vector2i] = [Vector2i(25, 22), Vector2i(28, 22), Vector2i(31, 22), Vector2i(34, 22)]
const ORCHARD_TREES: Array[String] = ["sapling_apple", "sapling_lemon", "sapling_orange", "sapling_peach", "sapling_banana"]


## Phase 21: tanam pohon buah dewasa di sepanjang halaman (game baru / save lama yang belum punya).
func ensure_starter_orchard() -> void:
	if orchard_given:
		return
	orchard_given = true
	for i in ORCHARD_CELLS.size():
		var item := InventoryManager.get_item(ORCHARD_TREES[i % ORCHARD_TREES.size()])
		if item == null:
			continue
		var base := ORCHARD_CELLS[i]
		for off: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0)]:
			if place_object(item, base + off) == "":
				var tree := object_at(Vector2((base + off) * TILE) + Vector2(8, 8)) as FruitTree
				if tree != null:
					tree.age = FruitTree.GROW_DAYS
					tree.fruit = FruitTree.Fruit.RIPE if tree._in_season() else FruitTree.Fruit.NONE
					tree._refresh()
				break


## Phase 19: pasang Papan Farm di dekat pintu rumah (game baru / save lama yang belum punya).
func ensure_starter_board() -> void:
	if board_given:
		return
	board_given = true
	var item := InventoryManager.get_item("farm_board")
	if item == null:
		return
	var door_cell := Vector2i(((house_door.position + house_door.size / 2.0) / TILE).floor())
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in [r, -r]:
				if place_object(item, door_cell + Vector2i(dx, dy + 1)) == "":
					return


## Phase 18: pasang satu Kompor Batu di dekat pintu rumah (game baru / save lama yang belum punya).
func ensure_starter_kitchen() -> void:
	if kitchen_given:
		return
	kitchen_given = true
	var item := InventoryManager.get_item("kitchen_stove")
	if item == null:
		return
	var door_cell := Vector2i(((house_door.position + house_door.size / 2.0) / TILE).floor())
	# Coba dulu kanan / kiri pintu, lalu cari melebar.
	for r in range(1, 12):
		for dy in range(-r, r + 1):
			for side in [1, -1]:
				var c := door_cell + Vector2i(side * (r + 3), dy + 2)
				if place_object(item, c) == "":
					return


func is_house_door(world_pos: Vector2) -> bool:
	return Rect2(house_door.position, house_door.size).has_point(world_pos)


# ---------------------------------------------------------------- mesin & objek pasang (Phase 14)

## Dihubungkan SETELAH FarmSoil (di _setup_farming), jadi Sprinkler menyiram sesudah tanah dikeringkan pagi hari.
func _setup_placed() -> void:
	TimeManager.day_started.connect(func(_d: int) -> void:
		for obj in placed_objects():
			obj.on_day_started())


## Semua objek terpasang (tanpa duplikat).
func placed_objects() -> Array[PlacedObject]:
	var result: Array[PlacedObject] = []
	for obj: PlacedObject in _placed.values():
		if not result.has(obj):
			result.append(obj)
	return result


## Objek terpasang di titik dunia ini (titik interaksi player), atau null.
func object_at(world_pos: Vector2) -> PlacedObject:
	return _placed.get(Vector2i((world_pos / TILE).floor())) as PlacedObject


## Alasan tile-tile ini tidak bisa dipakai, atau "" jika boleh.
func can_place(target_cells: Array[Vector2i]) -> String:
	var fences := objects.get_node_or_null("Fences") as TileMapLayer
	var player_cell := Vector2i((player.global_position / TILE).floor())
	var door := Rect2(house_door.position, house_door.size).grow(8.0)
	for cell in target_cells:
		if not _in_bounds(cell):
			return "Tidak bisa dipasang di luar peta."
		var terrain := get_terrain(cell)
		if terrain != TerrainTiles.Terrain.GRASS and terrain != TerrainTiles.Terrain.PATH:
			return "Hanya bisa dipasang di rumput atau tanah jalan (bukan di tanah olahan / air)."
		if cell == player_cell:
			return "Mundur sedikit, kamu berdiri di situ."
		if is_cell_blocked(cell) or (fences != null and fences.get_cell_source_id(cell) != -1):
			return "Ada benda yang menghalangi."
		if door.intersects(Rect2(Vector2(cell * TILE), Vector2(TILE, TILE))):
			return "Jangan menghalangi pintu rumah."
	return ""


## Memasang item (kategori MACHINE) dengan tile jangkar `cell`. Kembalikan "" jika berhasil, selain itu alasan.
func place_object(item: ItemData, cell: Vector2i) -> String:
	if item == null or not item.is_placeable():
		return "Item ini tidak bisa dipasang."
	var probe := item.placeable.instantiate() as PlacedObject
	probe.anchor = cell
	var reason := can_place(probe.cells())
	probe.free()
	if reason != "":
		return reason
	_spawn_placed(item, cell)
	return ""


func _spawn_placed(item: ItemData, cell: Vector2i) -> PlacedObject:
	var obj := item.placeable.instantiate() as PlacedObject
	obj.anchor = cell
	obj.item_id = item.id
	obj.farm = self
	obj.position = obj.position_for(cell)
	objects.add_child(obj)
	for c in obj.cells():
		_placed[c] = obj
		if decor != null:
			decor.erase_cell(c)
	return obj


## Mengambil objek dari peta (dipanggil Main saat dipukul Pickaxe / Axe).
func remove_object(obj: PlacedObject) -> void:
	for c in obj.cells():
		if _placed.get(c) == obj:
			_placed.erase(c)
	obj.queue_free()


func placed_to_save() -> Array:
	var list: Array = []
	for obj in placed_objects():
		list.append({"id": obj.item_id, "x": obj.anchor.x, "y": obj.anchor.y, "state": obj.state_to_save()})
	return list


func placed_from_save(list: Array) -> void:
	for obj in placed_objects():
		remove_object(obj)
	for entry: Dictionary in list:
		var item := InventoryManager.get_item(String(entry.get("id", "")))
		if item == null or not item.is_placeable():
			continue
		var cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
		var obj := _spawn_placed(item, cell)
		obj.state_from_save(entry.get("state", {}))


# ---------------------------------------------------------------- Phase 21: rumput bergoyang

func _process(_delta: float) -> void:
	if grass_detail != null and player != null:
		var pet_pos := dog.global_position if dog != null and dog.visible else Vector2(-9999, -9999)
		grass_detail.update_pushers(player.global_position, pet_pos)
