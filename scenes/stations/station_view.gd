extends Control
class_name StationView

const ProjectConfig = preload("res://src/core/project_config.gd")

const STATION_TITLES := {
	"register": "계산대 안쪽",
	"sink": "싱크대",
	"main_table": "메인 책상",
	"sub_table": "서브 책상",
	"display_fridge": "큰 냉장고",
	"pickup_counter": "카운터"
}

var station_index := 0

func current_station_id() -> String:
	return ProjectConfig.STATIONS[station_index]

func go_left() -> void:
	station_index = int(clamp(station_index - 1, 0, ProjectConfig.STATIONS.size() - 1))

func go_right() -> void:
	station_index = int(clamp(station_index + 1, 0, ProjectConfig.STATIONS.size() - 1))

func station_title() -> String:
	return STATION_TITLES.get(current_station_id(), current_station_id())
