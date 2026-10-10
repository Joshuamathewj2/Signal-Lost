extends Node

signal palette_changed

var default_palette: PaletteData = preload("res://resources/theme/palette_default.tres")
var colorblind_palette: PaletteData = preload("res://resources/theme/palette_colorblind.tres")

var data: PaletteData = default_palette
var is_colorblind: bool = false

func color(name: StringName) -> Color:
	match name:
		&"bg":
			return data.bg
		&"far":
			return data.far
		&"mid":
			return data.mid
		&"near":
			return data.near
		&"white":
			return data.white
		&"danger":
			return data.danger
		&"smudge":
			return data.smudge
		&"arc":
			return data.arc
		_:
			return Color.WHITE

func set_colorblind(on: bool) -> void:
	is_colorblind = on
	if on:
		data = colorblind_palette
	else:
		data = default_palette
	palette_changed.emit()
	if is_inside_tree():
		update_tree_hatch(get_tree().root)

func update_tree_hatch(root_node: Node) -> void:
	if root_node == null:
		return
	for child in root_node.get_children():
		if child is CanvasItem and (child as CanvasItem).material is ShaderMaterial:
			var sm: ShaderMaterial = (child as CanvasItem).material as ShaderMaterial
			if sm.shader != null and sm.get_shader_parameter(&"hatch") != null:
				sm.set_shader_parameter(&"hatch", is_colorblind)
		update_tree_hatch(child)
