import os

OUT = 'rooms'
os.makedirs(OUT, exist_ok=True)

rooms = [
    ('Room_01_Hub.tscn', 'room_01_hub', 'res://levels/rooms/room_01_hub.txt'),
    ('Room_02_Corridor.tscn', 'room_02_corridor', 'res://levels/rooms/room_02_corridor.txt'),
    ('Room_03_Shaft.tscn', 'room_03_shaft', 'res://levels/rooms/room_03_shaft.txt'),
    ('Room_04_Catwalks.tscn', 'room_04_catwalks', 'res://levels/rooms/room_04_catwalks.txt'),
    ('Room_05_EnemyPit.tscn', 'room_05_enemy_pit', 'res://levels/rooms/room_05_enemy_pit.txt'),
    ('Room_06_Arena.tscn', 'room_06_arena', 'res://levels/rooms/room_06_arena.txt'),
]

for fname, rid, txt in rooms:
    content = f"""[gd_scene load_steps=3 format=3 uid="uid://room_{rid}"]

[ext_resource type="PackedScene" path="res://scenes/level/level_root.tscn" id="1_lr"]
[ext_resource type="Script" path="res://scripts/level/playground_room.gd" id="2_pr"]

[node name="{fname[:-5]}" instance=ExtResource("1_lr")]
script = ExtResource("2_pr")
level_path = "{txt}"
room_id = "{rid}"
"""
    p = os.path.join(OUT, fname)
    with open(p, 'w') as f:
        f.write(content)
    print("Created " + p)
