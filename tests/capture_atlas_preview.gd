extends Node

## Renders tools/AtlasPreview.tscn for a few units and saves screenshots to
## res://qa/shots/atlas_preview_*.png (visual check of keying + pivots).

const SHOTS: Array = [
	["archer", "run", false], ["archer", "draw", false], ["acoustic_hunter", "crawl", false],
	["executioner", "windup", false], ["boss_leviathan", "walk", true], ["boss_leviathan", "enraged", false],
	["hazards_grid_obstacles", "pendulum_saw", false], ["warden", "thrust", true],
]

func _ready() -> void:
	call_deferred(&"_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://qa/shots")
	var preview: Node2D = (load("res://tools/AtlasPreview.tscn") as PackedScene).instantiate() as Node2D
	add_child(preview)
	await get_tree().process_frame
	preview.set("auto_cycle", false)
	for shot in SHOTS:
		var u: int = (preview.get("units") as PackedStringArray).find(shot[0])
		preview.call("_select_unit", u)
		var anims: PackedStringArray = preview.get("anim_names")
		preview.set("game_scale", shot[2])
		preview.call("_select_anim", anims.find(shot[1]))
		for f in 12:
			await get_tree().process_frame
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png("res://qa/shots/atlas_preview_%s_%s.png" % [shot[0], shot[1]])
	get_tree().quit()
