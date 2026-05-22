extends Control
class_name ManufacturingScreen

const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const GestureAnalyzer = preload("res://src/core/gesture_analyzer.gd")

var order_id: String = ""
var assembly = null
var analyzer := GestureAnalyzer.new()
var _last_gesture_score: float = 0.0

func start_order(new_order_id: String, menu_id: String) -> void:
	order_id = new_order_id
	assembly = DrinkAssembly.new(menu_id)
	_last_gesture_score = 0.0

func apply_drag(action: String, layer: String, amount: float) -> void:
	if assembly == null:
		return
	assembly.apply_action(action, layer, amount)

func apply_stir(points: Array[Vector2]) -> void:
	var score := analyzer.score_stir(points)
	_last_gesture_score = score
	if assembly == null:
		return
	assembly.apply_action("dissolve_powder", "mixed_base", score)

func apply_pour(action: String, layer: String, hold_seconds: float, target_seconds: float) -> void:
	var amount := analyzer.pour_amount(hold_seconds, target_seconds)
	_last_gesture_score = amount
	if assembly == null:
		return
	assembly.apply_action(action, layer, amount)

func apply_whip(points: Array[Vector2]) -> void:
	var score := analyzer.score_whip_path(points)
	_last_gesture_score = score
	if assembly == null:
		return
	assembly.apply_action("pipe_whipped_cream", "whipped_cream", score)

func current_layers() -> Array[String]:
	if assembly == null:
		return []
	return assembly.layers()

func last_gesture_score() -> float:
	return _last_gesture_score
