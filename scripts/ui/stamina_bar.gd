class_name StaminaBar
extends Control
## Bilah stamina (energi) di kanan bawah layar (Phase 12). Hijau -> kuning -> merah.
## Bingkai: papan kayu dari asset RPG UI (UiTheme.UiSkin.wood).

const BAR := Rect2(4, 14, 8, 58)

var _skin: UiTheme.UiSkin


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skin = UiTheme.UiSkin.new()
	GameManager.stamina_changed.connect(func(_v: int, _m: int) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var ratio := clampf(GameManager.stamina / float(GameManager.MAX_STAMINA), 0.0, 1.0)
	draw_style_box(_skin.header, Rect2(1, 0, 14, 12))
	draw_string(font, Vector2(1, 9), "E", HORIZONTAL_ALIGNMENT_CENTER, 14, UiTheme.FS, UiTheme.TITLE)
	draw_style_box(_skin.wood, BAR.grow(3.0))
	draw_rect(BAR, Color(0.18, 0.11, 0.07))
	var color := Color(1.0, 0.35, 0.3).lerp(Color(1.0, 0.85, 0.3), clampf(ratio * 2.0, 0.0, 1.0))
	if ratio > 0.5:
		color = Color(1.0, 0.85, 0.3).lerp(Color(0.45, 0.95, 0.4), (ratio - 0.5) * 2.0)
	var h := roundf(BAR.size.y * ratio)
	draw_rect(Rect2(BAR.position.x, BAR.end.y - h, BAR.size.x, h), color)
	draw_string_outline(font, Vector2(-4, BAR.end.y + 12), str(GameManager.stamina), HORIZONTAL_ALIGNMENT_CENTER, 24, UiTheme.FS, 3, Color.BLACK)
	draw_string(font, Vector2(-4, BAR.end.y + 12), str(GameManager.stamina), HORIZONTAL_ALIGNMENT_CENTER, 24, UiTheme.FS, Color.WHITE)
