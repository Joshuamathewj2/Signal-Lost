class_name VillainHitbox
extends Area2D

## VillainHitbox
## Data carrier for a villain's melee strike. StVillainAttack writes the current
## attack's numbers here, then hands this area to the hero's HurtboxComponent,
## which reads damage / poise_damage / knockback_force / hitstop_duration from it
## (and the hero's CombatController parries, guards or clashes against it).

@export var damage: int = 1
@export var poise_damage: float = 20.0
@export var knockback_force: float = 160.0
@export var hitstop_duration: float = 0.08


func configure(attack: Dictionary) -> void:
	damage = int(attack.get("damage", 1))
	poise_damage = float(attack.get("poise", 20.0))
	knockback_force = float(attack.get("knockback", 160.0))
	hitstop_duration = float(attack.get("hitstop", 0.08))
	set_meta(&"is_heavy", poise_damage >= 50.0)
