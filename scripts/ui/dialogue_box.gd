class_name DialogueBox
extends Control
## Kotak dialog NPC (Phase 6). Dibuat lewat kode: potret kepala NPC, nama, friendship,
## teks dengan efek mengetik, banyak halaman, dan pilihan.
## Kontrol: E = lanjut / pilih (jika teks masih mengetik: tampilkan semua), W/S atau panah = geser pilihan,
## ESC = tutup. Tombol 1-8 tetap bisa memilih item hotbar untuk dijadikan hadiah.
## Phase 7: NPC pemilik toko (NpcData.shop) punya pilihan "Belanja" -> dialog ditutup lalu
## signal shop_requested dipancarkan (Main membuka ShopPanel).
## Phase 11: pilihan tugas ("Tugas: ...", "Serahkan ...", "Laporkan ...") dari QuestManager,
## toko punya jam buka, dan start_notice() untuk pengumuman acara (tanpa NPC).

signal finished
signal shop_requested(shop: ShopData)

const CHARS_PER_SECOND := 45.0
const PANEL_RECT := Rect2(40, 232, 560, 98)
const TEXT_LEFT := 76.0
## Warna teks di atas kertas krem (asset RPG UI, lihat UiTheme).
const COL_GOLD := UiTheme.ACCENT
const COL_TEXT := UiTheme.TEXT

enum Mode { CLOSED, TEXT, CHOICES }

var active := false

var _npc: NpcData
var _mode: Mode = Mode.CLOSED
var _pages: Array[String] = []
var _page := 0
var _choices_after := true   # setelah halaman terakhir: true = tampilkan pilihan, false = tutup
var _choice := 0
var _typed := 0.0
var _choice_texts: Array[String] = []
var _choice_ids: Array[StringName] = []  # &"bio", &"gift", &"quest", &"shop", &"bye"
var _frame: Panel

var _panel: Panel
var _portrait: TextureRect
var _name_label: Label
var _friend_label: Label
var _text_label: Label
var _choice_box: VBoxContainer
var _choice_labels: Array[Label] = []
var _hint_label: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	InventoryManager.selected_changed.connect(func(_i: int) -> void: _refresh_choices())
	InventoryManager.inventory_changed.connect(_refresh_choices)


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.gui_input.connect(_on_panel_input)
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	var skin := UiTheme.UiSkin.new()
	# Jendela kertas dengan pita hijau (nama NPC ditulis di pita).
	_panel.add_theme_stylebox_override("panel", skin.window)
	add_child(_panel)

	# Potret: kepala NPC diperbesar 3x (nearest karena default filter project = nearest).
	var frame := Panel.new()
	_frame = frame
	frame.position = Vector2(8, 20)
	frame.size = Vector2(60, 60)
	frame.add_theme_stylebox_override("panel", skin.slot)
	_panel.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.size = Vector2(16, 14)  # ukuran asli potret (16x14 px)
	_portrait.scale = Vector2(3, 3)   # kelipatan bulat agar piksel tetap tajam
	_portrait.position = Vector2(5, 8)
	frame.add_child(_portrait)

	_name_label = _make_label(UiTheme.FS, UiTheme.TITLE)
	_name_label.position = Vector2(TEXT_LEFT, -1)
	_name_label.size = Vector2(200, 14)
	_panel.add_child(_name_label)

	_friend_label = _make_label(UiTheme.FS, UiTheme.TITLE)
	_friend_label.position = Vector2(PANEL_RECT.size.x - 208, 1)
	_friend_label.size = Vector2(200, 12)
	_friend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel.add_child(_friend_label)

	_text_label = _make_label(UiTheme.FS, COL_TEXT)
	_text_label.position = Vector2(TEXT_LEFT, 20)
	_text_label.size = Vector2(PANEL_RECT.size.x - TEXT_LEFT - 12, 58)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_text_label)

	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(TEXT_LEFT, 18)
	_choice_box.size = Vector2(PANEL_RECT.size.x - TEXT_LEFT - 12, 62)
	_choice_box.add_theme_constant_override("separation", 0)
	_panel.add_child(_choice_box)
	_choice_box.mouse_filter = Control.MOUSE_FILTER_PASS
	for i in 5:
		var label := _make_label(UiTheme.FS, COL_TEXT)
		# Phase 13: pilihan bisa diketuk / diklik.
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.gui_input.connect(_on_choice_input.bind(i))
		_choice_box.add_child(label)
		_choice_labels.append(label)

	_hint_label = _make_label(UiTheme.FS, UiTheme.TEXT_DIM)
	_hint_label.position = Vector2(PANEL_RECT.size.x - 208, PANEL_RECT.size.y - 16)
	_hint_label.size = Vector2(200, 12)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel.add_child(_hint_label)


## Ketuk kotak dialog = lanjut (sama dengan tombol E).
func _on_panel_input(event: InputEvent) -> void:
	if active and _mode == Mode.TEXT and event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_confirm()
		accept_event()


