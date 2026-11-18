extends Node2D
## Scene utama: menampung peta aktif, efek waktu/cuaca, dan HUD
## (info, jam, gold, toast, hotbar, inventory, dialog, toko, mini game memancing,
## fade tidur & pindah peta). Phase 8: FishingController mengatur alur memancing.
## Phase 10: peta Forest & Mine, Axe & Pickaxe memukul ResourceNode (pohon / batu / bijih).
## Phase 11: tugas (QuestManager + QuestLog, tombol J), acara kalender (EventManager, pengumuman pagi),
## jadwal NPC (VillageMap), jam buka toko.
## Phase 12: simpan/muat (SaveManager; simpan otomatis tiap pagi), menu pause (ESC), stamina,
## musik per peta & suara hujan (AudioManager), bantuan kontrol (F1).
## Phase 18: dapur (Kompor Batu -> HUD/CookPanel), bonus makanan (HUD/BuffLabel),
## penanda interaksi di atas benda (InteractHint), barang jatuh (ItemPickup).
## Semua peta dibuat sekali dan disimpan di `maps`; peta yang tidak aktif dilepas dari tree
## (tanaman, tanah, NPC, hewan, dan batu yang sudah dipecah tetap tersimpan).

## Peta selain Farm (Farm sudah ada di main.tscn). Kunci = nama peta yang dipakai MapExit.target_map.
const MAP_SCENES := {
	"village": preload("res://scenes/village/village.tscn"),
	"forest": preload("res://scenes/forest/forest.tscn"),
	"mine": preload("res://scenes/mine/mine.tscn"),
	"barn": preload("res://scenes/interiors/barn.tscn"),  # Phase 16: dalam gudang
}

@onready var farm: FarmMap = $Farm
@onready var info_label: Label = $HUD/InfoLabel
@onready var clock_label: Label = $HUD/ClockLabel
@onready var toast_label: Label = $HUD/ToastLabel
@onready var inventory_panel: InventoryPanel = $HUD/InventoryPanel
@onready var dialogue_box: DialogueBox = $HUD/DialogueBox
@onready var shop_panel: ShopPanel = $HUD/ShopPanel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var fishing: FishingController = $FishingController
@onready var quest_log: QuestLog = $HUD/QuestLog
@onready var world_map: WorldMap = $HUD/WorldMap
@onready var craft_panel: CraftPanel = $HUD/CraftPanel
@onready var chest_panel: ChestPanel = $HUD/ChestPanel
@onready var cook_panel: CraftPanel = $HUD/CookPanel        # Phase 18: panel masak (script CraftPanel, station = cook)
@onready var buff_label: Label = $HUD/BuffLabel             # Phase 18: bonus makanan aktif
@onready var board_panel: FarmBoardPanel = $HUD/FarmBoardPanel   # Phase 19: pekerja & traktor
@onready var stall_panel: StallPanel = $HUD/StallPanel        # Phase 22: kios pasar
@onready var hint: InteractHint = $HintLayer/InteractHint   # Phase 18: penanda interaksi (CanvasLayer ikut kamera, tidak digelapkan malam)
@onready var quest_label: Label = $HUD/QuestLabel
@onready var event_label: Label = $HUD/EventLabel
@onready var pause_menu: PauseMenu = $HUD/PauseMenu
@onready var touch_controls: TouchControls = $HUD/TouchControls
@onready var fade: ColorRect = $FadeLayer/Fade

var village: VillageMap
## "farm" / "village" / "forest" / "mine" -> node peta.
var maps: Dictionary = {}
var current_map: Node2D
var _player: Player  # player milik peta aktif
var _talking_npc: Npc

var _fps_timer := 0.0
var _toast_tween: Tween
var _sleeping := false
var _changing_map := false
var _pending_event: EventData  # pengumuman acara yang menunggu sampai bangun tidur
var _notice_open := false
var _show_help := false
var _active_stove: KitchenStove  # dapur yang sedang dipakai (untuk asap)


