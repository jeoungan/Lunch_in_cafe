extends RefCounted
class_name OrderModel

var id: String
var menu_id: String
var requests: Array[String]
var patience_total: float
var patience_remaining: float
var state: String = "waiting"
var elapsed: float = 0.0

func _init(order_id: String, ordered_menu_id: String, order_requests: Array[String], patience: float) -> void:
	id = order_id
	menu_id = ordered_menu_id
	requests = order_requests.duplicate()
	patience_total = patience
	patience_remaining = patience

func tick(delta_seconds: float) -> void:
	elapsed += delta_seconds
	patience_remaining = max(0.0, patience_remaining - delta_seconds)
	if patience_remaining <= 0.0 and state == "waiting":
		state = "angry"

func has_request(request: String) -> bool:
	return request in requests

func add_request(request: String) -> bool:
	if request.is_empty() or request in requests:
		return false
	requests.append(request)
	return true

func to_dict() -> Dictionary:
	return {
		"id": id,
		"menu_id": menu_id,
		"requests": requests.duplicate(),
		"patience_total": patience_total,
		"patience_remaining": patience_remaining,
		"state": state,
		"elapsed": elapsed
	}
