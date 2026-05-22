extends RefCounted
class_name PlayerProgress

const GameDefs = preload("res://src/core/game_defs.gd")

var level: int = 1

func _init(starting_level: int = 1) -> void:
	level = max(1, starting_level)

func unlocked_actions() -> Array[String]:
	var actions: Array[String] = [
		GameDefs.ACTION_TAKE_ORDER,
		GameDefs.ACTION_PREPARE_PACKAGING,
		GameDefs.ACTION_ADD_ICE,
		GameDefs.ACTION_POUR_WATER,
		GameDefs.ACTION_POUR_SPARKLING_WATER,
		GameDefs.ACTION_ADD_PREMADE_BASE,
		GameDefs.ACTION_DELIVER_ORDER,
		GameDefs.ACTION_RESTOCK_SUPPLIES
	]
	if level >= 2:
		actions.append(GameDefs.ACTION_MEASURE_SYRUP)
	if level >= 3:
		actions.append(GameDefs.ACTION_POUR_MILK)
	if level >= 4:
		actions.append(GameDefs.ACTION_MEASURE_POWDER)
		actions.append(GameDefs.ACTION_DISSOLVE_POWDER)
	if level >= 5:
		actions.append(GameDefs.ACTION_USE_MICROWAVE)
	if level >= 6:
		actions.append(GameDefs.ACTION_PIPE_WHIPPED_CREAM)
		actions.append(GameDefs.ACTION_ADD_TOPPING)
	if level >= 7:
		actions.append(GameDefs.ACTION_PULL_ESPRESSO)
		actions.append(GameDefs.ACTION_STEAM_MILK)
	if level >= 8:
		actions.append(GameDefs.ACTION_USE_SMOOTHIE_MACHINE)
	if level >= 9:
		actions.append(GameDefs.ACTION_FIX_BASIC_EQUIPMENT)
	return actions

func can_perform(action: String) -> bool:
	return action in unlocked_actions()

func missing_actions(required_actions: Array) -> Array[String]:
	var missing: Array[String] = []
	for action in required_actions:
		if not can_perform(action):
			missing.append(action)
	return missing
