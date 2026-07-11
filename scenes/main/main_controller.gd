extends Control

const GameState = preload("res://src/core/game_state.gd")
const ProjectConfig = preload("res://src/core/project_config.gd")
const CafeFont: FontFile = preload("res://assets/fonts/NotoSansKR-VF.ttf")
const CafeStationViewScript = preload("res://scenes/main/cafe_station_view.gd")
const ManufacturingScript = preload("res://scenes/manufacturing/manufacturing_screen.gd")
const ManufacturingScene = preload("res://scenes/manufacturing/ManufacturingScreen.tscn")

const STATION_IDS: Array[String] = [
	"register",
	"sink",
	"main_table",
	"sub_table",
	"display_fridge",
	"pickup_counter",
]
const STATION_NAMES := {
	"register": "계산대 안쪽",
	"sink": "싱크대",
	"main_table": "메인 책상",
	"sub_table": "서브 책상",
	"display_fridge": "큰 냉장고",
	"pickup_counter": "픽업대",
}
const STEP_LABELS := {
	"cup": "빈 컵 준비",
	"water": "물 붓기",
	"ice": "얼음 담기",
	"espresso": "사장님 샷 넣기",
	"lid": "뚜껑 닫기",
	"sleeve": "홀더 끼우기",
}

var game := GameState.new()
var selected_order_id: String = ""
var current_station_index: int = 0
var _order_accepted: bool = false
var _order_elapsed: float = 0.0
var _request_announced: bool = false
var _packaging_change_pending: bool = false
var _to_go: bool = false
var _boss_working: bool = false
var _boss_result_ready: bool = false
var _restocked_straws: bool = false
var _order_delivered: bool = false
var _shift_running: bool = true
var _toast_tween: Tween = null

var station_view = null
var manufacturing = null
var station_label: Label
var shift_label: Label
var money_label: Label
var receipt_number_label: Label
var receipt_menu_label: Label
var receipt_request_label: Label
var receipt_steps_label: Label
var receipt_boss_label: Label
var receipt_progress: ProgressBar
var customer_bubble: Panel
var customer_label: Label
var primary_button: Button
var secondary_button: Button
var bottom_hint_label: Label
var toast_label: Label
var left_button: Button
var right_button: Button


func _ready() -> void:
	var cafe_theme := Theme.new()
	cafe_theme.default_font = CafeFont
	cafe_theme.default_font_size = 16
	theme = cafe_theme
	_build_ui()
	game.consume_supply("pickup_counter", "straw", 58)
	manufacturing.step_completed.connect(_on_manufacturing_step_completed)
	manufacturing.boss_requested.connect(_on_boss_requested)
	manufacturing.drink_ready.connect(_on_drink_ready)
	manufacturing.interaction_message.connect(_show_toast)
	_set_station(0, false)
	_refresh_ui()


