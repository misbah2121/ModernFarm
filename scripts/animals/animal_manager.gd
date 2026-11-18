extends Node
## Autoload "AnimalManager" (Phase 9): daftar hewan milik player, pakan di tempat pakan, makan harian,
## produk harian, dan friendship hewan. Node hewan di peta (FarmAnimal) hanya menampilkan data ini.
##
## Aturan harian (setiap pagi):
##   1. Hewan yang makan kemarin -> hitungan produk +1; jika sudah produce_days -> produk siap diambil.
##      Makan: friendship +5. Tidak makan: friendship -20.
##   2. Hari baru: hewan makan lagi. Cuaca Sunny/Cloudy dan bukan Winter = merumput sendiri (gratis).
##      Selain itu tiap hewan mengambil 1 Animal Feed dari tempat pakan (Feeder). Pakan kosong = lapar.
##   Mengisi tempat pakan saat ada hewan lapar -> hewan langsung makan.
## Dielus (E) +15 friendship sekali sehari. Friendship 0-1000 (100 = 1 hati).
## Phase 20: data ANJING PELIHARAAN (satu ekor, Labrador di Farm). Dielus +15 / hari, makan dari mangkuk
## +10 / hari (lupa diberi makan -10). Hati >= 3: kadang membawa barang temuan di pagi hari.
## Phase 18: hewan dengan AnimalData.forage_item (babi) kadang menemukan barang (Truffle) di kandang.
## Barang itu tergeletak di tanah (ItemPickup) sampai diambil; posisinya disimpan di ground_items.
## Phase 23:
##   - Hewan baru: kambing (Susu Kambing), kelinci (Bulu Kelinci), keledai (mengisi tempat pakan),
##     ayam jago (ayam kadang bertelur EMAS, hewan Coop lebih cepat akrab, anak ayam bisa menetas).
##   - WARNA ACAK saat dibeli (AnimalState.variant, disimpan).
##   - ANAK HEWAN: setiap pagi, jenis yang punya 2 hewan dewasa kenyang & akrab (hati >= 2) berpeluang
##     melahirkan 1 anak (ayam butuh ayam jago). Anak tumbuh dewasa setelah AnimalData.grow_days hari.

signal animal_added(state: AnimalState)
## Status hewan / pakan berubah (dipakai FarmAnimal & Feeder untuk memperbarui tampilan).
signal changed
## Phase 18: hewan menemukan barang di tanah (FarmMap memunculkan ItemPickup di dekat hewan itu).
signal forage_found(state: AnimalState, item: ItemData)
## Phase 23: pesan untuk toast (anak lahir, anak dewasa, dll.).
signal message(text: String)

const ANIMALS_DIR := "res://data/animals/"
const CAPACITY := {"coop": 8, "barn": 6}
const BUILDING_NAMES := {"coop": "Coop", "barn": "Barn"}
const FEEDER_CAPACITY := 12
const FEED_ITEM := "animal_feed"
const MAX_FRIENDSHIP := 1000
const PET_POINTS := 15
const FED_POINTS := 5
const HUNGRY_POINTS := -20
const PRODUCT_POINTS := 5
## Phase 18: batas barang temuan yang tergeletak di kandang.
const MAX_GROUND_ITEMS := 8
## Phase 23: peluang lahir per jenis per pagi (jika syarat terpenuhi). Maksimal 1 kelahiran per hari.
const BIRTH_CHANCE := 0.15
const BREED_MIN_HEARTS := 2
## Nama jenis dalam bahasa Indonesia untuk pesan.
const KIND_NAMES := {"chicken": "ayam", "rooster": "ayam jago", "duck": "bebek", "rabbit": "kelinci", "cow": "sapi",
	"goat": "kambing", "sheep": "domba", "pig": "babi", "donkey": "keledai"}

## Data satu hewan milik player.
class AnimalState:
	var uid: int = 0
	var data: AnimalData
	var animal_name: String = ""
	var friendship: int = 0
	var fed: bool = false          # sudah makan hari ini
	var petted: bool = false       # sudah dielus hari ini
	var days_fed: int = 0          # hari makan sejak produk terakhir
	var product_ready: bool = false
	## Phase 23
	var variant: int = 0            # indeks warna (AnimalData.variant_sheets)
	var baby: bool = false          # masih anak
	var age: int = 0                # umur anak (hari)
	var bonus_ready: bool = false   # produk yang siap adalah produk bonus (Telur Emas)

	func hearts() -> int:
		return floori(friendship / 100.0)

	## Produk yang sedang siap diambil (biasa / bonus).
	func ready_item() -> ItemData:
		if not product_ready:
			return null
		if bonus_ready and data.bonus_product != null:
			return data.bonus_product
		return data.product

	func color_name() -> String:
		return data.variant_name(variant)

