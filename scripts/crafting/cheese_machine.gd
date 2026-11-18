class_name CheeseMachine
extends PlacedObject
## Phase 14: Cheese Machine. Pegang Milk lalu tekan E = masukkan 1 Milk. Setelah PROCESS_MINUTES
## menit game keju jadi; tekan E lagi untuk mengambil Cheese.
## Animasi dari Cheese_Machine_Anim_16x16.png (frame 64x48, baris 0):
## Phase 23: juga menerima Susu Kambing -> Keju Kambing (RECIPES). Bahan yang sedang diproses disimpan.
##   5-10 diam kosong, 11-20 membuat keju, 21-26 diam penuh (keju siap).

const SHEET := "res://assets/modern_farm/objects/machines/Cheese_Machine_Anim_16x16.png"
const FRAME := Vector2i(64, 48)
const INPUT_ITEM := "milk"
const OUTPUT_ITEM := "cheese"
## Phase 23: bahan -> hasil.
const RECIPES := {"milk": "cheese", "goat_milk": "goat_cheese"}
## 3 jam game (sekitar 3 menit nyata dengan kecepatan Normal).
const PROCESS_MINUTES := 180

enum State { EMPTY, WORKING, READY }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

## Phase 17: uap tipis selama mesin membuat keju (Vfx.steam).
var _steam: CPUParticles2D

var state: State = State.EMPTY
var input_id := INPUT_ITEM  # Phase 23: bahan yang sedang / terakhir diproses
var ready_at := 0  # menit game absolut saat keju jadi (lihat PlacedObject.now_minutes())


func _ready() -> void:
	sprite.sprite_frames = _build_frames()
	_steam = Vfx.steam()
	_steam.position = Vector2(-10, -40)
	add_child(_steam)
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _check_ready())
	_refresh()


func _build_frames() -> SpriteFrames:
	var sheet: Texture2D = load(SHEET)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: Array in [[&"empty", 5, 6, 5.0], [&"working", 11, 10, 8.0], [&"ready", 21, 6, 5.0]]:
		frames.add_animation(anim[0])
		frames.set_animation_speed(anim[0], anim[3])
		for i in int(anim[2]):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2((int(anim[1]) + i) * FRAME.x, 0, FRAME.x, FRAME.y)
			frames.add_frame(anim[0], atlas)
	return frames


func _refresh() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if _steam != null:
		_steam.emitting = state == State.WORKING
	match state:
		State.WORKING:
			sprite.play(&"working")
		State.READY:
			sprite.play(&"ready")
		_:
			sprite.play(&"empty")


func _check_ready() -> void:
	if state == State.WORKING and now_minutes() >= ready_at:
		state = State.READY
		_refresh()


func on_day_started() -> void:
	_check_ready()


func interact() -> String:
	_check_ready()
	match state:
		State.READY:
			var cheese := InventoryManager.get_item(output_id())
			if not InventoryManager.can_add(cheese, 1):
				return "Tas penuh. Kosongkan satu slot dulu."
			InventoryManager.add_item(cheese, 1)
			state = State.EMPTY
			_refresh()
			AudioManager.play_sfx("pickup")
			return "Dapat 1 %s! (di tas: %d)" % [cheese.item_name, InventoryManager.count_of(cheese.id)]
		State.WORKING:
			var left := maxi(ready_at - now_minutes(), 0)
			return "Sedang membuat keju... sekitar %d jam %d menit lagi." % [floori(left / 60.0), left % 60]
	var stack := InventoryManager.current_stack()
	if stack == null or not RECIPES.has(stack.item.id):
		return "Cheese Machine: pegang Milk atau Susu Kambing lalu tekan E untuk membuat keju."
	input_id = stack.item.id
	var input_name := stack.item.item_name
	InventoryManager.consume_selected(1)
	state = State.WORKING
	ready_at = now_minutes() + PROCESS_MINUTES
	_refresh()
	AudioManager.play_sfx("ui_select")
	var out := InventoryManager.get_item(output_id())
	return "%s dimasukkan. %s jadi dalam %d jam." % [input_name, out.item_name if out != null else "Keju", floori(PROCESS_MINUTES / 60.0)]


## id hasil keju untuk bahan yang sedang diproses.
func output_id() -> String:
	return String(RECIPES.get(input_id, OUTPUT_ITEM))


## Diambil dengan Pickaxe: Milk yang sedang diproses / keju yang sudah jadi ikut kembali.
func pick_up_items() -> Array:
	match state:
		State.WORKING:
			return [[input_id, 1]]
		State.READY:
			return [[output_id(), 1]]
	return []


func state_to_save() -> Dictionary:
	return {"state": int(state), "ready_at": ready_at, "input": input_id}


func state_from_save(d: Dictionary) -> void:
	state = clampi(int(d.get("state", 0)), 0, State.size() - 1) as State
	ready_at = int(d.get("ready_at", 0))
	input_id = String(d.get("input", INPUT_ITEM))
	if not RECIPES.has(input_id):
		input_id = INPUT_ITEM
	_check_ready()
	_refresh()
