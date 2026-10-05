class_name EnemyBase
extends CharacterBody2D

@export var profile: EnemyProfile
@export var kind: StringName = &"listener"

@onready var hearing: HearingComponent = $HearingComponent
@onready var vision: VisionComponent = $VisionComponent
@onready var awareness: Awareness = $Awareness
@onready var memory: NoiseMemory = $NoiseMemory
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox: Area2D = $Hitbox

var facing: int = 1
var last_noise: Dictionary = {}
var last_seen: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group(&"enemies")

	# Physics Layer 4 (enemy), Mask 1 (world) | 2 (one_way)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)

	if profile != null:
		if hearing != null:
			hearing.profile = profile
		if vision != null:
			vision.profile = profile
		if awareness != null:
			awareness.profile = profile
		if memory != null:
			memory.profile = profile

	if hearing != null:
		hearing.heard.connect(_on_heard)
	if vision != null:
		vision.player_spotted.connect(_on_player_spotted)
		vision.player_lost.connect(_on_player_lost)
	if hitbox != null:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func face(dir: int) -> void:
	if dir == 0:
		return
	facing = 1 if dir > 0 else -1
	var vis: Node = get_node_or_null("Visual")
	if vis is Node2D:
		(vis as Node2D).scale.x = float(facing)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		var g: float = GameConfig.data.gravity if (GameConfig != null and GameConfig.data != null) else 1800.0
		velocity.y += g * delta

func _on_heard(event: NoiseEvent, strength: float) -> void:
	last_noise = {
		"pos": event.position,
		"strength": strength,
		"loudness": event.loudness,
		"type": event.type
	}
	if awareness != null:
		awareness.on_heard(event, strength)
	if memory != null:
		memory.push_noise(event, strength)

func _on_player_spotted(pos: Vector2) -> void:
	last_seen = pos
	if awareness != null:
		awareness.on_spotted()

func _on_player_lost() -> void:
	pass

func _on_hitbox_body_entered(body: Node2D) -> void:
	if profile != null and not profile.contact_kills:
		return
	if body is Player or body.is_in_group(&"player"):
		if body.has_method("die"):
			body.call("die", &"caught")
