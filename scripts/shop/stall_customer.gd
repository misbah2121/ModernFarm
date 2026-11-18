class_name StallCustomer
extends Node2D
## Phase 22: warga desa yang datang ke Kios Pasar, membeli 1 barang, lalu pulang (hanya tampilan).
## Sprite dari sheet NPC asli (frame 16x32, baris 1 diam, baris 2 jalan, arah kanan/atas/kiri/bawah).
## Datang dari jalan ke Desa (kiri peta), berdiri di depan kios, membeli, lalu kembali dan menghilang.

const FRAME := Vector2i(16, 32)
const DIRS: Array[StringName] = [&"right", &"up", &"left", &"down"]
const SPEED := 34.0

var buyer_name := ""
var stall: MarketStall

var _sprite: AnimatedSprite2D
var _path: Array[Vector2] = []
var _state := 0   # 0 datang, 1 belanja, 2 pulang
var _wait := 0.0
var _facing: StringName = &"right"


func setup(sheet: Texture2D, p_name: String, p_stall: MarketStall) -> void:
	buyer_name = p_name
	stall = p_stall
	add_child(Vfx.shadow(12, Vector2(0, -1)))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _frames(sheet)
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)
	var front := stall.front_point()
	position = Vector2(-12, front.y + 4)
	_path = [Vector2(front.x - 20, front.y + 4), front]
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


func _process(delta: float) -> void:
	match _state:
		0, 2:
			if _path.is_empty():
				if _state == 0:
					_state = 1
					_wait = 1.6
					_facing = &"up"
					_play(&"idle")
				else:
					queue_free()
				return
			var goal: Vector2 = _path[0]
			var to := goal - position
			if to.length() < 1.5:
				_path.pop_front()
				return
			var step := to.normalized() * SPEED * delta
			position += step if step.length() < to.length() else to
			_facing = (&"right" if to.x > 0 else &"left") if absf(to.x) >= absf(to.y) else (&"down" if to.y > 0 else &"up")
			_play(&"walk")
		1:
			_wait -= delta
			if _wait <= 0.0:
				var item := stall.sell_one(buyer_name) if is_instance_valid(stall) else null
				if item != null:
					Vfx.pop_icon(get_parent(), position + Vector2(0, -36), item.pickup_texture if item.pickup_texture != null else item.icon)
				_state = 2
				_path = [position + Vector2(-20, 4), Vector2(-14, position.y + 4)]
				var t := create_tween()
				t.tween_interval(1.4)
				t.tween_property(self, "modulate:a", 0.0, 0.5)


func _play(state: StringName) -> void:
	var anim := StringName("%s_%s" % [state, _facing])
	if _sprite.animation != anim:
		_sprite.play(anim)


func _frames(sheet: Texture2D) -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	for a: Array in [[&"idle", 1, 6.0], [&"walk", 2, 8.0]]:
		for d in DIRS.size():
			var anim := StringName("%s_%s" % [a[0], DIRS[d]])
			f.add_animation(anim)
			f.set_animation_speed(anim, a[2])
			for i in 6:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.filter_clip = true
				atlas.region = Rect2((d * 6 + i) * FRAME.x, int(a[1]) * FRAME.y, FRAME.x, FRAME.y)
				f.add_frame(anim, atlas)
	return f
