@tool
extends SceneTree

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	print("[sprite_frames] Building SpriteFrames resources from manifest...")
	var manifest_file := FileAccess.open("res://assets/sprites/sprite_manifest.json", FileAccess.READ)
	if manifest_file == null:
		print("FAIL: Could not open sprite_manifest.json")
		quit(1)
		return

	var json_str := manifest_file.get_as_text()
	manifest_file.close()

	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		print("FAIL: JSON parse error: ", json.get_error_message())
		quit(1)
		return

	var data: Dictionary = json.data
	var sprites: Array = data.get("sprites", [])

	DirAccess.make_dir_recursive_absolute("res://resources/sprites/")

	# Group by target resource:
	# "hero" -> resources/sprites/hero_frames.tres
	# "ronin" -> resources/sprites/ronin_frames.tres
	# "archer" -> resources/sprites/archer_frames.tres
	# "spear" -> resources/sprites/spear_frames.tres
	# "brute" -> resources/sprites/brute_frames.tres
	# Traps -> resources/sprites/<trap_name>_frames.tres

	var resource_groups := {
		"hero": {},
		"ronin": {},
		"archer": {},
		"spear": {},
		"brute": {},
		"floor_spikes": {},
		"ceiling_spikes": {},
		"swinging_blade": {},
		"wall_blade": {},
		"arrow_trap": {},
		"spear_launcher": {},
		"falling_rock": {},
		"rolling_boulder": {},
		"guillotine": {},
		"fire_trap": {},
		"extra_projectiles": {},
		"fx": {}
	}

	for s in sprites:
		var cat: String = s.get("category", "")
		var group_key: String = ""
		if cat == "hero":
			group_key = "hero"
		elif cat in ["ronin", "archer", "spear", "brute"]:
			group_key = cat
		elif cat in ["floor_spikes", "ceiling_spikes", "swinging_blade", "wall_blade", "arrow_trap", "spear_launcher", "falling_rock", "rolling_boulder", "guillotine", "fire_trap"]:
			group_key = cat
		elif cat == "projectiles":
			group_key = "extra_projectiles"
		elif cat == "fx":
			group_key = "fx"

		if group_key == "":
			continue

		var anim: String = s.get("animation", "default")
		var f_path: String = "res://" + s.get("file", "")

		if not resource_groups[group_key].has(anim):
			resource_groups[group_key][anim] = []
		resource_groups[group_key][anim].append({
			"frame": s.get("frame", 0),
			"path": f_path
		})

	# Define FPS and Loop defaults per animation
	var loop_anims := ["idle", "walk", "run", "crouch", "roll", "swing_left", "flame"]
	var anim_fps := {
		"idle": 6.0,
		"walk": 8.0,
		"run": 10.0,
		"jump": 6.0,
		"crouch": 6.0,
		"attack1": 10.0,
		"attack2": 10.0,
		"attack3": 12.0,
		"attack_heavy": 8.0,
		"attack_thrust": 10.0,
		"aim": 6.0,
		"shoot": 10.0,
		"shoot_release": 10.0,
		"thrust": 10.0,
		"sweep": 10.0,
		"smash": 8.0,
		"swing": 10.0,
		"hurt": 8.0,
		"die": 6.0,
		"trigger": 10.0,
		"rising": 12.0,
		"drop": 12.0,
		"extend": 12.0,
		"retract": 10.0,
		"charge": 10.0,
		"launch": 14.0,
		"crack": 8.0,
		"fall": 12.0,
		"impact": 10.0,
		"roll": 10.0,
		"flame": 10.0
	}

	for res_name in resource_groups:
		var anims: Dictionary = resource_groups[res_name]
		if anims.is_empty():
			continue

		var sf := SpriteFrames.new()
		# Remove default animation if present
		if sf.has_animation(&"default"):
			sf.remove_animation(&"default")

		for a_name in anims:
			var anim_id := StringName(a_name)
			if not sf.has_animation(anim_id):
				sf.add_animation(anim_id)

			var fps: float = anim_fps.get(a_name, 8.0)
			sf.set_animation_speed(anim_id, fps)
			var should_loop: bool = (a_name in loop_anims)
			sf.set_animation_loop(anim_id, should_loop)

			# Sort frames by index
			var frame_list: Array = anims[a_name]
			frame_list.sort_custom(func(a, b): return a["frame"] < b["frame"])

			for item in frame_list:
				var tex: Texture2D = load(item["path"]) as Texture2D
				if tex != null:
					sf.add_frame(anim_id, tex)
				else:
					print("WARN: Texture not found: ", item["path"])

		# Add STAND-IN placeholder animations if hero or enemies are missing requested animations
		if res_name == "hero":
			_add_hero_standins(sf)
		elif res_name in ["ronin", "archer", "spear", "brute"]:
			_add_enemy_standins(sf, res_name)

		var out_path := "res://resources/sprites/%s_frames.tres" % res_name
		var save_err := ResourceSaver.save(sf, out_path)
		if save_err == OK:
			print("PASS: Saved %s (%d animations)" % [out_path, sf.get_animation_names().size()])
		else:
			print("FAIL: Could not save ", out_path, " err=", save_err)

	print("[sprite_frames] Done!")
	quit(0)