func _ready() -> void:
	# Peta lain dibangun sekali (_ready berjalan saat masuk tree), lalu dilepas sampai dikunjungi.
	maps["farm"] = farm
	for map_name: String in MAP_SCENES:
		var map: Node2D = (MAP_SCENES[map_name] as PackedScene).instantiate()
		add_child(map)
		remove_child(map)
		maps[map_name] = map
	village = maps["village"] as VillageMap
	current_map = farm
	_player = farm.player

	for map_name: String in maps:
		var map: Node2D = maps[map_name]
		var map_player: Player = map.player
		map.exit_reached.connect(_on_map_exit.bind(map_name))
		map_player.interact_requested.connect(_on_interact)
		map_player.fish_requested.connect(_try_fish)
		map_player.tool_used.connect(_on_tool_used)
		map_player.place_requested.connect(_on_place_requested)
	farm.soil.message.connect(_show_toast)
	InventoryManager.message.connect(_show_toast)
	inventory_panel.opened.connect(_on_inventory_opened)
	inventory_panel.closed.connect(_on_inventory_closed)
	dialogue_box.finished.connect(_on_dialogue_finished)
	dialogue_box.shop_requested.connect(_open_shop)
	shop_panel.opened.connect(_on_menu_opened)
	shop_panel.closed.connect(_on_menu_closed)
	GameManager.gold_changed.connect(func(_g: int) -> void: _refresh_gold())
	fishing.message.connect(_show_toast)
	# Phase 11: laporan kegiatan untuk tugas, daftar tugas, acara.
	farm.soil.crop_harvested.connect(func(crop: CropData) -> void: QuestManager.report(QuestData.Kind.HARVEST, crop.id, 1))
	fishing.fish_caught.connect(_on_fish_caught)
	QuestManager.message.connect(_show_toast)
	QuestManager.quest_changed.connect(func(_q: QuestData) -> void: _refresh_quests())
	InventoryManager.inventory_changed.connect(_refresh_quests)
	quest_log.opened.connect(_on_menu_opened)
	quest_log.closed.connect(_on_menu_closed)
	world_map.opened.connect(_on_menu_opened)
	world_map.closed.connect(_on_menu_closed)
	# Phase 14: kerajinan & peti
	craft_panel.opened.connect(_on_menu_opened)
	craft_panel.closed.connect(_on_menu_closed)
	craft_panel.message.connect(_show_toast)
	chest_panel.opened.connect(_on_menu_opened)
	chest_panel.closed.connect(_on_menu_closed)
	# Phase 18: dapur, bonus makanan, penanda interaksi
	cook_panel.opened.connect(_on_menu_opened)
	cook_panel.closed.connect(_on_menu_closed)
	cook_panel.message.connect(_show_toast)
	cook_panel.crafted.connect(func(_r: RecipeData) -> void:
		AudioManager.play_sfx("harvest")
		if is_instance_valid(_active_stove):
			_active_stove.puff())
	GameManager.buffs_changed.connect(_refresh_buffs)
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void:
		GameManager.update_buffs()
		_refresh_buffs())
	hint.main = self
	# Phase 19: Papan Farm
	board_panel.opened.connect(_on_menu_opened)
	board_panel.closed.connect(_on_menu_closed)
	board_panel.message.connect(_show_toast)
	# Phase 22: kios pasar
	stall_panel.opened.connect(_on_menu_opened)
	stall_panel.closed.connect(_on_menu_closed)
	if farm.stall != null:
		farm.stall.message.connect(_show_toast)
	EventManager.event_started.connect(_on_event_started)
	TimeManager.day_started.connect(func(_d: int) -> void: _refresh_event())
	TimeManager.time_changed.connect(func(_h: int, _m: int) -> void: _refresh_clock())
	TimeManager.weather_changed.connect(func(_w: int) -> void:
		_refresh_clock()
		_refresh_ambient())
	TimeManager.bedtime_reached.connect(func() -> void: _begin_sleep("Kamu kelelahan dan tertidur...", true))
	GameManager.message.connect(_show_toast)
	AnimalManager.message.connect(_show_toast)  # Phase 23: anak lahir / dewasa, keledai
	pause_menu.save_requested.connect(_save_game)
	toast_label.modulate.a = 0.0
	_refresh_info()
	_refresh_clock()
	_refresh_gold()
	_refresh_quests()
	# Phase 12: pasang data dunia dari file simpanan, lalu mulai hari (acara, musik, suara hujan).
	if not SaveManager.pending_world.is_empty():
		apply_world(SaveManager.pending_world)
		SaveManager.pending_world = {}
	farm.ensure_starter_kitchen()  # Phase 18: satu Kompor Batu di dekat rumah
	farm.ensure_starter_board()    # Phase 19: Papan Farm di dekat rumah
	farm.ensure_starter_orchard()  # Phase 21: deretan pohon buah di tepi halaman
	_refresh_buffs()
	EventManager.begin(SaveManager.is_new_game)
	_refresh_event()
	_refresh_clock()
	AudioManager.play_music(_map_name(current_map))
	_refresh_ambient()


