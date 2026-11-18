class_name TouchControls
extends Control
## Kontrol sentuh untuk Android / layar sentuh (Phase 13).
##   Kiri bawah   : joystick virtual  -> move_left/right/up/down
##   Kanan bawah  : tombol A (ikon item terpilih) -> tool_use (SPACE: alat / makan / pancing, tahan saat mini game)
##                  tombol B -> interact (E: bicara / panen / pungut / tidur)
##   Kanan atas   : BUAT -> craft (C), PETA -> world_map (M), TAS -> inventory (I), TUGAS -> quest_log (J), MENU -> pause (ESC)
## Gaya tombol: tombol hijau dari asset RPG UI (UiTheme.UiSkin).
## Tombol mengirim InputEventAction, jadi semua kode lama (yang membaca Input Map) tetap bekerja.
## Multi-touch: tiap jari dilacak dengan index-nya (joystick + tombol bisa bersamaan).
## Tampil otomatis di perangkat layar sentuh; atur di Settings > Kontrol sentuh (Otomatis / Selalu / Mati).

const JOY_CENTER := Vector2(72, 284)
const JOY_RADIUS := 38.0
const KNOB_RADIUS := 15.0
const JOY_TOUCH_AREA := Rect2(0, 150, 260, 210)  # sentuhan di area ini menggerakkan joystick
const DEADZONE := 0.25
const PRESS_THRESHOLD := 0.5

const COL_BASE := Color(0.42, 0.25, 0.13, 0.45)
const COL_RING := Color(0.91, 0.84, 0.63, 0.6)
const COL_KNOB := Color(0.36, 0.75, 0.45, 0.85)

## Tombol: id -> {pos, radius, action, label}
var buttons := {
	&"a": {"pos": Vector2(590, 292), "radius": 24.0, "action": "tool_use", "label": "A"},
	&"b": {"pos": Vector2(542, 252), "radius": 19.0, "action": "interact", "label": "B"},
	&"craft": {"pos": Vector2(452, 94), "radius": 18.0, "action": "craft", "label": "BUAT"},
	&"map": {"pos": Vector2(490, 94), "radius": 18.0, "action": "world_map", "label": "PETA"},
	&"bag": {"pos": Vector2(528, 94), "radius": 18.0, "action": "inventory", "label": "TAS"},
	&"quest": {"pos": Vector2(566, 94), "radius": 18.0, "action": "quest_log", "label": "TUGAS"},
	&"menu": {"pos": Vector2(604, 94), "radius": 18.0, "action": "pause", "label": "MENU"},
}
## Diisi Main: true saat panel layar penuh (tas, toko, daftar tugas, pause) terbuka.
var menu_open := false
## Diisi Main: true saat dialog / pengumuman tampil.
var dialogue_open := false

var _joy_index := -1
var _joy_vector := Vector2.ZERO
var _pressed_actions: Dictionary = {}  # action -> true (sedang ditekan lewat joystick)
var _button_touch: Dictionary = {}     # touch index -> button id
var _bag_icon: Texture2D
var _skin: UiTheme.UiSkin


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skin = UiTheme.UiSkin.new()
	_bag_icon = load("res://assets/modern_farm/icons/Icons_16x16_Tools_Bag.png")
	InventoryManager.selected_changed.connect(func(_i: int) -> void: queue_redraw())
	InventoryManager.inventory_changed.connect(queue_redraw)
	SaveManager.settings_changed.connect(_refresh_visibility)
	_refresh_visibility()


func should_show() -> bool:
	match String(SaveManager.settings.get("touch_controls", "Otomatis")):
		"Selalu":
			return true
		"Mati":
			return false
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _refresh_visibility() -> void:
	var show := should_show()
	if not show:
		_release_all()
	visible = show
	set_process_input(show)
	queue_redraw()


func set_state(p_menu_open: bool, p_dialogue_open: bool) -> void:
	if p_menu_open == menu_open and p_dialogue_open == dialogue_open:
		return
	menu_open = p_menu_open
	dialogue_open = p_dialogue_open
	_release_all()
	queue_redraw()


## Tombol mana yang aktif pada keadaan sekarang.
func _button_enabled(id: StringName) -> bool:
	if menu_open:
		return id == &"menu"  # MENU = ESC: menutup tas / toko / daftar tugas / pause
	if dialogue_open:
		return false  # dialog: ketuk kotak dialog untuk lanjut / pilih
	return true


func _joystick_enabled() -> bool:
	return not menu_open and not dialogue_open


func _notification(what: int) -> void:
	if (what == NOTIFICATION_PAUSED or what == NOTIFICATION_VISIBILITY_CHANGED) and is_node_ready():
		_release_all()


