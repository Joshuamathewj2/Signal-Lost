"""Generate the Chapter II villain roster: data/enemies/<kind>.json + scenes/enemies/<kind>.tscn.

Every villain = enemy_base.tscn + ManifestVisual (data/manifests/<unit>.json art)
+ Fighter locomotion + StVillainAttack driven by the "attacks" list below.
Re-run after tuning:  python tools/gen_villains.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

LOCO_LIGHT = {"run_speed": 150.0, "sneak_speed": 60.0, "ground_accel": 1400.0, "ground_friction": 1800.0,
              "air_accel": 900.0, "gravity": 1800.0, "fall_gravity_mult": 1.35, "jump_cut_mult": 0.45,
              "max_fall_speed": 900.0, "coyote_time": 0.10, "jump_buffer": 0.10, "drop_through_time": 0.20}


def loco(**over):
    d = dict(LOCO_LIGHT)
    d.update(over)
    return d


VILLAINS = {
    "phantom": {
        "_doc": "Crimson duelist. Quick slash at close range, telegraphed dash-slash from mid range.",
        "class": "Phantom", "profile": "enemy_kenshi", "radius": 8, "height": 26,
        "weight_class": "light", "health": 3, "poise": 35, "bar_y": -40,
        "locomotion": loco(run_speed=165.0),
        "jump": {"can_jump": True, "jump_height": 84.0, "cooldown": 0.35, "max_gap": 96.0},
        "dash": {"speed": 420.0, "time": 0.22, "cooldown": 1.2, "telegraph": 0.0},
        "nav": {"stuck_time": 1.5, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"attack": ["slash", "double_slash"], "telegraph": ["ready"]},
        "attacks": [
            {"name": "slash", "type": "lunge", "range": 40, "reach": 38, "telegraph": 0.40, "active": 0.12,
             "recovery": 0.40, "cooldown": 0.6, "weight": 3, "damage": 1, "poise": 20, "knockback": 160,
             "lunge_speed": 150, "anim_telegraph": "ready", "anim_strike": "slash"},
            {"name": "double_slash", "type": "spin", "range": 44, "reach": 42, "telegraph": 0.50, "active": 0.24,
             "recovery": 0.45, "cooldown": 2.0, "weight": 1, "hits": 2, "damage": 1, "poise": 15, "knockback": 120,
             "anim_telegraph": "ready", "anim_strike": "double_slash"},
            {"name": "dash_slash", "type": "dash", "range": 170, "min_range": 70, "telegraph": 0.45, "active": 0.22,
             "recovery": 0.55, "cooldown": 2.8, "weight": 2, "damage": 1, "poise": 25, "knockback": 220,
             "contact": 26, "anim_telegraph": "ready", "anim_strike": "dash"},
        ],
    },
    "warden": {
        "_doc": "Shield + spear jailer. Shield blocks frontal light hits (heavy / >=50 poise breaks through; strike from behind).",
        "class": "Warden", "profile": "enemy_kenshi", "radius": 10, "height": 32,
        "weight_class": "medium", "health": 5, "poise": 70, "bar_y": -48, "frontal_guard": True,
        "locomotion": loco(run_speed=110.0, sneak_speed=50.0),
        "jump": {"can_jump": True, "jump_height": 72.0, "cooldown": 0.5, "max_gap": 72.0},
        "dash": {"speed": 300.0, "time": 0.18, "cooldown": 2.0, "telegraph": 0.45},
        "nav": {"stuck_time": 1.8, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"attack": ["thrust"], "telegraph": ["spear_ready"]},
        "attacks": [
            {"name": "thrust", "type": "lunge", "range": 60, "reach": 58, "telegraph": 0.50, "active": 0.14,
             "recovery": 0.45, "cooldown": 0.9, "weight": 3, "damage": 1, "poise": 25, "knockback": 200,
             "lunge_speed": 180, "anim_telegraph": "spear_ready", "anim_strike": "thrust"},
            {"name": "skewer", "type": "lunge", "range": 64, "reach": 60, "telegraph": 0.70, "active": 0.16,
             "recovery": 0.55, "cooldown": 3.0, "weight": 1, "damage": 2, "poise": 40, "knockback": 260,
             "lunge_speed": 260, "anim_telegraph": "spear_raise", "anim_strike": "thrust", "tell": "!"},
            {"name": "shield_bash", "type": "melee", "range": 30, "reach": 32, "telegraph": 0.35, "active": 0.12,
             "recovery": 0.40, "cooldown": 2.2, "weight": 2, "damage": 1, "poise": 45, "knockback": 340,
             "anim_telegraph": "idle", "anim_strike": "shield_bash"},
        ],
    },
    "executioner": {
        "_doc": "Hulking cleaver. Hyper-armored while attacking; slam shockwave also crushes nearby allies.",
        "class": "Executioner", "profile": "enemy_kenshi", "radius": 12, "height": 40,
        "weight_class": "heavy", "health": 8, "poise": 140, "bar_y": -60,
        "hyper_armor_states": ["Attack"],
        "locomotion": loco(run_speed=85.0, sneak_speed=40.0, ground_accel=900.0),
        "jump": {"can_jump": True, "jump_height": 60.0, "cooldown": 0.8, "max_gap": 64.0},
        "dash": {"speed": 260.0, "time": 0.2, "cooldown": 2.5, "telegraph": 0.5},
        "nav": {"stuck_time": 2.0, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"attack": ["slam"], "telegraph": ["windup"], "evade": ["drag"]},
        "attacks": [
            {"name": "cleaver_slam", "type": "shockwave", "range": 62, "reach": 60, "telegraph": 0.75,
             "active": 0.18, "recovery": 0.75, "cooldown": 1.4, "weight": 3, "damage": 2, "poise": 55,
             "knockback": 300, "radius": 92, "shake": 0.45, "fx": "shockwave", "fx_y": 20,
             "anim_telegraph": "windup", "anim_strike": "slam"},
            {"name": "sweep", "type": "melee", "range": 76, "reach": 74, "telegraph": 0.60, "active": 0.16,
             "recovery": 0.60, "cooldown": 2.4, "weight": 2, "damage": 2, "poise": 45, "knockback": 320,
             "anim_telegraph": "windup", "anim_strike": "sweep", "then": "drag_finish"},
            {"name": "drag_finish", "type": "lunge", "range": 0, "reach": 50, "telegraph": 0.10, "active": 0.25,
             "recovery": 0.70, "cooldown": 0.0, "weight": 0, "damage": 1, "poise": 30, "knockback": 200,
             "lunge_speed": 120, "tint": False, "anim_telegraph": "drag", "anim_strike": "drag"},
        ],
    },
    "iron_monk": {
        "_doc": "Flail monk. Spins the flail to hit both sides up close; lobs the flail ball at range.",
        "class": "IronMonk", "profile": "enemy_kenshi", "radius": 10, "height": 34,
        "weight_class": "medium", "health": 6, "poise": 90, "bar_y": -52,
        "locomotion": loco(run_speed=100.0, sneak_speed=45.0),
        "jump": {"can_jump": True, "jump_height": 70.0, "cooldown": 0.6, "max_gap": 72.0},
        "dash": {"speed": 280.0, "time": 0.2, "cooldown": 2.0, "telegraph": 0.45},
        "nav": {"stuck_time": 1.8, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"attack": ["spin"], "telegraph": ["walk"]},
        "attacks": [
            {"name": "flail_spin", "type": "spin", "range": 58, "reach": 60, "telegraph": 0.55, "active": 0.80,
             "recovery": 0.50, "cooldown": 2.0, "weight": 3, "hits": 3, "damage": 1, "poise": 20, "knockback": 220,
             "anim_telegraph": "idle", "anim_strike": "spin", "tell": "!"},
            {"name": "chain_throw", "type": "projectile", "range": 260, "min_range": 70, "max_dy": 120,
             "telegraph": 0.60, "active": 0.20, "recovery": 0.60, "cooldown": 2.6, "weight": 2, "damage": 1,
             "poise": 35, "speed": 300, "gravity": 700, "projectile_anim": "flail_ball", "projectile_spin": 12.0,
             "anim_telegraph": "idle", "anim_strike": "chain_throw"},
        ],
    },
    "blood_archer": {
        "_doc": "Crimson bowman. Holds ~170 px, draws and looses arrows; hops away if crowded.",
        "class": "BloodArcher", "profile": "enemy_yumi", "radius": 8, "height": 28,
        "weight_class": "light", "health": 2, "poise": 30, "bar_y": -44, "keep_distance": 170,
        "locomotion": loco(run_speed=120.0),
        "jump": {"can_jump": True, "jump_height": 80.0, "cooldown": 0.4, "max_gap": 96.0},
        "dash": {"speed": 340.0, "time": 0.18, "cooldown": 1.6, "telegraph": 0.0},
        "nav": {"stuck_time": 1.5, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"attack": ["release"], "telegraph": ["draw"]},
        "attacks": [
            {"name": "loose", "type": "projectile", "range": 360, "min_range": 60, "max_dy": 160,
             "telegraph": 0.65, "active": 0.15, "recovery": 0.45, "cooldown": 1.4, "weight": 3, "damage": 1,
             "poise": 20, "speed": 480, "projectile_anim": "arrow", "anim_telegraph": "draw", "anim_strike": "release"},
            {"name": "backstep", "type": "reposition", "range": 64, "telegraph": 0.15, "active": 0.3,
             "recovery": 0.2, "cooldown": 2.5, "weight": 4, "distance": 120, "tint": False,
             "anim_telegraph": "idle", "anim_strike": "walk"},
        ],
    },
    "archer": {
        "_doc": "Concealed sniper. Waits crouched, rolls away when rushed, mixes quick shots with a charged unblockable arrow.",
        "class": "Archer", "profile": "enemy_yumi", "radius": 8, "height": 26,
        "weight_class": "light", "health": 3, "poise": 35, "bar_y": -42, "keep_distance": 200,
        "locomotion": loco(run_speed=135.0),
        "jump": {"can_jump": True, "jump_height": 84.0, "cooldown": 0.35, "max_gap": 96.0},
        "dash": {"speed": 360.0, "time": 0.2, "cooldown": 1.4, "telegraph": 0.0},
        "nav": {"stuck_time": 1.5, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"idle": ["idle_concealed"], "attack": ["release"], "telegraph": ["draw"], "evade": ["roll"],
                     "hurt": ["hit_flash", "hit"], "stun": ["knockdown"]},
        "attacks": [
            {"name": "quick_shot", "type": "projectile", "range": 400, "min_range": 60, "max_dy": 180,
             "telegraph": 0.55, "active": 0.15, "recovery": 0.40, "cooldown": 1.2, "weight": 3, "damage": 1,
             "poise": 20, "speed": 520, "projectile_anim": "arrow", "anim_telegraph": "draw", "anim_strike": "release"},
            {"name": "charged_shot", "type": "projectile", "range": 420, "min_range": 120, "max_dy": 180,
             "telegraph": 1.00, "active": 0.15, "recovery": 0.60, "cooldown": 4.0, "weight": 1, "damage": 2,
             "poise": 50, "speed": 700, "projectile_anim": "arrow_charged", "anim_telegraph": "aim",
             "anim_strike": "release", "tell": "!"},
            {"name": "roll_away", "type": "reposition", "range": 70, "telegraph": 0.10, "active": 0.3,
             "recovery": 0.2, "cooldown": 2.2, "weight": 4, "distance": 128, "tint": False,
             "anim_telegraph": "alert", "anim_strike": "roll"},
        ],
    },
    "acoustic_hunter": {
        "_doc": "Blind tracker with acute hearing. Crawls toward sounds, answers with an arrow volley.",
        "class": "AcousticHunter", "profile": "enemy_hunter", "radius": 8, "height": 28,
        "weight_class": "medium", "health": 4, "poise": 50, "bar_y": -42, "keep_distance": 150,
        "locomotion": loco(run_speed=140.0, sneak_speed=70.0),
        "jump": {"can_jump": True, "jump_height": 84.0, "cooldown": 0.4, "max_gap": 96.0},
        "dash": {"speed": 360.0, "time": 0.2, "cooldown": 1.6, "telegraph": 0.4},
        "nav": {"stuck_time": 1.5, "launch_distance": 40.0, "home_teleport": True},
        "anim_map": {"idle": ["crouch_idle"], "walk": ["crawl"], "attack": ["release"], "telegraph": ["aim"]},
        "attacks": [
            {"name": "volley", "type": "projectile", "range": 340, "min_range": 50, "max_dy": 160,
             "telegraph": 0.70, "active": 0.15, "recovery": 0.70, "cooldown": 2.2, "weight": 2, "count": 3,
             "spread": 22, "damage": 1, "poise": 20, "speed": 440, "projectile_anim": "arrow",
             "anim_telegraph": "aim", "anim_strike": "release", "tell": "!"},
            {"name": "snap_shot", "type": "projectile", "range": 300, "min_range": 50, "max_dy": 160,
             "telegraph": 0.45, "active": 0.15, "recovery": 0.40, "cooldown": 1.1, "weight": 3, "damage": 1,
             "poise": 20, "speed": 500, "projectile_anim": "arrow", "anim_telegraph": "aim", "anim_strike": "release"},
            {"name": "pounce", "type": "dash", "range": 56, "telegraph": 0.40, "active": 0.2, "recovery": 0.5,
             "cooldown": 2.0, "weight": 2, "damage": 1, "poise": 25, "knockback": 200, "contact": 24,
             "anim_telegraph": "alert", "anim_strike": "run"},
        ],
    },
}

SCENE_TEMPLATE = """[gd_scene format=3]

