extends RefCounted
class_name EquipmentState

var id: String
var base_speed: float
var capacity: int
var malfunctioning: bool = false
var level: int = 1

func _init(equipment_id: String, starting_speed: float, starting_capacity: int) -> void:
	id = equipment_id
	base_speed = starting_speed
	capacity = starting_capacity

func set_malfunction(value: bool) -> void:
	malfunctioning = value

func speed_multiplier() -> float:
	var upgrade_bonus := 1.0 + float(level - 1) * 0.1
	var malfunction_penalty := 0.5 if malfunctioning else 1.0
	return base_speed * upgrade_bonus * malfunction_penalty

func upgrade() -> void:
	level += 1
	capacity += 10