func _process(delta: float) -> void:
	if _shift_running:
		game.tick(delta)
		if game.shift.is_finished():
			_shift_running = false
			_show_toast("오늘 영업이 끝났어요. 정산을 확인하세요.")
	if _order_accepted and not _order_delivered:
		_order_elapsed += delta
		if _order_elapsed >= 7.0 and not _request_announced:
			_request_announced = true
			_packaging_change_pending = true
			_show_toast("손님 요청: 죄송한데 포장으로 바꿔주세요.")
	_collect_completed_boss_tasks()
	_refresh_clock()
	_refresh_context_actions()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#1f2b2e")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var top_bar := Panel.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 70.0
	top_bar.add_theme_stylebox_override("panel", _style_box(Color("#26383b"), Color("#516569"), 0, 0))
	add_child(top_bar)

	station_label = _make_label("계산대 안쪽", 25, Color("#f5f1e8"))
	station_label.position = Vector2(24.0, 17.0)
	station_label.size = Vector2(300.0, 38.0)
	top_bar.add_child(station_label)

	shift_label = _make_label("평상시 · 10:00", 17, Color("#d8e6df"))
	shift_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	shift_label.position = Vector2(-110.0, 22.0)
	shift_label.size = Vector2(220.0, 30.0)
	shift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(shift_label)

	money_label = _make_label("0원", 20, Color("#f0c66f"))
	money_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	money_label.position = Vector2(-272.0, 19.0)
	money_label.size = Vector2(128.0, 34.0)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(money_label)

	var level_label := _make_label("LEVEL 1 · 신입", 14, Color("#223234"))
	level_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	level_label.position = Vector2(-132.0, 17.0)
	level_label.size = Vector2(112.0, 36.0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_stylebox_override("normal", _style_box(Color("#dce8d7"), Color("#7c9a7a"), 2, 5))
	top_bar.add_child(level_label)

	var station_frame := Panel.new()
	station_frame.name = "StationFrame"
	station_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	station_frame.offset_left = 16.0
	station_frame.offset_top = 82.0
	station_frame.offset_right = -296.0
	station_frame.offset_bottom = -104.0
	station_frame.clip_contents = true
	station_frame.add_theme_stylebox_override("panel", _style_box(Color("#d9d2c4"), Color("#111b1d"), 3, 6))
	add_child(station_frame)

	station_view = CafeStationViewScript.new()
	station_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	station_frame.add_child(station_view)

	manufacturing = ManufacturingScene.instantiate()
	manufacturing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	manufacturing.visible = false
	station_frame.add_child(manufacturing)

	customer_bubble = Panel.new()
	customer_bubble.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	customer_bubble.position = Vector2(72.0, -168.0)
	customer_bubble.size = Vector2(440.0, 94.0)
	customer_bubble.add_theme_stylebox_override("panel", _style_box(Color("#fffaf0"), Color("#4e6262"), 3, 6))
	station_frame.add_child(customer_bubble)
	customer_label = _make_label("어서 오세요. 주문 도와드릴게요.", 18, Color("#2d3736"))
	customer_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	customer_label.offset_left = 18.0
	customer_label.offset_top = 12.0
	customer_label.offset_right = -18.0
	customer_label.offset_bottom = -12.0
	customer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	customer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	customer_bubble.add_child(customer_label)

	_build_receipt_panel()
	_build_bottom_bar()
	_build_navigation()

	toast_label = _make_label("", 15, Color("#284241"))
	toast_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toast_label.position = Vector2(-276.0, 420.0)
	toast_label.size = Vector2(252.0, 82.0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_stylebox_override("normal", _style_box(Color(0.89, 0.94, 0.91, 0.98), Color("#7e9d99"), 2, 6))
	toast_label.modulate.a = 0.0
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_label)


func _build_receipt_panel() -> void:
	var receipt := Panel.new()
	receipt.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	receipt.offset_left = -284.0
	receipt.offset_top = 82.0
	receipt.offset_right = -16.0
	receipt.offset_bottom = -104.0
	receipt.add_theme_stylebox_override("panel", _style_box(Color("#fffaf0"), Color("#9c8872"), 2, 4))
	add_child(receipt)

	var header := Label.new()
	header.text = "ORDER RECEIPT"
	header.position = Vector2(18.0, 15.0)
	header.size = Vector2(232.0, 24.0)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color("#786a5b"))
	receipt.add_child(header)

	receipt_number_label = _make_label("대기 중", 16, Color("#403a34"))
	receipt_number_label.position = Vector2(18.0, 48.0)
	receipt_number_label.size = Vector2(232.0, 25.0)
	receipt.add_child(receipt_number_label)

	receipt_menu_label = _make_label("손님의 주문을 받아주세요", 22, Color("#263638"))
	receipt_menu_label.position = Vector2(18.0, 78.0)
	receipt_menu_label.size = Vector2(232.0, 58.0)
	receipt_menu_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	receipt.add_child(receipt_menu_label)

	receipt_request_label = _make_label("요청사항 없음", 14, Color("#9b4f48"))
	receipt_request_label.position = Vector2(18.0, 139.0)
	receipt_request_label.size = Vector2(232.0, 30.0)
	receipt.add_child(receipt_request_label)

	var divider := HSeparator.new()
	divider.position = Vector2(18.0, 174.0)
	divider.size = Vector2(232.0, 8.0)
	receipt.add_child(divider)

	receipt_steps_label = _make_label("주문을 받으면 제조 순서가 인쇄됩니다.", 15, Color("#45413c"))
	receipt_steps_label.position = Vector2(18.0, 190.0)
	receipt_steps_label.size = Vector2(232.0, 206.0)
	receipt_steps_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	receipt_steps_label.add_theme_constant_override("line_spacing", 6)
	receipt.add_child(receipt_steps_label)

	receipt_boss_label = _make_label("사장님 작업 없음", 14, Color("#456f70"))
	receipt_boss_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	receipt_boss_label.offset_left = 18.0
	receipt_boss_label.offset_top = -78.0
	receipt_boss_label.offset_right = -18.0
	receipt_boss_label.offset_bottom = -48.0
	receipt.add_child(receipt_boss_label)

	receipt_progress = ProgressBar.new()
	receipt_progress.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	receipt_progress.offset_left = 18.0
	receipt_progress.offset_top = -42.0
	receipt_progress.offset_right = -18.0
	receipt_progress.offset_bottom = -24.0
	receipt_progress.show_percentage = false
	receipt_progress.min_value = 0.0
	receipt_progress.max_value = 6.0
	receipt_progress.value = 0.0
	receipt.add_child(receipt_progress)


