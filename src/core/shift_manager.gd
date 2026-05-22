extends RefCounted
class_name ShiftManager

const ProjectConfig = preload("res://src/core/project_config.gd")
const TrafficSchedule = preload("res://src/core/traffic_schedule.gd")

var elapsed: float = 0.0
var money: int = 0
var experience: int = 0
var reputation: int = 0
var delivered_count: int = 0
var discarded_count: int = 0
var _schedule := TrafficSchedule.new()

func tick(delta_seconds: float) -> void:
	elapsed = clamp(elapsed + delta_seconds, 0.0, ProjectConfig.SHIFT_SECONDS)

func is_finished() -> bool:
	return elapsed >= ProjectConfig.SHIFT_SECONDS

func current_phase() -> Dictionary:
	return _schedule.phase_at(elapsed)

func record_delivery(score: Dictionary, base_price: int) -> void:
	var total_score: int = int(clamp(score.get("total", 0), 0, 100))
	var safe_base_price: int = max(0, base_price)
	var quality_ratio := float(total_score) / 100.0
	money += int(round(float(safe_base_price) * quality_ratio))
	experience += 5 + int(round(quality_ratio * 10.0))
	reputation += int(round((quality_ratio - 0.5) * 4.0))
	delivered_count += 1

func record_discard() -> void:
	discarded_count += 1
	reputation -= 1

func settlement() -> Dictionary:
	return {
		"money": money,
		"experience": experience,
		"reputation": reputation,
		"delivered_count": delivered_count,
		"discarded_count": discarded_count,
		"elapsed": elapsed
	}
