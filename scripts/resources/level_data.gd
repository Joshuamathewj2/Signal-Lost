class_name LevelData
extends Resource

@export var name: String = ""
@export var decoys: int = 0
@export var seed: int = 0
@export var width: int = 0
@export var height: int = 0
@export var grid: PackedStringArray = PackedStringArray()
@export var cells: Dictionary = {}
@export var player_spawn: Vector2i = Vector2i.ZERO
@export var exit_cell: Vector2i = Vector2i.ZERO
@export var headers: Dictionary = {}
