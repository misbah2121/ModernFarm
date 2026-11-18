class_name FarmSoil
extends Node
## Logika lahan pertanian: cangkul -> tanah olahan -> siram -> tanam.
## Visual tanah memakai autotile asli (kering/basah) di layer Ground milik FarmMap,
## tanaman adalah node CropPlant di layer Objects (y-sort).

signal message(text: String)
## Dipancarkan saat tanaman dipanen (hasilnya masuk ke InventoryManager).
signal crop_harvested(crop: CropData)

## Area lahan pertanian diambil dari kotak Areas/FarmPlot, FarmPlot2, ... di farm.tscn (FarmMap.is_farm_plot()).

class SoilCell:
	var watered: bool = false
	var crop: CropPlant = null

var _farm: FarmMap
var _cells: Dictionary = {}  # Vector2i -> SoilCell
var harvested_counts: Dictionary = {}  # crop id -> total panen seumur game (statistik, untuk quest nanti)


func setup(farm: FarmMap) -> void:
	_farm = farm
	TimeManager.day_started.connect(_on_day_started)


## Dipanggil lewat signal Player.tool_used.
func use_tool(tool: ToolData, cell: Vector2i) -> void:
	match tool.kind:
		ToolData.Kind.HOE:
			_till(cell)
		ToolData.Kind.WATERING_CAN:
			_water(cell)
		ToolData.Kind.SEEDS:
			# Benih berkurang 1 hanya jika penanaman benar-benar berhasil.
			if _plant(cell, tool.crop):
				InventoryManager.consume_selected(1)


func is_tilled(cell: Vector2i) -> bool:
	return _cells.has(cell)


func get_crop(cell: Vector2i) -> CropPlant:
	return _cells[cell].crop if _cells.has(cell) else null


func is_harvestable(cell: Vector2i) -> bool:
	var crop := get_crop(cell)
	return crop != null and crop.is_harvestable()


## Dipakai Player sebelum animasi panen: tanaman siap DAN tas masih muat hasilnya.
func can_harvest(cell: Vector2i) -> bool:
	if not is_harvestable(cell):
		return false
	var item := InventoryManager.get_item(get_crop(cell).data.id)
	if item != null and not InventoryManager.can_add(item, 1):
		message.emit("Tas penuh! Kosongkan satu slot dulu.")
		return false
	return true


## Menyiram semua tanah olahan (dipakai Phase 4 saat hujan).
func water_all() -> void:
	for cell: Vector2i in _cells:
		_set_watered(cell, true)


## Phase 14: disiram Sprinkler. true jika tile ini tanah olahan (lalu menjadi basah).
func water_cell(cell: Vector2i) -> bool:
	if not _cells.has(cell) or (_cells[cell] as SoilCell).watered:
		return false
	_set_watered(cell, true)
	return true


## Tanah kembali kering.
func reset_watering() -> void:
	for cell: Vector2i in _cells:
		_set_watered(cell, false)


## Tanaman yang siap panen di tile ini dipanen; tanah tetap berupa tanah olahan.
func harvest(cell: Vector2i) -> void:
	if not is_harvestable(cell):
		return
	var soil: SoilCell = _cells[cell]
	var crop := soil.crop
	var data := crop.data
	soil.crop = null
	# Phase 17: efek panen - daun berhamburan.
	# Phase 18: hasil panen melompat keluar sebagai barang jatuh (asset Pickup) lalu terbang ke player.
	var item := crop.harvest_item()  # Phase 22: versi langka jika tanaman berkilau
	Vfx.burst(_farm.objects, crop.position + Vector2(0, -6), Vfx.Kind.CROP)
	if crop.rare:
		Vfx.burst(_farm.objects, crop.position + Vector2(0, -10), Vfx.Kind.SPLASH)  # kilau ekstra
	crop.queue_free()
	harvested_counts[data.id] = int(harvested_counts.get(data.id, 0)) + 1
	if item != null:
		for p in ItemPickup.drop(_farm.objects, crop.position, item, 1, 6.0):
			p.quest_gather = false
	crop_harvested.emit(data)
	if crop.rare and item != null:
		AudioManager.play_sfx("fish_catch")
		message.emit("WAH! Panen %s! (harga 3x)" % item.item_name)
	else:
		message.emit("Panen %s!" % data.crop_name)


