extends RefCounted

var _test_tree: SceneTree = null

func set_test_tree(value: SceneTree) -> void:
	_test_tree = value

func get_test_methods() -> Array[String]:
	return [
		"test_level_one_americano_boss_help_flow",
		"test_main_controller_completes_layered_americano",
		"test_main_controller_handles_packaging_change_and_restock",
		"test_shift_can_tick_through_peak_and_settle"
	]

func test_level_one_americano_boss_help_flow() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = ["to_go"]
	var order_id: String = game.spawn_order("iced_americano", requests)
	if order_id == "":
		return "First playable should spawn an iced americano order"
	var unavailable: Array[String] = game.route_unavailable_actions(order_id)
	if unavailable != ["pull_espresso"]:
		return "Level 1 should route only pull_espresso to boss, got %s" % [unavailable]
	if not game.perform_action(order_id, "prepare_packaging", "cup", 1.0):
		return "Player should be able to prepare an empty cup"
	if not game.perform_action(order_id, "pour_water", "water", 1.0):
		return "Player should be able to pour water before ice"
	if not game.perform_action(order_id, "add_ice", "ice", 1.0):
		return "Player should be able to add ice after water"
	game.tick(5.0)
	var completed: Array[Dictionary] = game.boss_queue.collect_completed()
	if completed.size() != 1:
		return "Boss queue should complete one espresso task"
	if not game.apply_boss_result(order_id, "pull_espresso", "espresso", 1.0):
		return "Boss espresso should be added by the player"
	if not game.perform_action(order_id, "deliver_order", "lid", 1.0):
		return "Player should be able to finish the drink"
	var expected: Array[String] = ["prepare_packaging", "pour_water", "add_ice", "pull_espresso", "deliver_order"]
	if game.assemblies[order_id].performed_actions() != expected:
		return "Americano recipe order should be exact"
	var satisfied_requests: Array[String] = ["to_go"]
	var result: Dictionary = game.deliver(order_id, satisfied_requests)
	if result.is_empty() or result["score"]["total"] < 80:
		return "Completed first order should score at least 80"
	return ""

func test_main_controller_completes_layered_americano() -> String:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	_test_tree.root.add_child(main)
	if main.selected_order_id != "":
		main.free()
		return "Customer order should wait for player acceptance"
	main._on_primary_button_pressed()
	var order_id: String = main.selected_order_id
	if order_id == "":
		main.free()
		return "Order button should accept the waiting customer"
	main.manufacturing.set_station("sink")
	for step_id in ["cup", "water", "ice"]:
		if not main.manufacturing.attempt_step(step_id):
			main.free()
			return "Sink step failed: %s" % step_id
	main.manufacturing.set_station("main_table")
	main.manufacturing._on_boss_button_pressed()
	main._process(5.0)
	if not main.manufacturing.attempt_step("espresso"):
		main.free()
		return "Boss espresso should become draggable after the wait"
	main.manufacturing.set_station("pickup_counter")
	for step_id in ["lid", "sleeve"]:
		if not main.manufacturing.attempt_step(step_id):
			main.free()
			return "Pickup step failed: %s" % step_id
	main._set_station(5, false)
	main._on_primary_button_pressed()
	var settlement: Dictionary = main.game.settlement()
	if settlement.get("money", 0) <= 0 or main.game.assemblies.has(order_id):
		main.free()
		return "Layered drink delivery should earn money and close the assembly"
	main.free()
	return ""

func test_main_controller_handles_packaging_change_and_restock() -> String:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	_test_tree.root.add_child(main)
	main._on_primary_button_pressed()
	main._process(7.1)
	if not main._packaging_change_pending:
		main.free()
		return "Customer should request a packaging change during the order"
	main._on_primary_button_pressed()
	if not main._to_go or main._packaging_change_pending:
		main.free()
		return "Player should be able to accept the packaging change"
	if "to_go" not in main.game.order_queue.get_order(main.selected_order_id)["requests"]:
		main.free()
		return "Accepted packaging change should update the live order data"
	main._set_station(5, false)
	var before: int = main.game.supply_amount("pickup_counter", "straw")
	main._on_secondary_button_pressed()
	var after: int = main.game.supply_amount("pickup_counter", "straw")
	if after <= before:
		main.free()
		return "Restock action should increase straw stock"
	main.free()
	return ""

func test_shift_can_tick_through_peak_and_settle() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.tick(420.0)
	var phase: Dictionary = game.shift.current_phase()
	if phase.get("name", "") != "peak":
		return "Shift should be in peak after 420 seconds"
	game.tick(180.0)
	if not game.shift.is_finished():
		return "Shift should finish after 600 seconds"
	var settlement: Dictionary = game.settlement()
	if not settlement.has("money") or not settlement.has("experience") or not settlement.has("reputation"):
		return "Settlement should include money, experience, and reputation"
	return ""
