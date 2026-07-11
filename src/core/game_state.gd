extends RefCounted
class_name GameState

const MenuCatalog = preload("res://src/core/menu_catalog.gd")
const PlayerProgress = preload("res://src/core/player_progress.gd")
const BossQueue = preload("res://src/core/boss_queue.gd")
const OrderQueue = preload("res://src/core/order_queue.gd")
const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const QualityScorer = preload("res://src/core/quality_scorer.gd")
const ShiftManager = preload("res://src/core/shift_manager.gd")
const Inventory = preload("res://src/core/inventory.gd")

var catalog := MenuCatalog.new()
var progress := PlayerProgress.new(1)
var boss_queue := BossQueue.new()
var order_queue := OrderQueue.new()
var shift := ShiftManager.new()
var inventory := Inventory.new()
var assemblies: Dictionary = {}
var _next_order_number := 1

func spawn_order(menu_id: String, requests: Array[String]) -> String:
	var menu: Dictionary = catalog.get_by_id(menu_id)
	if menu.is_empty():
		return ""
	var order_id := "order_%d" % _next_order_number
	_next_order_number += 1
	var phase: Dictionary = shift.current_phase()
	if not order_queue.add_order(order_id, menu_id, requests, float(phase["patience"])):
		return ""
	assemblies[order_id] = DrinkAssembly.new(menu_id)
	return order_id

func active_orders() -> Array[Dictionary]:
	return order_queue.active_orders()

func add_order_request(order_id: String, request: String) -> bool:
	return order_queue.add_request(order_id, request)

func route_unavailable_actions(order_id: String) -> Array[String]:
	var order: Dictionary = order_queue.get_order(order_id)
	if order.is_empty():
		return []
	var menu: Dictionary = catalog.get_by_id(String(order["menu_id"]))
	if menu.is_empty():
		return []
	if not assemblies.has(order_id):
		return []
	var required_actions: Array = menu["required_actions"]
	var assembly: DrinkAssembly = assemblies[order_id]
	var performed_actions: Array = assembly.performed_actions()
	for raw_action in required_actions:
		var action := String(raw_action)
		if action in performed_actions or progress.can_perform(action):
			continue
		boss_queue.enqueue(order_id, action)
		return [action]
	return []

func perform_action(order_id: String, action: String, layer: String, amount: float) -> bool:
	var order: Dictionary = order_queue.get_order(order_id)
	if order.is_empty() or order.get("state", "") == "delivered":
		return false
	if not assemblies.has(order_id):
		return false
	if not progress.can_perform(action):
		return false
	if not _is_next_action(order_id, action):
		return false
	assemblies[order_id].apply_action(action, layer, amount)
	return true

func apply_boss_result(order_id: String, action: String, layer: String, amount: float) -> bool:
	var order: Dictionary = order_queue.get_order(order_id)
	if order.is_empty() or order.get("state", "") == "delivered":
		return false
	if not assemblies.has(order_id) or progress.can_perform(action):
		return false
	if not _is_next_action(order_id, action):
		return false
	assemblies[order_id].apply_action(action, layer, amount)
	return true

func can_deliver(order_id: String) -> bool:
	var order: Dictionary = order_queue.get_order(order_id)
	if order.is_empty() or not assemblies.has(order_id):
		return false
	var menu: Dictionary = catalog.get_by_id(String(order["menu_id"]))
	if menu.is_empty():
		return false
	var required_actions: Array = menu["required_actions"]
	var performed_actions: Array = assemblies[order_id].performed_actions()
	return performed_actions == required_actions

func deliver(order_id: String, satisfied_requests: Array[String]) -> Dictionary:
	var order: Dictionary = order_queue.get_order(order_id)
	if order.is_empty() or order.get("state", "") == "delivered" or not assemblies.has(order_id):
		return {}
	if not can_deliver(order_id):
		return {}
	var menu: Dictionary = catalog.get_by_id(String(order["menu_id"]))
	if menu.is_empty():
		return {}
	var assembly: DrinkAssembly = assemblies[order_id]
	var patience_total: float = float(order["patience_total"])
	var wait_ratio := 1.0
	if patience_total > 0.0:
		wait_ratio = 1.0 - (float(order["patience_remaining"]) / patience_total)
	var score := QualityScorer.new().score({
		"required_actions": menu["required_actions"],
		"performed_actions": assembly.performed_actions(),
		"requests": order["requests"],
		"satisfied_requests": satisfied_requests,
		"wait_ratio": wait_ratio,
		"visual_neatness": 1.0
	})
	shift.record_delivery(score, int(menu["base_price"]))
	order_queue.mark_delivered(order_id)
	assemblies.erase(order_id)
	return {"order_id": order_id, "score": score}

func tick(delta_seconds: float) -> void:
	shift.tick(delta_seconds)
	order_queue.tick(delta_seconds)
	boss_queue.tick(delta_seconds)

func settlement() -> Dictionary:
	return shift.settlement()

func supply_amount(station: String, supply: String) -> int:
	return inventory.amount(station, supply)

func consume_supply(station: String, supply: String, count: int = 1) -> bool:
	return inventory.consume(station, supply, count)

func restock_supply(station: String, supply: String, count: int) -> void:
	inventory.restock(station, supply, count)

func _is_next_action(order_id: String, action: String) -> bool:
	var order: Dictionary = order_queue.get_order(order_id)
	if order.is_empty() or not assemblies.has(order_id):
		return false
	var menu: Dictionary = catalog.get_by_id(String(order["menu_id"]))
	if menu.is_empty():
		return false
	var required_actions: Array = menu["required_actions"]
	var performed_actions: Array = assemblies[order_id].performed_actions()
	if performed_actions.size() >= required_actions.size():
		return false
	return String(required_actions[performed_actions.size()]) == action
