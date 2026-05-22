extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_station_view_cycles_right_and_left",
		"test_main_scene_can_be_loaded"
	]

func test_station_view_cycles_right_and_left() -> String:
	var station_view = load("res://scenes/stations/station_view.gd").new()
	if station_view.current_station_id() != "register":
		return "Station view should start at register"
	station_view.go_right()
	if station_view.current_station_id() != "sink":
		return "Going right from register should move to sink"
	station_view.go_left()
	if station_view.current_station_id() != "register":
		return "Going left from sink should return to register"
	if station_view.station_title() != "계산대 안쪽":
		return "Register title should be 계산대 안쪽"
	station_view.go_right()
	if station_view.station_title() != "싱크대":
		return "Sink title should be 싱크대"
	station_view.go_right()
	if station_view.station_title() != "메인 책상":
		return "Main table title should be 메인 책상"
	station_view.go_right()
	if station_view.station_title() != "서브 책상":
		return "Sub table title should be 서브 책상"
	station_view.go_right()
	if station_view.station_title() != "큰 냉장고":
		return "Display fridge title should be 큰 냉장고"
	station_view.go_right()
	if station_view.station_title() != "카운터":
		return "Pickup counter title should be 카운터"
	return ""

func test_main_scene_can_be_loaded() -> String:
	var main_scene = load("res://scenes/main/Main.tscn")
	if main_scene == null:
		return "Main scene should load"
	return ""
