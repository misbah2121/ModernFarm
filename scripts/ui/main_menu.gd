extends Control
## Main Menu (Phase 12): MODERN FARM - NEW GAME / LOAD GAME / SETTINGS / EXIT.
## Latar = gambar desa dari asset Modern_Farm (assets/modern_farm/ui/menu_background.png).
## Scene: res://scenes/ui/main_menu.tscn (scene pertama saat game dijalankan).
## Keyboard: panah / W S pindah tombol (fokus), Enter / Spasi pilih. Mouse juga bisa.

@onready var _buttons_box: VBoxContainer = $Center/Box/Buttons
@onready var _new_button: Button = $Center/Box/Buttons/NewGame
@onready var _load_button: Button = $Center/Box/Buttons/LoadGame
@onready var _settings_button: Button = $Center/Box/Buttons/Settings
@onready var _exit_button: Button = $Center/Box/Buttons/Exit
@onready var _info: Label = $Center/Box/Info

var _settings: SettingsPanel
var _confirm_new := false


func _ready() -> void:
	theme = UiTheme.build()
	# Teks yang langsung di atas gambar latar (bukan di panel kertas): putih bergaris gelap.
	for path in ["Center/Box/Subtitle", "Center/Box/Info", "Credit"]:
		var l := get_node_or_null(path) as Label
		if l != null:
			l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.04))
			l.add_theme_constant_override("outline_size", 4)
			if not l.has_theme_color_override("font_color"):
				l.add_theme_color_override("font_color", Color.WHITE)
	get_tree().paused = false
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.closed.connect(func() -> void: _settings_button.grab_focus())

	_new_button.pressed.connect(_on_new_game)
	_load_button.pressed.connect(_on_load_game)
	_settings_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_open")
		_settings.open())
	_exit_button.pressed.connect(func() -> void: get_tree().quit())
	for button in [_new_button, _load_button, _settings_button, _exit_button]:
		(button as Button).focus_entered.connect(func() -> void: AudioManager.play_sfx("ui_select", 0.0, -6.0))

	var summary := SaveManager.save_summary()
	_load_button.disabled = summary == ""
	_info.text = "Simpanan: %s" % summary if summary != "" else "Belum ada simpanan."
	if summary != "":
		_load_button.grab_focus()
	else:
		_new_button.grab_focus()
	AudioManager.stop_ambient()
	AudioManager.play_music("menu")


func _on_new_game() -> void:
	if SaveManager.has_save() and not _confirm_new:
		_confirm_new = true
		_new_button.text = "YAKIN? (tekan lagi)"
		_info.text = "Game baru akan menimpa simpanan lama saat tersimpan."
		return
	AudioManager.play_sfx("ui_open")
	SaveManager.start_new_game()


func _on_load_game() -> void:
	AudioManager.play_sfx("ui_open")
	if not SaveManager.load_game():
		_info.text = "File simpanan tidak bisa dibaca."
