extends RefCounted
class_name BossQueue

const DURATIONS := {
	"pull_espresso": 4.0,
	"steam_milk": 5.0,
	"use_smoothie_machine": 7.0,
	"prepare_advanced_tea_base": 6.0,
	"use_locked_equipment": 6.0
}

var _pending: Array[Dictionary] = []
var _current: Dictionary = {}
var _completed: Array[Dictionary] = []

func enqueue(order_id: String, action: String) -> void:
	if _has_task(order_id, action):
		return
	_pending.append({
		"order_id": order_id,
		"action": action,
		"duration": _duration_for(action),
		"remaining": _duration_for(action)
	})

func pending_count() -> int:
	return _pending.size()

func current_task() -> Dictionary:
	return _current.duplicate(true)

func tick(delta_seconds: float) -> void:
	if _current.is_empty() and not _pending.is_empty():
		_current = _pending.pop_front()
	if _current.is_empty():
		return
	_current["remaining"] = max(0.0, _current["remaining"] - delta_seconds)
	if _current["remaining"] <= 0.0:
		_completed.append(_current)
		_current = {}

func assist_current_task(strength: float) -> void:
	if _current.is_empty():
		return
	var reduction := clamp(strength, 0.0, 1.0) * _current["duration"] * 0.25
	_current["remaining"] = max(0.0, _current["remaining"] - reduction)

func collect_completed() -> Array[Dictionary]:
	var result := _completed.duplicate(true)
	_completed.clear()
	return result

func _has_task(order_id: String, action: String) -> bool:
	if not _current.is_empty() and _current["order_id"] == order_id and _current["action"] == action:
		return true
	for task in _pending:
		if task["order_id"] == order_id and task["action"] == action:
			return true
	for task in _completed:
		if task["order_id"] == order_id and task["action"] == action:
			return true
	return false

func _duration_for(action: String) -> float:
	if DURATIONS.has(action):
		return DURATIONS[action]
	return 5.0