## Peta yang sedang tidak aktif dilepas dari tree, jadi harus dibebaskan manual saat keluar game.
func _exit_tree() -> void:
	for map: Node2D in maps.values():
		if is_instance_valid(map) and map.get_parent() == null:
			map.free()


func _process(delta: float) -> void:
	# Phase 13: kontrol sentuh menyesuaikan diri dengan panel yang sedang terbuka.
	touch_controls.set_state(
		inventory_panel.visible or shop_panel.visible or quest_log.visible or pause_menu.visible or world_map.visible \
			or craft_panel.visible or chest_panel.visible or cook_panel.visible or board_panel.visible or stall_panel.visible,
		dialogue_box.active)
	hint.refresh(_player, current_map, _can_open_menu() and not _panel_open() and not _notice_open and not _player._busy and _player.vehicle == null)
	_fps_timer += delta
	if _fps_timer >= 0.5:
		_fps_timer = 0.0
		_refresh_info()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _can_open_menu() and not _panel_open() and not _notice_open:
		pause_menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("help"):
		_show_help = not _show_help
		_refresh_info()
	elif event.is_action_pressed("debug_next_day"):
		_begin_sleep("Tidur...")
	elif event.is_action_pressed("inventory") and _can_open_menu() and not _panel_open(inventory_panel):
		AudioManager.play_sfx("ui_close" if inventory_panel.visible else "ui_open")
		inventory_panel.toggle()
	elif event.is_action_pressed("quest_log") and _can_open_menu() and not _panel_open(quest_log):
		AudioManager.play_sfx("ui_close" if quest_log.visible else "ui_open")
		quest_log.toggle()
	elif event.is_action_pressed("world_map") and _can_open_menu() and not _panel_open():
		AudioManager.play_sfx("ui_open")
		var location := _map_name(current_map)
		if current_map is InteriorMap:
			location = (current_map as InteriorMap).world_location
		world_map.open(location)
	elif event.is_action_pressed("craft") and _can_open_menu() and not _panel_open():
		AudioManager.play_sfx("ui_open")
		craft_panel.open()
	elif event.is_action_pressed("pause") and inventory_panel.visible:
		inventory_panel.close()


func _refresh_info() -> void:
	if _show_help:
		info_label.add_theme_font_size_override("font_size", UiTheme.FS)
		info_label.text = "WASD jalan | 1-8 pilih | SPACE alat / makan / pancing\nE bicara / pungut / panen / tidur | I tas | J tugas | M peta | C buat | ESC menu\nF1 tutup bantuan | Debug: F2 item uji, N tidur | FPS %d" % Engine.get_frames_per_second()
	else:
		info_label.add_theme_font_size_override("font_size", UiTheme.FS)
		info_label.text = "MODERN FARM\nF1: bantuan kontrol"


func _refresh_clock() -> void:
	clock_label.text = "%s %d - Tahun %d\n%s   %s" % [
		TimeManager.season_name().capitalize(), TimeManager.day_of_season(), TimeManager.year(),
		TimeManager.clock_text(), TimeManager.weather_name(),
	]


## Ada panel layar penuh yang terbuka (selain `except`)?
func _panel_open(except: Control = null) -> bool:
	for panel: Control in [inventory_panel, quest_log, world_map, craft_panel, chest_panel, cook_panel, board_panel, stall_panel]:
		if panel != except and panel.visible:
			return true
	return false


