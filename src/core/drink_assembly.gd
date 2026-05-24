extends RefCounted
class_name DrinkAssembly

var menu_id: String
var _layers: Array[String] = []
var _performed_actions: Array[String] = []
var _amounts_by_action: Dictionary = {}
var _recoveries: Array[String] = []

func _init(starting_menu_id: String) -> void:
	menu_id = starting_menu_id

func apply_action(action: String, layer: String, amount: float) -> void:
	_performed_actions.append(action)
	if layer != "":
		_layers.append(layer)
	var stored_amount: float = clamp(amount, 0.0, 1.25)
	if not _amounts_by_action.has(action):
		_amounts_by_action[action] = []
	_amounts_by_action[action].append(stored_amount)

func add_recovery(recovery_id: String) -> void:
	_recoveries.append(recovery_id)

func layers() -> Array[String]:
	return _layers.duplicate()

func performed_actions() -> Array[String]:
	return _performed_actions.duplicate()

func recoveries() -> Array[String]:
	return _recoveries.duplicate()

func amount_for(action: String) -> float:
	if _amounts_by_action.has(action):
		var amounts: Array = _amounts_by_action[action]
		if not amounts.is_empty():
			return float(amounts[amounts.size() - 1])
	return 0.0

func amounts_for(action: String) -> Array[float]:
	var copy: Array[float] = []
	if not _amounts_by_action.has(action):
		return copy
	for amount in _amounts_by_action[action]:
		copy.append(amount)
	return copy