func _build_bottom_bar() -> void:
	var bar := Panel.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 16.0
	bar.offset_top = -92.0
	bar.offset_right = -296.0
	bar.offset_bottom = -16.0
	bar.add_theme_stylebox_override("panel", _style_box(Color("#26383b"), Color("#516569"), 2, 5))
	add_child(bar)

	bottom_hint_label = _make_label("문 앞의 손님에게 주문을 받아보세요", 16, Color("#dce7e2"))
	bottom_hint_label.position = Vector2(20.0, 16.0)
	bottom_hint_label.size = Vector2(410.0, 44.0)
	bottom_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bar.add_child(bottom_hint_label)

	secondary_button = _make_button("빨대 채우기", Color("#708d86"))
	secondary_button.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	secondary_button.offset_left = -360.0
	secondary_button.offset_top = 12.0
	secondary_button.offset_right = -190.0
	secondary_button.offset_bottom = -12.0
	secondary_button.visible = false
	secondary_button.pressed.connect(_on_secondary_button_pressed)
	bar.add_child(secondary_button)

	primary_button = _make_button("주문 받기", Color("#c95f55"))
	primary_button.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	primary_button.offset_left = -178.0
	primary_button.offset_top = 12.0
	primary_button.offset_right = -12.0
	primary_button.offset_bottom = -12.0
	primary_button.pressed.connect(_on_primary_button_pressed)
	bar.add_child(primary_button)


func _build_navigation() -> void:
	left_button = _make_button("‹", Color("#344d50"))
	left_button.tooltip_text = "왼쪽 장소로 이동"
	left_button.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	left_button.position = Vector2(28.0, -28.0)
	left_button.size = Vector2(58.0, 58.0)
	left_button.add_theme_font_size_override("font_size", 34)
	left_button.pressed.connect(_on_left_pressed)
	add_child(left_button)

	right_button = _make_button("›", Color("#344d50"))
	right_button.tooltip_text = "오른쪽 장소로 이동"
	right_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_button.position = Vector2(-354.0, -28.0)
	right_button.size = Vector2(58.0, 58.0)
	right_button.add_theme_font_size_override("font_size", 34)
	right_button.pressed.connect(_on_right_pressed)
	add_child(right_button)


func _on_left_pressed() -> void:
	var next_index := posmod(current_station_index - 1, STATION_IDS.size())
	_set_station(next_index, true, -1)


func _on_right_pressed() -> void:
	var next_index := posmod(current_station_index + 1, STATION_IDS.size())
	_set_station(next_index, true, 1)


