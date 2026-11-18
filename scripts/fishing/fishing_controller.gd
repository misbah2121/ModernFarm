class_name FishingController
extends Node
## Alur memancing (Phase 8), satu node di scene Main.
##   Pegang Fishing Rod -> menghadap air (maks. 2 tile) -> SPACE / E -> lempar (animasi Throw)
##   -> menunggu -> ikan menggigit ("!") -> tekan SPACE / E dalam 1 detik -> mini game -> tangkap.
## Sampah (FishData.Rarity.JUNK) langsung didapat tanpa mini game.
## Saat menunggu, SPACE / E / ESC = tarik pancing (batal).
## Animasi player diambil dari Farmer_1_Fishing_128_frames_16x16.png (asset asli Modern_Farm).
## Phase 17: pelampung di sheet jatuh di titik tetap (Player.BOBBER_OFFSETS). Air dicek TEPAT di titik itu
## supaya pelampung tidak tampak jatuh di darat / pagar. Efek: cipratan saat pelampung jatuh, riak saat
## menunggu, cipratan besar saat ikan menggigit & ditarik (Vfx).

signal message(text: String)
## true saat mulai memancing, false saat selesai (Main memakai ini untuk mengunci menu).
signal active_changed(active: bool)
## Untuk sistem quest nanti (Phase 11).
signal fish_caught(fish: FishData)

enum State { IDLE, THROW, WAIT, BITE, MINIGAME, REEL }

const FISH_DIR := "res://data/fish/"
const CAST_RANGE := 2           # tile air terjauh di depan player
const WAIT_MIN := 2.5           # detik menunggu gigitan
const WAIT_MAX := 7.0
const RAIN_WAIT_FACTOR := 0.7   # saat hujan ikan lebih cepat menggigit
const BITE_WINDOW := 1.0        # detik untuk menyentak pancing setelah "!"
const FISHING_BUFF_WAIT := 0.55 # Phase 18: bonus "mudah memancing" = waktu tunggu x0.55
const FISHING_BUFF_BITE := 1.8  # ... dan waktu menyentak x1.8
const NO_CELL := Vector2i(-9999, -9999)
const RIPPLE_WAIT := 1.1        # detik antar riak saat menunggu
const RIPPLE_BITE := 0.22       # riak cepat saat ikan menggigit

@export var minigame_path: NodePath

var state: State = State.IDLE

var _minigame: FishingMinigame
var _fish_list: Array[FishData] = []
var _player: Player
var _map: Node
var _hooked: FishData
var _timer := 0.0
var _alert: Label
var _time_was_paused := false
var _rng := RandomNumberGenerator.new()
var _ripple_timer := 0.0


func _ready() -> void:
	_rng.randomize()
	_load_fish()
	_minigame = get_node(minigame_path) as FishingMinigame
	_minigame.finished.connect(_on_minigame_finished)


func _load_fish() -> void:
	for file_name in DirAccess.get_files_at(FISH_DIR):
		var clean := file_name.trim_suffix(".remap")  # hasil export
		if not clean.ends_with(".tres"):
			continue
		var fish := load(FISH_DIR + clean) as FishData
		if fish == null:
			push_warning("Bukan FishData: %s" % clean)
			continue
		_fish_list.append(fish)


func all_fish() -> Array[FishData]:
	return _fish_list


func is_active() -> bool:
	return state != State.IDLE


## Mencoba mulai memancing. `map` harus punya fungsi map_id() dan is_fishable(cell).
## quiet = true: tidak memunculkan pesan jika tidak menghadap air (dipakai tombol E).
## Mengembalikan true jika memancing dimulai.
func try_start(player: Player, map: Node, quiet: bool = false) -> bool:
	if state != State.IDLE or player == null or map == null:
		return false
	var tool := InventoryManager.current_tool()
	if tool == null or tool.kind != ToolData.Kind.FISHING_ROD:
		return false
	if _find_water(player, map) == NO_CELL:
		if not quiet:
			if _water_ahead(player, map):
				message.emit("Pelampung belum sampai ke air. Geser sedikit (maju / mundur).")
			else:
				message.emit("Hadapkan pancing ke air (sungai / kolam).")
		return false
	if not GameManager.use_stamina(tool.stamina_cost):
		return false
	_player = player
	_map = map
	AudioManager.play_sfx("fish_cast")
	_player.fishing_anim_finished.connect(_on_anim_finished)
	state = State.THROW
	_player.play_fishing(&"fish_throw")
	active_changed.emit(true)
	return true


