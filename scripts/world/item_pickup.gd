class_name ItemPickup
extends Node2D
## Phase 18: barang yang JATUH ke tanah (kayu dari pohon, batu, hasil panen, buah, truffle, ...).
## Gambar memakai asset asli Pickup_*_16x16.png (ItemData.pickup_texture); jika kosong memakai icon item.
## Alur: terlempar keluar (lompatan melengkung) -> memantul kecil -> diam bergoyang pelan di atas bayangan
## -> saat player mendekat (MAGNET_RANGE) barang terbang ke player -> masuk tas.
## Tas penuh = barang tetap di tanah (coba lagi setelah ada slot kosong).
## Buat lewat ItemPickup.drop(parent, posisi, item, jumlah). parent = layer Objects (y-sort) peta.

signal collected(pickup: ItemPickup)

const MAGNET_RANGE := 26.0
const COLLECT_RANGE := 6.0
const FLY_SPEED := 160.0
const READY_DELAY := 0.45   # detik sebelum boleh diambil (biar terlihat jatuh dulu)

var item: ItemData
var count := 1
## Tetap tinggal walau tas penuh, dan ikut disimpan oleh pemiliknya (dipakai truffle).
var persistent := false
## Laporkan ke QuestManager (GATHER) saat diambil. Hasil panen sudah dilaporkan sebagai HARVEST.
var quest_gather := true

var _sprite: Sprite2D
var _shadow: Sprite2D
var _t := 0.0
var _ready_left := READY_DELAY
var _flying := false
var _full_warned := false


## Jatuhkan `count` barang di `pos` (koordinat lokal parent). Maksimal 4 sprite; sisanya ditumpuk di sprite terakhir.
static func drop(parent: Node, pos: Vector2, p_item: ItemData, p_count: int = 1, spread := 10.0) -> Array[ItemPickup]:
	var result: Array[ItemPickup] = []
	if parent == null or p_item == null or p_count <= 0:
		return result
	var pieces := mini(p_count, 4)
	for i in pieces:
		var p := ItemPickup.new()
		p.item = p_item
		p.count = 1 if i < pieces - 1 else p_count - (pieces - 1)
		p.position = pos
		parent.add_child(p)
		var angle := randf_range(0.0, TAU)
		var target := pos + Vector2(cos(angle), sin(angle) * 0.6) * randf_range(spread * 0.4, spread)
		p.toss_to(target.round())
		result.append(p)
	return result


func _ready() -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = Vfx.shadow_texture(10)
	_shadow.position = Vector2(0, -1)
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = item.pickup_texture if item.pickup_texture != null else item.icon
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)


## Lompatan melengkung dari posisi sekarang ke `target`.
func toss_to(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.4).set_trans(Tween.TRANS_SINE)
	var hop := create_tween()
	hop.tween_property(_sprite, "position:y", -22.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(_sprite, "position:y", -8.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hop.tween_property(_sprite, "position:y", -12.0, 0.08).set_ease(Tween.EASE_OUT)
	hop.tween_property(_sprite, "position:y", -8.0, 0.08).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	_t += delta
	if _ready_left > 0.0:
		_ready_left -= delta
		return
	if not _flying:
		_sprite.position.y = -8.0 + roundf(sin(_t * 3.0) * 1.0)  # goyang pelan
	var player := _find_player()
	if player == null:
		return
	var to_player := (player.position + Vector2(0, -6)) - position
	var dist := to_player.length()
	if not _flying and dist <= MAGNET_RANGE:
		if not InventoryManager.can_add(item, 1):
			if not _full_warned:
				_full_warned = true
				InventoryManager.message.emit("Tas penuh! %s tertinggal di tanah." % item.item_name)
			return
		_flying = true
	if not _flying:
		_full_warned = false
		return
	if dist <= COLLECT_RANGE:
		_collect()
		return
	position += to_player / dist * minf(FLY_SPEED * delta, dist)
	_shadow.visible = false


func _collect() -> void:
	var left := InventoryManager.add_item(item, count)
	var got := count - left
	if got > 0 and quest_gather:
		QuestManager.report(QuestData.Kind.GATHER, item.id, got)
	if got > 0:
		AudioManager.play_sfx("pickup", 0.1, -4.0)
	if left > 0:
		count = left  # sebagian masuk; sisanya tetap di tanah
		_flying = false
		_shadow.visible = true
		return
	collected.emit(self)
	queue_free()


## Player ada di layer yang sama (Objects/Player) di semua peta.
func _find_player() -> Node2D:
	var parent := get_parent()
	return parent.get_node_or_null("Player") as Node2D if parent != null else null
