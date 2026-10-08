extends Control

const W := 17
const H := 13
const CELL := 36
const ORIGIN := Vector2(305, 135)
const SAVE_PATH := "user://abyss_save.json"
const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var player := Vector2i(2, 6)
var explored: Dictionary = {}
var monsters: Dictionary = {}
var walls: Dictionary = {}
var chests: Dictionary = {}
var hp := 100
var mp := 30
var gold := 0
var exp_points := 0
var level := 1
var activity := 0
var day := 1
var phase := "explore"
var enemy_name := ""
var enemy_hp := 0
var enemy_max_hp := 0
var enemy_attack := 0
var enemy_exp := 0
var ap := 2.0
var guard := false
var combat_log: Array[String] = []
var message := "WASD / 방향키 이동 · E 상자 열기 · F5 저장 · F9 불러오기"
var buttons: Array[Button] = []
var status_label: Label
var log_label: Label
var battle_panel: PanelContainer
var battle_label: Label
var actions: HBoxContainer
var hp_value: Label
var mp_value: Label
var xp_value: Label
var activity_value: Label
var day_value: Label
var reward_label: RichTextLabel
var history: Array[Dictionary] = []
var settings_popup: PanelContainer
var stat_values: Dictionary = {}

func _ready() -> void:
	_build_ui()
	_generate_map()
	_reveal()
	_refresh()

func _make_label(text_value: String, pos: Vector2, font_size: int, tint: Color = Color("dbe6f0")) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
	return label

func _style(bg: String, border: String = "35485a", radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	return style

func _panel(pos: Vector2, dimensions: Vector2, bg: String = "1b2938") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = dimensions
	panel.add_theme_stylebox_override("panel", _style(bg))
	add_child(panel)
	return panel

func _section(parent: Node, heading: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	parent.add_child(column)
	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.add_theme_color_override("font_color", Color("d9b878"))
	heading_label.add_theme_font_size_override("font_size", 14)
	column.add_child(heading_label)
	return column

func _stat_card(parent: Node, name: String, amount: String) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(94, 38)
	card.add_theme_stylebox_override("panel", _style("273a4d", "273a4d", 7))
	parent.add_child(card)
	var row_box := HBoxContainer.new()
	card.add_child(row_box)
	var label := Label.new()
	label.text = name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color("9fb3c5"))
	label.add_theme_font_size_override("font_size", 12)
	row_box.add_child(label)
	var value := Label.new()
	value.text = amount
	value.add_theme_font_size_override("font_size", 13)
	row_box.add_child(value)
	stat_values[name] = value

func _make_menu_item(parent: Node, icon_text: String, title_text: String) -> void:
	var row_box := VBoxContainer.new()
	row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_box.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row_box)
	var symbol := Label.new()
	symbol.text = icon_text
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.add_theme_color_override("font_color", Color("d9b878"))
	symbol.add_theme_font_size_override("font_size", 19)
	row_box.add_child(symbol)
	var title_label := Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 12)
	row_box.add_child(title_label)