var animals: Array[AnimalState] = []
## Jumlah Animal Feed di tempat pakan.
var feeder_hay: int = 0
## Phase 20: anjing peliharaan
const DOG_PET_POINTS := 15
const DOG_FED_POINTS := 10
const DOG_HUNGRY_POINTS := -10
const DOG_FOOD_ITEM := "dog_food"
const DOG_NAMES: Array[String] = ["Coklat", "Bobi", "Kopi", "Molly", "Brownie", "Max"]
## Barang yang bisa dibawa anjing (id, bobot). Item yang tidak ada dilewati.
const DOG_FINDS := [["wood", 30], ["stone", 25], ["driftwood", 15], ["copper_ore", 12], ["seeds_carrot", 8], ["seeds_corn", 6], ["truffle", 4]]
var dog_name := "Coklat"
var dog_friendship := 0
var dog_petted := false
var dog_fed := false
var bowl_full := false
## Phase 18: barang temuan hewan yang masih di tanah: [{"id": "truffle", "x": 0.0, "y": 0.0}, ...]
var ground_items: Array = []

var _types: Dictionary = {}  # id -> AnimalData
var _next_uid := 1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_load_types()
	TimeManager.day_started.connect(_on_day_started)


func _load_types() -> void:
	for file_name in DirAccess.get_files_at(ANIMALS_DIR):
		var clean := file_name.trim_suffix(".remap")  # hasil export
		if not clean.ends_with(".tres"):
			continue
		var data := load(ANIMALS_DIR + clean) as AnimalData
		if data == null:
			push_warning("Bukan AnimalData: %s" % clean)
			continue
		_types[data.id] = data


func get_type(id: String) -> AnimalData:
	return _types.get(id) as AnimalData


func count_in(building: String) -> int:
	var total := 0
	for a in animals:
		if a.data.building == building:
			total += 1
	return total


func capacity_of(building: String) -> int:
	return int(CAPACITY.get(building, 0))


# ---------------------------------------------------------------- beli

## Mengembalikan "" jika berhasil, atau alasan gagal. Gold dikurangi di sini.
func buy(data: AnimalData) -> String:
	if data == null:
		return "Hewan tidak dikenal."
	var building_name: String = BUILDING_NAMES.get(data.building, data.building)
	if count_in(data.building) >= capacity_of(data.building):
		return "%s penuh (%d/%d)." % [building_name, count_in(data.building), capacity_of(data.building)]
	if not GameManager.spend_gold(data.price):
		return "Gold tidak cukup (butuh %d)." % data.price
	var state := AnimalState.new()
	state.uid = _next_uid
	_next_uid += 1
	state.data = data
	state.animal_name = _pick_name(data)
	state.variant = _rng.randi_range(0, data.variant_count() - 1)  # Phase 23: warna acak
	animals.append(state)
	_feed_hungry()
	animal_added.emit(state)
	changed.emit()
	return ""


func _pick_name(data: AnimalData) -> String:
	var used := {}
	for a in animals:
		used[a.animal_name] = true
	var free: Array[String] = []
	for n in data.names:
		if not used.has(n):
			free.append(n)
	if free.is_empty():
		return "%s %d" % [data.animal_name, count_in(data.building) + 1]
	return free[_rng.randi_range(0, free.size() - 1)]


# ---------------------------------------------------------------- pakan

## Memasukkan Animal Feed ke tempat pakan. Mengembalikan jumlah yang benar-benar masuk.
func add_feed(amount: int) -> int:
	var added := clampi(amount, 0, FEEDER_CAPACITY - feeder_hay)
	if added <= 0:
		return 0
	feeder_hay += added
	_feed_hungry()
	changed.emit()
	return added


func is_grazing_day() -> bool:
	var good_weather := TimeManager.weather == TimeManager.Weather.SUNNY or TimeManager.weather == TimeManager.Weather.CLOUDY
	return good_weather and TimeManager.season() != TimeManager.Season.WINTER


