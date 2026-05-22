extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_level_one_allows_basic_actions",
		"test_level_one_requires_boss_for_espresso",
		"test_level_seven_can_make_latte_actions"
	]

func test_level_one_allows_basic_actions() -> String:
	var progress = load("res://src/core/player_progress.gd").new(1)
	for action in ["take_order", "prepare_packaging", "add_ice", "pour_water", "pour_sparkling_water", "add_premade_base", "deliver_order", "restock_supplies"]:
		if not progress.can_perform(action):
			return "Level 1 should allow %s" % action
	return ""

func test_level_one_requires_boss_for_espresso() -> String:
	var progress = load("res://src/core/player_progress.gd").new(1)
	var missing := progress.missing_actions(["prepare_packaging", "add_ice", "pour_water", "pull_espresso", "deliver_order"])
	if missing != ["pull_espresso"]:
		return "Level 1 iced americano should only miss pull_espresso, got %s" % [missing]
	return ""

func test_level_seven_can_make_latte_actions() -> String:
	var progress = load("res://src/core/player_progress.gd").new(7)
	for action in ["pull_espresso", "pour_milk", "steam_milk"]:
		if not progress.can_perform(action):
			return "Level 7 should allow %s" % action
	return ""
