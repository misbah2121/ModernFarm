class_name UiTheme
extends RefCounted
## Gaya UI game memakai asset "Free Basic Pixel Art UI for RPG" (CraftPix, assets/ui/rpg_ui/).
## Semua panel / tombol / slot adalah StyleBoxTexture (9-slice) dari gambar asli pack itu,
## jadi bisa diperbesar ke ukuran berapa pun tanpa merusak bingkai pixel art.
##
## Dipakai dengan dua cara:
##   * Control biasa (MainMenu, PauseMenu, SettingsPanel): `control.theme = UiTheme.build()`
##   * Panel yang digambar lewat _draw (inventory, toko, tugas, hotbar, ...):
##       var skin := UiTheme.UiSkin.new()          (buat sekali di _ready)
##       draw_style_box(skin.window, rect)       (atau UiTheme.draw_window(self, skin, rect, "JUDUL"))
##
## Warna teks: panel kertas krem -> teks cokelat tua (TEXT). Judul di pita hijau -> TITLE.

const SHEET_INVENTORY := "res://assets/ui/rpg_ui/Inventory.png"
const SHEET_TILES := "res://assets/ui/rpg_ui/Main_tiles.png"
const SHEET_BUTTONS := "res://assets/ui/rpg_ui/Buttons.png"
const SHEET_ACTION := "res://assets/ui/rpg_ui/Action_panel.png"
const SHEET_SETTINGS := "res://assets/ui/rpg_ui/Settings.png"

## Phase 19: ukuran font. Font pixel "Pixel Game" hanya tajam di ukuran 16 (1 piksel font = 1 piksel layar
## pada jendela 2x). Semua teks memakai FS; judul besar memakai FS_BIG.
const FS := 16
const FS_BIG := 32

## Tinggi pita judul hijau di bagian atas jendela (piksel).
const HEADER_H := 14

# ---- warna teks di atas kertas krem
const TEXT := Color(0.29, 0.18, 0.11)
const TEXT_DIM := Color(0.29, 0.18, 0.11, 0.62)
const TITLE := Color(0.10, 0.17, 0.11)        # teks di pita hijau / tombol hijau
const ACCENT := Color(0.15, 0.42, 0.24)       # nama item, pilihan aktif
const PRICE := Color(0.58, 0.36, 0.04)        # harga / gold
const RED := Color(0.70, 0.17, 0.12)
const GREEN := Color(0.18, 0.50, 0.22)
const SELECT := Color(0.36, 0.82, 0.48)       # bingkai slot terpilih
const SLOT_HOVER := Color(1, 1, 1, 0.16)

# ---- nama lama (Phase 12) tetap ada agar script lain tidak rusak
const COL_GOLD := TITLE
const COL_PANEL := Color(0.91, 0.84, 0.63)
const COL_BORDER := Color(0.42, 0.25, 0.13)