func _feed_hungry() -> void:
	var grazing := is_grazing_day()
	for a in animals:
		if a.fed:
			continue
		if grazing:
			a.fed = true
		elif feeder_hay > 0:
			feeder_hay -= 1
			a.fed = true


# ---------------------------------------------------------------- interaksi (tombol E)

## E pada hewan: ambil produk jika siap, selain itu elus. Mengembalikan pesan untuk toast.
func interact(a: AnimalState) -> String:
	if not a.baby and a.ready_item() != null:
		return _collect(a)
	var text := ""
	if not a.petted:
		a.petted = true
		_add_friendship(a, PET_POINTS)
		text = "Kamu mengelus %s. (+%d)  " % [a.animal_name, PET_POINTS]
	text += status_text(a)
	changed.emit()
	return text


func status_text(a: AnimalState) -> String:
	var food := "Kenyang" if a.fed else "Lapar"
	var kind := a.data.animal_name
	if a.color_name() != "":
		kind += " " + a.color_name()
	if a.baby:
		kind = "Anak %s, dewasa %d hari lagi" % [kind, maxi(a.data.grow_days - a.age, 1)]
	return "%s (%s)  Hati %d/10  %s" % [a.animal_name, kind, a.hearts(), food]


func _collect(a: AnimalState) -> String:
	var product := a.ready_item()
	if a.data.tool_required != "":
		var item := InventoryManager.current_item()
		if item == null or item.id != a.data.tool_required:
			var tool := InventoryManager.get_item(a.data.tool_required)
			var tool_name := tool.item_name if tool != null else a.data.tool_required
			return "%s siap diambil. Pegang %s dulu." % [product.item_name, tool_name]
	if InventoryManager.add_item(product, 1) > 0:
		return "Tas penuh! %s belum bisa diambil." % product.item_name
	a.product_ready = false
	a.bonus_ready = false
	_add_friendship(a, PRODUCT_POINTS)
	QuestManager.report(QuestData.Kind.GATHER, product.id, 1)
	AudioManager.play_sfx("pickup")
	changed.emit()
	return "Dapat %s dari %s!" % [product.item_name, a.animal_name]


## Phase 19 (pekerja peternak): ambil produk tanpa syarat alat. Mengembalikan item atau null.
func worker_collect(a: AnimalState) -> ItemData:
	var product := a.ready_item()
	if product == null or a.baby:
		return null
	a.product_ready = false
	a.bonus_ready = false
	_add_friendship(a, PRODUCT_POINTS)
	changed.emit()
	return product


## Phase 19 (pekerja peternak Lv 3): elus semua hewan yang belum dielus hari ini.
func worker_pet_all() -> int:
	var count := 0
	for a in animals:
		if not a.petted:
			a.petted = true
			_add_friendship(a, PET_POINTS)
			count += 1
	if count > 0:
		changed.emit()
	return count


## Phase 19: jumlah hewan yang belum makan hari ini.
func hungry_count() -> int:
	var n := 0
	for a in animals:
		if not a.fed:
			n += 1
	return n


# ---------------------------------------------------------------- anjing (Phase 20)

func dog_hearts() -> int:
	return floori(dog_friendship / 100.0)


## E pada anjing: elus sekali sehari. Mengembalikan teks toast.
func pet_dog() -> String:
	var text := ""
	if not dog_petted:
		dog_petted = true
		dog_friendship = clampi(dog_friendship + DOG_PET_POINTS, 0, MAX_FRIENDSHIP)
		text = "Kamu mengelus %s. Ekornya bergoyang! (+%d)  " % [dog_name, DOG_PET_POINTS]
	else:
		text = "%s senang ditemani.  " % dog_name
	text += dog_status()
	changed.emit()
	return text


func dog_status() -> String:
	var food := "Kenyang" if dog_fed else ("Mangkuk terisi" if bowl_full else "Lapar")
	return "%s  Hati %d/10  %s" % [dog_name, dog_hearts(), food]


## Isi mangkuk dengan Makanan Anjing (dipegang). true jika berhasil.
func fill_bowl() -> bool:
	if bowl_full:
		return false
	bowl_full = true
	changed.emit()
	return true


## Anjing makan dari mangkuk (dipanggil PetDog saat sampai di mangkuk).
func dog_eat() -> void:
	if not bowl_full or dog_fed:
		return
	bowl_full = false
	dog_fed = true
	changed.emit()


