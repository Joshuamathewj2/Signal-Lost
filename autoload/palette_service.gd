extends Node

signal palette_changed

var default_palette: PaletteData = preload("res://resources/theme/palette_default.tres")
var colorblind_palette: PaletteData = preload("res://resources/theme/palette_colorblind.tres")

var data: PaletteData = default_palette

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
	if on:
		data = colorblind_palette
	else:
		data = default_palette
	palette_changed.emit()
