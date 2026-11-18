class_name ResourceNode
extends Node2D
## Sumber daya di peta (Phase 10): pohon (Axe), batu & bijih (Pickaxe), atau barang pungut (tangan / E).
## Dipasang sebagai root scene di res://scenes/world/resources/*.tscn. Titik node = kaki objek.
## Isi scene: Sprite2D, dan (opsional) StaticBody2D/CollisionShape2D.
## Dipukul `hits` kali -> hilang dan memberi item -> muncul lagi setelah `respawn_days` hari.
## Phase 17: pohon (Axe) menjatuhkan daun saat dipukul (sheet Falling_Leaves asli); saat tumbang / batu pecah
## muncul serpihan besar (Vfx).

enum Tool { NONE, AXE, PICKAXE }

const TOOL_NAMES := ["tangan", "Axe", "Pickaxe"]

@export var resource_name: String = "Tree"
## Alat yang dibutuhkan. NONE = dipungut dengan tombol E.
@export var tool: Tool = Tool.AXE
@export var hits: int = 3
@export var drop_item: ItemData
@export var drop_min: int = 1
@export var drop_max: int = 1
## Item tambahan dengan peluang tertentu (mis. Crystal dari batu biasa).
@export var bonus_item: ItemData
@export_range(0.0, 1.0) var bonus_chance: float = 0.0
## Hari sampai muncul lagi setelah habis (0 = tidak muncul lagi).
@export var respawn_days: int = 3
## Area yang bisa dikenai alat / tangan, relatif terhadap titik node.
@export var hit_area: Rect2 = Rect2(-12, -16, 24, 18)

var broken: bool = false

var _hp := 0
var _days_left := 0
var _rng := RandomNumberGenerator.new()
var _sprite: Sprite2D
var _shapes: Array[CollisionShape2D] = []
var _shake: Tween
var _sprite_base := Vector2.ZERO


func _ready() -> void:
	_rng.randomize()
	_hp = hits
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		_sprite_base = _sprite.position
	for node in find_children("*", "CollisionShape2D", true, false):
		_shapes.append(node as CollisionShape2D)
	add_to_group(&"resource_node")
	TimeManager.day_started.connect(_on_day_started)


## Phase 22: tajuk pohon (Axe) jadi transparan saat player di belakangnya, seperti TreeProp di Farm.
var _player: Node2D


func _process(delta: float) -> void:
	if tool != Tool.AXE or broken or _sprite == null:
		return
	if _player == null:
		_player = get_parent().get_node_or_null("Player") as Node2D
		if _player == null:
			return
	var p := _player.global_position
	var rect := Rect2(global_position + _sprite.position, _sprite.get_rect().size).grow(-6.0)
	var behind := rect.has_point(p + Vector2(0, -10)) and p.y < global_position.y - 2.0
	_sprite.modulate.a = move_toward(_sprite.modulate.a, 0.45 if behind else 1.0, 6.0 * delta)


func is_at(world_pos: Vector2) -> bool:
	return not broken and Rect2(global_position + hit_area.position, hit_area.size).has_point(world_pos)


## Dipukul dengan alat. Mengembalikan pesan untuk toast ("" = tidak perlu pesan).
func hit(tool_used: Tool) -> String:
	if broken:
		return ""
	if tool_used != tool:
		return "%s butuh %s." % [resource_name, TOOL_NAMES[tool]]
	_hp -= 1
	_play_shake()
	if tool == Tool.AXE:
		Vfx.leaves(get_parent(), position + _canopy_point())
	if _hp > 0:
		return ""
	return _break()


## Dipungut dengan tombol E (hanya untuk tool == NONE).
func pick() -> String:
	if broken or tool != Tool.NONE:
		return ""
	return _break()


func _break() -> String:
	# Phase 18: hasil tidak langsung masuk tas, tetapi JATUH ke tanah (asset Pickup) lalu diambil player.
	var parts: Array[String] = []
	var drop_at := position + Vector2(0, -2)
	if drop_item != null:
		var amount := _rng.randi_range(drop_min, drop_max)
		ItemPickup.drop(get_parent(), drop_at, drop_item, amount, 14.0)
		parts.append("+%d %s" % [amount, drop_item.item_name])
	if bonus_item != null and _rng.randf() < bonus_chance:
		ItemPickup.drop(get_parent(), drop_at, bonus_item, 1, 14.0)
		parts.append("+1 %s" % bonus_item.item_name)
	_break_fx()
	_set_broken(true)
	_days_left = respawn_days
	AudioManager.play_sfx("pickup" if tool == Tool.NONE else "break")
	return "  ".join(parts)


## Titik tengah atas gambar (tajuk pohon / puncak batu), relatif ke node.
func _canopy_point() -> Vector2:
	if _sprite == null:
		return Vector2(0, -24)
	var rect := _sprite.get_rect()
	return _sprite.position + Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.35)


func _break_fx() -> void:
	var parent := get_parent()
	match tool:
		Tool.AXE:
			Vfx.leaves(parent, position + _canopy_point())
			Vfx.burst(parent, position + Vector2(0, -6), Vfx.Kind.WOOD)
			Vfx.burst(parent, position + Vector2(0, -10), Vfx.Kind.LEAF)
		Tool.PICKAXE:
			Vfx.burst(parent, position + Vector2(0, -6), Vfx.Kind.STONE)
			Vfx.burst(parent, position + Vector2(0, -4), Vfx.Kind.STEP)
		_:
			Vfx.burst(parent, position + Vector2(0, -4), Vfx.Kind.LEAF)


func _set_broken(value: bool) -> void:
	broken = value
	visible = not value
	for shape in _shapes:
		shape.set_deferred("disabled", value)
	if not value:
		_hp = hits


func _on_day_started(_total_day: int) -> void:
	if not broken or respawn_days <= 0:
		return
	_days_left -= 1
	if _days_left <= 0:
		_set_broken(false)


## Efek pukul: sheet pohon "Shake" punya 3 frame berjajar -> ganti frame; objek lain bergetar sedikit.
func _play_shake() -> void:
	if _sprite == null:
		return
	if _shake != null:
		_shake.kill()
	_shake = create_tween()
	var tex_w := _sprite.texture.get_width() if _sprite.texture != null else 0
	if _sprite.region_enabled and tex_w >= _sprite.region_rect.size.x * 3:
		var w := _sprite.region_rect.size.x
		for frame in [1, 2, 1, 0]:
			_shake.tween_callback(func() -> void: _sprite.region_rect.position.x = w * frame)
			_shake.tween_interval(0.06)
	else:
		for dx in [1.0, -1.0, 1.0, 0.0]:
			_shake.tween_callback(func() -> void: _sprite.position = _sprite_base + Vector2(dx, 0))
			_shake.tween_interval(0.04)


# ---------------------------------------------------------------- simpan (Phase 12)

func to_save() -> Dictionary:
	return {"broken": broken, "days_left": _days_left}


func from_save(d: Dictionary) -> void:
	_days_left = int(d.get("days_left", 0))
	_set_broken(bool(d.get("broken", false)))
