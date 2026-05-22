extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_level_one_americano_boss_help_flow",
		"test_main_controller_buttons_complete_first_order",
		"test_shift_can_tick_through_peak_and_settle"
	]

func test_level_one_americano_boss_help_flow() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var order_id: String = game.spawn_order("iced_americano", ["to_go"])
	if order_id == "":
		return "First playable should spawn an iced americano order"
	var unavailable := game.route_unavailable_actions(order_id)
	if unavailable != ["pull_espresso"]:
		return "Level 1 should route only pull_espresso to boss, got %s" % [unavailable]
	if not game.perform_action(order_id, "prepare_packaging", "cup", 1.0):
		return "Player should be able to prepare packaging"
	if not game.perform_action(order_id, "add_ice", "ice", 1.0):
		return "Player should be able to add ice"
	if not game.perform_action(order_id, "pour_water", "water", 1.0):
		return "Player should be able to pour water"
	game.tick(5.0)
	var completed: Array = game.boss_queue.collect_completed()
	if completed.size() != 1:
		return "Boss queue should complete pull_espresso, got %d completed tasks" % completed.size()
	var boss_task: Dictionary = completed[0]
	if boss_task.get("order_id", "") != order_id or boss_task.get("action", "") != "pull_espresso":
		return "Boss completed task should match order and action, got %s" % [boss_task]
	if not game.assemblies.has(order_id):
		return "Assembly should exist before delivery"
	game.assemblies[order_id].apply_action("pull_espresso", "espresso", 1.0)
	if not game.perform_action(order_id, "deliver_order", "lid", 1.0):
		return "Player should be able to mark order delivered before scoring"
	var actions_before_delivery: Array = game.assemblies[order_id].performed_actions()
	if actions_before_delivery != ["prepare_packaging", "add_ice", "pour_water", "pull_espresso", "deliver_order"]:
		return "Assembly should have completed americano recipe before delivery, got %s" % [actions_before_delivery]
	var result: Dictionary = game.deliver(order_id, ["to_go"])
	if result.is_empty():
		return "Delivery should return a score result"
	if result["score"]["total"] < 80:
		return "First playable delivery should score at least 80, got %d" % result["score"]["total"]
	if game.assemblies.has(order_id):
		return "Delivery should erase the assembly"
	return ""

func test_main_controller_buttons_complete_first_order() -> String:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	main._ready()
	var order_id: String = main.selected_order_id
	if order_id == "":
		return "Main controller should select the first spawned order"
	main._on_basic_step_pressed()
	main._on_boss_help_pressed()
	main._process(5.0)
	main._on_boss_help_pressed()
	main._process(5.0)
	var performed_actions: Array = main.game.assemblies[order_id].performed_actions()
	if performed_actions.count("pull_espresso") != 1:
		return "Repeated boss help should not duplicate pull_espresso, got %s" % [performed_actions]
	main._on_deliver_pressed()
	var settlement: Dictionary = main.game.settlement()
	if settlement.get("money", 0) <= 0:
		return "Controller button flow should deliver the first order and earn money"
	if not main.game.assemblies.is_empty():
		return "Controller delivery should clean up delivered assemblies"
	main.free()
	return ""

func test_shift_can_tick_through_peak_and_settle() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.tick(420.0)
	var phase: Dictionary = game.shift.current_phase()
	if phase.get("name", "") != "peak":
		return "Shift should be in peak after 420 seconds, got %s" % phase.get("name", "")
	game.tick(180.0)
	if not game.shift.is_finished():
		return "Shift should finish after 600 seconds"
	var settlement: Dictionary = game.settlement()
	if not settlement.has("money") or not settlement.has("experience") or not settlement.has("reputation"):
		return "Settlement should include money, experience, and reputation"
	return ""
