class_name TerrainTiles
extends RefCounted
## TileSet 16x16 dari asset Modern_Farm_v1.2 + tabel autotile.
## TileSet sudah disimpan sebagai res://assets/modern_farm/tilesets/modern_farm_terrain.tres dan
## dipakai Ground (TileMapLayer) di farm.tscn & village.tscn. build_tileset() adalah "resep" yang
## dipakai untuk membuat file itu (tidak dipanggil saat game berjalan).
## TileSet punya Terrain Set 0 (Match Corners and Sides) dengan terrain:
##   0 Grass, 1 Path, 2 Water, 3 Sand, 4 Soil Dry, 5 Soil Wet  (sama dengan enum Terrain)
## jadi peta bisa digambar di editor: panel TileMap > tab Terrains > pilih terrain > gambar.
## Script peta membaca nomor terrain tiap tile (TileData.terrain) untuk logika game.
##
## Autotile memakai file "Autotiles_Godot_16x16.png": tiap terrain = blok 12x4 tile (47 tile blob).
## Tabel BLOB di bawah dihasilkan dengan menganalisis piksel gambar asli tersebut
## (mask 8 tetangga -> koordinat tile di dalam blok).

const TILE := 16
const TILESET_PATH := "res://assets/modern_farm/tilesets/modern_farm_terrain.tres"
const TERRAIN_NAMES: Array[String] = ["Grass", "Path", "Water", "Sand", "Soil Dry", "Soil Wet"]
const TERRAIN_COLORS: Array[Color] = [
	Color(0.35, 0.75, 0.3), Color(0.8, 0.6, 0.35), Color(0.25, 0.55, 0.9),
	Color(0.95, 0.85, 0.5), Color(0.55, 0.35, 0.2), Color(0.35, 0.2, 0.1),
]
const SRC_TERRAINS := 0
const SRC_AUTOTILE := 1

const TERRAINS_TEX := "res://assets/modern_farm/16x16/terrains/1_Terrains_16x16.png"
const AUTOTILE_TEX := "res://assets/modern_farm/16x16/autotiles/Autotiles_Godot_16x16.png"
const GRASS_COORD := Vector2i(3, 2)  # tile rumput polos di 1_Terrains_16x16.png
## ---- Tanah kebun (hasil cangkul) ----
## Sama seperti petak tanah di asset asli (1_Terrains_16x16.png kolom 8-10, baris 16-18 =
## tanah cokelat muda; baris 12-14 = versi cokelat kemerahan):
##   * tile yang dicangkul = tile tanah penuh (SOIL_COORD) di layer Ground,
##   * rumbai rumput/tanah yang menjorok ke tile rumput di sekitarnya = layer SoilEdge
##     (Soil_Edges_16x16.png, dibuat oleh tools/make_soil_edges.py dari piksel asli),
##   * tanah basah = tile asli Soil_Wet_1..4_16x16.png (variasi bercak gelap) di layer SoilWet.
const SOIL_COORD := Vector2i(9, 17)  # tile tanah cokelat muda penuh (ganti ke (1, 13) untuk versi kemerahan)
const SOIL_EDGE_TEX := "res://assets/modern_farm/16x16/autotiles/Soil_Edges_16x16.png"
const SOIL_EDGE_TILESET_PATH := "res://assets/modern_farm/tilesets/modern_farm_soil_edge.tres"
const SOIL_WET_TILESET_PATH := "res://assets/modern_farm/tilesets/modern_farm_soil_wet.tres"
## Tanah basah asli dari asset (Props_and_Buildings/Soil_Wet_1..4). Source id = nomor file.
const SOIL_WET_TEX := "res://assets/modern_farm/16x16/soil/Soil_Wet_%d_16x16.png"
const SOIL_WET_VARIANTS := 4

enum Terrain { GRASS, PATH, WATER, SAND, SOIL_DRY, SOIL_WET }

## Baris pertama blok terrain di Autotiles_Godot (tiap blok setinggi 4 tile).
const BLOCK_FIRST_ROW := {
	Terrain.PATH: 0,    # tanah/jalan cokelat muda di atas rumput
	Terrain.WATER: 8,   # air di atas rumput
	Terrain.SAND: 16,   # pasir di atas rumput
}

