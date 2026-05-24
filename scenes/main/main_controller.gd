extends Control

const GameState = preload("res://src/core/game_state.gd")
const StationView = preload("res://scenes/stations/station_view.gd")
const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const GENERATED_DRINK_LAYER_PATH := "res://assets/generated/drinks/layers/iced_americano_water_only.png"

var game := GameState.new()
var station_view := StationView.new()
var selected_order_id: String = ""
var _displayed_order_rows: Array[String] = []
var _displayed_order_ids: Array[String] = []

const STATION_PANEL_NAMES := {
	"register": "RegisterStation",
	"sink": "SinkStation",
	"main_table": "MainTableStation",
	"sub_table": "SubTableStation",
	"display_fridge": "DisplayFridgeStation",
	"pickup_counter": "PickupCounterStation"
}

func _ready() -> void:
	add_child(station_view)
	station_view.hide()
	_add_generated_drink_preview()
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
	var order: Dictionary = game.order_queue.get_order(selected_order_id)
	if order.is_empty() or not game.assemblies.has(selected_order_id):
		return
	var menu_id := String(order["menu_id"])
	var menu: Dictionary = game.catalog.get_by_id(menu_id)
	if menu.is_empty():
		return
	var assembly: DrinkAssembly = game.assemblies[selected_order_id]
	var performed_actions: Array = assembly.performed_actions()
	var required_actions: Array = menu["required_actions"]
	for required_action in required_actions:
		var action := String(required_action)
		if action == "deliver_order":
			continue
		if action in performed_actions:
			continue
		if not game.progress.can_perform(action):
			continue
		if game.perform_action(selected_order_id, action, _layer_for_player_action(action, menu_id), 1.0):
			performed_actions.append(action)
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
	var result: Dictionary = game.deliver(selected_order_id, ["to_go"])
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
	_refresh_station_scene()
	var phase: Dictionary = game.shift.current_phase()
	%PhaseLabel.text = "Phase: %s / Money: %d" % [phase.get("name", "unknown"), game.settlement().get("money", 0)]
	var order_rows: Array[String] = []
	var order_ids: Array[String] = []
	for order in game.active_orders():
		var order_id := String(order.get("id", ""))
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

func _refresh_station_scene() -> void:
	var station_scenes := get_node_or_null("%StationScenes")
	if station_scenes == null:
		return
	var current_panel_name := String(STATION_PANEL_NAMES.get(station_view.current_station_id(), ""))
	for child in station_scenes.get_children():
		child.visible = child.name == current_panel_name

func _add_generated_drink_preview() -> void:
	var station := get_node_or_null("StationScenes/PickupCounterStation")
	if station == null or station.get_node_or_null("GeneratedDrinkLayerPreview") != null:
		return
	var texture := _load_generated_drink_texture()
	if texture == null:
		return
	var preview := TextureRect.new()
	preview.name = "GeneratedDrinkLayerPreview"
	preview.texture = texture
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.position = Vector2(178.0, 82.0)
	preview.size = Vector2(140.0, 140.0)
	station.add_child(preview)

func _load_generated_drink_texture() -> Texture2D:
	if ResourceLoader.exists(GENERATED_DRINK_LAYER_PATH):
		return load(GENERATED_DRINK_LAYER_PATH) as Texture2D
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(GENERATED_DRINK_LAYER_PATH)) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _collect_completed_boss_tasks() -> void:
	for task in game.boss_queue.collect_completed():
		var order_id := String(task.get("order_id", ""))
		var action := String(task.get("action", ""))
		if order_id == "" or action == "" or not game.assemblies.has(order_id):
			continue
		var assembly: DrinkAssembly = game.assemblies[order_id]
		if action in assembly.performed_actions():
			continue
		assembly.apply_action(action, _layer_for_boss_action(action), 1.0)

func _route_unperformed_boss_actions(order_id: String) -> void:
	if not game.assemblies.has(order_id):
		return
	var assembly: DrinkAssembly = game.assemblies[order_id]
	var performed_actions: Array = assembly.performed_actions()
	for action in _missing_boss_actions(order_id):
		if not (action in performed_actions):
			game.boss_queue.enqueue(order_id, action)

func _missing_boss_actions(order_id: String) -> Array[String]:
	var order: Dictionary = game.order_queue.get_order(order_id)
	if order.is_empty():
		return []
	var menu: Dictionary = game.catalog.get_by_id(String(order["menu_id"]))
	if menu.is_empty():
		return []
	var required_actions: Array = menu["required_actions"]
	return game.progress.missing_actions(required_actions)

func _layer_for_boss_action(action: String) -> String:
	if action == "pull_espresso":
		return "espresso"
	return action

func _layer_for_player_action(action: String, menu_id: String) -> String:
	if action == "prepare_packaging":
		return "cup"
	if action == "add_ice":
		return "ice"
	if action == "pour_water":
		return "water"
	if action == "add_premade_base":
		return _premade_base_layer(menu_id)
	return action

func _premade_base_layer(menu_id: String) -> String:
	if menu_id == "iced_tea" or menu_id == "hot_black_tea" or menu_id == "milk_tea":
		return "tea_base"
	if menu_id == "cold_brew":
		return "cold_brew_base"
	if menu_id == "strawberry_latte" or menu_id == "strawberry_smoothie":
		return "strawberry_base"
	if menu_id == "blueberry_latte":
		return "blueberry_base"
	if menu_id == "lemon_ade":
		return "lemon_base"
	if menu_id == "grapefruit_ade":
		return "grapefruit_base"
	if menu_id == "blue_lemon_ade":
		return "blue_lemon_base"
	if menu_id == "mango_smoothie":
		return "mango_base"
	if menu_id == "yogurt_smoothie":
		return "yogurt_base"
	return "premade_base"

func _select_first_active_order() -> void:
	for order in game.active_orders():
		selected_order_id = order.get("id", "")
		return
	selected_order_id = ""
