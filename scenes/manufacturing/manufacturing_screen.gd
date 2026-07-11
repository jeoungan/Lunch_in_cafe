extends Control
class_name ManufacturingScreen

signal step_completed(step_id: String)
signal boss_requested()
signal drink_ready()
signal interaction_message(message: String)

const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const GestureAnalyzer = preload("res://src/core/gesture_analyzer.gd")
const CupComposerScript = preload("res://scenes/manufacturing/cup_composer.gd")

const STEP_ORDER: Array[String] = ["cup", "water", "ice", "espresso", "lid", "sleeve"]
const STEP_INFO := {
	"cup": {
		"label": "빈 컵",
		"station": "sink",
		"action": "prepare_packaging",
		"layer": "cup",
		"color": Color("#d6e9e8"),
	},
	"water": {
		"label": "물",
		"station": "sink",
		"action": "pour_water",
		"layer": "water",
		"color": Color("#6cc2dc"),
	},
	"ice": {
		"label": "얼음",
		"station": "sink",
		"action": "add_ice",
		"layer": "ice",
		"color": Color("#a9dbe5"),
	},
	"espresso": {
		"label": "사장님 샷",
		"station": "main_table",
		"action": "pull_espresso",
		"layer": "espresso",
		"color": Color("#83503a"),
	},
	"lid": {
		"label": "뚜껑",
		"station": "pickup_counter",
		"action": "deliver_order",
		"layer": "lid",
		"color": Color("#d9e1dd"),
	},
	"sleeve": {
		"label": "홀더",
		"station": "pickup_counter",
		"action": "prepare_packaging",
		"layer": "sleeve",
		"color": Color("#bc7f58"),
	},
}

var order_id: String = ""
var menu_id: String = ""
var assembly: DrinkAssembly = null
var analyzer := GestureAnalyzer.new()
var current_station: String = "register"
var _last_gesture_score: float = 0.0
var _completed_steps: Array[String] = []
var _boss_result_ready: bool = false
var _boss_request_sent: bool = false
var _dragging_step: String = ""
var _drag_position: Vector2 = Vector2.ZERO
var _token_rects: Dictionary = {}

@onready var cup_composer: Control = %CupComposer
@onready var instruction_label: Label = %InstructionLabel
@onready var boss_button: Button = %BossButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	resized.connect(_refresh_layout)
	boss_button.pressed.connect(_on_boss_button_pressed)
	_refresh_layout()
	_refresh_state()


func start_order(new_order_id: String, new_menu_id: String) -> void:
	order_id = new_order_id
	menu_id = new_menu_id
	assembly = DrinkAssembly.new(new_menu_id)
	_last_gesture_score = 0.0
	_completed_steps.clear()
	_boss_result_ready = false
	_boss_request_sent = false
	_dragging_step = ""
	if is_instance_valid(cup_composer):
		cup_composer.reset()
	_refresh_state()


func set_station(station_id: String) -> void:
	current_station = station_id
	_dragging_step = ""
	_refresh_state()


func set_boss_result_ready(is_ready: bool) -> void:
	_boss_result_ready = is_ready
	if is_ready:
		interaction_message.emit("사장님이 샷을 내려두셨어요. 컵에 넣어주세요.")
	_refresh_state()


func mark_boss_working() -> void:
	_boss_request_sent = true
	_refresh_state()


func next_step() -> String:
	for step_id in STEP_ORDER:
		if not step_id in _completed_steps:
			return step_id
	return ""


func attempt_step(step_id: String) -> bool:
	if assembly == null:
		interaction_message.emit("먼저 주문을 받아주세요.")
		return false
	var expected: String = next_step()
	if step_id != expected:
		interaction_message.emit("영수증 순서를 확인해 주세요.")
		return false
	var info: Dictionary = STEP_INFO[step_id]
	if String(info["station"]) != current_station:
		interaction_message.emit("이 작업은 다른 장소에서 해야 해요.")
		return false
	if step_id == "espresso" and not _boss_result_ready:
		interaction_message.emit("사장님께 샷을 먼저 부탁드려야 해요.")
		return false

	var action := String(info["action"])
	var layer := String(info["layer"])
	assembly.apply_action(action, layer, 1.0)
	_completed_steps.append(step_id)
	cup_composer.apply_layer(layer)
	step_completed.emit(step_id)
	if next_step() == "":
		drink_ready.emit()
	_refresh_state()
	return true


