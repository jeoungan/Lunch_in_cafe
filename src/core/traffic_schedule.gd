extends RefCounted
class_name TrafficSchedule

const PHASES := [
	{"name": "normal", "start": 0.0, "end": 60.0, "spawn_interval": 18.0, "patience": 55.0},
	{"name": "peak", "start": 60.0, "end": 180.0, "spawn_interval": 8.0, "patience": 38.0},
	{"name": "normal", "start": 180.0, "end": 360.0, "spawn_interval": 16.0, "patience": 50.0},
	{"name": "peak", "start": 360.0, "end": 540.0, "spawn_interval": 7.0, "patience": 34.0},
	{"name": "closing", "start": 540.0, "end": 600.0, "spawn_interval": 14.0, "patience": 42.0}
]

func phase_at(elapsed_seconds: float) -> Dictionary:
	var first_phase: Dictionary = PHASES[0]
	if elapsed_seconds < float(first_phase["start"]):
		return first_phase.duplicate(true)
	for raw_phase in PHASES:
		var phase: Dictionary = raw_phase
		if elapsed_seconds >= float(phase["start"]) and elapsed_seconds < float(phase["end"]):
			return phase.duplicate(true)
	var last_phase: Dictionary = PHASES[PHASES.size() - 1]
	return last_phase.duplicate(true)
