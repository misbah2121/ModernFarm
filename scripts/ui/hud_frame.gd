class_name HudFrame
extends Control
## Bingkai kertas (asset RPG UI) di belakang label HUD, mis. jam & gold di kanan atas.
## Ukuran & posisi diatur dari Inspector (offset node). Tidak menangkap klik.

@export_enum("paper", "wood", "window") var style := "paper"

var _skin: UiTheme.UiSkin


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skin = UiTheme.UiSkin.new()
	queue_redraw()


func _draw() -> void:
	var box: StyleBox = _skin.paper
	if style == "wood":
		box = _skin.wood
	elif style == "window":
		box = _skin.window
	draw_style_box(box, Rect2(Vector2.ZERO, size))
