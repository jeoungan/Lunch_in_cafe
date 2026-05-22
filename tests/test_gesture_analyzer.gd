extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_stir_detects_circular_motion",
		"test_pour_amount_uses_hold_time",
		"test_whip_path_neatness_rewards_smooth_path",
		"test_short_inputs_return_zero",
		"test_pour_amount_handles_boundaries",
		"test_non_finite_inputs_return_safe_scores",
		"test_topping_distribution_counts_closed_edges"
	]

func test_stir_detects_circular_motion() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var points := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]
	var score := analyzer.score_stir(points)
	if score < 0.75:
		return "Circular stir should score at least 0.75"
	return ""

func test_pour_amount_uses_hold_time() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var amount := analyzer.pour_amount(1.5, 2.0)
	if amount < 0.74 or amount > 0.76:
		return "1.5s hold against 2.0s target should be about 0.75"
	return ""

func test_whip_path_neatness_rewards_smooth_path() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var path := [Vector2(0, 0), Vector2(20, 3), Vector2(40, 5), Vector2(60, 4)]
	var score := analyzer.score_whip_path(path)
	if score < 0.8:
		return "Smooth whip path should score at least 0.8"
	return ""

func test_short_inputs_return_zero() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	if analyzer.score_stir([Vector2(1, 0)]) != 0.0:
		return "Short stir input should score zero"
	if analyzer.score_whip_path([Vector2(0, 0), Vector2(0, 0)]) != 0.0:
		return "Short whip input should score zero"
	if analyzer.score_topping_distribution([], Rect2(0, 0, 10, 10)) != 0.0:
		return "Empty topping input should score zero"
	return ""

func test_pour_amount_handles_boundaries() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	if analyzer.pour_amount(-1.0, 2.0) != 0.0:
		return "Negative hold should clamp to zero"
	if analyzer.pour_amount(1.0, 0.0) != 0.0:
		return "Zero target should return zero"
	if analyzer.pour_amount(1.0, -2.0) != 0.0:
		return "Negative target should return zero"
	if analyzer.pour_amount(5.0, 2.0) != 1.25:
		return "Overlong hold should clamp to 1.25"
	var repeated_whip_score := analyzer.score_whip_path([Vector2(0, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)])
	if repeated_whip_score != repeated_whip_score or repeated_whip_score < 0.0 or repeated_whip_score > 1.0:
		return "Repeated whip points should return a finite bounded score"
	return ""

func test_non_finite_inputs_return_safe_scores() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	if analyzer.pour_amount(NAN, 2.0) != 0.0:
		return "NaN hold should return zero"
	if analyzer.pour_amount(INF, 2.0) != 0.0:
		return "Infinite hold should return zero"
	if analyzer.score_stir([Vector2(NAN, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]) != 0.0:
		return "NaN stir point should return zero"
	if analyzer.score_whip_path([Vector2(0, 0), Vector2(NAN, 0), Vector2(1, 0)]) != 0.0:
		return "NaN whip point should return zero"
	if analyzer.score_topping_distribution([Vector2(NAN, 0), Vector2(1, 1)], Rect2(0, 0, 10, 10)) != 0.5:
		return "NaN topping point should score as outside"
	return ""

func test_topping_distribution_counts_closed_edges() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var score := analyzer.score_topping_distribution([Vector2(0, 0), Vector2(10, 10), Vector2(11, 10)], Rect2(0, 0, 10, 10))
	if score < 0.66 or score > 0.67:
		return "Topping distribution should count top-left and bottom-right edges inside"
	return ""