## Pagi hari: hitung makan kemarin, reset elus. Mengembalikan item temuan (atau null).
func dog_new_day() -> ItemData:
	dog_friendship = clampi(dog_friendship + (DOG_FED_POINTS if dog_fed else DOG_HUNGRY_POINTS), 0, MAX_FRIENDSHIP)
	var found: ItemData = null
	if dog_fed and dog_hearts() >= 3 and _rng.randf() < 0.25 + dog_hearts() * 0.04:
		found = _pick_dog_find()
	dog_fed = false
	dog_petted = false
	changed.emit()
	return found


func _pick_dog_find() -> ItemData:
	var pool: Array = []
	var total := 0
	for entry: Array in DOG_FINDS:
		if InventoryManager.get_item(String(entry[0])) != null:
			pool.append(entry)
			total += int(entry[1])
	if total <= 0:
		return null
	var roll := _rng.randi_range(1, total)
	for entry: Array in pool:
		roll -= int(entry[1])
		if roll <= 0:
			return InventoryManager.get_item(String(entry[0]))
	return null


func _add_friendship(a: AnimalState, amount: int) -> void:
	a.friendship = clampi(a.friendship + amount, 0, MAX_FRIENDSHIP)


# ---------------------------------------------------------------- hari baru

func _on_day_started(_total_day: int) -> void:
	var helpers := _fed_adult_ids()  # jenis dewasa yang kemarin makan (untuk bonus ayam jago)
	for a in animals:
		if a.baby:
			_grow_baby(a)
		elif a.fed:
			_apply_helper(a)
			_add_friendship(a, FED_POINTS)
			# Phase 18: babi yang kenyang kadang menemukan truffle (lebih sering jika hatinya tinggi).
			if a.data.forage_item != null and ground_items.size() < MAX_GROUND_ITEMS:
				var chance := a.data.forage_chance + a.hearts() * 0.03
				if _rng.randf() < chance:
					forage_found.emit(a, a.data.forage_item)
			if a.data.product != null and not a.product_ready:
				a.days_fed += 1
				if a.days_fed >= a.data.produce_days:
					a.days_fed = 0
					a.product_ready = true
					# Phase 23: bonus (ayam + ayam jago -> Telur Emas)
					a.bonus_ready = a.data.bonus_product != null and (a.data.bonus_needs == "" or helpers.has(a.data.bonus_needs)) \
						and _rng.randf() < a.data.bonus_chance + a.hearts() * 0.01
		if not a.fed:
			_add_friendship(a, HUNGRY_POINTS)
		elif a.baby:
			_add_friendship(a, FED_POINTS)
	_try_birth()
	for a in animals:
		a.fed = false
		a.petted = false
	_feed_hungry()
	changed.emit()


# ---------------------------------------------------------------- Phase 23: penolong, anak

func _fed_adult_ids() -> Dictionary:
	var ids := {}
	for a in animals:
		if a.fed and not a.baby:
			ids[a.data.id] = true
	return ids


## Efek hewan penolong (keledai mengisi tempat pakan, ayam jago membuat Coop akrab).
func _apply_helper(a: AnimalState) -> void:
	if a.data.feeder_bonus > 0 and feeder_hay < FEEDER_CAPACITY:
		var add := mini(a.data.feeder_bonus, FEEDER_CAPACITY - feeder_hay)
		feeder_hay += add
		message.emit("%s si %s membawa %d pakan ke tempat pakan." % [a.animal_name, kind_name(a.data), add])
	if a.data.friend_aura > 0:
		for other in animals:
			if other != a and other.data.building == a.data.building:
				_add_friendship(other, a.data.friend_aura)


func _grow_baby(a: AnimalState) -> void:
	a.age += 1
	if a.age < a.data.grow_days:
		return
	a.baby = false
	a.age = 0
	a.days_fed = 0
	var alt := get_type(a.data.grow_alt_type) if a.data.grow_alt_type != "" else null
	if alt != null and _rng.randf() < a.data.grow_alt_chance:
		a.data = alt
		a.variant = clampi(a.variant, 0, alt.variant_count() - 1)
	message.emit("%s sudah dewasa! Sekarang ia seekor %s." % [a.animal_name, kind_name(a.data)])


## Hewan dewasa yang kemarin makan dan cukup akrab untuk beranak.
func _breeders(id: String) -> Array[AnimalState]:
	var list: Array[AnimalState] = []
	for a in animals:
		if a.data.id == id and not a.baby and a.fed and a.hearts() >= BREED_MIN_HEARTS:
			list.append(a)
	return list


