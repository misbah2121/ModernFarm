class_name QuestLog
extends Control
## Daftar tugas + kalender acara (Phase 11). Tombol J membuka/menutup, ESC menutup.
## Digambar lewat _draw, gaya sama dengan InventoryPanel.

signal opened
signal closed

const PANEL_SIZE := Vector2(440, 260)
const PAD := 10
const ROW_H := 40
const MAX_ROWS := 4

## Warna teks di atas kertas krem (asset RPG UI, lihat UiTheme).
const COL_GOLD := UiTheme.PRICE
const COL_GREEN := UiTheme.GREEN
const COL_DIM := UiTheme.TEXT_DIM
const COL_TEXT := UiTheme.TEXT

var _skin: UiTheme.UiSkin


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skin = UiTheme.UiSkin.new()
	QuestManager.quest_changed.connect(func(_q: QuestData) -> void: _redraw())
	InventoryManager.inventory_changed.connect(_redraw)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if visible:
		return
	visible = true
	queue_redraw()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _redraw() -> void:
	if visible:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("quest_log") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var origin := ((size - PANEL_SIZE) / 2.0).floor()
	var panel := Rect2(origin, PANEL_SIZE)
	UiTheme.draw_window(self, _skin, panel, "DAFTAR TUGAS")
	var x := origin.x + PAD
	var width := PANEL_SIZE.x - PAD * 2
	draw_string(font, origin + Vector2(PAD, 12), "Tuntas: %d / %d" % [QuestManager.done_count(), QuestManager.all_quests().size()],
		HORIZONTAL_ALIGNMENT_RIGHT, width, UiTheme.FS, UiTheme.TITLE)

	var quests := QuestManager.active_quests()
	var y := origin.y + 30
	if quests.is_empty():
		draw_multiline_string(font, Vector2(x, y + 12), "Belum ada tugas aktif. Bicaralah dengan penduduk desa (pilihan \"Tugas\").",
			HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, 3, COL_DIM)
	for i in mini(quests.size(), MAX_ROWS):
		_draw_quest(font, quests[i], Rect2(x, y, width, ROW_H - 4))
		y += ROW_H
	if quests.size() > MAX_ROWS:
		draw_string(font, Vector2(x, y + 8), "+%d tugas lain" % (quests.size() - MAX_ROWS), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_DIM)

	# Kalender acara
	var cal_y := origin.y + PANEL_SIZE.y - 40
	draw_line(Vector2(x, cal_y), Vector2(x + width, cal_y), Color(UiTheme.COL_BORDER, 0.4))
	var today := EventManager.today
	var today_text := "Hari ini: %s" % (today.title if today != null else "hari biasa")
	draw_string(font, Vector2(x, cal_y + 12), today_text, HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, COL_GOLD if today != null else COL_DIM)
	var next := EventManager.next_event()
	var next_text := "Acara berikutnya: -"
	if next != null:
		next_text = "Acara berikutnya: %s (%s %d)" % [next.title, next.season.capitalize(), next.day]
	draw_string(font, Vector2(x, cal_y + 23), next_text, HORIZONTAL_ALIGNMENT_LEFT, width, UiTheme.FS, COL_DIM)
	draw_string(font, Vector2(x, cal_y + 34), "J / ESC: tutup", HORIZONTAL_ALIGNMENT_RIGHT, width, UiTheme.FS, COL_DIM)


func _draw_quest(font: Font, quest: QuestData, rect: Rect2) -> void:
	var status := QuestManager.status(quest)
	var done := status == QuestManager.Status.COMPLETE or QuestManager.progress(quest) >= quest.target_count
	draw_style_box(_skin.paper, rect)
	if done:
		draw_rect(rect.grow(-1.0), UiTheme.SELECT, false, 2.0)
	var giver := NpcManager.get_npc(quest.giver_id)
	var giver_name := giver.npc_name if giver != null else quest.giver_id
	var giver_text := "dari %s" % giver_name
	var giver_w := ThemeDB.fallback_font.get_string_size(giver_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS).x
	draw_string(font, rect.position + Vector2(6, 13), UiTheme.fit(quest.title, rect.size.x - 20 - giver_w), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, UiTheme.ACCENT)
	draw_string(font, rect.position + Vector2(6, 13), giver_text, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 12, UiTheme.FS, COL_DIM)
	var line := "%s  -  Hadiah: %s" % [quest.target_text(), quest.reward_text()]
	draw_string(font, rect.position + Vector2(6, 24), UiTheme.fit(line, rect.size.x - 12), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_TEXT)
	# Bilah progres
	var bar := Rect2(rect.position + Vector2(6, 29), Vector2(rect.size.x - 72, 3))
	var ratio := clampf(QuestManager.progress(quest) / float(maxi(quest.target_count, 1)), 0.0, 1.0)
	UiTheme.draw_progress(self, bar, ratio, Color(0.36, 0.75, 0.42) if done else Color(0.95, 0.72, 0.25))
	var right := "%d/%d" % [QuestManager.progress(quest), quest.target_count]
	if done:
		right = "Lapor!"
	draw_string(font, Vector2(bar.end.x + 6, rect.position.y + 34), right, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FS, COL_GREEN if done else COL_TEXT)