## Urutan bit: N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

## mask kanonik -> koordinat (kolom, baris) di dalam blok 12x4
const BLOB := {
	0: Vector2i(0, 3),
	1: Vector2i(0, 2),
	4: Vector2i(1, 3),
	5: Vector2i(1, 2),
	7: Vector2i(8, 3),
	16: Vector2i(0, 0),
	17: Vector2i(0, 1),
	20: Vector2i(1, 0),
	21: Vector2i(1, 1),
	23: Vector2i(4, 2),
	28: Vector2i(8, 0),
	29: Vector2i(4, 1),
	31: Vector2i(8, 1),
	64: Vector2i(3, 3),
	65: Vector2i(3, 2),
	68: Vector2i(2, 3),
	69: Vector2i(2, 2),
	71: Vector2i(5, 3),
	80: Vector2i(3, 0),
	81: Vector2i(3, 1),
	84: Vector2i(2, 0),
	85: Vector2i(2, 1),
	87: Vector2i(7, 0),
	92: Vector2i(5, 0),
	93: Vector2i(7, 3),
	95: Vector2i(8, 2),
	112: Vector2i(11, 0),
	113: Vector2i(7, 1),
	116: Vector2i(6, 0),
	117: Vector2i(4, 3),
	119: Vector2i(9, 1),
	124: Vector2i(10, 0),
	125: Vector2i(9, 0),
	127: Vector2i(5, 1),
	193: Vector2i(11, 3),
	197: Vector2i(6, 3),
	199: Vector2i(9, 3),
	209: Vector2i(7, 2),
	213: Vector2i(4, 0),
	215: Vector2i(10, 3),
	221: Vector2i(10, 2),
	223: Vector2i(5, 2),
	241: Vector2i(11, 2),
	245: Vector2i(11, 1),
	247: Vector2i(6, 2),
	253: Vector2i(6, 1),
	255: Vector2i(9, 2),
}

## Peering bit Godot untuk tiap arah NEIGHBORS (urutan sama).
const PEERING_BITS: Array[int] = [
	TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
]

## Mask yang titik tengah tile-nya berisi terrain (dipakai untuk collision air).
const BLOB_CENTER_FILLED: Array[int] = [0, 17, 21, 23, 29, 31, 68, 69, 71, 81, 84, 85, 87, 92, 93, 95, 113, 116, 117, 119, 124, 125, 127, 197, 199, 209, 213, 215, 221, 223, 241, 245, 247, 253, 255]


## Tanah kering dan basah dianggap satu keluarga agar tepinya menyambung.
static func same_family(a: int, b: int) -> bool:
	if a == b:
		return true
	return (a == Terrain.SOIL_DRY or a == Terrain.SOIL_WET) and (b == Terrain.SOIL_DRY or b == Terrain.SOIL_WET)


static func canonical_mask(mask: int) -> int:
	# Sudut hanya dihitung jika kedua sisi di sebelahnya juga terisi.
	if not ((mask & 1) and (mask & 4)):
		mask &= ~2
	if not ((mask & 4) and (mask & 16)):
		mask &= ~8
	if not ((mask & 16) and (mask & 64)):
		mask &= ~32
	if not ((mask & 64) and (mask & 1)):
		mask &= ~128
	return mask


## Tile untuk satu terrain. Hasil: {"source", "coords", "alt"}.
## Tanah olahan (kering/basah) selalu tile tanah penuh; tepinya dibuat oleh layer SoilEdge.
static func tile_for(terrain: int, raw_mask: int) -> Dictionary:
	if terrain == Terrain.GRASS:
		return {"source": SRC_TERRAINS, "coords": GRASS_COORD, "alt": 0}
	if terrain == Terrain.SOIL_DRY or terrain == Terrain.SOIL_WET:
		return {"source": SRC_TERRAINS, "coords": SOIL_COORD, "alt": 0}
	var base: Vector2i = BLOB[canonical_mask(raw_mask)]
	var row_offset: int = BLOCK_FIRST_ROW[terrain]
	return {"source": SRC_AUTOTILE, "coords": Vector2i(base.x, base.y + row_offset), "alt": 0}