func _can_open_menu() -> bool:
	return not _sleeping and not _changing_map and not dialogue_box.active and not shop_panel.visible \
		and not fishing.is_active() and not pause_menu.visible


func _refresh_ambient() -> void:
	if TimeManager.is_raining():
		AudioManager.play_ambient("rain")
	else:
		AudioManager.stop_ambient()


## Nama peta ("farm", "village", ...) dari node peta.
func _map_name(map: Node2D) -> String:
	for map_name: String in maps:
		if maps[map_name] == map:
			return map_name
	return "farm"


# ---------------------------------------------------------------- simpan / muat (Phase 12)

## Data dunia untuk SaveManager: peta & posisi player, tanah/tanaman, pohon/batu yang dipecah.
func collect_world() -> Dictionary:
	_dismount()  # Phase 19: jangan simpan sambil di atas traktor
	var resources := {}
	for map_name: String in maps:
		var objects: Node = (maps[map_name] as Node).get_node_or_null("Objects")
		if objects == null:
			continue
		var states := {}
		for node in objects.get_children():
			if node is ResourceNode:
				states[String(node.name)] = (node as ResourceNode).to_save()
		if not states.is_empty():
			resources[map_name] = states
	return {
		"map": _map_name(current_map),
		"x": _player.global_position.x,
		"y": _player.global_position.y,
		"facing": String(_player.facing),
		"soil": farm.soil.to_save(),
		"placed": farm.placed_to_save(),  # Phase 14: mesin & peti
		"kitchen_given": farm.kitchen_given,  # Phase 18
		"board_given": farm.board_given,  # Phase 19
		"orchard_given": farm.orchard_given,  # Phase 21
		"stall": farm.stall.state_to_save() if farm.stall != null else {},  # Phase 22
		"tractor": farm.tractor.to_save() if farm.tractor != null else {},  # Phase 19
		"interiors": _interiors_to_save(),  # Phase 16: isi peti di dalam gudang
		"resources": resources,
	}


func _interiors_to_save() -> Dictionary:
	var result := {}
	for map_name: String in maps:
		if maps[map_name] is InteriorMap:
			result[map_name] = (maps[map_name] as InteriorMap).to_save()
	return result


func apply_world(world: Dictionary) -> void:
	farm.soil.from_save(world.get("soil", {}))
	farm.placed_from_save(world.get("placed", []))
	farm.kitchen_given = bool(world.get("kitchen_given", false))
	farm.board_given = bool(world.get("board_given", false))
	farm.orchard_given = bool(world.get("orchard_given", false))
	if farm.stall != null and world.has("stall"):
		farm.stall.state_from_save(world["stall"])
	if farm.tractor != null:
		farm.tractor.from_save(world.get("tractor", {}))
	var interiors: Dictionary = world.get("interiors", {})
	for map_name: String in interiors:
		if maps.get(map_name) is InteriorMap:
			(maps[map_name] as InteriorMap).from_save(interiors[map_name])
	var resources: Dictionary = world.get("resources", {})
	for map_name: String in resources:
		if not maps.has(map_name):
			continue
		var objects: Node = (maps[map_name] as Node).get_node_or_null("Objects")
		var states: Dictionary = resources[map_name]
		for node_name: String in states:
			var node := objects.get_node_or_null(NodePath(node_name)) if objects != null else null
			if node is ResourceNode:
				(node as ResourceNode).from_save(states[node_name])
	# Pindah langsung ke peta tersimpan (tanpa fade).
	var target_name := String(world.get("map", "farm"))
	var target: Node2D = maps.get(target_name, farm)
	if target != current_map:
		remove_child(current_map)
		add_child(target)
		move_child(target, 0)
		current_map = target
		_player = target.player
		(_player.get_node("Camera2D") as Camera2D).make_current()
	_player.global_position = Vector2(float(world.get("x", _player.global_position.x)), float(world.get("y", _player.global_position.y)))
	_player.facing = StringName(String(world.get("facing", "down")))
	(_player.get_node("Camera2D") as Camera2D).reset_smoothing()


func _save_game() -> void:
	if SaveManager.save_game(collect_world()):
		_show_toast("Game tersimpan.")
	else:
		_show_toast("Gagal menyimpan game!")


