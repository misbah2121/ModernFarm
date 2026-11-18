class_name AnimalFeeder
extends Node2D
## Tempat pakan hewan (Phase 9). Titik node = kaki (tengah bawah), sama seperti props lain.
## Sprite berganti Empty / Full sesuai AnimalManager.feeder_hay.
## Isi pakan: pegang Animal Feed, hadap tempat pakan, tekan E (diatur Main).

@export var empty_texture: Texture2D
@export var full_texture: Texture2D
## Area interaksi relatif terhadap titik node.
@export var interact_area: Rect2 = Rect2(-20, -28, 40, 36)

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	AnimalManager.changed.connect(_refresh)
	_refresh()


func is_at(world_pos: Vector2) -> bool:
	return Rect2(global_position + interact_area.position, interact_area.size).has_point(world_pos)


func _refresh() -> void:
	var tex := full_texture if AnimalManager.feeder_hay > 0 else empty_texture
	if tex == null:
		return
	sprite.texture = tex
	var size := tex.get_size()
	sprite.position = Vector2(-size.x / 2.0, -size.y)