## Membatalkan memancing seketika (mis. tidur / pingsan).
func cancel() -> void:
	if state == State.IDLE:
		return
	if state == State.MINIGAME:
		_minigame.stop()
		TimeManager.paused = _time_was_paused
	_finish()


## Tile air tempat pelampung jatuh, atau NO_CELL. Titik pelampung dan sekelilingnya (3-4 px) harus air,
## supaya pelampung tidak tampak mendarat di tepi rumput / pagar.
func _find_water(player: Player, map: Node) -> Vector2i:
	var bob := player.bobber_position()
	for d: Vector2 in [Vector2.ZERO, Vector2(0, -4), Vector2(0, 3), Vector2(4, 0), Vector2(-4, 0)]:
		if not map.is_fishable(Vector2i(((bob + d) / float(Player.TILE)).floor())):
			return NO_CELL
	return Vector2i((bob / float(Player.TILE)).floor())


## Phase 18: pelampung akan jatuh di air jika melempar sekarang? (dipakai penanda interaksi)
func can_cast(player: Player, map: Node) -> bool:
	return state == State.IDLE and map != null and map.has_method("is_fishable") and _find_water(player, map) != NO_CELL


## Ada air dalam CAST_RANGE tile di depan (dipakai untuk pesan petunjuk saja).
func _water_ahead(player: Player, map: Node) -> bool:
	var cell := player.get_target_cell()
	var dir: Vector2i = Player.FACING_VECTORS[player.facing]
	for i in CAST_RANGE + 1:
		if map.is_fishable(cell + dir * i):
			return true
	return false


# ---------------------------------------------------------------- alur

func _process(delta: float) -> void:
	if state == State.WAIT or state == State.BITE:
		_ripple_timer -= delta
		if _ripple_timer <= 0.0:
			_ripple_timer = RIPPLE_WAIT if state == State.WAIT else RIPPLE_BITE
			Vfx.ripple(_fx_parent(), _bobber_local(), state == State.BITE)
	match state:
		State.WAIT:
			_timer -= delta
			if _timer <= 0.0:
				_bite()
		State.BITE:
			_timer -= delta
			if _timer <= 0.0:
				message.emit("Ikannya lepas... terlambat menarik pancing.")
				_reel()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.WAIT and state != State.BITE:
		return
	var pull := event.is_action_pressed("tool_use") or event.is_action_pressed("interact")
	if not pull and not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if state == State.WAIT or not pull:
		message.emit("Pancing ditarik. Belum ada yang menggigit.")
		_reel()
		return
	_hide_alert()
	if _hooked.rarity == FishData.Rarity.JUNK:
		_catch()
	else:
		state = State.MINIGAME
		_time_was_paused = TimeManager.paused
		TimeManager.paused = true  # jam berhenti selama mini game
		_minigame.start(_hooked)


func _start_wait() -> void:
	if state == State.THROW:
		Vfx.splash(_fx_parent(), _bobber_local())  # pelampung jatuh ke air
		AudioManager.play_sfx("water", 0.1, -6.0)
	_ripple_timer = RIPPLE_WAIT
	state = State.WAIT
	_timer = _rng.randf_range(WAIT_MIN, WAIT_MAX)
	if TimeManager.is_raining():
		_timer *= RAIN_WAIT_FACTOR
	if GameManager.has_buff("fishing"):  # Phase 18: bonus makanan = ikan lebih cepat menggigit
		_timer *= FISHING_BUFF_WAIT
	_player.play_fishing(&"fish_wait")


