extends Node2D

# Abyss RPG - first playable Godot skeleton (PC only)
const WORLD_SIZE := Vector2(1280, 720)
const SPEED := 280.0
const PLAYER_RADIUS := 15.0
const ROOM_NAMES := ["보물방", "정예방", "소재방", "빈 방"]
const ROOM_RECTS := [
	Rect2(85, 90, 315, 185), Rect2(482, 90, 315, 185), Rect2(880, 90, 315, 185),
	Rect2(85, 365, 315, 185), Rect2(482, 365, 315, 185), Rect2(880, 365, 315, 185)
]
var area := "town"
var player_position := Vector2(640, 540)
var room_assignments: Array[String] = []
var elapsed := 0.0
var info_label: Label
var tip_label: Label

func _ready() -> void:
	_setup_ui()
	_roll_rooms()
	_update_ui()
	queue_redraw()

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	info_label = Label.new()
	info_label.position = Vector2(22, 15)
	info_label.add_theme_font_size_override("font_size", 26)
	layer.add_child(info_label)
	tip_label = Label.new()
	tip_label.position = Vector2(22, 55)
	tip_label.add_theme_font_size_override("font_size", 17)
	layer.add_child(tip_label)

func _roll_rooms() -> void:
	room_assignments.clear()
	for i in range(ROOM_RECTS.size()):
		if randf() < 0.12:
			room_assignments.append("균열방")
		else:
			room_assignments.append(ROOM_NAMES.pick_random())

func _process(delta: float) -> void:
	elapsed += delta
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	player_position += direction.normalized() * SPEED * delta
	player_position = player_position.clamp(Vector2(PLAYER_RADIUS, 90), WORLD_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
	if Input.is_key_pressed(KEY_E):
		_interact()
	queue_redraw()

func _portal_position() -> Vector2:
	if area == "town":
		return Vector2(640, 190)
	return Vector2(640, 620)

func _interact() -> void:
	if player_position.distance_to(_portal_position()) > 65.0:
		return
	if area == "town":
		area = "abyss"
		player_position = Vector2(640, 540)
		_roll_rooms()
	else:
		area = "town"
		player_position = Vector2(640, 350)
	_update_ui()

func _update_ui() -> void:
	info_label.text = "카르디아 · 마을" if area == "town" else "어비스 · 미궁 1층"
	tip_label.text = "WASD / 방향키: 이동    E: 포탈 상호작용    |    PC 전용 기본 뼈대"

func _draw() -> void:
	if area == "town":
		_draw_town()
	else:
		_draw_abyss()
	_draw_portal(_portal_position(), Color("#7ad8ed") if area == "town" else Color("#bda1f4"))
	draw_circle(player_position, PLAYER_RADIUS + 3, Color("#273342"))
	draw_circle(player_position, PLAYER_RADIUS, Color("#ffd082"))
	_draw_text("탐사자", player_position + Vector2(-28, -26), 17, Color.WHITE)

func _draw_town() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#27443c"))
	draw_rect(Rect2(410, 110, 460, 490), Color("#867a61"))
	draw_rect(Rect2(435, 125, 410, 450), Color("#a69a7b"))
	_draw_text("마을 광장", Vector2(586, 410), 28, Color("#262c31"))
	_draw_place(Rect2(70, 140, 260, 145), "상점 (예정)")
	_draw_place(Rect2(950, 140, 260, 145), "길드 (예정)")
	_draw_place(Rect2(70, 420, 260, 145), "신전 (예정)")
	_draw_place(Rect2(950, 420, 260, 145), "거래소 (예정)")
	_draw_text("도박장 · 추후 구현", Vector2(530, 665), 20, Color("#d9dfd8"))
	_draw_text("미궁 입구", Vector2(588, 115), 20, Color.WHITE)

func _draw_place(rect: Rect2, title: String) -> void:
	draw_rect(rect, Color("#354957"))
	draw_rect(rect, Color("#8c9caa"), false, 3.0)
	_draw_text(title, rect.position + Vector2(24, rect.size.y / 2.0), 20, Color.WHITE)

func _draw_abyss() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#202a38"))
	draw_rect(Rect2(370, 245, 540, 210), Color("#465160"))
	_draw_text("탐험 광장", Vector2(577, 345), 28, Color.WHITE)
	for i in range(ROOM_RECTS.size()):
		var rect: Rect2 = ROOM_RECTS[i]
		draw_rect(rect, Color("#394653"))
		draw_rect(rect, Color("#82919f"), false, 3.0)
		_draw_text(room_assignments[i], rect.position + rect.size * 0.5 - Vector2(40, 0), 22, Color("#f2e5c7"))
	_draw_text("마을 귀환", Vector2(580, 560), 20, Color.WHITE)

func _draw_portal(center: Vector2, color: Color) -> void:
	var glow := color
	glow.a = 0.17
	draw_circle(center, 49.0 + sin(elapsed * 3.0) * 3.0, glow)
	draw_arc(center, 37.0, 0.0, TAU, 60, color, 6.0, true)
	draw_circle(center, 25.0, glow)

func _draw_text(value: String, at: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
