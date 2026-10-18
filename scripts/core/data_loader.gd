class_name DataLoader
extends RefCounted

## DataLoader
## Single entry point for tunable JSON under res://data/.
## Parses, validates required keys and reports precise errors (file, line, missing
## keys) instead of failing silently. Results are cached per path.

static var _cache: Dictionary = {}


static func load_json(path: String, required_keys: PackedStringArray = PackedStringArray(), use_cache: bool = true) -> Dictionary:
	if use_cache and _cache.has(path):
		return _cache[path]

	if not FileAccess.file_exists(path):
		push_error("[DataLoader] missing file: %s" % path)
		return {}

	var json := JSON.new()
	var err: Error = json.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		push_error("[DataLoader] %s:%d JSON parse error: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("[DataLoader] %s: top level must be an object" % path)
		return {}

	var data: Dictionary = json.data
	if not validate_keys(data, required_keys, path).is_empty():
		return {}

	_cache[path] = data
	return data


## Returns the missing keys (empty when valid) and logs them with context.
static func validate_keys(data: Dictionary, keys: PackedStringArray, context: String) -> PackedStringArray:
	var missing := PackedStringArray()
	for k in keys:
		if not data.has(k):
			missing.append(k)
	if not missing.is_empty():
		push_error("[DataLoader] %s is missing required keys: %s" % [context, ", ".join(missing)])
	return missing


static func clear_cache() -> void:
	_cache.clear()