## Pagi hari: (1) tanaman di luar musimnya layu, (2) tanaman yang disiram kemarin tumbuh 1 hari,
## (3) tanah kering lagi, (4) jika hujan hari ini, semua tanah otomatis basah.
func _on_day_started(_total_day: int) -> void:
	var withered := 0
	var grown := 0
	var ripe := 0
	for cell: Vector2i in _cells:
		var soil: SoilCell = _cells[cell]
		if soil.crop == null:
			continue
		if soil.crop.data.season != TimeManager.season_name():
			soil.crop.queue_free()
			soil.crop = null
			withered += 1
			continue
		if not soil.watered or soil.crop.is_harvestable():
			continue
		soil.crop.grow_one_day()
		grown += 1
		if soil.crop.is_harvestable():
			ripe += 1
	reset_watering()
	if TimeManager.is_raining():
		water_all()
	if withered > 0:
		message.emit("%d tanaman layu karena pergantian musim." % withered)
	elif ripe > 0:
		message.emit("%d tanaman siap panen!" % ripe)
	elif grown > 0:
		message.emit("%d tanaman tumbuh." % grown)


func _set_watered(cell: Vector2i, watered: bool) -> void:
	var soil: SoilCell = _cells[cell]
	if soil.watered == watered:
		return
	soil.watered = watered
	_farm.set_terrain(cell, TerrainTiles.Terrain.SOIL_WET if watered else TerrainTiles.Terrain.SOIL_DRY)


func _till(cell: Vector2i) -> void:
	if _cells.has(cell):
		message.emit("Tanah ini sudah dicangkul.")
		return
	if not _farm.is_farm_plot(cell):
		message.emit("Cangkul hanya bisa dipakai di lahan pertanian.")
		return
	if _farm.get_terrain(cell) != TerrainTiles.Terrain.GRASS:
		message.emit("Hanya rumput yang bisa dicangkul.")
		return
	if _farm.is_cell_blocked(cell):
		message.emit("Ada benda yang menghalangi.")
		return
	_cells[cell] = SoilCell.new()
	_farm.set_terrain(cell, TerrainTiles.Terrain.SOIL_DRY)


## Phase 19 (pekerja): tile olahan yang masih kering; yang ada tanamannya di depan.
func dry_cells() -> Array[Vector2i]:
	var with_crop: Array[Vector2i] = []
	var empty: Array[Vector2i] = []
	for cell: Vector2i in _cells:
		var soil: SoilCell = _cells[cell]
		if soil.watered:
			continue
		if soil.crop != null and not soil.crop.is_harvestable():
			with_crop.append(cell)
		else:
			empty.append(cell)
	return with_crop + empty


## Phase 21: tile bertanaman (belum siap panen) yang belum disiram hari ini - untuk penanda tetes air.
func thirsty_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in _cells:
		var soil: SoilCell = _cells[cell]
		if soil.crop != null and not soil.watered and not soil.crop.is_harvestable():
			result.append(cell)
	return result


## Phase 19 (pekerja): tile dengan tanaman siap panen.
func ripe_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in _cells:
		if is_harvestable(cell):
			result.append(cell)
	return result


## Phase 19 (pekerja): panen tanpa barang jatuh; hasilnya dikembalikan untuk disimpan pekerja.
func take_harvest(cell: Vector2i) -> ItemData:
	if not is_harvestable(cell):
		return null
	var soil: SoilCell = _cells[cell]
	var data := soil.crop.data
	var item := soil.crop.harvest_item()
	Vfx.burst(_farm.objects, soil.crop.position + Vector2(0, -6), Vfx.Kind.CROP)
	soil.crop.queue_free()
	soil.crop = null
	harvested_counts[data.id] = int(harvested_counts.get(data.id, 0)) + 1
	crop_harvested.emit(data)
	return item