func _set_station(index: int, animated: bool, direction: int = 1) -> void:
	current_station_index = clampi(index, 0, STATION_IDS.size() - 1)
	var station_id := STATION_IDS[current_station_index]
	if animated:
		station_view.slide_to(station_id, direction)
	else:
		station_view.set_station(station_id)
	station_label.text = String(STATION_NAMES[station_id])
	manufacturing.set_station(station_id)
	manufacturing.visible = _order_accepted and station_id in ["sink", "main_table", "pickup_counter"] and not _order_delivered
	customer_bubble.visible = station_id == "register" and not _order_delivered
	_refresh_ui()


func _on_primary_button_pressed() -> void:
	if not _order_accepted:
		_take_order()
		return
	if _order_delivered:
		_prepare_next_customer()
		return
	if _packaging_change_pending and STATION_IDS[current_station_index] in ["register", "pickup_counter"]:
		_accept_packaging_change()
		return
	if manufacturing.cup_composer.is_complete() and STATION_IDS[current_station_index] == "pickup_counter":
		_deliver_order()


func _on_secondary_button_pressed() -> void:
	if STATION_IDS[current_station_index] != "pickup_counter" or _restocked_straws:
		return
	game.restock_supply("pickup_counter", "straw", 18)
	_restocked_straws = true
	_show_toast("빨대를 가득 채웠어요. 사장님 샷도 곧 준비됩니다.")
	_refresh_ui()


func _take_order() -> void:
	if _order_accepted:
		return
	selected_order_id = game.spawn_order("iced_americano", [])
	if selected_order_id == "":
		_show_toast("주문을 만들지 못했어요.")
		return
	_order_accepted = true
	_order_delivered = false
	_order_elapsed = 0.0
	_request_announced = false
	_packaging_change_pending = false
	_to_go = false
	_boss_working = false
	_boss_result_ready = false
	_restocked_straws = false
	manufacturing.start_order(selected_order_id, "iced_americano")
	customer_label.text = "아이스 아메리카노 한 잔 부탁드려요. 일단 매장에서 마실게요."
	_show_toast("주문이 인쇄됐어요. 싱크대에서 빈 컵부터 준비하세요.")
	_refresh_ui()


func _accept_packaging_change() -> void:
	if not game.add_order_request(selected_order_id, "to_go"):
		_show_toast("포장 변경 요청을 반영할 수 없어요. 주문을 다시 확인해주세요.")
		return
	_packaging_change_pending = false
	_to_go = true
	customer_label.text = "고마워요. 포장으로 부탁드릴게요."
	_show_toast("영수증을 포장 주문으로 수정했어요.")
	_refresh_ui()


func _on_boss_requested() -> void:
	if selected_order_id == "" or _boss_working or _boss_result_ready:
		return
	var routed: Array[String] = game.route_unavailable_actions(selected_order_id)
	if "pull_espresso" not in routed:
		_show_toast("지금 부탁드릴 사장님 작업이 없어요.")
		return
	_boss_working = true
	manufacturing.mark_boss_working()
	_show_toast("사장님이 샷을 내리는 동안 다른 주문이나 비품을 준비할 수 있어요.")
	_refresh_ui()


func _collect_completed_boss_tasks() -> void:
	for task in game.boss_queue.collect_completed():
		if String(task.get("order_id", "")) != selected_order_id:
			continue
		if String(task.get("action", "")) == "pull_espresso":
			_boss_working = false
			_boss_result_ready = true
			manufacturing.set_boss_result_ready(true)
	_refresh_ui()


func _on_manufacturing_step_completed(step_id: String) -> void:
	if selected_order_id == "":
		return
	var synced := true
	match step_id:
		"cup":
			synced = game.consume_supply("sink", "cup", 1) and game.perform_action(selected_order_id, "prepare_packaging", "cup", 1.0)
		"water":
			synced = game.perform_action(selected_order_id, "pour_water", "water", 0.82)
		"ice":
			synced = game.consume_supply("sink", "ice", 1) and game.perform_action(selected_order_id, "add_ice", "ice", 0.9)
		"espresso":
			synced = game.apply_boss_result(selected_order_id, "pull_espresso", "espresso", 1.0)
			_boss_result_ready = false
		"lid":
			synced = game.consume_supply("sink", "lid", 1) and game.perform_action(selected_order_id, "deliver_order", "lid", 1.0)
		"sleeve":
			synced = game.consume_supply("pickup_counter", "sleeve", 1)
	if not synced:
		_show_toast("제조 순서나 비품 수량을 다시 확인해 주세요.")
	_refresh_ui()


