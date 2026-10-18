class_name FighterIntent
extends RefCounted

## FighterIntent
## What a Fighter wants to do this physics frame. The player fills it from Input,
## enemies fill it from AI (PlatformMover / states). The Fighter never reads Input.

var move_dir: float = 0.0
var jump_pressed: bool = false   ## edge: pressed this frame
var jump_held: bool = false
var jump_released: bool = false  ## edge: released this frame (variable jump height)
var dash_pressed: bool = false
var attack_pressed: bool = false
var parry_pressed: bool = false
var crouch: bool = false
var drop_through: bool = false   ## AI shortcut for "crouch + jump" on a one-way platform


func clear() -> void:
	move_dir = 0.0
	jump_pressed = false
	jump_held = false
	jump_released = false
	dash_pressed = false
	attack_pressed = false
	parry_pressed = false
	crouch = false
	drop_through = false


## Edge flags last exactly one physics step.
func consume_edges() -> void:
	jump_pressed = false
	jump_released = false
	dash_pressed = false
	attack_pressed = false
	parry_pressed = false
	drop_through = false
