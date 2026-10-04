extends SceneTree

func _init() -> void:
	call_deferred(&"_run_all")

func _run_all() -> void:
	# Await a frame to ensure engine and autoloads are initialized if needed
	await process_frame

	var dir: DirAccess = DirAccess.open("res://tests/")
	if dir == null:
		print("FAIL: Could not open res://tests/")
		quit(1)
		return

	var test_files: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd"):
			test_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	test_files.sort()

	var total_failures: int = 0

	for file in test_files:
		var test_path: String = "res://tests/" + file
		var script: Script = load(test_path) as Script
		if script == null:
			print("FAIL %s: failed to load script" % file)
			total_failures += 1
			continue

		var instance: RefCounted = script.new() as RefCounted
		if instance == null:
			print("FAIL %s: failed to instantiate script" % file)
			total_failures += 1
			continue

		if not instance.has_method("run"):
			print("FAIL %s: missing run() method" % file)
			total_failures += 1
			continue

		var failures: Array[String] = instance.run()
		if failures.is_empty():
			print("PASS %s" % file)
		else:
			for err in failures:
				print("FAIL %s: %s" % [file, err])
			total_failures += failures.size()

	if total_failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d FAILURES" % total_failures)
		quit(1)
