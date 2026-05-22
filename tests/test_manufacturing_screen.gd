extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_screen_records_dragged_layer",
		"test_screen_records_stir_score",
		"test_screen_records_whipped_cream_layer",
		"test_scene_can_be_loaded"
	]

func test_screen_records_dragged_layer() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "iced_americano")
	screen.apply_drag("add_ice", "ice", 1.0)
	if screen.current_layers() != ["ice"]:
		return "Dragged layer should be recorded in current layers"
	return ""

func test_screen_records_stir_score() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "green_tea_latte")
	screen.apply_stir([Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)])
	if screen.last_gesture_score() < 0.75:
		return "Circular stir should record a score of at least 0.75"
	return ""

func test_screen_records_whipped_cream_layer() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "green_tea_latte")
	screen.apply_whip([Vector2(0, 0), Vector2(20, 3), Vector2(40, 5), Vector2(60, 4)])
	if screen.current_layers() != ["whipped_cream"]:
		return "Whip gesture should record the whipped_cream visual layer"
	if screen.assembly.performed_actions() != ["pipe_whipped_cream"]:
		return "Whip gesture should record the pipe_whipped_cream action"
	return ""

func test_scene_can_be_loaded() -> String:
	var scene = load("res://scenes/manufacturing/ManufacturingScreen.tscn")
	if scene == null:
		return "Manufacturing screen scene should load"
	return ""