func _toggle_settings() -> void:
	settings_popup.visible = not settings_popup.visible

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("101923")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	add_child(bg)
	_make_label("THE GREAT LABYRINTH", Vector2(25, 7), 11, Color("d7b77b"))
	_make_label("대미궁 아비스", Vector2(25, 24), 26, Color("f0f4fa"))
	_make_label("제1층  ·  초원 지대", Vector2(512, 26), 18, Color("e5c28a"))
	var settings_button := Button.new()
	settings_button.text = "⚙"
	settings_button.position = Vector2(1216, 15)
	settings_button.custom_minimum_size = Vector2(43, 41)
	settings_button.add_theme_font_size_override("font_size", 23)
	settings_button.add_theme_stylebox_override("normal", _style("223448"))
	settings_button.add_theme_stylebox_override("hover", _style("30495f", "d9b878"))
	settings_button.pressed.connect(_toggle_settings)
	add_child(settings_button)
	var left := _panel(Vector2(15, 76), Vector2(240, 563))
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 12)
	left.add_child(left_col)
	var name_label := Label.new()
	name_label.text = "아이젠 하이르"
	name_label.add_theme_font_size_override("font_size", 19)
	left_col.add_child(name_label)
	var subtitle := Label.new()
	subtitle.text = "인간  ·  탐사자"
	subtitle.add_theme_color_override("font_color", Color("9fb3c5"))
	left_col.add_child(subtitle)
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color("d9b878"))
	left_col.add_child(status_label)
	for item in [["HP", "d9767d"], ["MP", "76a8e8"], ["EXP", "d9b56d"]]:
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 4)
		left_col.add_child(group)
		var line := HBoxContainer.new()
		group.add_child(line)
		var title_label := Label.new()
		title_label.text = item[0]
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.add_theme_font_size_override("font_size", 12)
		line.add_child(title_label)
		var amount := Label.new()
		amount.add_theme_font_size_override("font_size", 12)
		line.add_child(amount)
		var progress := ProgressBar.new()
		progress.custom_minimum_size = Vector2(200, 9)
		progress.show_percentage = false
		progress.max_value = 100
		progress.add_theme_stylebox_override("background", _style("304256", "304256", 5))
		progress.add_theme_stylebox_override("fill", _style(item[1], item[1], 5))
		group.add_child(progress)
		match item[0]:
			"HP": hp_value = amount
			"MP": mp_value = amount
			"EXP": xp_value = amount
		progress.set_meta("stat_type", item[0])
		stat_values["bar_" + item[0]] = progress
	var stat_column := _section(left_col, "기본 능력치")
	var stat_grid := GridContainer.new()
	stat_grid.columns = 2
	stat_grid.add_theme_constant_override("h_separation", 6)
	stat_grid.add_theme_constant_override("v_separation", 6)
	stat_column.add_child(stat_grid)
	for stat in [["STR", "20"], ["AGI", "5"], ["HP", "5"], ["MP", "5"], ["WIL", "5"], ["MAG", "5"], ["LUK", "20"]]:
		_stat_card(stat_grid, stat[0], stat[1])
	var gold_label := Label.new()
	gold_label.add_theme_color_override("font_color", Color("f1c76d"))
	gold_label.add_theme_font_size_override("font_size", 15)
	left_col.add_child(gold_label)
	stat_values["gold"] = gold_label
	var essence_label := Label.new()
	essence_label.text = "정수  ·  회색 송곳니"
	essence_label.add_theme_font_size_override("font_size", 12)
	left_col.add_child(essence_label)
	var middle := _panel(Vector2(267, 76), Vector2(697, 563))
	_make_label("◇  탐사 지도", Vector2(288, 91), 18, Color("eaf0f5"))
	_make_label("WASD / 방향키", Vector2(827, 97), 12, Color("9fb3c5"))
	_make_label("지도 범례", Vector2(287, 585), 12, Color("d9b878"))
	var legend_data := [["플레이어", 307, 603], ["몬스터", 510, 603], ["보물상자", 713, 603], ["장애물", 307, 620], ["미탐사", 510, 620], ["탐사 지역", 713, 620]]
	for item in legend_data:
		_make_label(str(item[0]), Vector2(float(item[1]) + 14, float(item[2]) - 2), 11, Color("a5b6c7"))
	var right := _panel(Vector2(977, 76), Vector2(288, 563))
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 12)
	right.add_child(right_col)
	var heading := Label.new()
	heading.text = "탐사 기록"
	heading.add_theme_color_override("font_color", Color("d9b878"))
	heading.add_theme_font_size_override("font_size", 18)
	right_col.add_child(heading)
	reward_label = RichTextLabel.new()
	reward_label.custom_minimum_size = Vector2(255, 345)
	reward_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_label.bbcode_enabled = true
	reward_label.scroll_active = true
	reward_label.scroll_following = false
	reward_label.add_theme_font_size_override("normal_font_size", 14)
	right_col.add_child(reward_label)
	var progress_title := Label.new()
	progress_title.text = "탐사 진행"
	progress_title.add_theme_color_override("font_color", Color("d9b878"))
	right_col.add_child(progress_title)
	activity_value = Label.new()
	right_col.add_child(activity_value)
	day_value = Label.new()
	day_value.add_theme_color_override("font_color", Color("9fb3c5"))
	right_col.add_child(day_value)
	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 11)
	log_label.add_theme_color_override("font_color", Color("9fb3c5"))
	right_col.add_child(log_label)
	var bottom := _panel(Vector2(15, 650), Vector2(1250, 62))
	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", 4)
	bottom.add_child(bottom_row)
	for item in [["◇", "탐사"], ["♙", "캐릭터"], ["▣", "가방"], ["♜", "장비"], ["✦", "정수"], ["▤", "도감"]]:
		_make_menu_item(bottom_row, item[0], item[1])
	settings_popup = _panel(Vector2(996, 66), Vector2(265, 172), "223448")
	var settings_content := VBoxContainer.new()
	settings_content.add_theme_constant_override("separation", 12)
	settings_popup.add_child(settings_content)
	for item in ["설정", "게임 설정  ·  준비 중", "화면 설정  ·  준비 중", "사운드 설정  ·  준비 중"]:
		var label := Label.new()
		label.text = item
		label.add_theme_font_size_override("font_size", 14)
		settings_content.add_child(label)
	settings_popup.visible = false
	battle_panel = PanelContainer.new()
	battle_panel.position = Vector2(294, 176)
	battle_panel.custom_minimum_size = Vector2(652, 365)
	battle_panel.visible = false
	battle_panel.add_theme_stylebox_override("panel", _style("1d2c3c", "b59660"))
	add_child(battle_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	battle_panel.add_child(content)
	battle_label = Label.new()
	battle_label.custom_minimum_size = Vector2(610, 262)
	battle_label.add_theme_font_size_override("font_size", 18)
	content.add_child(battle_label)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	content.add_child(actions)
	for data in [["공격", "attack"], ["정수 스킬", "skill"], ["방어", "guard"], ["도주", "flee"], ["턴 종료", "end"]]:
		var btn := Button.new()
		btn.text = data[0]
		btn.custom_minimum_size = Vector2(116, 44)
		btn.pressed.connect(_battle_action.bind(data[1]))
		actions.add_child(btn)
		buttons.append(btn)

func _record_event(title_text: String, gained_gold: int = 0, gained_exp: int = 0) -> void:
	history.push_front({"title": title_text, "gold": gained_gold, "exp": gained_exp})
	if history.size() > 300:
		history.resize(300)

func _generate_map() -> void:
	walls.clear()
	monsters.clear()
	chests.clear()
	for x in range(W):
		for y in range(H):
			if x == 0 or y == 0 or x == W - 1 or y == H - 1:
				walls[Vector2i(x, y)] = true
	for p in [Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(9, 7), Vector2i(9, 8), Vector2i(12, 4), Vector2i(12, 5)]:
		walls[p] = true
	monsters[Vector2i(7, 6)] = "wolf"
	monsters[Vector2i(4, 9)] = "slime"
	monsters[Vector2i(13, 9)] = "wolf"
	chests[Vector2i(3, 3)] = true
	chests[Vector2i(14, 3)] = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			_save()
			return
		if event.keycode == KEY_F9:
			_load()
			return
		if phase != "explore":
			return
		var d := Vector2i.ZERO
		match event.keycode:
			KEY_W, KEY_UP: d = Vector2i.UP
			KEY_S, KEY_DOWN: d = Vector2i.DOWN
			KEY_A, KEY_LEFT: d = Vector2i.LEFT
			KEY_D, KEY_RIGHT: d = Vector2i.RIGHT
			KEY_E:
				_open_chest()
				return
		if d != Vector2i.ZERO:
			_move(d)

func _move(d: Vector2i) -> void:
	var next := player + d
	if walls.has(next):
		message = "바위와 경계 때문에 이동할 수 없다."
		_refresh()
		return
	player = next
	if not explored.has(player):
		activity += 1
	_reveal()
	if monsters.has(player):
		_start_battle(monsters[player])
	else:
		message = "초원을 탐사했다."
		_check_camp()
	_refresh()

func _reveal() -> void:
	for x in range(max(0, player.x - 3), min(W, player.x + 4)):
		for y in range(max(0, player.y - 3), min(H, player.y + 4)):
			if abs(x - player.x) + abs(y - player.y) <= 4:
				explored[Vector2i(x, y)] = true

func _open_chest() -> void:
	for d in DIRS + [Vector2i.ZERO]:
		var p: Vector2i = player + d
		if chests.has(p):
			chests.erase(p)
			gold += 35
			activity += 1
			message = "낡은 상자를 열었다! 35G 획득."
			_record_event("낡은 상자 개봉", 35)
			_check_camp()
			_refresh()
			return
	message = "주변에 열 수 있는 상자가 없다."
	_refresh()

func _start_battle(kind: String) -> void:
	phase = "battle"
	enemy_name = "회색 늑대" if kind == "wolf" else "슬라임"
	enemy_max_hp = 42 if kind == "wolf" else 32
	enemy_hp = enemy_max_hp
	enemy_attack = 12 if kind == "wolf" else 7
	enemy_exp = 16 if kind == "wolf" else 12
	ap = 2.0
	guard = false
	combat_log = [enemy_name + "와 조우했다!"]
	_record_event(enemy_name + " 발견")
	battle_panel.visible = true
	_refresh()

func _battle_action(action: String) -> void:
	if phase != "battle":
		return
	match action:
		"attack":
			if ap < 1.0: return
			ap -= 1.0
			var damage := randi_range(17, 25)
			enemy_hp -= damage
			combat_log.append("기본 공격! %d 피해" % damage)
		"skill":
			if ap < 1.0 or mp < 8: return
			ap -= 1.0
			mp -= 8
			var damage := randi_range(12, 18) + randi_range(12, 18)
			enemy_hp -= damage
			combat_log.append("송곳니 연격! %d 피해 (MP -8)" % damage)
		"guard":
			if ap < 0.5: return
			ap -= 0.5
			guard = true
			combat_log.append("방어 태세: 다음 피해 25% 감소")
		"flee":
			if ap < 0.5: return
			ap -= 0.5
			if randf() < 0.6:
				combat_log.append("도주 성공!")
				phase = "explore"
				battle_panel.visible = false
				player = Vector2i(2, 6)
				message = "도주에 성공했다."
				_refresh()
				return
			combat_log.append("도주 실패!")
		"end":
			ap = 0.0
	if enemy_hp <= 0:
		_win()
		return
	if ap <= 0.0:
		_enemy_turn()
	_refresh()

func _enemy_turn() -> void:
	var damage := maxi(1, enemy_attack + randi_range(-2, 2) - 2)
	if guard:
		damage = maxi(1, roundi(damage * 0.75))
	hp -= damage
	combat_log.append("%s의 공격! %d 피해" % [enemy_name, damage])
	guard = false
	ap = 2.0
	if hp <= 0:
		hp = 100
		mp = 30
		player = Vector2i(2, 6)
		phase = "explore"
		battle_panel.visible = false
		message = "전투에서 패배했다. 시작 위치로 귀환했다."

func _win() -> void:
	monsters.erase(player)
	exp_points += enemy_exp
	gold += 15
	activity += 1
	message = "%s 처치! EXP +%d, 골드 +15G" % [enemy_name, enemy_exp]
	_record_event(enemy_name + " 처치", 15, enemy_exp)
	if exp_points >= level * 100:
		exp_points -= level * 100
		level += 1
		hp += 20
		message += "  레벨 업! Lv.%d" % level
	phase = "explore"
	battle_panel.visible = false
	_check_camp()
	_refresh()

func _check_camp() -> void:
	if activity >= 10:
		activity -= 10
		day += 1
		hp = mini(100 + (level - 1) * 20, hp + 25)
		mp = mini(30, mp + 10)
		message += "  야영 완료! HP +25, MP +10 / %d일차" % day

func _refresh() -> void:
	var max_hp: int = 100 + (level - 1) * 20
	hp_value.text = "%d / %d" % [hp, max_hp]
	mp_value.text = "%d / 30" % mp
	xp_value.text = "%d / %d" % [exp_points, level * 100]
	status_label.text = "Lv. %d" % level
	stat_values["gold"].text = "◈  %d G" % gold
	stat_values["bar_HP"].value = 100.0 * float(hp) / float(maxi(1, max_hp))
	stat_values["bar_MP"].value = 100.0 * float(mp) / 30.0
	stat_values["bar_EXP"].value = 100.0 * float(exp_points) / float(maxi(1, level * 100))
	log_label.text = message
	var entries: Array[String] = []
	for event_data in history:
		var line: String = "[color=#eaf0f5]" + str(event_data["title"]) + "[/color]"
		var reward_parts: Array[String] = []
		if int(event_data["gold"]) > 0:
			reward_parts.append("[color=#f1c76d]+%d G[/color]" % int(event_data["gold"]))
		if int(event_data["exp"]) > 0:
			reward_parts.append("[color=#85b7ff]+%d EXP[/color]" % int(event_data["exp"]))
		if not reward_parts.is_empty():
			line += "\n[font_size=12]" + "    ".join(reward_parts) + "[/font_size]"
		entries.append(line)
	reward_label.text = "\n\n".join(entries)
	reward_label.scroll_to_line(0)
	activity_value.text = "활동   %d / 10" % activity
	day_value.text = "던전   %d일차" % day
	if phase == "battle":
		battle_label.text = "전투  ·  %s\n\n적 HP  %d / %d\n내 HP  %d     MP  %d     AP  %.1f / 2.0\n\n%s" % [enemy_name, maxi(0, enemy_hp), enemy_max_hp, hp, mp, ap, "\n".join(combat_log.slice(maxi(0, combat_log.size() - 5)))]
		buttons[0].disabled = ap < 1.0
		buttons[1].disabled = ap < 1.0 or mp < 8
		buttons[2].disabled = ap < 0.5
		buttons[3].disabled = ap < 0.5
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("101923"))
	draw_rect(Rect2(0, 65, 1280, 2), Color("b59660"))
	for i in range(6):
		var sx: float = 291.0 + float(i % 3) * 203.0
		var sy: float = 606.0 + float(i / 3) * 17.0
		var colors: Array[Color] = [Color("79c7fa"), Color("e37d75"), Color("e5bb68"), Color("5b6872"), Color("0d1720"), Color("385f50")]
		draw_rect(Rect2(sx, sy, 9, 9), colors[i])
	for y in range(H):
		for x in range(W):
			var p: Vector2i = Vector2i(x, y)
			var rect: Rect2 = Rect2(ORIGIN + Vector2(x * CELL, y * CELL), Vector2(CELL - 2, CELL - 2))
			var dist: int = absi(x - player.x) + absi(y - player.y)
			if not explored.has(p):
				draw_rect(rect, Color("0d1720"))
				continue
			var visible_now: bool = dist <= 4 and absi(x - player.x) <= 3 and absi(y - player.y) <= 3
			var c: Color = Color("385f50")
			if walls.has(p):
				c = Color("5b6872")
			elif (x + y) % 7 == 0:
				c = Color("436c54")
			if not visible_now:
				c = c.darkened(0.62)
			draw_rect(rect, c)
			if visible_now and chests.has(p):
				draw_rect(rect.grow(-10), Color("e5bb68"))
			if visible_now and monsters.has(p):
				draw_circle(rect.get_center(), 12, Color("e37d75"))
			if p == player:
				draw_circle(rect.get_center(), 13, Color("79c7fa"))
				draw_arc(rect.get_center(), 15, 0, TAU, 24, Color("d7f1ff"), 2.0)
				draw_circle(rect.get_center(), 5, Color("f5f9ff"))