func _add_hero_standins(sf: SpriteFrames) -> void:
	# Missing hero animations: parry, heavy, shuriken throw, takedown, death, wall/air attack
	# Stand-ins drop in with names matching future real art
	var thrust_tex := load("res://assets/sprites/hero/hero_attack_thrust_0.png") as Texture2D
	var heavy_tex := load("res://assets/sprites/hero/hero_attack_heavy_0.png") as Texture2D
	var crouch_tex := load("res://assets/sprites/hero/hero_crouch_0.png") as Texture2D
	var hurt_tex := load("res://assets/sprites/hero/hero_hurt_0.png") as Texture2D
	var jump_tex := load("res://assets/sprites/hero/hero_jump_0.png") as Texture2D
	var idle_tex := load("res://assets/sprites/hero/hero_idle_0.png") as Texture2D

	var standins := {
		"parry": [thrust_tex], # parry = thrust stance hold
		"guard": [thrust_tex],
		"heavy": [heavy_tex], # overhead windup
		"dash": [thrust_tex],
		"dash_slash": [thrust_tex],
		"plunge": [jump_tex],
		"rising_slash": [heavy_tex],
		"counter_strike": [thrust_tex],
		"shuriken": [thrust_tex], # shuriken throw
		"kunai_toss": [thrust_tex],
		"takedown": [heavy_tex], # takedown strike
		"dead": [hurt_tex], # knocked back prone
		"wall_slide": [crouch_tex],
		"air_attack": [heavy_tex]
	}

	for s_name in standins:
		var a_id := StringName(s_name)
		if not sf.has_animation(a_id):
			sf.add_animation(a_id)
			sf.set_animation_speed(a_id, 8.0)
			sf.set_animation_loop(a_id, false)
			for t in standins[s_name]:
				if t != null:
					sf.add_frame(a_id, t)

func _add_enemy_standins(sf: SpriteFrames, _cat: String) -> void:
	# Stun, shield raise, evade
	var hurt_tex: Texture2D = null
	if sf.has_animation(&"hurt") and sf.get_frame_count(&"hurt") > 0:
		hurt_tex = sf.get_frame_texture(&"hurt", 0)

	var idle_tex: Texture2D = null
	if sf.has_animation(&"idle") and sf.get_frame_count(&"idle") > 0:
		idle_tex = sf.get_frame_texture(&"idle", 0)

	if hurt_tex != null:
		if not sf.has_animation(&"stun"):
			sf.add_animation(&"stun")
			sf.set_animation_speed(&"stun", 4.0)
			sf.set_animation_loop(&"stun", true)
			sf.add_frame(&"stun", hurt_tex)

	if idle_tex != null:
		if not sf.has_animation(&"evade"):
			sf.add_animation(&"evade")
			sf.set_animation_speed(&"evade", 8.0)
			sf.set_animation_loop(&"evade", false)
			sf.add_frame(&"evade", idle_tex)

		if not sf.has_animation(&"shield_raise"):
			sf.add_animation(&"shield_raise")
			sf.set_animation_speed(&"shield_raise", 6.0)
			sf.set_animation_loop(&"shield_raise", false)
			sf.add_frame(&"shield_raise", idle_tex)
