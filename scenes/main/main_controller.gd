extends Control

const GameState = preload("res://src/core/game_state.gd")
const StationView = preload("res://scenes/stations/station_view.gd")

var game := GameState.new()
var station_view := StationView.new()
var selected_order_id: String = ""
var _displayed_order_rows: Array[String] = []
var _displayed_order_ids: Array[String] = []

func _ready() -> void:
	add_child(station_view)
	station_view.hide()
	selected_order_id = game.spawn_order("iced_americano", ["to_go"])
	_refresh()

func _process(delta: float) -> void:
	game.tick(delta)
	_collect_completed_boss_tasks()
	_refresh()

func _on_left_pressed() -> void:
	station_view.go_left()
	_refresh()

func _on_right_pressed() -> void:
	station_view.go_right()
	_refresh()

func _on_spawn_order_pressed() -> void:
	var order_id := game.spawn_order("iced_tea", [])
	if order_id != "":
		selected_order_id = order_id
	_refresh()

func _on_basic_step_pressed() -> void:
	if selected_order_id == "":
		return
	game.perform_action(selected_order_id, "prepare_packaging", "cup", 1.0)
	game.perform_action(selected_order_id, "add_ice", "ice", 1.0)
	game.perform_action(selected_order_id, "pour_water", "water", 1.0)
	_refresh()

func _on_boss_help_pressed() -> void:
	if selected_order_id == "":
		return
	_route_unperformed_boss_actions(selected_order_id)
	_refresh()

func _on_deliver_pressed() -> void:
	if selected_order_id == "":
		return
	_collect_completed_boss_tasks()
	game.perform_action(selected_order_id, "deliver_order", "lid", 1.0)
	var result := game.deliver(selected_order_id, ["to_go"])
	if not result.is_empty():
		_select_first_active_order()
	_refresh()

func _on_order_selected(index: int) -> void:
	if index < 0 or index >= _displayed_order_ids.size():
		return
	selected_order_id = _displayed_order_ids[index]
	_refresh()

func _refresh() -> void:
	%StationLabel.text = station_view.station_title()
	var phase := game.shift.current_phase()
	%PhaseLabel.text = "Phase: %s / Money: %d" % [phase.get("name", "unknown"), game.settlement().get("money", 0)]
	var order_rows: Array[String] = []
	var order_ids: Array[String] = []
	for order in game.active_orders():
		var order_id: String = order.get("id", "")
		order_ids.append(order_id)
		order_rows.append("%s - %s / Patience: %.0f / %s" % [
			order_id,
			order.get("menu_id", ""),
			order.get("patience_remaining", 0.0),
			order.get("state", "")
		])
	if selected_order_id == "" or not (selected_order_id in order_ids):
		selected_order_id = order_ids[0] if not order_ids.is_empty() else ""
	if order_rows == _displayed_order_rows:
		return
	_displayed_order_rows = order_rows.duplicate()
	_displayed_order_ids = order_ids.duplicate()
	%OrderList.clear()
	for row in _displayed_order_rows:
		%OrderList.add_item(row)
	if selected_order_id in _displayed_order_ids:
		%OrderList.select(_displayed_order_ids.find(selected_order_id))

func _collect_completed_boss_tasks() -> void:
	for task in game.boss_queue.collect_completed():
		var order_id: String = task.get("order_id", "")
		var action: String = task.get("action", "")
		if order_id == "" or action == "" or not game.assemblies.has(order_id):
			continue
		if action in game.assemblies[order_id].performed_actions():
			continue
		game.assemblies[order_id].apply_action(action, _layer_for_boss_action(action), 1.0)

func _route_unperformed_boss_actions(order_id: String) -> void:
	if not game.assemblies.has(order_id):
		return
	var performed_actions: Array = game.assemblies[order_id].performed_actions()
	for action in _missing_boss_actions(order_id):
		if not (action in performed_actions):
			game.boss_queue.enqueue(order_id, action)

func _missing_boss_actions(order_id: String) -> Array[String]:
	var order := game.order_queue.get_order(order_id)
	if order.is_empty():
		return []
	var menu := game.catalog.get_by_id(order["menu_id"])
	if menu.is_empty():
		return []
	return game.progress.missing_actions(menu["required_actions"])

func _layer_for_boss_action(action: String) -> String:
	if action == "pull_espresso":
		return "espresso"
	return action

func _select_first_active_order() -> void:
	for order in game.active_orders():
		selected_order_id = order.get("id", "")
		return
	selected_order_id = ""
