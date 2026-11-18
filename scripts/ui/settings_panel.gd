class_name SettingsPanel
extends Control
## Panel pengaturan (Phase 12), dipakai di Main Menu dan Pause Menu. Dibuat lewat kode.
## Volume (Master, Musik, Efek, Lingkungan), layar penuh, kecepatan waktu.
## Nilai disimpan langsung oleh SaveManager ke user://settings.cfg. ESC / KEMBALI = tutup.

signal closed

const SLIDERS := [
	["master_volume", "Volume utama"],
	["music_volume", "Musik"],
	["sfx_volume", "Efek suara"],
	["ambient_volume", "Suara lingkungan"],
]

var _first_focus: Control


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.build()
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title := UiTheme.label("PENGATURAN", UiTheme.FS, UiTheme.TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)

	for entry: Array in SLIDERS:
		grid.add_child(UiTheme.label(entry[1]))
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(130, 12)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value = float(SaveManager.settings[entry[0]]) * 100.0
		var key: String = entry[0]
		slider.value_changed.connect(func(v: float) -> void:
			SaveManager.set_setting(key, v / 100.0)
			AudioManager.play_sfx("ui_select", 0.0))
		grid.add_child(slider)
		if _first_focus == null:
			_first_focus = slider

	grid.add_child(UiTheme.label("Layar penuh"))
	var full := CheckButton.new()
	full.button_pressed = bool(SaveManager.settings["fullscreen"])
	full.toggled.connect(func(on: bool) -> void: SaveManager.set_setting("fullscreen", on))
	grid.add_child(full)

	grid.add_child(UiTheme.label("Kecepatan waktu"))
	var speed := OptionButton.new()
	var names: Array = SaveManager.TIME_SPEEDS.keys()
	for i in names.size():
		speed.add_item(String(names[i]), i)
		if names[i] == SaveManager.settings["time_speed"]:
			speed.select(i)
	speed.item_selected.connect(func(i: int) -> void: SaveManager.set_setting("time_speed", String(names[i])))
	grid.add_child(speed)

	grid.add_child(UiTheme.label("Kontrol sentuh"))
	var touch := OptionButton.new()
	for i in SaveManager.TOUCH_MODES.size():
		touch.add_item(SaveManager.TOUCH_MODES[i], i)
		if SaveManager.TOUCH_MODES[i] == SaveManager.settings["touch_controls"]:
			touch.select(i)
	touch.item_selected.connect(func(i: int) -> void: SaveManager.set_setting("touch_controls", SaveManager.TOUCH_MODES[i]))
	grid.add_child(touch)

	var hint := UiTheme.label("Detik nyata per menit game: Cepat 0.7, Normal 1, Lambat 1.5", UiTheme.FS, UiTheme.TEXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(300, 0)
	box.add_child(hint)

	var back := Button.new()
	back.text = "KEMBALI"
	back.pressed.connect(close)
	box.add_child(back)


func open() -> void:
	visible = true
	if _first_focus != null:
		_first_focus.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	AudioManager.play_sfx("ui_close")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