## Pelacak tugas di HUD (maks. 2 tugas aktif).
func _refresh_quests() -> void:
	var lines: Array[String] = []
	for q in QuestManager.active_quests():
		if lines.size() >= 2:
			break
		var done := QuestManager.status(q) == QuestManager.Status.COMPLETE or QuestManager.progress(q) >= q.target_count
		lines.append("> %s  %s" % [q.title, "(lapor!)" if done else "%d/%d" % [QuestManager.progress(q), q.target_count]])
	quest_label.text = "\n".join(lines)


func _refresh_event() -> void:
	var today := EventManager.today
	event_label.text = "* %s *" % today.title if today != null else ""


func _on_fish_caught(fish: FishData) -> void:
	if fish.rarity != FishData.Rarity.JUNK:
		QuestManager.report(QuestData.Kind.FISH, fish.id, 1)


## Acara hari ini: pengumuman ditampilkan setelah bangun (atau langsung saat game dimulai).
func _on_event_started(event: EventData) -> void:
	_refresh_event()
	if _sleeping:
		_pending_event = event
	else:
		_show_event(event)


func _show_event(event: EventData) -> void:
	if dialogue_box.active:
		return
	inventory_panel.close()
	quest_log.close()
	world_map.close(true)
	craft_panel.close()
	chest_panel.close()
	cook_panel.close()
	board_panel.close()
	stall_panel.close()
	shop_panel.close()
	_notice_open = true
	TimeManager.paused = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	dialogue_box.start_notice(event.title, event.description)


## Phase 18: teks bonus makanan aktif di HUD (kanan atas, di bawah acara).
## Phase 19: turunkan player dari traktor (jika sedang mengemudi).
func _dismount() -> void:
	if _player != null and _player.vehicle != null:
		_player.vehicle.dismount()


func _refresh_buffs() -> void:
	var parts: Array[String] = []
	if GameManager.has_buff("speed"):
		parts.append("Jalan cepat %s" % GameManager.duration_text(GameManager.buff_minutes_left("speed")))
	if GameManager.has_buff("fishing"):
		parts.append("Mudah memancing %s" % GameManager.duration_text(GameManager.buff_minutes_left("fishing")))
	buff_label.text = "\n".join(parts)


func _refresh_gold() -> void:
	gold_label.text = "GOLD: %d" % GameManager.gold


# ---------------------------------------------------------------- interaksi

## Tombol E dari player peta mana pun.
func _on_interact(world_pos: Vector2, facing: StringName) -> void:
	if dialogue_box.active or shop_panel.visible or _sleeping or _changing_map:
		return
	if _player.vehicle != null:  # Phase 19: E di atas traktor = turun
		_dismount()
		_show_toast("Turun dari traktor.")
		return
	if current_map == farm:
		_on_farm_interact(world_pos, facing)
	elif current_map == village:
		_on_village_interact(world_pos, facing)
	elif current_map is InteriorMap:
		_on_interior_interact(world_pos)
	else:
		_on_wild_interact(world_pos)


## Phase 16: di dalam ruangan (gudang): E di depan peti = buka isi peti.
func _on_interior_interact(world_pos: Vector2) -> void:
	var chest := (current_map as InteriorMap).chest_at(world_pos)
	if chest != null:
		AudioManager.play_sfx("ui_open")
		chest_panel.open(chest)


## Phase 10: Forest / Mine -> pungut barang (buah, ranting), selain itu memancing.
func _on_wild_interact(world_pos: Vector2) -> void:
	var res := _resource_at(world_pos)
	if res != null and res.tool == ResourceNode.Tool.NONE:
		var text := res.pick()
		if text != "":
			_show_toast(text)
	elif res != null:
		_show_toast("Pakai %s (SPACE) untuk %s." % [ResourceNode.TOOL_NAMES[res.tool], res.resource_name.to_lower()])
	else:
		_try_fish(true)


## ResourceNode di peta aktif pada titik itu, atau null.
func _resource_at(world_pos: Vector2) -> ResourceNode:
	var objects := current_map.get_node_or_null("Objects")
	if objects == null:
		return null
	for node in objects.get_children():
		if node is ResourceNode and (node as ResourceNode).is_at(world_pos):
			return node as ResourceNode
	return null


