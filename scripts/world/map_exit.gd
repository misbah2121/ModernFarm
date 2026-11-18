@tool
class_name MapExit
extends Area2D
## Pintu keluar peta. Saat player masuk, memancarkan signal player_entered.
## @tool: kotak collision ikut terlihat (biru) di editor dan menyesuaikan `size` saat diubah.

signal player_entered(target_map: String)

@export var target_map: String = "village"
@export var size: Vector2 = Vector2(16, 48):
	set(value):
		size = value
		_update_shape()


func _ready() -> void:
	_update_shape()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


## Memakai CollisionShape2D anak bernama "Shape" (dibuat jika belum ada).
func _update_shape() -> void:
	if not is_inside_tree():
		return
	var shape := get_node_or_null("Shape") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "Shape"
		add_child(shape)
	var rect := shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		shape.shape = rect
	rect.size = size


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered.emit(target_map)
