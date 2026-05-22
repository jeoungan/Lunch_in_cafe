extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_project_name_and_shift_length",
		"test_station_count"
	]

func test_project_name_and_shift_length() -> String:
	var config = load("res://src/core/project_config.gd").new()
	if config.APP_NAME != "Lunch Time in Cafe":
		return "APP_NAME should be Lunch Time in Cafe"
	if config.SHIFT_SECONDS != 600.0:
		return "SHIFT_SECONDS should be 600.0"
	return ""

func test_station_count() -> String:
	var config = load("res://src/core/project_config.gd").new()
	if config.STATIONS.size() != 6:
		return "There should be exactly 6 cafe stations"
	if config.STATIONS[0] != "register":
		return "First station should be register"
	if config.STATIONS[5] != "pickup_counter":
		return "Last station should be pickup_counter"
	return ""