func _bite() -> void:
	_hooked = _pick_fish()
	if _hooked == null:
		_start_wait()  # tidak ada tangkapan yang cocok: tunggu lagi
		return
	state = State.BITE
	_timer = BITE_WINDOW * (FISHING_BUFF_BITE if GameManager.has_buff("fishing") else 1.0)
	_player.play_fishing(&"fish_bite")
	AudioManager.play_sfx("fish_bite")
	Vfx.splash(_fx_parent(), _bobber_local(), true)
	_ripple_timer = 0.0
	_show_alert()


func _pick_fish() -> FishData:
	var season := TimeManager.season_name()
	var hour := TimeManager.hour()
	var raining := TimeManager.is_raining()
	var location: String = _map.map_id()
	var pool: Array[FishData] = []
	var total := 0.0
	for fish in _fish_list:
		if fish.is_available(season, hour, raining, location):
			pool.append(fish)
			total += fish.weight
	if pool.is_empty() or total <= 0.0:
		return null
	var roll := _rng.randf() * total
	for fish in pool:
		roll -= fish.weight
		if roll <= 0.0:
			return fish
	return pool.back()


func _on_minigame_finished(success: bool) -> void:
	TimeManager.paused = _time_was_paused
	if state != State.MINIGAME:
		return
	if success:
		_catch()
	else:
		message.emit("%s lolos!" % _hooked.fish_name)
		AudioManager.play_sfx("fish_lost")
		_reel()


func _catch() -> void:
	var item := _hooked.item
	if InventoryManager.add_item(item, 1) > 0:
		message.emit("Tas penuh! %s dilepas kembali." % _hooked.fish_name)
	else:
		if _hooked.rarity == FishData.Rarity.JUNK:
			message.emit("Dapat %s... (sampah)" % _hooked.fish_name)
		else:
			message.emit("Dapat %s! (%s, jual %d Gold)" % [_hooked.fish_name, _hooked.rarity_name(), _hooked.sell_price()])
		_show_catch_icon(item.icon)
		AudioManager.play_sfx("fish_catch")
		fish_caught.emit(_hooked)
	_reel()


func _reel() -> void:
	_hide_alert()
	if state == State.WAIT or state == State.BITE or state == State.MINIGAME:
		Vfx.splash(_fx_parent(), _bobber_local(), _hooked != null and state == State.MINIGAME)
	state = State.REEL
	_player.play_fishing(&"fish_reel")


func _on_anim_finished(stage: StringName) -> void:
	match stage:
		&"fish_throw":
			if state == State.THROW:
				_start_wait()
		&"fish_reel":
			if state == State.REEL:
				_finish()


func _finish() -> void:
	_hide_alert()
	if _player != null:
		if _player.fishing_anim_finished.is_connected(_on_anim_finished):
			_player.fishing_anim_finished.disconnect(_on_anim_finished)
		_player.stop_fishing()
	_player = null
	_map = null
	_hooked = null
	state = State.IDLE
	active_changed.emit(false)


# ---------------------------------------------------------------- efek kecil

## Efek air dipasang di layer yang sama dengan player (Objects) agar ikut y-sort.
func _fx_parent() -> Node:
	return _player.get_parent() if _player != null else null


func _bobber_local() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	var parent := _player.get_parent() as Node2D
	var bob := _player.bobber_position()
	return parent.to_local(bob) if parent != null else bob


func _show_alert() -> void:
	_hide_alert()
	_alert = Label.new()
	_alert.text = "!"
	_alert.add_theme_font_size_override("font_size", 16)
	_alert.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_alert.add_theme_color_override("font_outline_color", Color.BLACK)
	_alert.add_theme_constant_override("outline_size", 4)
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.size = Vector2(16, 20)
	_alert.position = Vector2(-8, -62)
	_alert.z_index = 20
	_player.add_child(_alert)


func _hide_alert() -> void:
	if is_instance_valid(_alert):
		_alert.queue_free()
	_alert = null


## Icon tangkapan melayang di atas kepala player lalu menghilang.
func _show_catch_icon(icon: Texture2D) -> void:
	if icon == null or _player == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = icon
	sprite.position = Vector2(0, -44)
	sprite.z_index = 20
	_player.add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "position:y", -56.0, 0.8)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.8)
	tween.tween_callback(sprite.queue_free)