func apply_drag(action: String, layer: String, amount: float) -> void:
	if assembly == null:
		return
	assembly.apply_action(action, layer, amount)
	if is_instance_valid(cup_composer) and layer in CupComposerScript.REQUIRED_LAYERS and not cup_composer.has_layer(layer):
		cup_composer.apply_layer(layer)


func apply_stir(points: Array[Vector2]) -> void:
	var score: float = analyzer.score_stir(points)
	_last_gesture_score = score
	if assembly == null:
		return
	assembly.apply_action("dissolve_powder", "mixed_base", score)


func apply_pour(action: String, layer: String, hold_seconds: float, target_seconds: float) -> void:
	var amount: float = analyzer.pour_amount(hold_seconds, target_seconds)
	_last_gesture_score = amount
	if assembly == null:
		return
	assembly.apply_action(action, layer, amount)


func apply_whip(points: Array[Vector2]) -> void:
	var score: float = analyzer.score_whip_path(points)
	_last_gesture_score = score
	if assembly == null:
		return
	assembly.apply_action("pipe_whipped_cream", "whipped_cream", score)


func current_layers() -> Array[String]:
	if assembly == null:
		return []
	return assembly.layers()


func completed_steps() -> Array[String]:
	return _completed_steps.duplicate()


func last_gesture_score() -> float:
	return _last_gesture_score


func _on_boss_button_pressed() -> void:
	if next_step() != "espresso" or current_station != "main_table" or _boss_request_sent:
		return
	_boss_request_sent = true
	boss_requested.emit()
	interaction_message.emit("사장님, 샷 하나 부탁드려요.")
	_refresh_state()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_begin_drag(mouse_event.position)
		else:
			_finish_drag(mouse_event.position)
		accept_event()
	elif event is InputEventMouseMotion and _dragging_step != "":
		_drag_position = (event as InputEventMouseMotion).position
		queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_begin_drag(touch_event.position)
		else:
			_finish_drag(touch_event.position)
		accept_event()
	elif event is InputEventScreenDrag and _dragging_step != "":
		_drag_position = (event as InputEventScreenDrag).position
		queue_redraw()
		accept_event()


func _begin_drag(pointer_position: Vector2) -> void:
	for step_id in _token_rects:
		var rect: Rect2 = _token_rects[step_id]
		if rect.has_point(pointer_position) and _is_step_draggable(String(step_id)):
			_dragging_step = String(step_id)
			_drag_position = pointer_position
			interaction_message.emit("%s을(를) 컵으로 옮겨주세요." % String(STEP_INFO[step_id]["label"]))
			queue_redraw()
			return


func _finish_drag(pointer_position: Vector2) -> void:
	if _dragging_step == "":
		return
	var dropped_step := _dragging_step
	_dragging_step = ""
	if _cup_drop_rect().has_point(pointer_position):
		attempt_step(dropped_step)
	else:
		interaction_message.emit("컵 안에 놓아주세요.")
	queue_redraw()


func _is_step_draggable(step_id: String) -> bool:
	if step_id != next_step():
		return false
	var info: Dictionary = STEP_INFO[step_id]
	if String(info["station"]) != current_station:
		return false
	if step_id == "espresso" and not _boss_result_ready:
		return false
	return true


func _visible_station_steps() -> Array[String]:
	var result: Array[String] = []
	for step_id in STEP_ORDER:
		var info: Dictionary = STEP_INFO[step_id]
		if String(info["station"]) == current_station and not step_id in _completed_steps:
			result.append(step_id)
	return result