## Phase 10: Axe / Pickaxe mengenai sesuatu (dipanggil pada frame pukulan animasi).
func _on_tool_used(tool: ToolData, _cell: Vector2i) -> void:
	var kind := ResourceNode.Tool.NONE
	if tool.kind == ToolData.Kind.AXE:
		kind = ResourceNode.Tool.AXE
	elif tool.kind == ToolData.Kind.PICKAXE:
		kind = ResourceNode.Tool.PICKAXE
	else:
		return  # alat pertanian ditangani FarmSoil
	var point := _player.global_position + (Player.INTERACT_OFFSET[_player.facing] as Vector2)
	if current_map == farm and farm.object_at(point) != null:
		_pick_up_placed(farm.object_at(point), tool.kind)
		return
	var res := _resource_at(point)
	if res == null:
		return
	var text := res.hit(kind)
	if text != "":
		_show_toast(text)


## Phase 14: SPACE sambil memegang mesin -> pasang di tile depan player (hanya di Farm).
## Phase 15: bibit pohon buah memakai jalur yang sama (ditanam sebagai FruitTree).
func _on_place_requested(item: ItemData, cell: Vector2i) -> void:
	if current_map != farm:
		_show_toast("%s hanya bisa dipasang di Farm." % item.item_name)
		return
	var reason := farm.place_object(item, cell)
	if reason != "":
		_show_toast(reason)
		return
	InventoryManager.consume_selected(1)
	if item.category == ItemData.Category.SEED:  # Phase 15: bibit pohon buah
		AudioManager.play_sfx("seed")
		_show_toast("%s ditanam. Dewasa dalam %d hari." % [item.item_name, FruitTree.GROW_DAYS])
		return
	AudioManager.play_sfx("hit_wood")
	_show_toast("%s dipasang. (Pukul dengan Pickaxe / Axe untuk mengambil kembali)" % item.item_name)


## Phase 14: mesin dipukul Pickaxe / Axe -> kembali ke tas (beserta isinya).
## Phase 15: pohon buah hanya dengan Axe; pohon besar menjadi kayu (bibitnya tidak kembali).
func _pick_up_placed(obj: PlacedObject, tool_kind: int) -> void:
	var reason := obj.accepts_tool(tool_kind)
	if reason == "":
		reason = obj.can_pick_up()
	if reason != "":
		_show_toast(reason)
		return
	var item := InventoryManager.get_item(obj.item_id)
	if obj.returns_self():
		if item == null or not InventoryManager.can_add(item, 1):
			_show_toast("Tas penuh.")
			return
		InventoryManager.add_item(item, 1)
	var got: Array[String] = []
	for extra: Array in obj.pick_up_items():
		InventoryManager.add_item_by_id(String(extra[0]), int(extra[1]))
		var extra_item := InventoryManager.get_item(String(extra[0]))
		if extra_item != null:
			got.append("%d %s" % [int(extra[1]), extra_item.item_name])
	farm.remove_object(obj)
	var name_text := obj.display_name()
	if name_text == "":
		name_text = item.item_name if item != null else "Objek"
	if obj.returns_self():
		_show_toast("%s diambil kembali." % name_text)
	else:
		_show_toast("%s ditebang. Dapat %s." % [name_text, ", ".join(got)])


