extends RefCounted

var _test_tree: SceneTree = null

func set_test_tree(value: SceneTree) -> void:
	_test_tree = value

func get_test_methods() -> Array[String]:
	return [
		"test_screen_records_dragged_layer",
		"test_screen_records_stir_score",
		"test_screen_records_whipped_cream_layer",
		"test_pointer_drag_completes_layered_recipe_in_station_order",
		"test_scene_can_be_loaded"
	]

func test_screen_records_dragged_layer() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "iced_americano")
	screen.apply_drag("add_ice", "ice", 1.0)
	if screen.current_layers() != ["ice"]:
		screen.free()
		return "Dragged layer should be recorded in current layers"
	screen.free()
	return ""

func test_screen_records_stir_score() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "green_tea_latte")
	var stir_points: Array[Vector2] = [
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(-1, 0),
		Vector2(0, -1),
		Vector2(1, 0)
	]
	screen.apply_stir(stir_points)
	if screen.last_gesture_score() < 0.75:
		screen.free()
		return "Circular stir should record a score of at least 0.75"
	screen.free()
	return ""

func test_screen_records_whipped_cream_layer() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "green_tea_latte")
	var whip_points: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(20, 3),
		Vector2(40, 5),
		Vector2(60, 4)
	]
	screen.apply_whip(whip_points)
	if screen.current_layers() != ["whipped_cream"]:
		screen.free()
		return "Whip gesture should record the whipped_cream visual layer"
	if screen.assembly.performed_actions() != ["pipe_whipped_cream"]:
		screen.free()
		return "Whip gesture should record the pipe_whipped_cream action"
	screen.free()
	return ""

func test_pointer_drag_completes_layered_recipe_in_station_order() -> String:
	var screen = load("res://scenes/manufacturing/ManufacturingScreen.tscn").instantiate()
	_test_tree.root.add_child(screen)
	screen.start_order("order_1", "iced_americano")
	screen.set_station("sink")
	for step_id in ["cup", "water", "ice"]:
		if not _drag_token_to_cup(screen, step_id):
			screen.free()
			return "Pointer drag should complete sink step: %s" % step_id
	screen.set_station("main_table")
	screen.set_boss_result_ready(true)
	if not _drag_token_to_cup(screen, "espresso"):
		screen.free()
		return "Boss espresso should be draggable at the main table"
	screen.set_station("pickup_counter")
	for step_id in ["lid", "sleeve"]:
		if not _drag_token_to_cup(screen, step_id):
			screen.free()
			return "Pointer drag should complete pickup step: %s" % step_id
	if not screen.cup_composer.is_complete():
		screen.free()
		return "Layered cup should be complete after six ordered drops"
	screen.free()
	return ""

func _drag_token_to_cup(screen, step_id: String) -> bool:
	if not screen._token_rects.has(step_id):
		return false
	var token_rect: Rect2 = screen._token_rects[step_id]
	var cup_rect: Rect2 = screen._cup_drop_rect()
	screen._begin_drag(token_rect.get_center())
	screen._finish_drag(cup_rect.get_center())
	return step_id in screen.completed_steps()

func test_scene_can_be_loaded() -> String:
	var scene = load("res://scenes/manufacturing/ManufacturingScreen.tscn")
	if scene == null:
		return "Manufacturing screen scene should load"
	return ""