func _try_birth() -> void:
	var tried := {}
	var order := animals.duplicate()
	order.shuffle()
	for a: AnimalState in order:
		var data := a.data
		if tried.has(data.id) or not data.can_breed():
			continue
		tried[data.id] = true
		if count_in(data.building) >= capacity_of(data.building):
			continue
		var parents := _breeders(data.id)
		var ok := parents.size() >= 2
		if data.breed_partner != "":
			ok = parents.size() >= 1 and not _breeders(data.breed_partner).is_empty()
		if not ok or _rng.randf() >= BIRTH_CHANCE:
			continue
		var mother: AnimalState = parents[_rng.randi_range(0, parents.size() - 1)]
		add_baby(data, mother.variant if _rng.randf() < 0.7 else _rng.randi_range(0, data.variant_count() - 1))
		message.emit("Seekor anak %s lahir di kandang! Induknya %s." % [kind_name(data), mother.animal_name])
		return  # maksimal 1 kelahiran per hari


func kind_name(data: AnimalData) -> String:
	return String(KIND_NAMES.get(data.id, data.animal_name.to_lower()))


## Menambah anak hewan (dipakai kelahiran & tes). Mengembalikan state baru.
func add_baby(data: AnimalData, variant: int) -> AnimalState:
	var b := AnimalState.new()
	b.uid = _next_uid
	_next_uid += 1
	b.data = data
	b.baby = true
	b.variant = clampi(variant, 0, data.variant_count() - 1)
	b.animal_name = _pick_name(data)
	b.friendship = 100
	b.fed = true
	animals.append(b)
	animal_added.emit(b)
	changed.emit()
	return b


# ---------------------------------------------------------------- simpan / game baru (Phase 12)

func reset() -> void:
	animals.clear()
	feeder_hay = 0
	ground_items.clear()
	dog_name = DOG_NAMES[0]
	dog_friendship = 0
	dog_petted = false
	dog_fed = false
	bowl_full = false
	_next_uid = 1


func to_save() -> Dictionary:
	var list: Array = []
	for a in animals:
		list.append({
			"uid": a.uid, "type": a.data.id, "name": a.animal_name, "friendship": a.friendship,
			"fed": a.fed, "petted": a.petted, "days_fed": a.days_fed, "product_ready": a.product_ready,
			"variant": a.variant, "baby": a.baby, "age": a.age, "bonus": a.bonus_ready,
		})
	return {"animals": list, "feeder_hay": feeder_hay, "next_uid": _next_uid, "ground_items": ground_items.duplicate(true),
		"dog": {"name": dog_name, "friendship": dog_friendship, "petted": dog_petted, "fed": dog_fed, "bowl": bowl_full}}


func from_save(d: Dictionary) -> void:
	reset()
	for v: Dictionary in d.get("animals", []):
		var data := get_type(String(v.get("type", "")))
		if data == null:
			continue
		var a := AnimalState.new()
		a.uid = int(v.get("uid", _next_uid))
		a.data = data
		a.animal_name = String(v.get("name", data.animal_name))
		a.friendship = clampi(int(v.get("friendship", 0)), 0, MAX_FRIENDSHIP)
		a.fed = bool(v.get("fed", false))
		a.petted = bool(v.get("petted", false))
		a.days_fed = int(v.get("days_fed", 0))
		a.product_ready = bool(v.get("product_ready", false))
		a.variant = clampi(int(v.get("variant", 0)), 0, data.variant_count() - 1)
		a.baby = bool(v.get("baby", false)) and data.can_breed()
		a.age = int(v.get("age", 0))
		a.bonus_ready = bool(v.get("bonus", false))
		animals.append(a)
	feeder_hay = clampi(int(d.get("feeder_hay", 0)), 0, FEEDER_CAPACITY)
	ground_items = (d.get("ground_items", []) as Array).duplicate(true)
	var dog: Dictionary = d.get("dog", {})
	dog_name = String(dog.get("name", DOG_NAMES[0]))
	dog_friendship = clampi(int(dog.get("friendship", 0)), 0, MAX_FRIENDSHIP)
	dog_petted = bool(dog.get("petted", false))
	dog_fed = bool(dog.get("fed", false))
	bowl_full = bool(dog.get("bowl", false))
	_next_uid = maxi(int(d.get("next_uid", 1)), animals.size() + 1)