func _on_farm_interact(world_pos: Vector2, _facing: StringName) -> void:
	if farm.is_house_door(world_pos):
		_begin_sleep("Tidur...")
		return
	# Phase 14: mesin / peti yang dipasang
	var placed := farm.object_at(world_pos)
	if placed is FarmBoard:  # Phase 19: Papan Farm
		AudioManager.play_sfx("ui_open")
		board_panel.open()
		return
	if placed is KitchenStove:  # Phase 18: dapur
		AudioManager.play_sfx("ui_open")
		_active_stove = placed as KitchenStove
		cook_panel.open()
		return
	if placed is StorageChest:
		AudioManager.play_sfx("ui_open")
		chest_panel.open(placed as StorageChest)
		return
	if placed != null:
		var text := placed.interact()
		if text != "":
			_show_toast(text)
		return
	# Phase 22: kios pasar
	if farm.stall != null and farm.stall.is_at(world_pos):
		AudioManager.play_sfx("ui_open")
		stall_panel.open(farm.stall)
		return
	# Phase 19: traktor & pekerja
	if farm.tractor != null and farm.tractor.is_at(world_pos):
		if FarmServices.tractor_level <= 0:
			_show_toast("Traktor rusak. Perbaiki lewat Papan Farm (dekat rumah): 2000 Gold + 5 Iron Ore.")
		else:
			farm.tractor.mount(_player)
			_show_toast("Naik traktor. WASD jalan, SPACE ganti alat (bajak), E turun.")
		return
	# Phase 20: anjing peliharaan, mangkuk, rumah anjing
	if farm.dog != null:
		if farm.dog.is_at(world_pos):
			_show_toast(farm.dog.pet(_player.global_position))
			return
		if farm.dog.bowl_at(world_pos):
			_use_dog_bowl()
			return
		if farm.dog.house_at(world_pos) and farm.dog.is_sleeping():
			_show_toast("%s tidur nyenyak di rumahnya. Zzz..." % AnimalManager.dog_name)
			return
	var worker_id := farm.workers.worker_at(world_pos)
	if worker_id != "":
		var w := FarmServices.worker(worker_id)
		_show_toast("%s (%s Lv %d): \"%s.\"" % [w["name"], w["role"], FarmServices.level_of(worker_id), FarmServices.task_of(worker_id)])
		return
	var animal := farm.animal_at(world_pos)
	if animal != null:
		_show_toast(AnimalManager.interact(animal.state))
	elif farm.is_feeder(world_pos):
		_use_feeder()
	else:
		_try_fish(true)  # E sambil memegang pancing di depan air = memancing


## Phase 20: E di mangkuk anjing sambil memegang Makanan Anjing = isi mangkuk.
func _use_dog_bowl() -> void:
	if AnimalManager.dog_fed:
		_show_toast("%s sudah makan hari ini." % AnimalManager.dog_name)
		return
	if AnimalManager.bowl_full:
		_show_toast("Mangkuk sudah terisi. %s akan segera makan." % AnimalManager.dog_name)
		return
	var item := InventoryManager.current_item()
	if item == null or item.id != AnimalManager.DOG_FOOD_ITEM:
		_show_toast("Mangkuk kosong. Pegang Makanan Anjing (beli di Barnaby) lalu tekan E.")
		return
	InventoryManager.consume_selected(1)
	AnimalManager.fill_bowl()
	AudioManager.play_sfx("pickup")
	_show_toast("Mangkuk diisi. %s berlari ke mangkuknya!" % AnimalManager.dog_name)


## Phase 9: E di tempat pakan sambil memegang Animal Feed = isi pakan.
func _use_feeder() -> void:
	var stack := InventoryManager.current_stack()
	if stack == null or stack.item.id != AnimalManager.FEED_ITEM:
		_show_toast("Tempat pakan: %d/%d. Pegang Animal Feed (dari Barnaby) untuk mengisi." % [
			AnimalManager.feeder_hay, AnimalManager.FEEDER_CAPACITY])
		return
	var added := AnimalManager.add_feed(stack.count)
	if added == 0:
		_show_toast("Tempat pakan sudah penuh (%d/%d)." % [AnimalManager.feeder_hay, AnimalManager.FEEDER_CAPACITY])
		return
	InventoryManager.consume_selected(added)
	_show_toast("Mengisi %d Animal Feed. Tempat pakan: %d/%d" % [added, AnimalManager.feeder_hay, AnimalManager.FEEDER_CAPACITY])


func _on_village_interact(world_pos: Vector2, _facing: StringName) -> void:
	var npc := village.npc_at(world_pos)
	if npc == null:
		var shop := village.shop_at(world_pos)
		if shop != null and not shop.is_open():
			_show_toast("%s tutup. Buka %s." % [shop.shop_name, shop.hours_text()])
		elif shop != null:
			_open_shop(shop)
		else:
			_try_fish(true)
		return
	_talking_npc = npc
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	TimeManager.paused = true
	npc.begin_talk(_player.global_position)
	dialogue_box.start(npc.data)