## Kumpulan StyleBox untuk satu panel. Dibuat sekali per node (bukan static) agar tidak ada
## resource yang tertahan saat game ditutup.
class UiSkin:
	var window: StyleBoxTexture      # kertas krem + bingkai cokelat + pita judul hijau
	var paper: StyleBoxTexture       # kertas krem + bingkai cokelat (tanpa pita)
	var wood: StyleBoxTexture        # papan cokelat
	var header: StyleBoxTexture      # pita hijau saja (label nama, tab aktif)
	var slot: StyleBoxTexture        # kotak slot item (dari Action_panel)
	var bar: StyleBoxTexture         # papan dasar hotbar
	var button: StyleBoxTexture
	var button_hover: StyleBoxTexture
	var button_pressed: StyleBoxTexture
	var button_disabled: StyleBoxTexture

	func _init() -> void:
		window = UiTheme.box(UiTheme.SHEET_INVENTORY, Rect2(7, 112, 34, 37), 4, 18, 4, 5)
		paper = UiTheme.box(UiTheme.SHEET_TILES, Rect2(203, 155, 26, 26), 5, 5, 5, 5)
		wood = UiTheme.box(UiTheme.SHEET_TILES, Rect2(299, 155, 26, 26), 5, 5, 5, 5)
		header = UiTheme.box(UiTheme.SHEET_INVENTORY, Rect2(7, 112, 34, 14), 3, 3, 3, 3)
		slot = UiTheme.box(UiTheme.SHEET_ACTION, Rect2(16, 48, 16, 16), 1, 1, 3, 4)
		bar = UiTheme.box(UiTheme.SHEET_ACTION, Rect2(13, 13, 166, 19), 5, 5, 5, 5)
		button = UiTheme.box(UiTheme.SHEET_BUTTONS, Rect2(18, 500, 43, 14), 3, 3, 3, 4)
		button_hover = UiTheme.box(UiTheme.SHEET_BUTTONS, Rect2(114, 500, 43, 14), 3, 3, 3, 4)
		button_pressed = UiTheme.box(UiTheme.SHEET_BUTTONS, Rect2(66, 500, 43, 14), 3, 4, 3, 3)
		button_disabled = UiTheme.box(UiTheme.SHEET_BUTTONS, Rect2(18, 500, 43, 14), 3, 3, 3, 4)
		button_disabled.modulate_color = Color(0.6, 0.6, 0.6, 0.8)


