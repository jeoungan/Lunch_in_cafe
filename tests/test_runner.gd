extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var test_paths := _collect_tests("res://tests")
	for path in test_paths:
		_run_suite(path)

	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("TESTS FAILED: %d" % failures.size())
		quit(1)

func _collect_tests(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		failures.append("Cannot open tests directory: %s" % dir_path)
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd":
			paths.append("%s/%s" % [dir_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths

func _run_suite(path: String) -> void:
	var script := load(path)
	if script == null:
		failures.append("Cannot load test suite: %s" % path)
		return
	var suite = script.new()
	for method_name in suite.get_test_methods():
		var result: String = suite.call(method_name)
		if result != "":
			failures.append("%s::%s - %s" % [path, method_name, result])