func _save() -> void:
	var e: Array = []
	for p in explored.keys(): e.append([p.x, p.y])
	var m: Array = []
	for p in monsters.keys(): m.append([p.x, p.y, monsters[p]])
	var c: Array = []
	for p in chests.keys(): c.append([p.x, p.y])
	var data := {"player": [player.x, player.y], "explored": e, "monsters": m, "chests": c, "hp": hp, "mp": mp, "gold": gold, "exp": exp_points, "level": level, "activity": activity, "day": day, "history": history}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		message = "저장 실패"
	else:
		file.store_string(JSON.stringify(data))
		message = "저장 완료!"
	_refresh()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		message = "저장 파일이 없다."
		_refresh()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary: return
	player = Vector2i(int(data.player[0]), int(data.player[1]))
	explored.clear()
	for p in data.explored: explored[Vector2i(int(p[0]), int(p[1]))] = true
	monsters.clear()
	for p in data.monsters: monsters[Vector2i(int(p[0]), int(p[1]))] = str(p[2])
	chests.clear()
	for p in data.chests: chests[Vector2i(int(p[0]), int(p[1]))] = true
	hp = int(data.hp)
	mp = int(data.mp)
	gold = int(data.gold)
	exp_points = int(data.exp)
	level = int(data.level)
	activity = int(data.activity)
	day = int(data.day)
	phase = "explore"
	battle_panel.visible = false
	history.clear()
	if data.has("history") and data["history"] is Array:
		for event_data in data["history"]:
			if event_data is Dictionary and event_data.has("title") and event_data.has("gold") and event_data.has("exp"):
				history.append({"title": str(event_data["title"]), "gold": int(event_data["gold"]), "exp": int(event_data["exp"])})
				if history.size() >= 300:
					break
	message = "저장 데이터 불러오기 완료!"
	_refresh()
