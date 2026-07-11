extends RefCounted
class_name OrderQueue

const OrderModel = preload("res://src/core/order_model.gd")

var _orders: Array[OrderModel] = []

func add_order(order_id: String, menu_id: String, requests: Array[String], patience: float) -> bool:
	if has_order(order_id):
		return false
	_orders.append(OrderModel.new(order_id, menu_id, requests, patience))
	return true

func has_order(order_id: String) -> bool:
	for order in _orders:
		if order.id == order_id:
			return true
	return false

func tick(delta_seconds: float) -> void:
	for order in _orders:
		if order.state != "delivered":
			order.tick(delta_seconds)

func get_order(order_id: String) -> Dictionary:
	for order in _orders:
		if order.id == order_id:
			return order.to_dict()
	return {}

func add_request(order_id: String, request: String) -> bool:
	for order in _orders:
		if order.id == order_id and order.state != "delivered":
			return order.add_request(request)
	return false

func active_orders() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order in _orders:
		if order.state != "delivered":
			result.append(order.to_dict())
	return result

func mark_delivered(order_id: String) -> void:
	for order in _orders:
		if order.id == order_id:
			order.state = "delivered"
			return
