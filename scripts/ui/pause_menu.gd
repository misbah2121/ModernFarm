class_name PauseMenu
extends Control
## Menu pause (Phase 12): ESC saat bermain. RESUME, SAVE, SETTINGS, MAIN MENU.
## Saat terbuka seluruh game berhenti (get_tree().paused); menu ini tetap jalan (PROCESS_MODE_ALWAYS).
## MAIN MENU perlu ditekan dua kali (konfirmasi) karena progres sejak simpanan terakhir akan hilang.

signal save_requested

var _buttons: Array[Button] = []
var _main_menu_button: Button
var _confirm_exit := false
var _settings: SettingsPanel
var _status: Label


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.build()
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := UiTheme.label("PAUSED", UiTheme.FS, UiTheme.TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_add_button(box, "RESUME", close)
	_add_button(box, "SAVE", func() -> void:
		save_requested.emit()
		_status.text = "Tersimpan (%s)" % TimeManager.clock_text())
	_add_button(box, "SETTINGS", func() -> void:
		AudioManager.play_sfx("ui_open")
		_settings.open())
	_main_menu_button = _add_button(box, "MAIN MENU", _on_main_menu)

	_status = UiTheme.label("", UiTheme.FS, UiTheme.GREEN)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)

	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.closed.connect(func() -> void: _buttons[0].grab_focus())


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	button.focus_entered.connect(func() -> void: AudioManager.play_sfx("ui_select", 0.0, -6.0))
	parent.add_child(button)
	_buttons.append(button)
	return button


func open() -> void:
	if visible:
		return
	visible = true
	_confirm_exit = false
	_main_menu_button.text = "MAIN MENU"
	_status.text = ""
	get_tree().paused = true
	AudioManager.play_sfx("ui_open")
	_buttons[0].grab_focus()


func close() -> void:
	if not visible:
		return
	_settings.close()
	visible = false
	get_tree().paused = false
	AudioManager.play_sfx("ui_close")


func _on_main_menu() -> void:
	if not _confirm_exit:
		_confirm_exit = true
		_main_menu_button.text = "YAKIN? (tekan lagi)"
		_status.text = "Progres sejak simpanan terakhir akan hilang."
		return
	SaveManager.go_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not _settings.visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
