class_name AnimalData
extends Resource
## Data satu jenis hewan ternak (Resource). File .tres ada di res://data/animals/ dan dimuat otomatis
## oleh AnimalManager. Sheet hewan Modern_Farm: 24 kolom = 4 arah x 6 frame
## (kanan, atas, kiri, bawah), baris 0 = pratinjau (tidak dipakai), baris 1-3 = animasi.

@export var id: String = ""
@export var animal_name: String = ""
## "coop" (kandang ayam) atau "barn" (kandang besar). Menentukan kapasitas.
@export var building: String = "coop"
## Harga beli di Peternakan Barnaby.
@export var price: int = 400
@export_multiline var description: String = ""
## Icon kecil 16x16 (potongan sheet) untuk daftar toko.
@export var icon: Texture2D

@export_group("Sprite")
@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(16, 16)
## Piksel kosong di bawah kaki (tampak samping), agar kaki tepat di titik node.
## Phase 23: -1 = dihitung otomatis dari sheet (piksel terbawah frame diam).
@export var foot_offset: int = 1
@export var row_idle: int = 1
@export var row_walk: int = 2
## Baris animasi makan (kepala menunduk). -1 = tidak ada.
@export var row_eat: int = -1
@export var walk_speed: float = 18.0
## Ukuran collision badan (piksel).
@export var body_size: Vector2 = Vector2(10, 6)

@export_group("Produk")
## Hasil ternak (null = tidak menghasilkan apa-apa).
@export var product: ItemData
## Produk muncul setiap N hari selama hewan diberi makan.
@export var produce_days: int = 1
## id item yang harus dipegang untuk mengambil produk ("" = cukup tekan E). Contoh: "shears".
@export var tool_required: String = ""
## Phase 18: barang yang kadang DITEMUKAN hewan di tanah kandang (babi -> Truffle). null = tidak ada.
@export var forage_item: ItemData
## Peluang menemukan forage_item setiap pagi (hanya jika kemarin makan). 0.0 - 1.0.
@export_range(0.0, 1.0) var forage_chance: float = 0.0
## Nama acak untuk hewan yang baru dibeli.
@export var names: PackedStringArray = PackedStringArray()

@export_group("Bonus (Phase 23)")
## Produk bonus yang kadang menggantikan produk biasa (ayam -> Telur Emas).
@export var bonus_product: ItemData
@export_range(0.0, 1.0) var bonus_chance: float = 0.0
## id hewan yang harus ada (dewasa & kenyang) agar bonus bisa muncul. "" = tidak perlu. Contoh: "rooster".
@export var bonus_needs: String = ""
## Keledai: setiap pagi (jika kemarin makan) menambah N Animal Feed ke tempat pakan.
@export var feeder_bonus: int = 0
## Ayam jago: setiap pagi menambah friendship hewan Coop lain sebanyak N.
@export var friend_aura: int = 0

@export_group("Varian warna (Phase 23)")
## Semua sheet warna (indeks 0 = sheet bawaan, dipakai save lama). Kosong = hanya `sheet`.
## Layout harus sama dengan `sheet`. Warna dipilih acak saat dibeli.
@export var variant_sheets: Array[Texture2D] = []
## Nama warna, sejajar dengan variant_sheets (contoh "Coklat").
@export var variant_names: PackedStringArray = PackedStringArray()

@export_group("Anak (Phase 23)")
## Sheet anak hewan. Kosong = jenis ini tidak bisa beranak.
@export var baby_sheets: Array[Texture2D] = []
@export var baby_frame_size: Vector2i = Vector2i(32, 32)
## Sheet anak untuk tiap varian (indeks ke baby_sheets, sejajar variant_sheets). Kosong = varian % jumlah.
@export var baby_variant: PackedInt32Array = PackedInt32Array()
@export var baby_row_idle: int = 1
@export var baby_row_walk: int = 2
@export var baby_row_eat: int = 3
## Hari sampai anak menjadi dewasa.
@export var grow_days: int = 5
## Pasangan yang dibutuhkan untuk beranak. "" = dua hewan sejenis. Ayam: "rooster".
@export var breed_partner: String = ""
## Saat dewasa, anak kadang menjadi jenis lain (anak ayam -> ayam jago).
@export var grow_alt_type: String = ""
@export_range(0.0, 1.0) var grow_alt_chance: float = 0.0


func can_breed() -> bool:
	return not baby_sheets.is_empty()


func variant_count() -> int:
	return maxi(variant_sheets.size(), 1)


func variant_name(variant: int) -> String:
	if variant >= 0 and variant < variant_names.size():
		return variant_names[variant]
	return ""


func sheet_for(variant: int, baby: bool) -> Texture2D:
	if baby and not baby_sheets.is_empty():
		var bi := variant % baby_sheets.size()
		if variant >= 0 and variant < baby_variant.size():
			bi = clampi(baby_variant[variant], 0, baby_sheets.size() - 1)
		return baby_sheets[bi]
	if variant >= 0 and variant < variant_sheets.size() and variant_sheets[variant] != null:
		return variant_sheets[variant]
	return sheet


func frame_for(baby: bool) -> Vector2i:
	return baby_frame_size if baby and not baby_sheets.is_empty() else frame_size


## Baris animasi (idle, walk, eat) untuk dewasa / anak.
func rows_for(baby: bool) -> Vector3i:
	if baby and not baby_sheets.is_empty():
		return Vector3i(baby_row_idle, baby_row_walk, baby_row_eat)
	return Vector3i(row_idle, row_walk, row_eat)
