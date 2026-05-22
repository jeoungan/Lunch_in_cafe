extends RefCounted
class_name GameState

const MenuCatalog = preload("res://src/core/menu_catalog.gd")
const PlayerProgress = preload("res://src/core/player_progress.gd")
const BossQueue = preload("res://src/core/boss_queue.gd")
const OrderQueue = preload("res://src/core/order_queue.gd")
const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const QualityScorer = preload("res://src/core/quality_scorer.gd")
const ShiftManager = preload("res://src/core/shift_manager.gd")

var catalog := MenuCatalog.new()
var progress := PlayerProgress.new(1)
var boss_queue := BossQueue.new()
var order_queue := OrderQueue.new()
var shift := ShiftManager.new()
var assemblies: Dictionary = {}
var _next_order_number := 1

func spawn_order(menu_id: String, requests: Array[String]) -> String:
	var menu := catalog.get_by_id(menu_id)
	if menu.is_empty():
		return ""
	var order_id := "order_%d" % _next_order_number
	_next_order_number += 1
	var phase := shift.current_phase()
	if not order_queue.add_order(order_id, menu_id, requests, phase["patience"]):
		return ""
	assemblies[order_id] = DrinkAssembly.new(menu_id)
	return order_id

func active_orders() -> Array[Dictionary]:
	return order_queue.active_orders()

func route_unavailable_actions(order_id: String) -> Array[String]:
	var order := order_queue.get_order(order_id)
	if order.is_empty():
		return []
	var menu := catalog.get_by_id(order["menu_id"])
	if menu.is_empty():
		return []
	var missing := progress.missing_actions(menu["required_actions"])
	for action in missing:
		boss_queue.enqueue(order_id, action)
	return missing

func perform_action(order_id: String, action: String, layer: String, amount: float) -> bool:
	var order := order_queue.get_order(order_id)
	if order.is_empty() or order.get("state", "") == "delivered":
		return false
	if not assemblies.has(order_id):
		return false
	if not progress.can_perform(action):
		return false
	assemblies[order_id].apply_action(action, layer, amount)
	return true

func deliver(order_id: String, satisfied_requests: Array[String]) -> Dictionary:
	var order := order_queue.get_order(order_id)
	if order.is_empty() or order.get("state", "") == "delivered" or not assemblies.has(order_id):
		return {}
	var menu := catalog.get_by_id(order["menu_id"])
	if menu.is_empty():
		return {}
	var assembly: DrinkAssembly = assemblies[order_id]
	var patience_total: float = order["patience_total"]
	var wait_ratio := 1.0
	if patience_total > 0.0:
		wait_ratio = 1.0 - (order["patience_remaining"] / patience_total)
	var score := QualityScorer.new().score({
		"required_actions": menu["required_actions"],
		"performed_actions": assembly.performed_actions(),
		"requests": order["requests"],
		"satisfied_requests": satisfied_requests,
		"wait_ratio": wait_ratio,
		"visual_neatness": 1.0
	})
	shift.record_delivery(score, menu["base_price"])
	order_queue.mark_delivered(order_id)
	assemblies.erase(order_id)
	return {"order_id": order_id, "score": score}

func tick(delta_seconds: float) -> void:
	shift.tick(delta_seconds)
	order_queue.tick(delta_seconds)
	boss_queue.tick(delta_seconds)

func settlement() -> Dictionary:
	return shift.settlement()
