class_name GrassDetail
extends TileMapLayer
## Phase 21: lapisan DETAIL RUMPUT seperti video referensi Modern Farm.
## Atlas: assets/modern_farm/tilesets/grass_detail_16x16.png (dibuat tools/make_grass_detail.py dari
## palet rumput asli pack). Baris atlas: 0 jarang, 1 sedang, 2 lebat gelap, 3 terang, 4 bunga, 5 rumpun tinggi.
## Penempatan otomatis per tile rumput memakai FastNoiseLite (seed tetap, jadi peta selalu sama):
##   noise tinggi -> petak rumput gelap & lebat, noise rendah -> petak terang, di antaranya jarang / sedang,
##   ditambah bunga kecil dan rumpun tinggi secara acak.
## Tile dihapus otomatis saat tanah dicangkul (FarmMap.set_terrain).
## Phase 22: dipakai juga di Desa (VillageMap) dan Hutan (WildMap).
## Shader grass_wind.gdshader: rumput bergoyang angin dan menyibak saat player / anjing lewat.
## Posisi node di scene: tepat di atas layer Ground (di bawah SoilWet / SoilEdge / Decor).

const ATLAS := preload("res://assets/modern_farm/tilesets/grass_detail_16x16.png")
const WIND_SHADER := preload("res://assets/shaders/grass_wind.gdshader")
const VARIANTS := 8
enum Row { SPARSE, MEDIUM, DENSE, LIGHT, FLOWER, TALL, PATH }

## Seed noise. Ganti untuk pola rumput lain.
@export var noise_seed := 21
## Kepadatan rumput 0..1 (semakin besar semakin rimbun).
@export_range(0.0, 1.0) var density := 0.8

var shared_material: ShaderMaterial
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()
var _source_id := 0
## Peta pemilik: FarmMap / VillageMap / WildMap (harus punya map_w, map_h, get_terrain(cell)).
var _map: Node2D


func setup(map: Node2D) -> void:
	_map = map
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_tileset()
	shared_material = ShaderMaterial.new()
	shared_material.shader = WIND_SHADER
	material = shared_material
	_noise.seed = noise_seed
	_noise.frequency = 0.085
	_noise.fractal_octaves = 3
	_noise2.seed = noise_seed + 7
	_noise2.frequency = 0.21
	fill()


func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = ATLAS
	src.texture_region_size = Vector2i(16, 16)
	for y in Row.size():
		for x in VARIANTS:
			src.create_tile(Vector2i(x, y))
	_source_id = ts.add_source(src)
	tile_set = ts


## Isi ulang seluruh peta.
func fill() -> void:
	clear()
	for y in _map.map_h:
		for x in _map.map_w:
			paint(Vector2i(x, y))


## Pilih tile detail untuk satu sel rumput (atau kosongkan).
func paint(cell: Vector2i) -> void:
	var terrain: int = _map.get_terrain(cell)
	if terrain == TerrainTiles.Terrain.PATH:
		var hp := _hash(cell)
		if hp % 100 < 22:
			set_cell(cell, _source_id, Vector2i(hp % VARIANTS, Row.PATH))
		else:
			erase_cell(cell)
		return
	if terrain != TerrainTiles.Terrain.GRASS:
		erase_cell(cell)
		return
	var n := _noise.get_noise_2d(cell.x, cell.y)        # -1..1 petak besar
	var m := _noise2.get_noise_2d(cell.x, cell.y)       # variasi kecil
	var h := _hash(cell)
	var row := -1
	if n > 0.30:
		row = Row.DENSE
	elif n > 0.12:
		row = Row.MEDIUM
	elif n < -0.36:
		row = Row.LIGHT
	elif n < -0.22:
		row = Row.MEDIUM if h % 3 == 0 else Row.LIGHT
	else:
		var r := float(h % 1000) / 1000.0
		if r < 0.42 * density:
			row = Row.SPARSE
		elif r < 0.50 * density:
			row = Row.MEDIUM
	# bunga & rumpun tinggi di sela-sela
	if row != Row.DENSE and m > 0.45 and h % 4 == 0:
		row = Row.FLOWER
	elif h % 29 == 0:
		row = Row.TALL
	if row < 0:
		erase_cell(cell)
		return
	set_cell(cell, _source_id, Vector2i(h % VARIANTS, row))


func _hash(cell: Vector2i) -> int:
	var v := cell.x * 73856093 ^ cell.y * 19349663 ^ noise_seed * 83492791
	return absi(v) % 100000


## Dipanggil FarmMap setiap frame: posisi player & anjing untuk efek menyibak.
func update_pushers(player_pos: Vector2, pet_pos: Vector2) -> void:
	if shared_material != null:
		shared_material.set_shader_parameter("player_pos", player_pos)
		shared_material.set_shader_parameter("pet_pos", pet_pos)
