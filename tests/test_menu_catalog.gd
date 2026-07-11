extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_catalog_has_at_least_30_items",
		"test_catalog_uses_required_categories",
		"test_low_level_menu_can_require_boss_action"
	]

func test_catalog_has_at_least_30_items() -> String:
	var catalog = load("res://src/core/menu_catalog.gd").new()
	var menus: Array[Dictionary] = catalog.get_all()
	if menus.size() < 30:
		return "Menu catalog should contain at least 30 items"
	for item in menus:
		if not item.has("id") or not item.has("name") or not item.has("required_actions"):
			return "Each menu item should include id, name, and required_actions"
	return ""

func test_catalog_uses_required_categories() -> String:
	var catalog = load("res://src/core/menu_catalog.gd").new()
	var categories: Dictionary = {}
	for item in catalog.get_all():
		categories[item["category"]] = true
	for category in ["coffee", "tea", "latte", "ade", "powder", "smoothie", "display", "dessert"]:
		if not categories.has(category):
			return "Missing category: %s" % category
	return ""

func test_low_level_menu_can_require_boss_action() -> String:
	var catalog = load("res://src/core/menu_catalog.gd").new()
	var americano: Dictionary = catalog.get_by_id("iced_americano")
	if americano.is_empty():
		return "iced_americano should exist"
	if not "pull_espresso" in americano["required_actions"]:
		return "iced_americano should require pull_espresso"
	if not "add_ice" in americano["required_actions"]:
		return "iced_americano should require add_ice"
	return ""
