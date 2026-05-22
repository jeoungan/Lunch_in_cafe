extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_drink_layers_preserve_order",
		"test_quality_penalizes_missing_request",
		"test_quality_allows_recovery_action",
		"test_quality_penalizes_extra_actions",
		"test_duplicate_action_amounts_are_preserved",
		"test_action_amount_is_clamped",
		"test_duplicate_requests_are_scored_once"
	]

func test_drink_layers_preserve_order() -> String:
	var drink = load("res://src/core/drink_assembly.gd").new("iced_americano")
	drink.apply_action("add_ice", "ice", 1.0)
	drink.apply_action("pour_water", "water", 1.0)
	if drink.layers() != ["ice", "water"]:
		return "Drink layers should preserve applied order"
	return ""

func test_quality_penalizes_missing_request() -> String:
	var scorer = load("res://src/core/quality_scorer.gd").new()
	var score := scorer.score({
		"required_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"performed_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"requests": ["to_go"],
		"satisfied_requests": [],
		"wait_ratio": 0.2,
		"visual_neatness": 1.0
	})
	if score["total"] >= 90:
		return "Missing to_go request should reduce score below 90"
	return ""

func test_quality_allows_recovery_action() -> String:
	var drink = load("res://src/core/drink_assembly.gd").new("green_tea_latte")
	drink.apply_action("measure_powder", "powder", 1.0)
	drink.add_recovery("stir_again")
	if not "stir_again" in drink.recoveries():
		return "Recovery action should be recorded"
	return ""

func test_quality_penalizes_extra_actions() -> String:
	var scorer = load("res://src/core/quality_scorer.gd").new()
	var perfect := scorer.score({
		"required_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"performed_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"requests": [],
		"satisfied_requests": [],
		"wait_ratio": 0.0,
		"visual_neatness": 1.0
	})
	var extra := scorer.score({
		"required_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"performed_actions": ["prepare_packaging", "add_ice", "deliver_order", "add_ice"],
		"requests": [],
		"satisfied_requests": [],
		"wait_ratio": 0.0,
		"visual_neatness": 1.0
	})
	if not extra["recipe"] < perfect["recipe"]:
		return "Extra performed actions should reduce recipe score"
	return ""

func test_duplicate_action_amounts_are_preserved() -> String:
	var drink = load("res://src/core/drink_assembly.gd").new("iced_americano")
	drink.apply_action("add_ice", "ice", 0.5)
	drink.apply_action("add_ice", "ice", 0.75)
	var amounts := drink.amounts_for("add_ice")
	if amounts != [0.5, 0.75]:
		return "Duplicate action amounts should be preserved"
	if drink.amount_for("add_ice") != 0.75:
		return "amount_for should return the last amount for duplicate actions"
	amounts.append(9.0)
	if drink.amounts_for("add_ice") != [0.5, 0.75]:
		return "amounts_for should return a copy of stored amounts"
	return ""

func test_action_amount_is_clamped() -> String:
	var drink = load("res://src/core/drink_assembly.gd").new("iced_americano")
	drink.apply_action("add_ice", "ice", -1.0)
	drink.apply_action("pour_water", "water", 2.0)
	if drink.amount_for("add_ice") != 0.0:
		return "Negative amount should clamp to 0"
	if drink.amount_for("pour_water") != 1.25:
		return "Overfull amount should clamp to 1.25"
	return ""

func test_duplicate_requests_are_scored_once() -> String:
	var scorer = load("res://src/core/quality_scorer.gd").new()
	var score := scorer.score({
		"required_actions": [],
		"performed_actions": [],
		"requests": ["to_go", "to_go", "no_straw"],
		"satisfied_requests": ["to_go"],
		"wait_ratio": 0.0,
		"visual_neatness": 1.0
	})
	if score["requests"] != 50:
		return "Duplicate requests should be scored as unique requests"
	return ""
