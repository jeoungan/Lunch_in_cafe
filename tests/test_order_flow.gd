extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_traffic_schedule_matches_shift_design",
		"test_order_patience_decreases",
		"test_to_go_request_is_recorded",
		"test_mid_order_request_is_added_once",
		"test_delivered_order_stops_ticking",
		"test_duplicate_order_id_is_ignored",
		"test_waiting_order_becomes_angry",
		"test_order_dict_is_copy_isolated",
		"test_traffic_schedule_boundaries"
	]

func test_traffic_schedule_matches_shift_design() -> String:
	var schedule = load("res://src/core/traffic_schedule.gd").new()
	if schedule.phase_at(30.0)["name"] != "normal":
		return "0:30 should be normal"
	if schedule.phase_at(90.0)["name"] != "peak":
		return "1:30 should be peak"
	if schedule.phase_at(240.0)["name"] != "normal":
		return "4:00 should be normal"
	if schedule.phase_at(420.0)["name"] != "peak":
		return "7:00 should be peak"
	if schedule.phase_at(570.0)["name"] != "closing":
		return "9:30 should be closing"
	return ""

func test_order_patience_decreases() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	var requests: Array[String] = ["to_go"]
	queue.add_order("order_1", "iced_americano", requests, 30.0)
	queue.tick(5.0)
	var order: Dictionary = queue.get_order("order_1")
	if order["patience_remaining"] != 25.0:
		return "Patience should decrease from 30 to 25"
	return ""

func test_to_go_request_is_recorded() -> String:
	var requests: Array[String] = ["to_go"]
	var order = load("res://src/core/order_model.gd").new("order_1", "iced_tea", requests, 40.0)
	if not order.has_request("to_go"):
		return "Order should include to_go request"
	return ""

func test_mid_order_request_is_added_once() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	var requests: Array[String] = []
	queue.add_order("order_1", "iced_americano", requests, 40.0)
	if not queue.add_request("order_1", "to_go"):
		return "A new mid-order request should be accepted"
	if queue.add_request("order_1", "to_go"):
		return "A duplicate mid-order request should be ignored"
	if queue.get_order("order_1")["requests"] != ["to_go"]:
		return "The accepted request should be stored exactly once"
	return ""

func test_delivered_order_stops_ticking() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	var requests: Array[String] = []
	queue.add_order("order_1", "iced_americano", requests, 30.0)
	queue.tick(5.0)
	queue.mark_delivered("order_1")
	queue.tick(10.0)
	var order: Dictionary = queue.get_order("order_1")
	if order["patience_remaining"] != 25.0:
		return "Delivered orders should stop losing patience"
	if order["elapsed"] != 5.0:
		return "Delivered orders should stop accumulating elapsed time"
	return ""

func test_duplicate_order_id_is_ignored() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	var requests: Array[String] = []
	if not queue.add_order("order_1", "iced_americano", requests, 30.0):
		return "First order insert should succeed"
	if queue.add_order("order_1", "iced_tea", requests, 40.0):
		return "Duplicate order ID should be rejected"
	if queue.active_orders().size() != 1:
		return "Duplicate order should not be active"
	return ""

func test_waiting_order_becomes_angry() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	var requests: Array[String] = []
	queue.add_order("order_1", "iced_americano", requests, 3.0)
	queue.tick(3.0)
	if queue.get_order("order_1")["state"] != "angry":
		return "Waiting order should become angry when patience reaches zero"
	return ""

func test_order_dict_is_copy_isolated() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	var requests: Array[String] = ["to_go"]
	queue.add_order("order_1", "iced_americano", requests, 30.0)
	var order: Dictionary = queue.get_order("order_1")
	order["requests"].append("fake_request")
	if "fake_request" in queue.get_order("order_1")["requests"]:
		return "Order dictionary should not expose mutable request array"
	return ""

func test_traffic_schedule_boundaries() -> String:
	var schedule = load("res://src/core/traffic_schedule.gd").new()
	if schedule.phase_at(-1.0)["name"] != "normal":
		return "Negative time should use first phase"
	if schedule.phase_at(60.0)["name"] != "peak":
		return "60.0 should enter first peak"
	if schedule.phase_at(180.0)["name"] != "normal":
		return "180.0 should return to normal"
	if schedule.phase_at(360.0)["name"] != "peak":
		return "360.0 should enter second peak"
	if schedule.phase_at(540.0)["name"] != "closing":
		return "540.0 should enter closing"
	if schedule.phase_at(600.0)["name"] != "closing":
		return "600.0 should remain closing"
	return ""
