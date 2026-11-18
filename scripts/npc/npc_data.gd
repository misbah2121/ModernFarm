class_name NpcData
extends Resource
## Data satu NPC (Resource). File .tres ada di res://data/npc/ dan dimuat otomatis oleh NpcManager.
## Teks dialog: tanda "|" memisahkan halaman. "{greet}" diganti sapaan sesuai jam
## (Selamat pagi / siang / sore / malam).

## Sheet NPC dirakit dari potongan karakter asli Modern_Farm (Farmer_Generator_Pieces).
## Frame 16x32, 24 frame per baris (4 arah x 6): baris 1 = idle, baris 2 = jalan.
const PORTRAIT_FRAME := 18             # idle menghadap bawah
const PORTRAIT_REGION := Rect2(18 * 16, 41, 16, 14)  # bagian kepala frame itu

@export var id: String = ""
@export var npc_name: String = ""
@export var sheet: Texture2D
## Phase 11: jadwal harian. Tiap baris "HH:MM NamaTempat" (NamaTempat = nama Marker2D di
## village.tscn > Places). NPC berjalan ke tempat itu pada jam tersebut dan tinggal di sana sampai
## jadwal berikutnya. Tempat di grup "indoor" (rumah) = NPC masuk rumah (tidak terlihat).
@export var schedule: PackedStringArray = PackedStringArray()
## Jadwal saat hujan / badai (kosong = pakai jadwal biasa).
@export var rain_schedule: PackedStringArray = PackedStringArray()
## Posisi awal (jika jadwal kosong) di peta desa (titik kaki, piksel) dan jarak jalan-jalan dari sana.
@export var home: Vector2 = Vector2.ZERO
@export var wander_radius: float = 32.0
## Sapaan biasa (dipilih acak). Tiap elemen = satu percakapan, halaman dipisah "|".
@export var greetings: PackedStringArray = PackedStringArray()
## Dipakai saat hujan / badai.
@export var rain_lines: PackedStringArray = PackedStringArray()
## Dipakai saat friendship >= NpcManager.FRIEND_THRESHOLD.
@export var friend_lines: PackedStringArray = PackedStringArray()
## Jawaban pilihan "Ceritakan tentang dirimu" (halaman dipisah "|").
@export_multiline var bio: String = ""
@export var like_reply: String = ""
@export var neutral_reply: String = ""
@export var dislike_reply: String = ""
## id item (ItemData.id) yang disukai / tidak disukai.
@export var favorite_items: PackedStringArray = PackedStringArray()
@export var disliked_items: PackedStringArray = PackedStringArray()
## Phase 7: toko milik NPC ini (kosong = bukan pemilik toko). Jika diisi, dialog
## menampilkan pilihan "Belanja".
@export var shop: ShopData

var _portrait: AtlasTexture


## Potret kecil (kepala) diambil dari sheet NPC itu sendiri.
func get_portrait() -> AtlasTexture:
	if _portrait == null:
		_portrait = AtlasTexture.new()
		_portrait.atlas = sheet
		_portrait.filter_clip = true
		_portrait.region = PORTRAIT_REGION
	return _portrait