func _on_dialogue_finished() -> void:
	_notice_open = false
	if _talking_npc != null:
		_talking_npc.end_talk()
		_talking_npc = null
	TimeManager.paused = false
	_player.process_mode = Node.PROCESS_MODE_INHERIT


## Inventory terbuka: waktu berhenti dan player tidak bisa bergerak / memakai alat.
func _on_inventory_opened() -> void:
	_on_menu_opened()


func _on_inventory_closed() -> void:
	_on_menu_closed()


## SPACE (quiet = false) atau E (quiet = true) sambil memegang Fishing Rod.
func _try_fish(quiet: bool = false) -> void:
	if _sleeping or _changing_map or dialogue_box.active or shop_panel.visible or inventory_panel.visible:
		return
	fishing.try_start(_player, current_map, quiet)


func _open_shop(shop: ShopData) -> void:
	if shop == null or _sleeping or _changing_map:
		return
	inventory_panel.close()
	shop_panel.open(shop)


## Menu layar penuh (inventory / toko) terbuka: waktu berhenti dan player diam.
func _on_menu_opened() -> void:
	TimeManager.paused = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED


func _on_menu_closed() -> void:
	TimeManager.paused = false
	_player.process_mode = Node.PROCESS_MODE_INHERIT


# ---------------------------------------------------------------- pindah peta

## MapExit di peta `from_map` dimasuki player -> pindah ke `target_map`.
func _on_map_exit(target_map: String, from_map: String) -> void:
	if _player.vehicle != null:  # Phase 19: traktor hanya di Farm
		_show_toast("Traktor hanya untuk di Farm. Turun dulu (E).")
		return
	if not maps.has(target_map):
		_show_toast("Jalan menuju %s belum dibuka." % target_map.to_upper())
		return
	var target: Node2D = maps[target_map]
	_change_map(target, target.player, target.get_spawn(from_map))


func _change_map(target: Node2D, target_player: Player, spawn: Vector2) -> void:
	if _changing_map or _sleeping or target == current_map:
		return
	_changing_map = true
	TimeManager.paused = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.35)
	await tween.finished

	remove_child(current_map)
	target_player.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(target)
	move_child(target, 0)  # peta selalu di belakang efek dan HUD
	current_map = target
	_player = target_player
	_player.global_position = spawn
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.make_current()
	cam.reset_smoothing()
	AudioManager.play_music(_map_name(target))

	var tween_in := create_tween()
	tween_in.tween_property(fade, "color:a", 0.0, 0.35)
	await tween_in.finished
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	TimeManager.paused = false
	_changing_map = false


# ---------------------------------------------------------------- tidur

## passed_out = true: pingsan jam 2 pagi -> stamina hanya pulih setengah.
func _begin_sleep(text: String, passed_out: bool = false) -> void:
	if _sleeping or _changing_map:
		return
	pause_menu.close()
	fishing.cancel()
	_dismount()
	quest_log.close()
	world_map.close(true)
	craft_panel.close()
	chest_panel.close()
	inventory_panel.close()  # jika terbuka: kembalikan item di tangan, waktu & player aktif lagi
	shop_panel.close()
	dialogue_box.close()
	_sleeping = true
	TimeManager.paused = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_show_toast(text)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.7)
	await tween.finished
	TimeManager.sleep()  # ganti hari: tanaman tumbuh, cuaca baru, jam 06:00
	if passed_out:
		GameManager.stamina = 0
		GameManager.restore_stamina(floori(GameManager.MAX_STAMINA * 0.5))
	else:
		GameManager.restore_stamina(GameManager.MAX_STAMINA)
	_save_game()  # simpan otomatis setiap pagi
	await get_tree().create_timer(0.6).timeout
	var tween_out := create_tween()
	tween_out.tween_property(fade, "color:a", 0.0, 0.7)
	await tween_out.finished
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_sleeping = false
	if _pending_event != null:
		var event := _pending_event
		_pending_event = null
		_show_event(event)


func _show_toast(text: String) -> void:
	toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)
