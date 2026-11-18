class_name CropPlant
extends Node2D
## Satu tanaman di satu tile. Sprite diambil dari sheet pertumbuhan asli (lihat CropData).
## Phase 3 akan memanggil set_stage() saat tanaman tumbuh.
## Phase 17: tanaman siap panen berkilau (Modern_Farm_vfx_Rare_Crop_Glitter_16x16.png) sebagai penanda.
## Phase 22: PANEN LANGKA. Saat tanaman mencapai tahap siap panen, ada peluang RARE_CHANCE menjadi langka.
## Hanya tanaman langka yang berkilau; hasilnya item "<id>_rare" (gambar Pickup_Crop_*_Rare asli, harga 3x).

var data: CropData
var cell: Vector2i
var stage: int = 0
## Jumlah hari tanaman ini disiram sejak ditanam.
var days_grown: int = 0

var _sprite: Sprite2D
var _glitter: AnimatedSprite2D
## Phase 22: tanaman langka? (diputuskan sekali saat pertama kali siap panen, ikut disimpan)
var rare := false
var _rare_rolled := false
const RARE_CHANCE := 0.1


func setup(p_data: CropData, p_cell: Vector2i, tile_size: int) -> void:
	data = p_data
	cell = p_cell
	# Titik pijakan = tengah-bawah tile (naik 2 px agar akar menempel di tanah).
	position = Vector2(p_cell.x * tile_size + tile_size / 2.0, p_cell.y * tile_size + tile_size - 2.0)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.position = Vector2(-CropData.FRAME_W / 2.0, -data.sprite_height())
	add_child(_sprite)
	set_stage(0)


## Dipakai saat memuat simpanan: status langka tidak diundi ulang.
func set_rare_state(value: bool) -> void:
	rare = value
	_rare_rolled = true
	_update_glitter()


func set_stage(new_stage: int) -> void:
	stage = clampi(new_stage, 0, CropData.STAGE_COUNT - 1)
	_sprite.texture = data.get_stage_texture(stage)
	_update_glitter()


## Item hasil panen: versi langka jika rare dan item-nya ada.
func harvest_item() -> ItemData:
	if rare:
		var r := InventoryManager.get_item(data.id + "_rare")
		if r != null:
			return r
	return InventoryManager.get_item(data.id)


func _update_glitter() -> void:
	if is_harvestable() and not _rare_rolled:
		_rare_rolled = true
		rare = randf() < RARE_CHANCE and InventoryManager.get_item(data.id + "_rare") != null
	if is_harvestable() and rare and _glitter == null:
		_glitter = Vfx.glitter()
		_glitter.position = Vector2(0, -data.sprite_height() * 0.5)
		add_child(_glitter)
		_glitter.play(&"fx")
		# mulai di frame acak agar tanaman tidak berkilau bersamaan
		_glitter.frame = randi() % _glitter.sprite_frames.get_frame_count(&"fx")
	elif (not is_harvestable() or not rare) and _glitter != null:
		_glitter.queue_free()
		_glitter = null


func is_harvestable() -> bool:
	return stage >= CropData.STAGE_HARVEST


## Dipanggil FarmSoil saat hari berganti dan tanah disiram. True jika tahap visual berubah.
func grow_one_day() -> bool:
	if is_harvestable():
		return false
	days_grown += 1
	var new_stage := data.stage_for_days(days_grown)
	var changed := new_stage != stage
	set_stage(new_stage)
	return changed
