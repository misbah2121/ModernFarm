class_name Vfx
extends RefCounted
## Phase 17: efek visual kecil (VFX) yang dipakai banyak script. Semua fungsi static, tidak perlu node / autoload.
##   burst()      : percikan partikel piksel (tanah, air, serpih kayu, batu, daun, debu langkah).
##   ripple()     : riak lingkaran di air (pelampung pancing).
##   leaves()     : daun berguguran dari sheet asli Modern_Farm_vfx_Falling_Leaves_16x16.png.
##   pop_icon()   : ikon item melompat ke atas lalu hilang (panen).
##   sheet_loop() : AnimatedSprite2D berulang dari sheet efek (kilau tanaman siap panen).
## Partikel memakai CPUParticles2D tanpa tekstur = kotak 1-2 piksel, jadi tetap tajam seperti pixel art.
## Efek dipasang sebagai anak `parent` (biasanya layer Objects peta) dan menghapus dirinya sendiri setelah selesai.

enum Kind { DIRT, WATER, WOOD, STONE, LEAF, SPLASH, STEP, CROP }

const FX_DIR := "res://assets/modern_farm/effects/"
const LEAVES_GREEN := FX_DIR + "Modern_Farm_vfx_Falling_Leaves_16x16.png"
const LEAVES_YELLOW := FX_DIR + "Modern_Farm_vfx_Falling_Leaves_Yellow_16x16.png"
const LEAVES_BROWN := FX_DIR + "Modern_Farm_vfx_Falling_Leaves_Brown_16x16.png"
const GLITTER := FX_DIR + "Modern_Farm_vfx_Rare_Crop_Glitter_16x16.png"
const LEAVES_FRAME := Vector2i(48, 48)
const LEAVES_COUNT := 24

## Warna partikel per jenis (diambil dari palet asset Modern Farm).
const PALETTES := {
	Kind.DIRT: ["7a4b33", "9c6440", "b98257", "5e3a29"],
	Kind.WATER: ["5fcde4", "8fe3f0", "ffffff", "3ea0c9"],
	Kind.WOOD: ["a8703f", "c88d52", "7d4f2c", "e2b07a"],
	Kind.STONE: ["8b93a6", "b5bccb", "5f667a", "d8dce6"],
	Kind.LEAF: ["5aa543", "7cc957", "3d7d3a", "a3dd6e"],
	Kind.SPLASH: ["8fe3f0", "ffffff", "5fcde4", "c8f4fa"],
	Kind.STEP: ["d9c9a3", "c2b08a", "e9dcbc"],
	Kind.CROP: ["7cc957", "f6e27a", "ffffff"],
}

## amount, lifetime, kecepatan min/max, gravitasi, sebaran (derajat), ukuran maks
const SETTINGS := {
	Kind.DIRT: [10, 0.45, 35.0, 70.0, 260.0, 70.0, 2.0],
	Kind.WATER: [12, 0.45, 20.0, 55.0, 200.0, 80.0, 2.0],
	Kind.WOOD: [9, 0.5, 45.0, 85.0, 280.0, 75.0, 2.0],
	Kind.STONE: [9, 0.45, 45.0, 90.0, 300.0, 75.0, 2.0],
	Kind.LEAF: [8, 0.55, 25.0, 55.0, 120.0, 90.0, 2.0],
	Kind.SPLASH: [16, 0.55, 40.0, 80.0, 260.0, 45.0, 2.0],
	Kind.STEP: [3, 0.35, 6.0, 14.0, -10.0, 70.0, 1.0],
	Kind.CROP: [10, 0.6, 30.0, 60.0, 160.0, 80.0, 2.0],
}

static var _frames_cache := {}
static var _shadow_cache := {}


## Percikan partikel di `pos` (koordinat lokal `parent`). `up` = arah lontaran.
static func burst(parent: Node, pos: Vector2, kind: Kind, up := Vector2.UP) -> CPUParticles2D:
	if parent == null or not parent.is_inside_tree():
		return null
	var s: Array = SETTINGS[kind]
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 2
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.9
	p.amount = int(s[0])
	p.lifetime = float(s[1])
	p.direction = up
	p.spread = float(s[5])
	p.initial_velocity_min = float(s[2])
	p.initial_velocity_max = float(s[3])
	p.gravity = Vector2(0, float(s[4]))
	p.scale_amount_min = 1.0
	p.scale_amount_max = float(s[6])
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(3, 2)
	p.color_initial_ramp = _palette(PALETTES[kind])
	p.color_ramp = _fade()
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Riak air: lingkaran pipih yang membesar lalu memudar.
static func ripple(parent: Node, pos: Vector2, big := false) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var r := RippleFx.new()
	r.position = pos
	r.max_radius = 9.0 if big else 6.0
	parent.add_child(r)