func _on_drink_ready() -> void:
	_show_toast("음료가 완성됐어요. 손님 요청을 확인하고 전달하세요.")
	_refresh_ui()


func _deliver_order() -> void:
	if _packaging_change_pending:
		_show_toast("손님의 포장 변경 요청을 먼저 반영해 주세요.")
		return
	if not manufacturing.cup_composer.is_complete() or not game.can_deliver(selected_order_id):
		_show_toast("아직 빠진 제조 단계가 있어요.")
		return
	var satisfied: Array[String] = []
	if _to_go:
		satisfied.append("to_go")
	var result: Dictionary = game.deliver(selected_order_id, satisfied)
	if result.is_empty():
		_show_toast("음료를 전달할 수 없어요. 영수증을 확인해 주세요.")
		return
	_order_delivered = true
	manufacturing.visible = false
	station_view.customer_visible = true
	station_view.queue_redraw()
	customer_label.text = "감사합니다. 잘 마실게요!"
	_show_toast("주문 완료! 정확한 협업으로 매출이 올랐어요.")
	_refresh_ui()


func _prepare_next_customer() -> void:
	_order_accepted = false
	_order_delivered = false
	selected_order_id = ""
	manufacturing.visible = false
	customer_label.text = "다음 손님이 들어오고 있어요."
	_set_station(0, true, -1)
	_refresh_ui()


func _refresh_ui() -> void:
	if station_label == null:
		return
	_refresh_clock()
	_refresh_receipt()
	_refresh_context_actions()


func _refresh_clock() -> void:
	if shift_label == null:
		return
	var phase: Dictionary = game.shift.current_phase()
	var phase_name: String = String({
		"normal": "평상시",
		"peak": "피크타임",
		"closing": "마감 준비",
	}.get(String(phase.get("name", "normal")), "평상시"))
	var remaining_seconds: int = maxi(0, int(ceil(ProjectConfig.SHIFT_SECONDS - game.shift.elapsed)))
	var remaining_minutes: int = remaining_seconds / 60
	var remaining_remainder: int = remaining_seconds % 60
	shift_label.text = "%s · %02d:%02d" % [phase_name, remaining_minutes, remaining_remainder]
	money_label.text = "%s원" % _format_money(int(game.settlement().get("money", 0)))


func _refresh_receipt() -> void:
	if not _order_accepted:
		receipt_number_label.text = "주문 대기 중"
		receipt_menu_label.text = "손님의 주문을 받아주세요"
		receipt_request_label.text = "요청사항 없음"
		receipt_steps_label.text = "주문을 받으면\n제조 순서가 여기에 인쇄됩니다."
		receipt_boss_label.text = "사장님 작업 없음"
		receipt_progress.value = 0.0
		return
	receipt_number_label.text = "A-%02d · %s" % [int(selected_order_id.get_slice("_", 1)), "완료" if _order_delivered else "제조 중"]
	receipt_menu_label.text = "아이스 아메리카노"
	if _packaging_change_pending:
		receipt_request_label.text = "● 포장 변경 요청"
	elif _to_go:
		receipt_request_label.text = "포장 · 홀더 포함"
	else:
		receipt_request_label.text = "매장 이용"
	var lines: Array[String] = []
	var completed: Array[String] = manufacturing.completed_steps()
	for step_id in ManufacturingScript.STEP_ORDER:
		var marker := "✓" if step_id in completed else "·"
		lines.append("%s  %s" % [marker, String(STEP_LABELS[step_id])])
	receipt_steps_label.text = "\n".join(lines)
	receipt_progress.value = float(completed.size())
	if _boss_result_ready:
		receipt_boss_label.text = "● 샷 준비 완료 · 메인 책상"
	elif _boss_working:
		var task: Dictionary = game.boss_queue.current_task()
		var remaining := float(task.get("remaining", 0.0))
		receipt_boss_label.text = "사장님 샷 추출 중 · %.1f초" % remaining
	else:
		receipt_boss_label.text = "사장님 작업 없음"