func _on_choice_input(event: InputEvent, index: int) -> void:
	if active and _mode == Mode.CHOICES and index < _choice_texts.size() and event is InputEventMouseButton \
			and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_choice = index
		_refresh_choices()
		_pick_choice(index)
		accept_event()


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	return label


# ---------------------------------------------------------------- alur dialog

## Mulai percakapan: sapaan (+1 friendship sekali sehari), lalu pilihan.
func start(npc: NpcData) -> void:
	_npc = npc
	active = true
	visible = true
	_frame.visible = true
	_text_label.position.x = TEXT_LEFT
	_name_label.position.x = TEXT_LEFT
	_portrait.texture = npc.get_portrait()
	_name_label.text = npc.npc_name
	var pages := _greeting_pages()
	if NpcManager.talk(npc.id):
		pages.append("(Friendship +%d)" % (NpcManager.TALK_POINTS * EventManager.talk_multiplier()))
	_refresh_friendship()
	_show_pages(pages, true)


## Pengumuman tanpa NPC (mis. acara kalender). Halaman dipisah "|".
func start_notice(title: String, text: String) -> void:
	_npc = null
	active = true
	visible = true
	_frame.visible = false
	_text_label.position.x = 12
	_name_label.position.x = 12
	_name_label.text = title
	_friend_label.text = ""
	var pages: Array[String] = []
	for part in text.split("|"):
		pages.append(part.strip_edges())
	_show_pages(pages, false)


func close() -> void:
	if not active:
		return
	active = false
	visible = false
	_mode = Mode.CLOSED
	finished.emit()


func _greeting_pages() -> Array[String]:
	var pool := _npc.greetings
	if TimeManager.is_raining() and not _npc.rain_lines.is_empty():
		pool = _npc.rain_lines
	elif NpcManager.friendship(_npc.id) >= NpcManager.FRIEND_THRESHOLD and not _npc.friend_lines.is_empty():
		pool = _npc.friend_lines
	if pool.is_empty():
		return _split_pages("...")
	return _split_pages(pool[randi() % pool.size()])


func _split_pages(text: String) -> Array[String]:
	var result: Array[String] = []
	for part in text.replace("{greet}", _time_greeting()).split("|"):
		result.append(part.strip_edges())
	return result


func _time_greeting() -> String:
	var h := TimeManager.hour()
	if h < 11:
		return "Selamat pagi"
	if h < 15:
		return "Selamat siang"
	if h < 18:
		return "Selamat sore"
	return "Selamat malam"


func _show_pages(pages: Array[String], then_choices: bool) -> void:
	_pages = pages
	_page = 0
	_choices_after = then_choices
	_mode = Mode.TEXT
	_show_page()


func _show_page() -> void:
	_text_label.text = _pages[_page]
	_text_label.visible_characters = 0
	_typed = 0.0
	_text_label.visible = true
	_choice_box.visible = false
	_hint_label.text = ""


func _show_choices() -> void:
	_mode = Mode.CHOICES
	_choice = 0
	_text_label.visible = false
	_choice_box.visible = true
	_hint_label.text = "W/S: geser   E: pilih"
	_refresh_choices()


func _refresh_choices() -> void:
	if not active or _mode != Mode.CHOICES:
		return
	var item := InventoryManager.current_item()
	var gift_text := "Beri hadiah (pilih item di hotbar: 1-8)"
	if item != null:
		gift_text = "Beri hadiah: %s" % item.item_name
	if _npc == null:
		return
	_choice_texts = ["Ceritakan tentang dirimu", gift_text]
	_choice_ids = [&"bio", &"gift"]
	var finish := QuestManager.finishable_from(_npc.id)
	var offer := QuestManager.offer_from(_npc.id)
	if finish != null:
		if finish.kind == QuestData.Kind.DELIVER:
			_choice_texts.append("Serahkan: %s" % finish.target_text().trim_prefix("Serahkan "))
		else:
			_choice_texts.append("Laporkan tugas: %s" % finish.title)
		_choice_ids.append(&"quest_finish")
	elif offer != null:
		_choice_texts.append("Tugas: %s" % offer.title)
		_choice_ids.append(&"quest_offer")
	if _npc.shop != null:
		if _npc.shop.is_open():
			_choice_texts.append("Belanja di %s" % _npc.shop.shop_name)
		else:
			_choice_texts.append("Belanja (tutup, buka %s)" % _npc.shop.hours_text())
		_choice_ids.append(&"shop")
	_choice_texts.append("Selesai")
	_choice_ids.append(&"bye")
	_choice = clampi(_choice, 0, _choice_texts.size() - 1)
	for i in _choice_labels.size():
		var label := _choice_labels[i]
		label.visible = i < _choice_texts.size()
		if not label.visible:
			continue
		var selected := i == _choice
		label.text = ("> " if selected else "   ") + _choice_texts[i]
		label.add_theme_color_override("font_color", COL_GOLD if selected else COL_TEXT)