## Percikan air besar + riak (pelampung jatuh, ikan menggigit, ikan ditarik).
static func splash(parent: Node, pos: Vector2, big := false) -> void:
	burst(parent, pos, Kind.SPLASH)
	ripple(parent, pos, big)
	if big:
		burst(parent, pos + Vector2(0, -2), Kind.WATER)


## Daun berguguran (sheet asli). Warna mengikuti musim: gugur = kuning, dingin = coklat.
static func leaves(parent: Node, pos: Vector2) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var path := LEAVES_GREEN
	match TimeManager.season_name():
		"autumn":
			path = LEAVES_YELLOW
		"winter":
			path = LEAVES_BROWN
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = _sheet_frames(path, LEAVES_FRAME, LEAVES_COUNT, 18.0, false)
	spr.position = pos
	spr.z_index = 3
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(spr)
	spr.play(&"fx")
	spr.animation_finished.connect(spr.queue_free)
	var tween := spr.create_tween()
	tween.tween_interval(LEAVES_COUNT / 18.0 * 0.6)
	tween.tween_property(spr, "modulate:a", 0.0, LEAVES_COUNT / 18.0 * 0.4)


## Ikon item melompat dari `pos` lalu menghilang (dipakai saat panen).
static func pop_icon(parent: Node, pos: Vector2, icon: Texture2D) -> void:
	if parent == null or icon == null or not parent.is_inside_tree():
		return
	var spr := Sprite2D.new()
	spr.texture = icon
	spr.position = pos
	spr.z_index = 20
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(spr)
	var tween := spr.create_tween()
	tween.tween_property(spr, "position:y", pos.y - 24.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "position:y", pos.y - 20.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(spr, "modulate:a", 0.0, 0.25)
	tween.tween_callback(spr.queue_free)


## Kilau tanaman siap panen (Rare_Crop_Glitter, 8 frame 16x16) yang berulang dengan jeda.
static func glitter() -> AnimatedSprite2D:
	var spr := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"fx")
	frames.set_animation_speed(&"fx", 10.0)
	frames.set_animation_loop(&"fx", true)
	var sheet: Texture2D = load(GLITTER)
	for i in 8:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 16, 0, 16, 16)
		frames.add_frame(&"fx", atlas)
	var blank := AtlasTexture.new()  # pojok kiri atas frame 0 = piksel transparan
	blank.atlas = sheet
	blank.region = Rect2(0, 0, 1, 1)
	frames.add_frame(&"fx", blank, 25.0)  # jeda kosong ~2.5 detik sebelum berkilau lagi
	spr.sprite_frames = frames
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	return spr


## Uap / asap tipis yang terus keluar (mesin bekerja). Atur `emitting` untuk menyalakan / mematikan.
static func steam() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 6
	p.lifetime = 1.4
	p.direction = Vector2.UP
	p.spread = 20.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 12.0
	p.gravity = Vector2(2, -6)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color_initial_ramp = _palette(["e9eef2", "cfd6dc", "ffffff"])
	p.color_ramp = _fade()
	p.z_index = 2
	p.emitting = false
	return p


## Phase 18: bayangan elips gelap transparan (di bawah karakter, hewan, barang jatuh) seperti gambar referensi.
## Digambar per piksel (tanpa blur) agar tetap pixel art. Hasil di-cache per lebar.
static func shadow_texture(width: int) -> Texture2D:
	if _shadow_cache.has(width):
		return _shadow_cache[width]
	var h := maxi(3, roundi(width * 0.4))
	var img := Image.create(width, h, false, Image.FORMAT_RGBA8)
	var c := Vector2((width - 1) / 2.0, (h - 1) / 2.0)
	for y in h:
		for x in width:
			var d := pow((x - c.x) / (width / 2.0), 2) + pow((y - c.y) / (h / 2.0), 2)
			if d <= 1.0:
				img.set_pixel(x, y, Color(0.08, 0.12, 0.1, 0.28 if d > 0.55 else 0.36))
	var tex := ImageTexture.create_from_image(img)
	_shadow_cache[width] = tex
	return tex


## Sprite2D bayangan siap pakai; `show_behind_parent` agar selalu di bawah gambar pemiliknya.
static func shadow(width: int, offset := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Shadow"
	s.texture = shadow_texture(width)
	s.position = offset
	s.show_behind_parent = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s


# ---------------------------------------------------------------- bantu

static func _palette(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offsets.append(float(i) / colors.size())
		cols.append(Color(String(colors[i])))
	g.offsets = offsets
	g.colors = cols
	return g


static func _fade() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	return g


static func _sheet_frames(path: String, frame: Vector2i, count: int, fps: float, loop: bool) -> SpriteFrames:
	var key := "%s|%d|%s" % [path, count, loop]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var sheet: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"fx")
	frames.set_animation_speed(&"fx", fps)
	frames.set_animation_loop(&"fx", loop)
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame.x, 0, frame.x, frame.y)
		frames.add_frame(&"fx", atlas)
	_frames_cache[key] = frames
	return frames
