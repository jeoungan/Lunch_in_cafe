extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_boss_processes_one_task_at_a_time",
		"test_assist_reduces_remaining_time",
		"test_completed_tasks_are_collected",
		"test_duplicate_enqueue_is_ignored",
		"test_collect_completed_clears_results"
	]

func test_boss_processes_one_task_at_a_time() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.enqueue("order_2", "steam_milk")
	queue.tick(0.1)
	if queue.current_task()["order_id"] != "order_1":
		return "Boss should start first queued task"
	if queue.pending_count() != 1:
		return "One task should remain pending"
	return ""

func test_assist_reduces_remaining_time() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.tick(0.1)
	var before := queue.current_task()["remaining"]
	queue.assist_current_task(0.5)
	var after := queue.current_task()["remaining"]
	if not after < before:
		return "Assist should reduce remaining time"
	return ""

func test_completed_tasks_are_collected() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.tick(99.0)
	var completed := queue.collect_completed()
	if completed.size() != 1:
		return "One completed boss task expected"
	if completed[0]["action"] != "pull_espresso":
		return "Completed action should be pull_espresso"
	if queue.current_task().size() != 0:
		return "Current task should be empty after completion"
	return ""

func test_duplicate_enqueue_is_ignored() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.enqueue("order_1", "pull_espresso")
	if queue.pending_count() != 1:
		return "Duplicate pending boss task should be ignored"
	queue.tick(0.1)
	queue.enqueue("order_1", "pull_espresso")
	if queue.pending_count() != 0:
		return "Duplicate current boss task should be ignored"
	queue.tick(99.0)
	queue.enqueue("order_1", "pull_espresso")
	if queue.pending_count() != 0:
		return "Duplicate completed boss task should be ignored until collected"
	var completed := queue.collect_completed()
	if completed.size() != 1:
		return "Only the original completed boss task should be collected"
	return ""

func test_collect_completed_clears_results() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.tick(99.0)
	queue.collect_completed()
	if queue.collect_completed().size() != 0:
		return "Completed tasks should only be collected once"
	return ""
