extends RefCounted
class_name GestureAnalyzer

func score_stir(points: Array[Vector2]) -> float:
	if points.size() < 5:
		return 0.0
	if not _all_points_valid(points):
		return 0.0
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())

	var angle_total := 0.0
	var last_angle := (points[0] - center).angle()
	for index in range(1, points.size()):
		var angle := (points[index] - center).angle()
		angle_total += abs(wrapf(angle - last_angle, -PI, PI))
		last_angle = angle
	return clamp(angle_total / TAU, 0.0, 1.0)

func pour_amount(hold_seconds: float, target_seconds: float) -> float:
	if not _is_finite_number(hold_seconds) or not _is_finite_number(target_seconds) or target_seconds <= 0.0:
		return 0.0
	return clamp(hold_seconds / target_seconds, 0.0, 1.25)

func score_whip_path(points: Array[Vector2]) -> float:
	if points.size() < 3:
		return 0.0
	if not _all_points_valid(points):
		return 0.0
	var direction_changes := 0
	var compared_segments := 0
	var last_direction := Vector2.ZERO
	for index in range(1, points.size()):
		var segment := points[index] - points[index - 1]
		if segment.length_squared() <= 0.0:
			continue
		var direction := segment.normalized()
		if last_direction != Vector2.ZERO:
			compared_segments += 1
			if last_direction.dot(direction) < 0.65:
				direction_changes += 1
		last_direction = direction
	if compared_segments == 0:
		return 0.0
	var penalty := float(direction_changes) / float(compared_segments)
	return clamp(1.0 - penalty, 0.0, 1.0)

func score_topping_distribution(points: Array[Vector2], target_rect: Rect2) -> float:
	if points.is_empty():
		return 0.0
	var inside := 0
	for point in points:
		if _is_valid_point(point) and _closed_rect_has_point(target_rect, point):
			inside += 1
	return float(inside) / float(points.size())

func _is_finite_number(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)

func _is_valid_point(point: Vector2) -> bool:
	return _is_finite_number(point.x) and _is_finite_number(point.y)

func _all_points_valid(points: Array[Vector2]) -> bool:
	for point in points:
		if not _is_valid_point(point):
			return false
	return true

func _closed_rect_has_point(rect: Rect2, point: Vector2) -> bool:
	if not _is_valid_point(point) or not _is_valid_point(rect.position) or not _is_valid_point(rect.size):
		return false
	var min_x = min(rect.position.x, rect.position.x + rect.size.x)
	var max_x = max(rect.position.x, rect.position.x + rect.size.x)
	var min_y = min(rect.position.y, rect.position.y + rect.size.y)
	var max_y = max(rect.position.y, rect.position.y + rect.size.y)
	return point.x >= min_x and point.x <= max_x and point.y >= min_y and point.y <= max_y
