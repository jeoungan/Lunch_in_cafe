extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_game_state_spawns_order",
		"test_level_one_routes_missing_action_to_boss",
		"test_delivered_order_records_settlement",
		"test_unknown_menu_spawn_is_rejected",
		"test_delivery_is_idempotent",
		"test_perform_action_rejects_delivered_order",
		"test_delivery_cleans_up_assembly",
		"test_incomplete_delivery_is_rejected",
		"test_routing_skips_boss_action_already_applied_to_assembly",
		"test_delivery_handles_zero_patience"
	]

func test_game_state_spawns_order() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = ["to_go"]
	game.spawn_order("iced_americano", requests)
	if game.active_orders().size() != 1:
		return "Game state should spawn one order"
	return ""

func test_level_one_routes_missing_action_to_boss() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	game.spawn_order("iced_americano", requests)
	var route: Array[String] = game.route_unavailable_actions("order_1")
	if route != ["pull_espresso"]:
		return "Level 1 should route pull_espresso to boss, got %s" % [route]
	return ""

func test_delivered_order_records_settlement() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	game.spawn_order("iced_tea", requests)
	game.perform_action("order_1", "prepare_packaging", "cup", 1.0)
	game.perform_action("order_1", "add_ice", "ice", 1.0)
	game.perform_action("order_1", "add_premade_base", "iced_tea_base", 1.0)
	game.perform_action("order_1", "pour_water", "water", 1.0)
	game.perform_action("order_1", "deliver_order", "lid", 1.0)
	var satisfied_requests: Array[String] = []
	var result: Dictionary = game.deliver("order_1", satisfied_requests)
	if result.is_empty() or result["score"]["total"] <= 0:
		return "Delivered order should return a positive score"
	if game.settlement()["delivered_count"] != 1:
		return "Settlement should record one delivered order"
	return ""

func test_unknown_menu_spawn_is_rejected() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	var order_id: String = game.spawn_order("not_real", requests)
	if order_id != "":
		return "Unknown menu should not spawn an order"
	if game.active_orders().size() != 0:
		return "Unknown menu should not create active orders"
	return ""

func test_delivery_is_idempotent() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	game.spawn_order("iced_tea", requests)
	game.perform_action("order_1", "prepare_packaging", "cup", 1.0)
	game.perform_action("order_1", "add_ice", "ice", 1.0)
	game.perform_action("order_1", "add_premade_base", "iced_tea_base", 1.0)
	game.perform_action("order_1", "pour_water", "water", 1.0)
	game.perform_action("order_1", "deliver_order", "lid", 1.0)
	var satisfied_requests: Array[String] = []
	var first: Dictionary = game.deliver("order_1", satisfied_requests)
	var settlement_after_first: Dictionary = game.settlement()
	var second: Dictionary = game.deliver("order_1", satisfied_requests)
	if first.is_empty():
		return "First delivery should succeed"
	if not second.is_empty():
		return "Second delivery should be ignored"
	if game.settlement()["delivered_count"] != settlement_after_first["delivered_count"]:
		return "Second delivery should not change settlement"
	return ""

func test_perform_action_rejects_delivered_order() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	game.spawn_order("iced_tea", requests)
	game.perform_action("order_1", "prepare_packaging", "cup", 1.0)
	game.perform_action("order_1", "add_ice", "ice", 1.0)
	game.perform_action("order_1", "add_premade_base", "iced_tea_base", 1.0)
	game.perform_action("order_1", "pour_water", "water", 1.0)
	game.perform_action("order_1", "deliver_order", "lid", 1.0)
	var satisfied_requests: Array[String] = []
	game.deliver("order_1", satisfied_requests)
	if game.perform_action("order_1", "add_ice", "ice", 1.0):
		return "Delivered order should reject further actions"
	return ""

func test_delivery_cleans_up_assembly() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	game.spawn_order("iced_tea", requests)
	game.perform_action("order_1", "prepare_packaging", "cup", 1.0)
	game.perform_action("order_1", "add_ice", "ice", 1.0)
	game.perform_action("order_1", "add_premade_base", "iced_tea_base", 1.0)
	game.perform_action("order_1", "pour_water", "water", 1.0)
	game.perform_action("order_1", "deliver_order", "lid", 1.0)
	var satisfied_requests: Array[String] = []
	game.deliver("order_1", satisfied_requests)
	if game.assemblies.has("order_1"):
		return "Delivered order assembly should be cleaned up"
	return ""

func test_incomplete_delivery_is_rejected() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	var order_id: String = game.spawn_order("iced_americano", requests)
	game.perform_action(order_id, "prepare_packaging", "cup", 1.0)
	var satisfied_requests: Array[String] = []
	if not game.deliver(order_id, satisfied_requests).is_empty():
		return "An incomplete drink must never be deliverable"
	if not game.assemblies.has(order_id):
		return "Rejected delivery should keep the assembly active"
	return ""

func test_routing_skips_boss_action_already_applied_to_assembly() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	var order_id: String = game.spawn_order("iced_americano", requests)
	var first_route: Array[String] = game.route_unavailable_actions(order_id)
	if first_route != ["pull_espresso"]:
		return "Initial routing should enqueue pull_espresso, got %s" % [first_route]
	game.tick(5.0)
	var completed: Array[Dictionary] = game.boss_queue.collect_completed()
	if completed.size() != 1:
		return "Boss task should complete before applying it, got %d completed tasks" % completed.size()
	game.perform_action(order_id, "prepare_packaging", "cup", 1.0)
	game.perform_action(order_id, "pour_water", "water", 1.0)
	game.perform_action(order_id, "add_ice", "ice", 1.0)
	if not game.apply_boss_result(order_id, "pull_espresso", "espresso", 1.0):
		return "Completed boss result should be applicable in recipe order"
	var second_route: Array[String] = game.route_unavailable_actions(order_id)
	if second_route != []:
		return "Applied boss action should not be routed again, got %s" % [second_route]
	if game.boss_queue.pending_count() != 0:
		return "Applied boss action should not enqueue another pending task"
	return ""

func test_delivery_handles_zero_patience() -> String:
	var game = load("res://src/core/game_state.gd").new()
	var requests: Array[String] = []
	game.order_queue.add_order("order_1", "iced_tea", requests, 0.0)
	game.assemblies["order_1"] = load("res://src/core/drink_assembly.gd").new("iced_tea")
	game.assemblies["order_1"].apply_action("prepare_packaging", "cup", 1.0)
	game.assemblies["order_1"].apply_action("add_ice", "ice", 1.0)
	game.assemblies["order_1"].apply_action("add_premade_base", "iced_tea_base", 1.0)
	game.assemblies["order_1"].apply_action("pour_water", "water", 1.0)
	game.assemblies["order_1"].apply_action("deliver_order", "lid", 1.0)
	var satisfied_requests: Array[String] = []
	var result: Dictionary = game.deliver("order_1", satisfied_requests)
	if result.is_empty() or result["score"]["total"] <= 0:
		return "Zero-patience order should still score safely"
	return ""
