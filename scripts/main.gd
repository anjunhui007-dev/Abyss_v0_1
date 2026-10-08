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

func _make_card_button(title_text: String, x: float, shortcut: String) -> void:
	_make_label(title_text, Vector2(x, 672), 14, Color("d6e3ec"))
	_make_label(shortcut, Vector2(x, 692), 10, Color("8096a8"))

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("101923")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	add_child(bg)
	_make_label("THE GREAT LABYRINTH", Vector2(25, 9), 11, Color("d7b77b"))
	_make_label("대미궁 아비스", Vector2(25, 26), 26, Color("f0f4fa"))
	_make_label("제1층   /   초원 지대", Vector2(455, 30), 18, Color("e5c28a"))
	_make_label("PC  ·  v0.2.2", Vector2(1130, 33), 13, Color("91a9bd"))
	_make_label("탐사자", Vector2(29, 90), 17, Color("d9ba7e"))
	_make_label("아이젠 하이르", Vector2(29, 121), 20, Color("f1f5f9"))
	_make_label("인간  ·  탐사자", Vector2(29, 151), 13, Color("9fb3c4"))
	_make_label("생명력", Vector2(29, 219), 13, Color("c4d2dd"))
	_make_label("마력", Vector2(29, 279), 13, Color("c4d2dd"))
	_make_label("경험치", Vector2(29, 339), 13, Color("c4d2dd"))
	hp_value = _make_label("", Vector2(151, 219), 12)
	mp_value = _make_label("", Vector2(151, 279), 12)
	xp_value = _make_label("", Vector2(151, 339), 12)
	_make_label("기본 능력치", Vector2(29, 403), 15, Color("d9ba7e"))
	status_label = _make_label("", Vector2(29, 434), 14)
	_make_label("탐사 지도", Vector2(286, 88), 18, Color("e4edf3"))
	_make_label("WASD / 방향키", Vector2(790, 92), 12, Color("9fb6c6"))
	_make_label("탐사 기록", Vector2(989, 90), 18, Color("d9ba7e"))
	_make_label("최근 이벤트", Vector2(990, 143), 13, Color("9fb6c6"))
	reward_label = RichTextLabel.new()
	reward_label.position = Vector2(990, 173)
	reward_label.size = Vector2(250, 240)
	reward_label.bbcode_enabled = true
	reward_label.scroll_active = false
	reward_label.add_theme_font_size_override("normal_font_size", 14)
	add_child(reward_label)
	log_label = _make_label("", Vector2(990, 408), 12, Color("a5b6c7"))
	log_label.size = Vector2(250, 28)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_make_label("지도 범례", Vector2(286, 603), 12, Color("d9ba7e"))
	for legend in [["플레이어", 320, 618], ["몬스터", 535, 618], ["보물상자", 750, 618], ["장애물", 320, 635], ["미탐사", 535, 635], ["탐사 지역", 750, 635]]:
		_make_label(str(legend[0]), Vector2(float(legend[1]), float(legend[2])), 11, Color("a5b6c7"))
	_make_label("탐사 진행", Vector2(990, 454), 14, Color("d9ba7e"))
	activity_value = _make_label("", Vector2(990, 484), 15)
	day_value = _make_label("", Vector2(990, 520), 14, Color("aebfcf"))
	_make_label("조작 안내", Vector2(990, 565), 13, Color("d9ba7e"))
	_make_label("E  상자 열기", Vector2(990, 592), 12, Color("aebfcf"))
	_make_label("F5  저장   ·   F9  불러오기", Vector2(990, 612), 12, Color("aebfcf"))
	_make_card_button("탐사", 42, "W A S D")
	_make_card_button("캐릭터", 257, "준비 중")
	_make_card_button("가방", 461, "준비 중")
	_make_card_button("장비", 663, "11슬롯 예정")
	_make_card_button("정수", 862, "준비 중")
	_make_card_button("도감", 1070, "준비 중")
	battle_panel = PanelContainer.new()
	battle_panel.position = Vector2(294, 176)
	battle_panel.custom_minimum_size = Vector2(652, 365)
	battle_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d2c3c")
	style.border_color = Color("b59660")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	battle_panel.add_theme_stylebox_override("panel", style)
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
	if history.size() > 6:
		history.resize(6)

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
	status_label.text = "Lv. %d\n\nSTR  20      AGI   5\nHP     5      MP    5\nWIL    5      MAG   5\nLUK  20\n\n골드  %d G\n정수  회색 송곳니" % [level, gold]
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
	activity_value.text = "활동   %d / 10" % activity
	day_value.text = "던전   %d일차" % day
	if phase == "battle":
		battle_label.text = "전투  ·  %s\n\n적 HP  %d / %d\n내 HP  %d     MP  %d     AP  %.1f / 2.0\n\n%s" % [enemy_name, maxi(0, enemy_hp), enemy_max_hp, hp, mp, ap, "\n".join(combat_log.slice(maxi(0, combat_log.size() - 5)))]
		buttons[0].disabled = ap < 1.0
		buttons[1].disabled = ap < 1.0 or mp < 8
		buttons[2].disabled = ap < 0.5
		buttons[3].disabled = ap < 0.5
	queue_redraw()

func _card(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(rect, Color("35475a"), false, 1.0)

func _bar(y: float, fraction: float, tint: Color) -> void:
	var width_value: float = 205.0
	draw_rect(Rect2(29, y, width_value, 9), Color("304052"))
	draw_rect(Rect2(29, y, width_value * clampf(fraction, 0.0, 1.0), 9), tint)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("101923"))
	draw_rect(Rect2(0, 65, 1280, 2), Color("b59660"))
	_card(Rect2(15, 77, 239, 563), Color("1b2938"))
	_card(Rect2(267, 77, 697, 563), Color("1b2938"))
	_card(Rect2(977, 77, 288, 563), Color("1b2938"))
	_card(Rect2(15, 650, 1250, 63), Color("1b2938"))
	draw_rect(Rect2(29, 190, 205, 1), Color("3b4e60"))
	draw_rect(Rect2(29, 390, 205, 1), Color("3b4e60"))
	_bar(244, float(hp) / float(maxi(1, 100 + (level - 1) * 20)), Color("d96b76"))
	_bar(304, float(mp) / 30.0, Color("649ee8"))
	_bar(364, float(exp_points) / float(maxi(1, level * 100)), Color("d8b66f"))
	draw_rect(Rect2(989, 131, 263, 1), Color("3b4e60"))
	for i in range(6):
		var sx: float = 305.0 + float(i % 3) * 215.0
		var sy: float = 621.0 + float(i / 3) * 17.0
		var tint: Color = [Color("79c7fa"), Color("e37d75"), Color("e5bb68"), Color("5b6872"), Color("0d1720"), Color("385f50")][i]
		draw_rect(Rect2(sx, sy, 9, 9), tint)
	draw_rect(Rect2(989, 438, 263, 1), Color("3b4e60"))
	draw_rect(Rect2(989, 551, 263, 1), Color("3b4e60"))
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
	var data := {"player": [player.x, player.y], "explored": e, "monsters": m, "chests": c, "hp": hp, "mp": mp, "gold": gold, "exp": exp_points, "level": level, "activity": activity, "day": day}
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
	message = "저장 데이터 불러오기 완료!"
	_refresh()