func _refresh_context_actions() -> void:
	if primary_button == null:
		return
	var station_id := STATION_IDS[current_station_index]
	primary_button.visible = false
	secondary_button.visible = false
	if not _order_accepted:
		bottom_hint_label.text = "문 앞의 손님에게 주문을 받아보세요"
		primary_button.text = "주문 받기"
		primary_button.visible = station_id == "register"
		return
	if _order_delivered:
		bottom_hint_label.text = "첫 주문을 완료했어요. 다음 손님을 맞이할 수 있어요"
		primary_button.text = "다음 손님 맞이하기"
		primary_button.visible = true
		return
	var expected: String = manufacturing.next_step()
	if expected == "":
		bottom_hint_label.text = "음료가 완성됐어요. 픽업대에서 전달하세요"
	elif String(ManufacturingScript.STEP_INFO[expected]["station"]) == station_id:
		bottom_hint_label.text = "%s을(를) 컵으로 드래그하세요" % String(ManufacturingScript.STEP_INFO[expected]["label"])
	else:
		bottom_hint_label.text = "%s에서 다음 단계를 진행하세요" % String(STATION_NAMES[String(ManufacturingScript.STEP_INFO[expected]["station"])])

	if _packaging_change_pending and station_id in ["register", "pickup_counter"]:
		primary_button.text = "포장으로 변경"
		primary_button.visible = true
	elif manufacturing.cup_composer.is_complete() and station_id == "pickup_counter":
		primary_button.text = "손님께 전달"
		primary_button.visible = true
	if station_id == "pickup_counter" and not _restocked_straws:
		secondary_button.text = "빨대 채우기 %d/80" % game.supply_amount("pickup_counter", "straw")
		secondary_button.visible = _boss_working or game.supply_amount("pickup_counter", "straw") < 40


func _show_toast(message: String) -> void:
	if toast_label == null:
		return
	if is_instance_valid(_toast_tween):
		_toast_tween.kill()
	toast_label.text = message
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(56.0, 48.0)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#f7f4ea"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style_box(color, color.darkened(0.24), 2, 6))
	button.add_theme_stylebox_override("hover", _style_box(color.lightened(0.1), Color("#f0d38b"), 2, 6))
	button.add_theme_stylebox_override("pressed", _style_box(color.darkened(0.1), Color("#f0d38b"), 2, 6))
	button.add_theme_stylebox_override("disabled", _style_box(Color("#596361"), Color("#3e4847"), 1, 6))
	return button


func _style_box(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _format_money(value: int) -> String:
	var digits := str(maxi(0, value))
	var result := ""
	while digits.length() > 3:
		result = "," + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return digits + result


# Compatibility hooks remain callable for existing automated tests, but are not exposed in the UI.
func _on_spawn_order_pressed() -> void:
	_take_order()


func _on_basic_step_pressed() -> void:
	if not _order_accepted:
		_take_order()
	manufacturing.set_station("sink")
	for step_id in ["cup", "water", "ice"]:
		if manufacturing.next_step() == step_id:
			manufacturing.attempt_step(step_id)
	if manufacturing.next_step() == "espresso" and _boss_result_ready:
		manufacturing.set_station("main_table")
		manufacturing.attempt_step("espresso")
	manufacturing.set_station(STATION_IDS[current_station_index])


func _on_boss_help_pressed() -> void:
	_on_boss_requested()


func _on_deliver_pressed() -> void:
	manufacturing.set_station("pickup_counter")
	for step_id in ["lid", "sleeve"]:
		if manufacturing.next_step() == step_id:
			manufacturing.attempt_step(step_id)
	manufacturing.set_station(STATION_IDS[current_station_index])
	if _packaging_change_pending:
		_accept_packaging_change()
	_deliver_order()


func _on_order_selected(_index: int) -> void:
	pass
