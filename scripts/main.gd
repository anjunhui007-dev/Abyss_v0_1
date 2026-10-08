extends Control

const W := 17
const H := 13
const CELL := 40
const ORIGIN := Vector2(270, 90)
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

func _ready() -> void:
	_build_ui()
	_generate_map()
	_reveal()
	_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("101923")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "대미궁 아비스  |  1층 · 초원  |  v0.1.0"
	title.position = Vector2(24, 15)
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(20, 95)
	status_label.custom_minimum_size = Vector2(235, 450)
	status_label.add_theme_font_size_override("font_size", 17)
	add_child(status_label)
	log_label = Label.new()
	log_label.position = Vector2(275, 635)
	log_label.custom_minimum_size = Vector2(900, 70)
	log_label.add_theme_font_size_override("font_size", 16)
	add_child(log_label)
	battle_panel = PanelContainer.new()
	battle_panel.position = Vector2(305, 130)
	battle_panel.custom_minimum_size = Vector2(635, 390)
	battle_panel.visible = false
	add_child(battle_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	battle_panel.add_child(content)
	battle_label = Label.new()
	battle_label.custom_minimum_size = Vector2(600, 270)
	battle_label.add_theme_font_size_override("font_size", 21)
	content.add_child(battle_label)
	actions = HBoxContainer.new()
	content.add_child(actions)
	for data in [["공격", "attack"], ["정수 스킬", "skill"], ["방어", "guard"], ["도주", "flee"], ["턴 종료", "end"]]:
		var btn := Button.new()
		btn.text = data[0]
		btn.custom_minimum_size = Vector2(116, 48)
		btn.pressed.connect(_battle_action.bind(data[1]))
		actions.add_child(btn)
		buttons.append(btn)

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
	status_label.text = "아이젠 하이르\n인간 · 탐사자\n\nLv.%d\nHP %d / %d\nMP %d / 30\nEXP %d / %d\n골드 %dG\n\nSTR 20   AGI 5\nMAG 5   LUK 20\n\n활동 %d / 10\n던전 %d일차\n\n정수: 회색 송곳니\n장비 슬롯: 11개(추후 UI)\n\nF5 저장 / F9 불러오기" % [level, hp, 100 + (level - 1) * 20, mp, exp_points, level * 100, gold, activity, day]
	log_label.text = message
	if phase == "battle":
		battle_label.text = "전투: %s\n적 HP: %d / %d\n내 HP: %d   MP: %d   AP: %.1f / 2.0\n\n%s" % [enemy_name, maxi(0, enemy_hp), enemy_max_hp, hp, mp, ap, "\n".join(combat_log.slice(maxi(0, combat_log.size() - 5)))]
		buttons[0].disabled = ap < 1.0
		buttons[1].disabled = ap < 1.0 or mp < 8
		buttons[2].disabled = ap < 0.5
		buttons[3].disabled = ap < 0.5
	queue_redraw()

func _draw() -> void:
	for y in range(H):
		for x in range(W):
			var p := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(x * CELL, y * CELL), Vector2(CELL - 2, CELL - 2))
			var dist: int = absi(x - player.x) + absi(y - player.y)
			if not explored.has(p):
				draw_rect(rect, Color("090e15"))
				continue
			var visible_now: bool = dist <= 4 and absi(x - player.x) <= 3 and absi(y - player.y) <= 3
			var c := Color("3d6546")
			if walls.has(p): c = Color("58606a")
			if not visible_now: c = c.darkened(0.6)
			draw_rect(rect, c)
			if visible_now and chests.has(p):
				draw_rect(rect.grow(-10), Color("e2b657"))
			if visible_now and monsters.has(p):
				draw_circle(rect.get_center(), 12, Color("cf6e62"))
			if p == player:
				draw_circle(rect.get_center(), 13, Color("68b8f2"))
				draw_circle(rect.get_center(), 6, Color("f5f9ff"))

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
	message = "저장 데이터 불러오기 완료!"
	_refresh()
