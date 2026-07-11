extends RefCounted

var _test_tree: SceneTree = null

func set_test_tree(value: SceneTree) -> void:
	_test_tree = value

func get_test_methods() -> Array[String]:
	return [
		"test_station_view_cycles_right_and_left",
		"test_main_scene_can_be_loaded",
		"test_main_scene_builds_six_visual_stations"
	]

func test_station_view_cycles_right_and_left() -> String:
	var station_view = load("res://scenes/stations/station_view.gd").new()
	if station_view.current_station_id() != "register":
		station_view.free()
		return "Station view should start at register"
	station_view.go_right()
	if station_view.current_station_id() != "sink":
		station_view.free()
		return "Going right from register should move to sink"
	station_view.go_left()
	if station_view.current_station_id() != "register":
		station_view.free()
		return "Going left from sink should return to register"
	if station_view.station_title() != "계산대 안쪽":
		station_view.free()
		return "Register title should be 계산대 안쪽"
	station_view.go_right()
	if station_view.station_title() != "싱크대":
		station_view.free()
		return "Sink title should be 싱크대"
	station_view.go_right()
	if station_view.station_title() != "메인 책상":
		station_view.free()
		return "Main table title should be 메인 책상"
	station_view.go_right()
	if station_view.station_title() != "서브 책상":
		station_view.free()
		return "Sub table title should be 서브 책상"
	station_view.go_right()
	if station_view.station_title() != "큰 냉장고":
		station_view.free()
		return "Display fridge title should be 큰 냉장고"
	station_view.go_right()
	if station_view.station_title() != "카운터":
		station_view.free()
		return "Pickup counter title should be 카운터"
	station_view.free()
	return ""

func test_main_scene_can_be_loaded() -> String:
	var main_scene = load("res://scenes/main/Main.tscn")
	if main_scene == null:
		return "Main scene should load"
	return ""

func test_main_scene_builds_six_visual_stations() -> String:
	var main = load("res://scenes/main/Main.tscn").instantiate()
	_test_tree.root.add_child(main)
	if main.station_view == null:
		main.free()
		return "Main scene should build the visual cafe station view"
	var expected: Array[String] = [
		"register",
		"sink",
		"main_table",
		"sub_table",
		"display_fridge",
		"pickup_counter"
	]
	for station_id in expected:
		main.station_view.set_station(station_id)
		if main.station_view.station_id != station_id:
			main.free()
			return "Visual station should switch to %s" % station_id
	main.free()
	return ""