# ---------------------------------------------------------------- input sentuh

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var pos := _to_local(touch.position)
		if touch.pressed:
			var id := _button_at(pos)
			if id != &"":
				_button_touch[touch.index] = id
				_send_action(String(buttons[id]["action"]), true)
				AudioManager.play_sfx("ui_select", 0.0, -8.0)
				queue_redraw()
				get_viewport().set_input_as_handled()
			elif _joystick_enabled() and _joy_index == -1 and JOY_TOUCH_AREA.has_point(pos):
				_joy_index = touch.index
				_update_joystick(pos)
				get_viewport().set_input_as_handled()
		else:
			if _button_touch.has(touch.index):
				var id: StringName = _button_touch[touch.index]
				_button_touch.erase(touch.index)
				_send_action(String(buttons[id]["action"]), false)
				queue_redraw()
				get_viewport().set_input_as_handled()
			elif touch.index == _joy_index:
				_joy_index = -1
				_update_joystick(JOY_CENTER)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joy_index:
			_update_joystick(_to_local(drag.position))
			get_viewport().set_input_as_handled()


## Posisi layar -> koordinat Control ini (memperhitungkan skala stretch).
func _to_local(screen_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_pos


func _button_at(pos: Vector2) -> StringName:
	for id: StringName in buttons:
		if not _button_enabled(id):
			continue
		var b: Dictionary = buttons[id]
		# Area sentuh sedikit lebih besar dari gambar tombol agar mudah ditekan.
		if pos.distance_to(b["pos"]) <= float(b["radius"]) + 6.0:
			return id
	return &""


func _update_joystick(pos: Vector2) -> void:
	var offset := (pos - JOY_CENTER).limit_length(JOY_RADIUS)
	_joy_vector = offset / JOY_RADIUS
	if _joy_vector.length() < DEADZONE:
		_joy_vector = Vector2.ZERO
	_set_axis("move_right", maxf(_joy_vector.x, 0.0))
	_set_axis("move_left", maxf(-_joy_vector.x, 0.0))
	_set_axis("move_down", maxf(_joy_vector.y, 0.0))
	_set_axis("move_up", maxf(-_joy_vector.y, 0.0))
	queue_redraw()


## Kekuatan arah joystick. Melewati ambang = kirim event "ditekan" (untuk menu pilihan dialog W/S).
func _set_axis(action: String, strength: float) -> void:
	var was := _pressed_actions.has(action)
	var now := strength >= PRESS_THRESHOLD
	if now and not was:
		_pressed_actions[action] = true
		_send_action(action, true, strength)
	elif not now and was:
		_pressed_actions.erase(action)
		_send_action(action, false)
	if strength > 0.0:
		Input.action_press(action, strength)  # gerak analog halus
	elif not now:
		Input.action_release(action)


func _send_action(action: String, pressed: bool, strength: float = 1.0) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = strength if pressed else 0.0
	Input.parse_input_event(ev)


func _release_all() -> void:
	for index: int in _button_touch:
		_send_action(String(buttons[_button_touch[index]]["action"]), false)
	_button_touch.clear()
	if _joy_index != -1 or _joy_vector != Vector2.ZERO:
		_joy_index = -1
		_update_joystick(JOY_CENTER)
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		if InputMap.has_action(action):  # Input Map didaftarkan GameManager saat game mulai
			Input.action_release(action)
	_pressed_actions.clear()


# ---------------------------------------------------------------- gambar

func _draw() -> void:
	var font := ThemeDB.fallback_font
	if _joystick_enabled():
		draw_circle(JOY_CENTER, JOY_RADIUS + 4.0, COL_BASE)
		draw_arc(JOY_CENTER, JOY_RADIUS + 4.0, 0.0, TAU, 40, COL_RING, 1.5)
		draw_circle((JOY_CENTER + _joy_vector * JOY_RADIUS).round(), KNOB_RADIUS, COL_KNOB)
	for id: StringName in buttons:
		if not _button_enabled(id):
			continue
		var b: Dictionary = buttons[id]
		var pos: Vector2 = b["pos"]
		var radius: float = b["radius"]
		var down := id in _button_touch.values()
		var box := Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0).grow(1.0)
		draw_style_box(_skin.button_pressed if down else _skin.button, box)
		var icon: Texture2D = null
		if id == &"a":
			var item := InventoryManager.current_item()
			icon = item.icon if item != null else null
		elif id == &"bag":
			icon = _bag_icon
		if icon != null and id == &"a":
			draw_texture_rect(icon, Rect2(pos - Vector2(16, 16), Vector2(32, 32)), false)  # 2x, tetap tajam
		elif icon != null:
			draw_texture(icon, pos - Vector2(8, 8))
		else:
			var size := UiTheme.FS
			var label: String = b["label"]
			var text_pos := pos + Vector2(-radius, 5)
			draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, size, UiTheme.TITLE)
	# label kecil di bawah tombol A agar jelas fungsinya
	if _button_enabled(&"a"):
		var a_pos: Vector2 = buttons[&"a"]["pos"]
		draw_string_outline(font, a_pos + Vector2(-24, 36), "A: pakai", HORIZONTAL_ALIGNMENT_CENTER, 48, UiTheme.FS, 3, Color.BLACK)
		draw_string(font, a_pos + Vector2(-24, 36), "A: pakai", HORIZONTAL_ALIGNMENT_CENTER, 48, UiTheme.FS, Color.WHITE)
