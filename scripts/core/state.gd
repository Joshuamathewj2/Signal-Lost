class_name State
extends Node

signal transition_requested(to: StringName, msg: Dictionary)

var machine: StateMachine
var actor: Node

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func transition(to_name: StringName, msg: Dictionary = {}) -> void:
	if machine != null:
		machine.transition_to(to_name, msg)
	else:
		transition_requested.emit(to_name, msg)
