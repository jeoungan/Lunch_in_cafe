extends RefCounted
class_name QualityScorer

func score(input: Dictionary) -> Dictionary:
	var required: Array = input.get("required_actions", [])
	var performed: Array = input.get("performed_actions", [])
	var requests: Array = input.get("requests", [])
	var satisfied: Array = input.get("satisfied_requests", [])
	var wait_ratio: float = clamp(input.get("wait_ratio", 0.0), 0.0, 1.0)
	var visual_neatness: float = clamp(input.get("visual_neatness", 1.0), 0.0, 1.0)

	var recipe_score := _recipe_score(required, performed)
	var request_score := _request_score(requests, satisfied)
	var wait_score := 100.0 - wait_ratio * 35.0
	var visual_score := visual_neatness * 100.0
	var total := recipe_score * 0.4 + request_score * 0.25 + wait_score * 0.2 + visual_score * 0.15

	return {
		"total": int(round(clamp(total, 0.0, 100.0))),
		"recipe": int(round(recipe_score)),
		"requests": int(round(request_score)),
		"wait": int(round(wait_score)),
		"visual": int(round(visual_score))
	}

func _recipe_score(required: Array, performed: Array) -> float:
	var denominator: int = max(required.size(), performed.size())
	if denominator == 0:
		return 100.0
	var correct := 0
	for index in range(min(required.size(), performed.size())):
		if required[index] == performed[index]:
			correct += 1
	return float(correct) / float(denominator) * 100.0

func _request_score(requests: Array, satisfied: Array) -> float:
	var unique_requests := _unique_values(requests)
	var unique_satisfied := _unique_values(satisfied)
	if unique_requests.is_empty():
		return 100.0
	var correct := 0
	for request in unique_requests:
		if request in unique_satisfied:
			correct += 1
	return float(correct) / float(unique_requests.size()) * 100.0

func _unique_values(values: Array) -> Array:
	var seen := {}
	var unique := []
	for value in values:
		if not seen.has(value):
			seen[value] = true
			unique.append(value)
	return unique