func _refresh_friendship() -> void:
	var value := NpcManager.friendship(_npc.id)
	_friend_label.text = "Friendship: %d   Hati: %d/%d" % [
		value, NpcManager.hearts(_npc.id), floori(NpcManager.MAX_FRIENDSHIP / float(NpcManager.POINTS_PER_HEART)),
	]


func _process(delta: float) -> void:
	if not active or _mode != Mode.TEXT:
		return
	var total := _text_label.text.length()
	if _typed < total:
		_typed = minf(_typed + CHARS_PER_SECOND * delta, float(total))
		_text_label.visible_characters = int(_typed)
		if _typed >= total:
			_hint_label.text = "[E]"
	elif _hint_label.text == "":
		_hint_label.text = "[E]"


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact"):
		_confirm()
	elif event.is_action_pressed("pause"):
		close()
	elif _mode == Mode.CHOICES and event.is_action_pressed("move_up"):
		_choice = wrapi(_choice - 1, 0, _choice_texts.size())
		_refresh_choices()
	elif _mode == Mode.CHOICES and event.is_action_pressed("move_down"):
		_choice = wrapi(_choice + 1, 0, _choice_texts.size())
		_refresh_choices()
	else:
		return
	get_viewport().set_input_as_handled()


func _confirm() -> void:
	if _mode == Mode.TEXT:
		var total := _text_label.text.length()
		if _typed < total:
			_typed = float(total)  # tampilkan semua teks halaman ini
			_text_label.visible_characters = total
			_hint_label.text = "[E]"
			return
		_page += 1
		if _page < _pages.size():
			_show_page()
		elif _choices_after:
			_show_choices()
		else:
			close()
	elif _mode == Mode.CHOICES:
		_pick_choice(_choice)


func _pick_choice(index: int) -> void:
	AudioManager.play_sfx("ui_select")
	match _choice_ids[index]:
		&"bio":
			_show_pages(_split_pages(_npc.bio), true)
		&"gift":
			_give_gift()
		&"quest_offer":
			_offer_quest()
		&"quest_finish":
			_finish_quest()
		&"shop":
			var shop := _npc.shop
			if not shop.is_open():
				var closed_pages: Array[String] = ["Maaf, tokoku sedang tutup. Buka jam %s, ya." % shop.hours_text()]
				_show_pages(closed_pages, true)
				return
			close()  # dialog ditutup dulu (finished), baru toko dibuka
			shop_requested.emit(shop)
		_:
			close()


func _offer_quest() -> void:
	var quest := QuestManager.offer_from(_npc.id)
	if quest == null:
		_show_choices()
		return
	var pages := _split_pages(quest.offer_text if quest.offer_text != "" else quest.description)
	QuestManager.accept(quest)
	pages.append("(Tugas diterima: %s. Hadiah: %s)" % [quest.target_text(), quest.reward_text()])
	_show_pages(pages, true)


func _finish_quest() -> void:
	var quest := QuestManager.finishable_from(_npc.id)
	if quest == null or not QuestManager.finish(quest):
		var fail: Array[String] = ["(Belum bisa diselesaikan.)"]
		_show_pages(fail, true)
		return
	var pages := _split_pages(quest.thanks_text if quest.thanks_text != "" else "Terima kasih banyak!")
	pages.append("(Tugas \"%s\" tuntas! Hadiah: %s)" % [quest.title, quest.reward_text()])
	_refresh_friendship()
	_show_pages(pages, true)


func _give_gift() -> void:
	var item := InventoryManager.current_item()
	var pages: Array[String] = []
	if item == null:
		pages.append("(Tanganmu kosong. Pilih item di hotbar dengan tombol 1-8.)")
		_show_pages(pages, true)
		return
	match NpcManager.give_gift(_npc, item):
		NpcManager.GiftResult.REFUSED:
			pages.append("(%s tidak cocok dijadikan hadiah.)" % item.item_name)
		NpcManager.GiftResult.ALREADY_GIFTED:
			pages.append("Terima kasih, tapi hari ini kamu sudah memberiku hadiah. Besok lagi, ya!")
		NpcManager.GiftResult.LIKED:
			InventoryManager.consume_selected(1)
			pages.append(_npc.like_reply)
			pages.append("(Friendship +%d)" % NpcManager.LIKE_POINTS)
		NpcManager.GiftResult.DISLIKED:
			InventoryManager.consume_selected(1)
			pages.append(_npc.dislike_reply)
			pages.append("(Friendship %d)" % NpcManager.DISLIKE_POINTS)
		_:
			InventoryManager.consume_selected(1)
			pages.append(_npc.neutral_reply)
			pages.append("(Friendship +%d)" % NpcManager.NEUTRAL_POINTS)
	_refresh_friendship()
	_show_pages(pages, true)