## StyleBoxTexture 9-slice dari satu bagian sheet. l/t/r/b = lebar bingkai yang tidak ikut melar.
static func box(sheet: String, region: Rect2, l: int, t: int, r: int, b: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(sheet)
	s.region_rect = region
	s.texture_margin_left = l
	s.texture_margin_top = t
	s.texture_margin_right = r
	s.texture_margin_bottom = b
	s.content_margin_left = l + 3
	s.content_margin_top = t + 1
	s.content_margin_right = r + 3
	s.content_margin_bottom = b + 1
	return s


## Ikon kecil dari sheet (mis. kotak centang).
static func icon(sheet: String, region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = load(sheet)
	a.region = region
	return a


## Menggambar jendela berjudul: kertas + pita hijau + teks judul di tengah pita.
static func draw_window(ci: CanvasItem, skin: UiSkin, rect: Rect2, title: String, title_size: int = FS) -> void:
	ci.draw_style_box(skin.window, rect)
	if title != "":
		var font := ThemeDB.fallback_font
		ci.draw_string(font, rect.position + Vector2(0, 12), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, title_size, TITLE)


## Slot item: kotak slot pack + bingkai hijau jika terpilih + terang jika disorot.
static func draw_slot(ci: CanvasItem, skin: UiSkin, rect: Rect2, selected: bool = false, hover: bool = false) -> void:
	ci.draw_style_box(skin.slot, rect)
	if hover:
		ci.draw_rect(rect.grow(-2.0), SLOT_HOVER)
	if selected:
		ci.draw_rect(rect.grow(-0.5), SELECT, false, 2.0)


## Phase 19: potong teks dengan ".." agar muat di lebar `width` (piksel) pada ukuran `font_size`.
static func fit(text: String, width: float, font_size: int = FS) -> String:
	var font := ThemeDB.fallback_font
	if width <= 0.0 or font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return text
	var t := text
	while t.length() > 1 and font.get_string_size(t + "..", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		t = t.substr(0, t.length() - 1)
	return t.strip_edges() + ".."


## Angka jumlah item (putih bergaris hitam) di pojok kanan bawah slot.
static func draw_count(ci: CanvasItem, rect: Rect2, count: int) -> void:
	if count <= 1:
		return
	var font := ThemeDB.fallback_font
	var pos := rect.position + Vector2(0, rect.size.y - 2)
	ci.draw_string_outline(font, pos, str(count), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2, UiTheme.FS, 3, Color.BLACK)
	ci.draw_string(font, pos, str(count), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2, UiTheme.FS, Color.WHITE)


## Tombol hijau yang digambar manual (untuk panel _draw).
static func draw_button(ci: CanvasItem, skin: UiSkin, rect: Rect2, text: String, hover: bool = false, font_size: int = FS) -> void:
	ci.draw_style_box(skin.button_hover if hover else skin.button, rect)
	var font := ThemeDB.fallback_font
	var y := rect.position.y + floorf(rect.size.y / 2.0) + 5.0
	ci.draw_string(font, Vector2(rect.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, TITLE)


## Bilah progres: alur cokelat tua + isi berwarna.
static func draw_progress(ci: CanvasItem, rect: Rect2, ratio: float, color: Color) -> void:
	ci.draw_rect(rect.grow(1.0), COL_BORDER)
	ci.draw_rect(rect, Color(0.55, 0.40, 0.26))
	ci.draw_rect(Rect2(rect.position, Vector2(roundf(rect.size.x * clampf(ratio, 0.0, 1.0)), rect.size.y)), color)


## Theme untuk Control biasa (tombol, panel, label, slider, centang, dropdown).
static func build() -> Theme:
	var skin := UiSkin.new()
	var t := Theme.new()
	t.default_font_size = FS
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, skin.button)
		t.set_stylebox("hover", type, skin.button_hover)
		t.set_stylebox("pressed", type, skin.button_pressed)
		t.set_stylebox("hover_pressed", type, skin.button_pressed)
		t.set_stylebox("disabled", type, skin.button_disabled)
		t.set_stylebox("focus", type, _focus_box())
		t.set_color("font_color", type, TITLE)
		t.set_color("font_hover_color", type, TITLE)
		t.set_color("font_focus_color", type, TITLE)
		t.set_color("font_pressed_color", type, TITLE)
		t.set_color("font_hover_pressed_color", type, TITLE)
		t.set_color("font_disabled_color", type, Color(0.2, 0.2, 0.2, 0.6))
		t.set_font_size("font_size", type, FS)
	# CheckButton: kotak centang cokelat dari Settings.png
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		t.set_stylebox(state, "CheckButton", empty)
	t.set_stylebox("focus", "CheckButton", _focus_box())
	var on := icon(SHEET_SETTINGS, Rect2(192, 195, 11, 12))
	var off := icon(SHEET_SETTINGS, Rect2(192, 211, 11, 12))
	t.set_icon("checked", "CheckButton", on)
	t.set_icon("unchecked", "CheckButton", off)
	t.set_icon("checked_disabled", "CheckButton", on)
	t.set_icon("unchecked_disabled", "CheckButton", off)
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_stylebox("panel", "Panel", skin.paper)
	var window := skin.window.duplicate() as StyleBoxTexture
	window.content_margin_top = 1  # baris pertama (judul) duduk di atas pita hijau
	window.content_margin_left = 10
	window.content_margin_right = 10
	window.content_margin_bottom = 9
	t.set_stylebox("panel", "PanelContainer", window)
	t.set_stylebox("panel", "PopupMenu", skin.paper)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", ACCENT)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.36, 0.82, 0.48, 0.35)
	t.set_stylebox("hover", "PopupMenu", hover)
	t.set_color("font_color", "Label", TEXT)
	t.set_constant("outline_size", "Label", 0)
	# Slider: alur papan cokelat + pegangan kotak hijau
	var track := skin.wood.duplicate() as StyleBoxTexture
	track.texture_margin_top = 3
	track.texture_margin_bottom = 3
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.36, 0.70, 0.45)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grab := icon(SHEET_SETTINGS, Rect2(128, 195, 11, 12))
	t.set_icon("grabber", "HSlider", grab)
	t.set_icon("grabber_highlight", "HSlider", icon(SHEET_SETTINGS, Rect2(160, 195, 11, 12)))
	return t


static func _focus_box() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color(1.0, 0.95, 0.6)
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(1)
	return focus


## Label dengan ukuran dan warna tertentu (default: teks cokelat tua untuk panel kertas).
static func label(text: String, font_size: int = FS, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l
