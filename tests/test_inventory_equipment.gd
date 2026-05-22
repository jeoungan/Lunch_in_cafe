extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_inventory_consumes_station_supply",
		"test_inventory_rejects_non_positive_consume",
		"test_inventory_rejects_non_positive_restock",
		"test_new_supply_can_define_capacity",
		"test_inventory_restock_caps_at_capacity",
		"test_equipment_malfunction_slows_work"
	]

func test_inventory_consumes_station_supply() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	if not inventory.consume("sink", "ice", 3):
		return "Sink should have initial ice"
	if inventory.amount("sink", "ice") != 37:
		return "Sink ice should decrease from 40 to 37"
	return ""

func test_inventory_rejects_non_positive_consume() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	if inventory.consume("sink", "ice", 0):
		return "Consuming zero should fail"
	if inventory.consume("sink", "ice", -3):
		return "Consuming negative supply should fail"
	if inventory.amount("sink", "ice") != 40:
		return "Rejected consume should not change stock"
	return ""

func test_inventory_rejects_non_positive_restock() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	inventory.restock("sink", "ice", -5)
	if inventory.amount("sink", "ice") != 40:
		return "Rejected restock should not change stock"
	inventory.restock("new_station", "new_supply", 0)
	if inventory.amount("new_station", "new_supply") != 0:
		return "Zero restock should not create stock"
	return ""

func test_new_supply_can_define_capacity() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	inventory.restock("register", "sample_cups", 5, 20)
	inventory.restock("register", "sample_cups", 30)
	if inventory.amount("register", "sample_cups") != 20:
		return "New supply should respect explicit capacity"
	return ""

func test_inventory_restock_caps_at_capacity() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	if not inventory.consume("pickup_counter", "straw", 60):
		return "Pickup counter should have enough straw to consume"
	inventory.restock("pickup_counter", "straw", 200)
	if inventory.amount("pickup_counter", "straw") != 80:
		return "Pickup counter straw should cap at 80"
	return ""

func test_equipment_malfunction_slows_work() -> String:
	var equipment = load("res://src/core/equipment_state.gd").new("ice_maker", 1.0, 100)
	equipment.set_malfunction(true)
	if abs(equipment.speed_multiplier() - 0.5) > 0.001:
		return "Malfunctioning equipment should run at half speed"
	return ""