[ext_resource type="PackedScene" path="res://scenes/enemies/enemy_base.tscn" id="1_eb"]
[ext_resource type="Resource" path="res://resources/enemies/{profile}.tres" id="2_prof"]
[ext_resource type="Script" path="res://scenes/enemies/visuals/manifest_visual.gd" id="3_mv"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_patrol.gd" id="4_pat"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_investigate.gd" id="5_inv"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_search.gd" id="6_src"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_chase.gd" id="7_chs"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_villain_attack.gd" id="8_atk"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_return.gd" id="9_ret"]
[ext_resource type="Script" path="res://scenes/enemies/states/st_stunned.gd" id="10_stn"]
[ext_resource type="Script" path="res://scripts/fighter/fighter.gd" id="11_ftr"]
[ext_resource type="Script" path="res://scenes/enemies/villain_hitbox.gd" id="12_vhb"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_body"]
radius = {radius}.0
height = {height}.0

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_hurt"]
radius = {hurt_radius}.0
height = {hurt_height}.0

[node name="{cls}" instance=ExtResource("1_eb")]
profile = ExtResource("2_prof")
kind = &"{kind}"

[node name="CollisionShape2D" parent="." index="0"]
shape = SubResource("CapsuleShape2D_body")

[node name="Visual" type="Node2D" parent="." index="2"]
script = ExtResource("3_mv")

[node name="Hitbox" parent="." index="6"]
script = ExtResource("12_vhb")

[node name="StateMachine" parent="." index="7" node_paths=PackedStringArray("initial")]
initial = NodePath("Patrol")

[node name="Patrol" type="Node" parent="StateMachine" index="0"]
script = ExtResource("4_pat")

[node name="Investigate" type="Node" parent="StateMachine" index="1"]
script = ExtResource("5_inv")

[node name="Search" type="Node" parent="StateMachine" index="2"]
script = ExtResource("6_src")

[node name="Chase" type="Node" parent="StateMachine" index="3"]
script = ExtResource("7_chs")

[node name="Attack" type="Node" parent="StateMachine" index="4"]
script = ExtResource("8_atk")

[node name="Return" type="Node" parent="StateMachine" index="5"]
script = ExtResource("9_ret")

[node name="Stagger" type="Node" parent="StateMachine" index="6"]
script = ExtResource("10_stn")

[node name="CollisionShape2D" parent="HurtboxComponent" index="0"]
shape = SubResource("CapsuleShape2D_hurt")

[node name="Fighter" type="Node" parent="."]
script = ExtResource("11_ftr")
"""

SCENE_KEYS = ("class", "profile", "radius", "height")


def main() -> None:
    for kind, spec in VILLAINS.items():
        data = {"manifest": kind}
        data.update({k: v for k, v in spec.items() if k not in SCENE_KEYS})
        with open(os.path.join(ROOT, "data", "enemies", kind + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, indent=1, ensure_ascii=False)
            f.write("\n")
        scene = SCENE_TEMPLATE.format(
            profile=spec["profile"], cls=spec["class"], kind=kind,
            radius=spec["radius"], height=spec["height"],
            hurt_radius=spec["radius"] + 1, hurt_height=spec["height"] + 2)
        with open(os.path.join(ROOT, "scenes", "enemies", kind + ".tscn"), "w", encoding="utf-8", newline="\n") as f:
            f.write(scene)
        print("wrote", kind)


if __name__ == "__main__":
    main()