## Phase 19: cangkul tanpa pesan (dipakai traktor). true jika tile berubah jadi tanah olahan.
func till_quiet(cell: Vector2i) -> bool:
	if _cells.has(cell) or not _farm.is_farm_plot(cell):
		return false
	if _farm.get_terrain(cell) != TerrainTiles.Terrain.GRASS or _farm.is_cell_blocked(cell):
		return false
	_cells[cell] = SoilCell.new()
	_farm.set_terrain(cell, TerrainTiles.Terrain.SOIL_DRY)
	return true


func _water(cell: Vector2i) -> void:
	if not _cells.has(cell):
		message.emit("Cangkul tanahnya dulu sebelum disiram.")
		return
	var soil: SoilCell = _cells[cell]
	if soil.watered:
		message.emit("Tanah ini sudah basah.")
		return
	_set_watered(cell, true)


## True jika benih berhasil ditanam.
func _plant(cell: Vector2i, crop: CropData) -> bool:
	if crop == null:
		return false
	if not _cells.has(cell):
		message.emit("Benih harus ditanam di tanah yang sudah dicangkul.")
		return false
	var soil: SoilCell = _cells[cell]
	if soil.crop != null:
		message.emit("Sudah ada tanaman di sini.")
		return false
	if crop.season != TimeManager.season_name():
		if TimeManager.season() == TimeManager.Season.WINTER:
			message.emit("Tidak ada yang bisa ditanam di musim dingin.")
		else:
			message.emit("%s hanya bisa ditanam di musim %s." % [crop.crop_name, crop.season])
		return false
	var plant := CropPlant.new()
	_farm.objects.add_child(plant)
	plant.setup(crop, cell, TerrainTiles.TILE)
	soil.crop = plant
	message.emit("Menanam %s." % crop.crop_name)
	return true


# ---------------------------------------------------------------- simpan (Phase 12)

func to_save() -> Dictionary:
	var list: Array = []
	for cell: Vector2i in _cells:
		var soil: SoilCell = _cells[cell]
		var entry := {"x": cell.x, "y": cell.y, "watered": soil.watered}
		if soil.crop != null:
			entry["crop"] = soil.crop.data.id
			entry["days"] = soil.crop.days_grown
			entry["stage"] = soil.crop.stage
			entry["rare"] = soil.crop.rare
		list.append(entry)
	return {"cells": list, "harvested": harvested_counts}


func from_save(d: Dictionary) -> void:
	for v: Dictionary in d.get("cells", []):
		var cell := Vector2i(int(v.get("x", 0)), int(v.get("y", 0)))
		if not _farm.is_farm_plot(cell):
			continue  # save lama: tanah di luar lahan yang sekarang (peta farm sudah diubah) dilewati
		var soil := SoilCell.new()
		soil.watered = bool(v.get("watered", false))
		_cells[cell] = soil
		_farm.set_terrain(cell, TerrainTiles.Terrain.SOIL_WET if soil.watered else TerrainTiles.Terrain.SOIL_DRY)
		var crop_id := String(v.get("crop", ""))
		if crop_id == "":
			continue
		var crop := load("res://data/crops/%s.tres" % crop_id) as CropData
		if crop == null:
			continue
		var plant := CropPlant.new()
		_farm.objects.add_child(plant)
		plant.setup(crop, cell, TerrainTiles.TILE)
		plant.days_grown = int(v.get("days", 0))
		plant.set_stage(int(v.get("stage", 0)))
		if v.has("rare"):
			plant.set_rare_state(bool(v.get("rare", false)))
		soil.crop = plant
	harvested_counts = d.get("harvested", {})