## Koordinat tile rumbai di modern_farm_soil_edge.tres untuk tile rumput yang punya tanah olahan
## di arah `mask` (bit sama dengan NEIGHBORS). mask 0 = tidak ada rumbai.
static func soil_edge_coords(mask: int) -> Vector2i:
	return Vector2i(mask % 16, mask / 16)


## "Resep" TileSet layer SoilEdge (255 kombinasi rumbai).
static func build_soil_edge_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = load(SOIL_EDGE_TEX)
	src.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(src, 0)
	for mask in range(1, 256):
		src.create_tile(soil_edge_coords(mask))
	return tile_set


## Variasi tanah basah untuk satu tile. Selalu sama untuk tile yang sama, jadi polanya tidak
## berubah-ubah saat disiram ulang atau setelah load. Soil_Wet_1 paling sering (warnanya paling
## mirip kebun di gambar promo), _4 sesekali, _3 (bercak lebih gelap) jarang. Soil_Wet_2 hampir
## sama terangnya dengan tanah kering, jadi tidak dipakai agar beda basah/kering tetap terlihat.
static func soil_wet_source(cell: Vector2i) -> int:
	var h := posmod((cell.x * 73856093) ^ (cell.y * 19349663), 10)
	if h < 6:
		return 1
	if h < 9:
		return 4
	return 3


## "Resep" TileSet layer SoilWet: 4 source (1..4), masing-masing satu tile Soil_Wet_N.
static func build_soil_wet_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	for n in range(1, SOIL_WET_VARIANTS + 1):
		var src := TileSetAtlasSource.new()
		src.texture = load(SOIL_WET_TEX % n)
		src.texture_region_size = Vector2i(TILE, TILE)
		tile_set.add_source(src, n)
		src.create_tile(Vector2i.ZERO)
	return tile_set


static func build_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)

	# Physics layer 0: dipakai untuk menabrak air.
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)

	# Terrain Set 0 untuk menggambar autotile di editor.
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	for i in TERRAIN_NAMES.size():
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, i, TERRAIN_NAMES[i])
		tile_set.set_terrain_color(0, i, TERRAIN_COLORS[i])

	var terrains_src := TileSetAtlasSource.new()
	terrains_src.texture = load(TERRAINS_TEX)
	terrains_src.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(terrains_src, SRC_TERRAINS)
	terrains_src.create_tile(GRASS_COORD)
	_set_terrain_bits(terrains_src.get_tile_data(GRASS_COORD, 0), Terrain.GRASS, 255)
	terrains_src.create_tile(SOIL_COORD)
	_set_terrain_bits(terrains_src.get_tile_data(SOIL_COORD, 0), Terrain.SOIL_DRY, 255)

	var auto_src := TileSetAtlasSource.new()
	auto_src.texture = load(AUTOTILE_TEX)
	auto_src.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(auto_src, SRC_AUTOTILE)

	var half := TILE / 2.0 - 1.0
	var solid := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	])
	for terrain: int in BLOCK_FIRST_ROW:
		var row_offset: int = BLOCK_FIRST_ROW[terrain]
		for mask: int in BLOB:
			var base: Vector2i = BLOB[mask]
			var coords := Vector2i(base.x, base.y + row_offset)
			auto_src.create_tile(coords)
			var tile_data := auto_src.get_tile_data(coords, 0)
			_set_terrain_bits(tile_data, terrain, mask)
			if terrain == Terrain.WATER and mask in BLOB_CENTER_FILLED:
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, solid)
	return tile_set


## Tile milik `terrain`; arah yang bit-nya ada di `mask` bertetangga dengan terrain yang sama,
## arah lainnya bertetangga dengan rumput.
static func _set_terrain_bits(tile_data: TileData, terrain: int, mask: int) -> void:
	tile_data.terrain_set = 0
	tile_data.terrain = terrain
	for i in PEERING_BITS.size():
		var neighbor: int = terrain if mask & (1 << i) else Terrain.GRASS
		tile_data.set_terrain_peering_bit(PEERING_BITS[i] as TileSet.CellNeighbor, neighbor)
