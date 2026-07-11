extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_shift_ends_at_ten_minutes",
		"test_shift_elapsed_never_goes_below_zero",
		"test_rewards_include_money_experience_and_reputation",
		"test_delivery_rewards_are_clamped",
		"test_discard_reduces_reputation",
		"test_settlement_returns_copy",
		"test_phase_updates_from_schedule"
	]

func test_shift_ends_at_ten_minutes() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.tick(600.0)
	if not shift.is_finished():
		return "Shift should finish after 600 seconds"
	return ""

func test_rewards_include_money_experience_and_reputation() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.record_delivery({"total": 92}, 5500)
	var settlement: Dictionary = shift.settlement()
	if settlement["money"] <= 0:
		return "Settlement should include money"
	if settlement["experience"] <= 0:
		return "Settlement should include experience"
	if settlement["reputation"] <= 0:
		return "Settlement should include reputation"
	return ""

func test_shift_elapsed_never_goes_below_zero() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.tick(10.0)
	shift.tick(-99.0)
	if shift.settlement()["elapsed"] != 0.0:
		return "Shift elapsed should not go below zero"
	return ""

func test_delivery_rewards_are_clamped() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.record_delivery({"total": 150}, 1000)
	if shift.settlement()["money"] != 1000:
		return "Score above 100 should not overpay beyond base price"
	shift.record_delivery({"total": -50}, -1000)
	var settlement: Dictionary = shift.settlement()
	if settlement["money"] != 1000:
		return "Negative score/base price should not subtract money"
	if settlement["experience"] < 10:
		return "Completed deliveries should not reduce experience"
	return ""

func test_discard_reduces_reputation() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.record_discard()
	var settlement: Dictionary = shift.settlement()
	if settlement["discarded_count"] != 1:
		return "Discard count should increase"
	if settlement["reputation"] != -1:
		return "Discard should reduce reputation"
	return ""

func test_settlement_returns_copy() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	var settlement: Dictionary = shift.settlement()
	settlement["money"] = 999
	if shift.settlement()["money"] == 999:
		return "Settlement mutation should not affect shift state"
	return ""

func test_phase_updates_from_schedule() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.tick(70.0)
	if shift.current_phase()["name"] != "peak":
		return "70 seconds should be first peak"
	return ""