func _refresh_layout() -> void:
	_token_rects.clear()
	var steps := _visible_station_steps()
	if steps.is_empty():
		queue_redraw()
		return
	var token_width := clampf((size.x - 48.0 - 12.0 * float(steps.size() - 1)) / float(steps.size()), 74.0, 118.0)
	var total_width := token_width * float(steps.size()) + 12.0 * float(steps.size() - 1)
	var start_x := (size.x - total_width) * 0.5
	var y := size.y - 82.0
	for index in range(steps.size()):
		_token_rects[steps[index]] = Rect2(start_x + float(index) * (token_width + 12.0), y, token_width, 62.0)
	queue_redraw()


func _refresh_state() -> void:
	if not is_node_ready():
		return
	_refresh_layout()
	var expected := next_step()
	if assembly == null:
		instruction_label.text = "손님의 주문을 먼저 받아주세요"
	elif expected == "":
		instruction_label.text = "음료가 완성됐어요. 픽업대에서 전달하세요"
	elif String(STEP_INFO[expected]["station"]) != current_station:
		instruction_label.text = "%s에서 다음 단계를 진행하세요" % _station_name(String(STEP_INFO[expected]["station"]))
	elif expected == "espresso" and not _boss_result_ready:
		instruction_label.text = "사장님께 에스프레소 샷을 부탁드리세요"
	else:
		instruction_label.text = "%s을(를) 컵으로 드래그하세요" % String(STEP_INFO[expected]["label"])

	boss_button.visible = expected == "espresso" and current_station == "main_table" and not _boss_result_ready
	boss_button.disabled = _boss_request_sent
	boss_button.text = "샷 준비 중..." if _boss_request_sent else "사장님, 샷 하나 부탁드려요"
	queue_redraw()


func _station_name(station_id: String) -> String:
	return {
		"register": "계산대",
		"sink": "싱크대",
		"main_table": "메인 책상",
		"sub_table": "서브 책상",
		"display_fridge": "큰 냉장고",
		"pickup_counter": "픽업대",
	}.get(station_id, "다른 장소")


func _cup_drop_rect() -> Rect2:
	if not is_instance_valid(cup_composer):
		return Rect2()
	return Rect2(cup_composer.position, cup_composer.size).grow(14.0)


func _draw() -> void:
	var mat_rect := _cup_drop_rect().grow(10.0)
	var mat_style := StyleBoxFlat.new()
	mat_style.bg_color = Color(0.94, 0.92, 0.86, 0.86)
	mat_style.border_color = Color("#b9aa94")
	mat_style.set_border_width_all(2)
	mat_style.set_corner_radius_all(7)
	draw_style_box(mat_style, mat_rect)

	var font := get_theme_default_font()
	var font_size := maxi(14, get_theme_default_font_size())
	for step_id in _token_rects:
		var rect: Rect2 = _token_rects[step_id]
		var info: Dictionary = STEP_INFO[step_id]
		var active := _is_step_draggable(String(step_id))
		var fill: Color = info["color"]
		fill = fill if active else fill.lerp(Color("#6f6b65"), 0.48)
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = Color("#f7f3ea") if active else Color("#817b73")
		style.set_border_width_all(3 if active else 1)
		style.set_corner_radius_all(6)
		draw_style_box(style, rect)
		draw_string(font, rect.position + Vector2(0.0, rect.size.y * 0.62), String(info["label"]), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color("#2d3231"))
		if not active:
			draw_circle(rect.position + Vector2(rect.size.x - 12.0, 12.0), 4.0, Color("#55504a"))

	if _dragging_step != "":
		var ghost_rect := Rect2(_drag_position - Vector2(48.0, 28.0), Vector2(96.0, 56.0))
		var ghost_info: Dictionary = STEP_INFO[_dragging_step]
		var ghost_style := StyleBoxFlat.new()
		var ghost_color: Color = ghost_info["color"]
		ghost_color.a = 0.84
		ghost_style.bg_color = ghost_color
		ghost_style.border_color = Color.WHITE
		ghost_style.set_border_width_all(3)
		ghost_style.set_corner_radius_all(6)
		draw_style_box(ghost_style, ghost_rect)
		draw_string(font, ghost_rect.position + Vector2(0.0, ghost_rect.size.y * 0.62), String(ghost_info["label"]), HORIZONTAL_ALIGNMENT_CENTER, ghost_rect.size.x, font_size, Color("#26302f"))
