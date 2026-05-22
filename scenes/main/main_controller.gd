extends Control

const GameState = preload("res://src/core/game_state.gd")
const StationView = preload("res://scenes/stations/station_view.gd")

var game := GameState.new()
var station_view := StationView.new()
var _displayed_order_rows: Array[String] = []

func _ready() -> void:
	add_child(station_view)
	station_view.hide()
	game.spawn_order("iced_americano", [])
	_refresh()

func _process(delta: float) -> void:
	game.tick(delta)
	_refresh()

func _on_left_pressed() -> void:
	station_view.go_left()
	_refresh()

func _on_right_pressed() -> void:
	station_view.go_right()
	_refresh()

func _on_spawn_order_pressed() -> void:
	game.spawn_order("iced_tea", [])
	_refresh()

func _refresh() -> void:
	%StationLabel.text = station_view.station_title()
	var phase := game.shift.current_phase()
	%PhaseLabel.text = "Phase: %s" % phase.get("name", "unknown")
	var order_rows: Array[String] = []
	for order in game.active_orders():
		order_rows.append("%s - %s (%s)" % [
			order.get("id", ""),
			order.get("menu_id", ""),
			order.get("state", "")
		])
	if order_rows == _displayed_order_rows:
		return
	_displayed_order_rows = order_rows.duplicate()
	%OrderList.clear()
	for row in _displayed_order_rows:
		%OrderList.add_item(row)
