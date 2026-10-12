class_name EnemyBase
extends CharacterBody2D

@export var profile: EnemyProfile
@export var kind: StringName = &"listener"

@onready var hearing: HearingComponent = $HearingComponent
@onready var vision: VisionComponent = $VisionComponent
@onready var awareness: Awareness = $Awareness
@onready var memory: NoiseMemory = $NoiseMemory
@onready var state_machine: StateMachine = $StateMachine
@onready var mover: PlatformMover = $PlatformMover
@onready var hitbox: Area2D = $Hitbox
@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var poise_component: PoiseComponent = get_node_or_null("PoiseComponent")
@onready var hurtbox_component: HurtboxComponent = get_node_or_null("HurtboxComponent")

@export var has_gravity: bool = true
var facing: int = 1
var facing_direction: Vector2 = Vector2.ZERO
var last_noise: Dictionary = {}
var last_seen: Vector2 = Vector2.ZERO

var smudge: Node2D = null
var smudge_scene: PackedScene = preload("res://scenes/enemies/smudge.tscn")

var awareness_bar: Node2D = null
var awareness_bar_scene: PackedScene = preload("res://scenes/ui/awareness_bar.tscn")

var noise_reticle: Node2D = null
var world_reticle_scene: PackedScene = preload("res://scenes/ui/world_reticle.tscn")

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
	if awareness != null:
		awareness.awareness_changed.connect(_on_awareness_changed)
	if state_machine != null:
		state_machine.state_changed.connect(_on_state_changed)
	if hitbox != null:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
	if poise_component != null:
		poise_component.staggered.connect(_on_staggered)

	match kind:
		&"kenshi":
			if health_component != null:
				health_component.max_health = 3
				health_component.current_health = 3
			if poise_component != null:
				poise_component.max_poise = 60.0
				poise_component.current_poise = 60.0
		&"yumi":
			if health_component != null:
				health_component.max_health = 1
				health_component.current_health = 1
			if poise_component != null:
				poise_component.max_poise = 20.0
				poise_component.current_poise = 20.0
		&"brute":
			if health_component != null:
				health_component.max_health = 6
				health_component.current_health = 6
			if poise_component != null:
				poise_component.max_poise = 120.0
				poise_component.current_poise = 120.0

	call_deferred(&"_setup_sense_ui")

func _setup_sense_ui() -> void:
	var sense_layer: Node = get_tree().get_first_node_in_group(&"sense_layer")
	if sense_layer != null:
		smudge = smudge_scene.instantiate() as Node2D
		sense_layer.add_child(smudge)
		smudge.visible = false

		awareness_bar = awareness_bar_scene.instantiate() as Node2D
		sense_layer.add_child(awareness_bar)
		if awareness_bar.has_method("setup"):
			awareness_bar.setup(self)

		noise_reticle = world_reticle_scene.instantiate() as Node2D
		sense_layer.add_child(noise_reticle)
		if noise_reticle.has_method("deactivate"):
			noise_reticle.deactivate()

func _exit_tree() -> void:
	if smudge != null and is_instance_valid(smudge):
		smudge.queue_free()
	if awareness_bar != null and is_instance_valid(awareness_bar):
		awareness_bar.queue_free()
	if noise_reticle != null and is_instance_valid(noise_reticle):
		noise_reticle.queue_free()

func face(dir: int) -> void:
	if dir == 0:
		return
	facing = 1 if dir > 0 else -1
	var vis: Node = get_node_or_null("Visual")
	if vis is Node2D:
		(vis as Node2D).scale.x = float(facing)

func _physics_process(delta: float) -> void:
	if has_gravity and not is_on_floor():
		var g: float = GameConfig.data.gravity if (GameConfig != null and GameConfig.data != null) else 1800.0
		velocity.y += g * delta

func trigger_smudge() -> void:
	if smudge != null and PulseRegistry != null and PulseRegistry.reveal_at(global_position) <= 0.25:
		smudge.show_at(global_position, self)

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
	if noise_reticle != null:
		noise_reticle.setup_noise(event.position, self)
	trigger_smudge()

func _on_player_spotted(pos: Vector2) -> void:
	last_seen = pos
	if awareness != null:
		awareness.on_spotted()

func _on_player_lost() -> void:
	pass

func _on_awareness_changed(new_val: float, _old_val: float) -> void:
	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("set_alert"):
		vis.call("set_alert", new_val)

func _on_state_changed(_actor: Node, _from: StringName, to: StringName) -> void:
	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")

	if to == &"Investigate" or to == &"Search":
		if not last_noise.is_empty() and noise_reticle != null:
			var n_pos: Vector2 = last_noise.get("pos", global_position)
			noise_reticle.setup_noise(n_pos, self)
	elif to != &"Investigate" and to != &"Search":
		if noise_reticle != null:
			noise_reticle.deactivate()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if profile != null and not profile.contact_kills:
		return
	if body != null and body.is_in_group(&"player"):
		if body.has_method("die"):
			body.call("die", &"caught")

func _on_damaged(_amount: int, knockback: Vector2) -> void:
	velocity += knockback
	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")

func _on_staggered(duration: float) -> void:
	if AttackTokenManager != null:
		AttackTokenManager.release_token(self)
	if state_machine != null and state_machine.states.has(&"Stagger"):
		state_machine.change_state(&"Stagger", {"duration": duration})

func intercept_hit(hitbox: Area2D) -> bool:
	if is_in_group(&"brute"):
		var facing_dir: float = float(facing)
		var is_frontal: bool = (hitbox.global_position.x - global_position.x) * facing_dir >= -6.0
		if is_frontal:
			var is_penetrating: bool = false
			if hitbox.has_meta(&"is_heavy") and bool(hitbox.get_meta(&"is_heavy")):
				var w_type: int = int(hitbox.get_meta(&"weapon_type")) if hitbox.has_meta(&"weapon_type") else 0
				if w_type == 1: # Naginata heavy
					is_penetrating = true
			var p_dmg: float = float(hitbox.get("poise_damage")) if hitbox.get("poise_damage") != null else 0.0
			if p_dmg >= 55.0:
				is_penetrating = true

			if not is_penetrating:
				var vis: Node = get_node_or_null("Visual")
				if vis != null and vis.has_method("flash"):
					vis.call("flash")
				if NoiseBus != null:
					var ev := NoiseEvent.make(global_position, 120.0, 1.2, NoiseEvent.NoiseType.COMBAT, self)
					NoiseBus.emit_noise(ev)
				return true

	var sm: StateMachine = state_machine
	if sm == null:
		sm = get_node_or_null("StateMachine") as StateMachine
	if sm != null and sm.current != null and sm.current.has_method("intercept_hit"):
		return bool(sm.current.call("intercept_hit", hitbox))
	return false

func _on_died(_cause: StringName) -> void:
	if AttackTokenManager != null:
		AttackTokenManager.release_token(self)
	queue_free()
