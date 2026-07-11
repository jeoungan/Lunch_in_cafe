extends RefCounted
class_name MenuCatalog

const GameDefsResource := preload("res://src/core/game_defs.gd")

var _menus: Array[Dictionary] = [
	{
		"id": "iced_americano",
		"name": "Iced Americano",
		"category": GameDefsResource.CATEGORY_COFFEE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_POUR_WATER, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "water", "ice", "espresso", "lid", "sleeve"],
		"base_price": 3500
	},
	{
		"id": "hot_americano",
		"name": "Hot Americano",
		"category": GameDefsResource.CATEGORY_COFFEE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_POUR_WATER, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["hot_cup", "water", "espresso", "sleeve"],
		"base_price": 3500
	},
	{
		"id": "iced_latte",
		"name": "Iced Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "ice", "milk", "espresso"],
		"base_price": 4200
	},
	{
		"id": "hot_latte",
		"name": "Hot Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_STEAM_MILK, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["hot_cup", "espresso", "steamed_milk", "foam"],
		"base_price": 4200
	},
	{
		"id": "vanilla_latte",
		"name": "Vanilla Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_MEASURE_SYRUP, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "vanilla_syrup", "milk", "espresso"],
		"base_price": 4800
	},
	{
		"id": "caramel_latte",
		"name": "Caramel Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_MEASURE_SYRUP, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_ADD_TOPPING, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "caramel_syrup", "milk", "espresso", "caramel_drizzle"],
		"base_price": 5000
	},
	{
		"id": "mocha_latte",
		"name": "Mocha Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_MEASURE_SYRUP, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_PULL_ESPRESSO, GameDefsResource.ACTION_PIPE_WHIPPED_CREAM, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "chocolate_syrup", "milk", "espresso", "whipped_cream"],
		"base_price": 5200
	},
	{
		"id": "cold_brew",
		"name": "Cold Brew",
		"category": GameDefsResource.CATEGORY_COFFEE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_WATER, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "ice", "cold_brew_base", "water"],
		"base_price": 4300
	},
	{
		"id": "iced_tea",
		"name": "Iced Tea",
		"category": GameDefsResource.CATEGORY_TEA,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_WATER, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "ice", "tea_base", "water"],
		"base_price": 3800
	},
	{
		"id": "hot_black_tea",
		"name": "Hot Black Tea",
		"category": GameDefsResource.CATEGORY_TEA,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_WATER, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["hot_cup", "tea_base", "hot_water", "sleeve"],
		"base_price": 3800
	},
	{
		"id": "milk_tea",
		"name": "Milk Tea",
		"category": GameDefsResource.CATEGORY_TEA,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "tea_base", "milk", "lid"],
		"base_price": 4500
	},
	{
		"id": "green_tea_latte",
		"name": "Green Tea Latte",
		"category": GameDefsResource.CATEGORY_POWDER,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_MEASURE_POWDER, GameDefsResource.ACTION_DISSOLVE_POWDER, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["cup", "green_tea_powder", "milk", "foam"],
		"base_price": 4700
	},
	{
		"id": "chocolate_latte",
		"name": "Chocolate Latte",
		"category": GameDefsResource.CATEGORY_POWDER,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_MEASURE_POWDER, GameDefsResource.ACTION_DISSOLVE_POWDER, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["cup", "chocolate_powder", "milk", "cocoa_dust"],
		"base_price": 4600
	},
	{
		"id": "sweet_potato_latte",
		"name": "Sweet Potato Latte",
		"category": GameDefsResource.CATEGORY_POWDER,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_MEASURE_POWDER, GameDefsResource.ACTION_DISSOLVE_POWDER, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["cup", "sweet_potato_powder", "milk", "foam"],
		"base_price": 4800
	},
	{
		"id": "strawberry_latte",
		"name": "Strawberry Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "strawberry_base", "ice", "milk"],
		"base_price": 5200
	},
	{
		"id": "blueberry_latte",
		"name": "Blueberry Latte",
		"category": GameDefsResource.CATEGORY_LATTE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "blueberry_base", "ice", "milk"],
		"base_price": 5200
	},
	{
		"id": "lemon_ade",
		"name": "Lemon Ade",
		"category": GameDefsResource.CATEGORY_ADE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_SPARKLING_WATER, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "lemon_base", "ice", "sparkling_water"],
		"base_price": 4800
	},
	{
		"id": "grapefruit_ade",
		"name": "Grapefruit Ade",
		"category": GameDefsResource.CATEGORY_ADE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_SPARKLING_WATER, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "grapefruit_base", "ice", "sparkling_water"],
		"base_price": 5000
	},
	{
		"id": "blue_lemon_ade",
		"name": "Blue Lemon Ade",
		"category": GameDefsResource.CATEGORY_ADE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_ICE, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_SPARKLING_WATER, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["clear_cup", "blue_lemon_base", "ice", "sparkling_water"],
		"base_price": 5200
	},
	{
		"id": "strawberry_smoothie",
		"name": "Strawberry Smoothie",
		"category": GameDefsResource.CATEGORY_SMOOTHIE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_USE_SMOOTHIE_MACHINE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["smoothie_cup", "strawberry_base", "milk", "smoothie_blend"],
		"base_price": 5800
	},
	{
		"id": "mango_smoothie",
		"name": "Mango Smoothie",
		"category": GameDefsResource.CATEGORY_SMOOTHIE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_USE_SMOOTHIE_MACHINE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["smoothie_cup", "mango_base", "milk", "smoothie_blend"],
		"base_price": 5800
	},
	{
		"id": "yogurt_smoothie",
		"name": "Yogurt Smoothie",
		"category": GameDefsResource.CATEGORY_SMOOTHIE,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_POUR_MILK, GameDefsResource.ACTION_USE_SMOOTHIE_MACHINE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["smoothie_cup", "yogurt_base", "milk", "smoothie_blend"],
		"base_price": 5600
	},
	{
		"id": "plain_soda",
		"name": "Plain Soda",
		"category": GameDefsResource.CATEGORY_DISPLAY,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["display_bottle", "clear_soda"],
		"base_price": 2500
	},
	{
		"id": "orange_juice_bottle",
		"name": "Orange Juice Bottle",
		"category": GameDefsResource.CATEGORY_DISPLAY,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["display_bottle", "orange_juice"],
		"base_price": 3200
	},
	{
		"id": "milk_bottle",
		"name": "Milk Bottle",
		"category": GameDefsResource.CATEGORY_DISPLAY,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_ADD_PREMADE_BASE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["display_bottle", "milk"],
		"base_price": 2800
	},
	{
		"id": "cookie_pack",
		"name": "Cookie Pack",
		"category": GameDefsResource.CATEGORY_DESSERT,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["dessert_pack", "cookies"],
		"base_price": 3000
	},
	{
		"id": "madeleine_pack",
		"name": "Madeleine Pack",
		"category": GameDefsResource.CATEGORY_DESSERT,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["dessert_pack", "madeleines"],
		"base_price": 3500
	},
	{
		"id": "warm_bagel",
		"name": "Warm Bagel",
		"category": GameDefsResource.CATEGORY_DESSERT,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_USE_MICROWAVE, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["paper_tray", "bagel", "steam"],
		"base_price": 4200
	},
	{
		"id": "cheese_cake_slice",
		"name": "Cheese Cake Slice",
		"category": GameDefsResource.CATEGORY_DESSERT,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["dessert_plate", "cheese_cake_slice"],
		"base_price": 5500
	},
	{
		"id": "cream_croissant",
		"name": "Cream Croissant",
		"category": GameDefsResource.CATEGORY_DESSERT,
		"required_actions": [GameDefsResource.ACTION_PREPARE_PACKAGING, GameDefsResource.ACTION_PIPE_WHIPPED_CREAM, GameDefsResource.ACTION_DELIVER_ORDER],
		"visual_layers": ["paper_tray", "croissant", "cream"],
		"base_price": 5000
	}
]

var _by_id: Dictionary = {}

func _init() -> void:
	for item in _menus:
		_by_id[String(item["id"])] = item

func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in _menus:
		result.append(item.duplicate(true))
	return result

func get_by_id(id: String) -> Dictionary:
	if not _by_id.has(id):
		return {}
	var menu: Dictionary = _by_id[id]
	return menu.duplicate(true)
