"""One-off generator for the Step 0D playground rooms (ASCII, existing legend).
Hero limits used: rise <= 2 tiles per jump, gap <= 3 tiles."""
import os

OUT = 'levels/rooms'
os.makedirs(OUT, exist_ok=True)


class Room:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [['.'] * w for _ in range(h)]
        for x in range(w):
            self.g[0][x] = '#'
            self.g[h - 1][x] = '#'
        for y in range(h):
            self.g[y][0] = '#'
            self.g[y][w - 1] = '#'

    def fill(self, x0, y0, x1, y1, ch='#'):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = ch

    def plat(self, x0, x1, y):  # one-way platform row y (stand row y-1)
        self.fill(x0, y, x1, y, '=')

    def put(self, x, y, ch):
        self.g[y][x] = ch

    def write(self, name, headers):
        lines = [';%s=%s' % (k, v) for k, v in headers] + [''.join(r) for r in self.g]
        open(os.path.join(OUT, name), 'w').write('\n'.join(lines) + '\n')
        print(name)
        print('\n'.join(lines[len(headers):]))
        print()


# R01 HUB 40x20: ground hub, zig-zag catwalks up to an east ledge (door to the shaft)
r = Room(40, 20)
r.fill(1, 18, 38, 18)                      # floor, stand row 17
r.plat(8, 13, 16)                          # stand 15
r.plat(15, 20, 14)                         # stand 13
r.plat(22, 27, 12)                         # stand 11
r.plat(29, 32, 10)                         # stand 9
r.fill(33, 10, 38, 11)                     # east ledge, stand 9 (ground passes under)
r.plat(2, 6, 14)                           # west lookout, stand 13 (from the stand-15 catwalk)
r.fill(39, 16, 39, 17, '.')                # East lower door to Corridor
r.fill(39, 8, 39, 9, '.')                  # East upper door to Shaft
r.put(10, 1, '~'); r.put(24, 1, '~'); r.put(35, 1, '~')
r.put(6, 17, 'P')
r.write('room_01_hub.txt', [('name', 'R01 Hub'), ('room', 'R01'), ('seed', '101'), ('music', 'calm')])

# R02 LONG CORRIDOR 48x16: pits (3 wide, 2 deep), a raised mid section
r = Room(48, 16)
r.fill(1, 12, 46, 14)                      # floor, stand row 11
r.fill(11, 12, 13, 13, '.')                # pit 1 (3 wide, 2 deep, floor row 14)
r.fill(32, 12, 34, 13, '.')                # pit 2
r.fill(20, 10, 26, 11)                     # raised block, stand 9
r.fill(38, 7, 41, 7)                       # low ceiling beam (crouch-height feel)
r.fill(0, 10, 0, 11, '.')                  # West door to Hub
r.fill(47, 10, 47, 11, '.')                # East door to Catwalks
r.put(14, 1, '~'); r.put(30, 1, '~'); r.put(42, 1, '~')
r.put(4, 11, 'P')
r.write('room_02_corridor.txt', [('name', 'R02 Long Corridor'), ('room', 'R02'), ('seed', '202'), ('music', 'tense')])

# R03 VERTICAL SHAFT 24x32: alternating one-ways up to a top ledge
r = Room(24, 32)
r.fill(1, 30, 22, 30)                      # floor, stand row 29
y = 28
left = True
while y >= 6:
    if left:
        r.plat(3, 11, y)
    else:
        r.plat(12, 20, y)
    left = not left
    y -= 2
r.fill(14, 4, 22, 4)                       # top ledge, stand row 3
r.fill(0, 28, 0, 29, '.')                  # West door to Hub
r.fill(23, 2, 23, 3, '.')                  # East door to Arena
r.put(6, 1, '~'); r.put(18, 1, '~')
r.put(4, 29, 'P')
r.write('room_03_shaft.txt', [('name', 'R03 Vertical Shaft'), ('room', 'R03'), ('seed', '303'), ('music', 'tense')])

# R04 CATWALKS 44x22: upper catwalks over a pit floor; one-way ladder back up on the left
r = Room(44, 22)
r.fill(1, 20, 42, 20)                      # pit floor, stand 19
r.fill(1, 8, 6, 9)                         # west entry ledge, stand 7
r.plat(9, 14, 8)                           # stand 7 (gap 2 from ledge)
r.plat(17, 22, 10)                         # stand 9 (gap 2, drop 2)
r.plat(25, 30, 8)                          # stand 7 (gap 2, rise 2)
r.plat(33, 36, 8)                          # stand 7 (gap 2)
r.fill(38, 8, 42, 9)                       # east ledge, stand 7
for i, yy in enumerate([18, 16, 14, 12, 10]):   # ladder back up from the pit floor (west side)
    r.plat(7 if i % 2 == 0 else 2, 10 if i % 2 == 0 else 5, yy)   # top step x7..10 -> ledge
r.fill(0, 6, 0, 7, '.')                    # West door to Corridor
r.fill(43, 6, 43, 7, '.')                  # East door to Enemy Pit
r.put(12, 1, '~'); r.put(28, 1, '~')
r.put(4, 7, 'P')
r.write('room_04_catwalks.txt', [('name', 'R04 Catwalks'), ('room', 'R04'), ('seed', '404'), ('music', 'tense')])

# R05 ENEMY PIT 40x18: test fighters, a pit and a 2-tile ledge, one-way overhead
r = Room(40, 18)
r.fill(1, 16, 38, 16)                      # floor, stand 15
r.fill(14, 16, 15, 16, '.')                # pit cols 14-15 (1 deep into border row: floor row 17)
r.fill(26, 14, 38, 15)                     # east ledge, stand 13
r.plat(17, 23, 12)                         # one-way overhead, stand 11
r.fill(0, 14, 0, 15, '.')                  # West door to Catwalks
r.fill(39, 12, 39, 13, '.')                # East door to Arena
r.put(9, 1, '~'); r.put(30, 1, '~')
r.put(4, 15, 'P')
# Chapter II: villains come from data/level.json "enemies" (no T marker)
r.write('room_05_enemy_pit.txt', [('name', 'R05 Enemy Pit'), ('room', 'R05'), ('seed', '505'), ('music', 'tense')])

# R06 ARENA 48x22: boss arena / gauntlet: big floor, central dais, floating one-ways
r = Room(48, 22)
r.fill(1, 20, 46, 20)                      # arena floor, stand 19
r.fill(1, 8, 6, 9)                         # west upper ledge (from the shaft), stand 7
for i, yy in enumerate([18, 16, 14, 12, 10]):   # west steps: floor <-> upper ledge
    r.plat(8 if i % 2 == 0 else 12, 11 if i % 2 == 0 else 15, yy)
r.fill(20, 18, 27, 19)                     # central dais, stand 17
r.plat(30, 34, 16)                         # floating platform, stand 15 (dais +2)
r.plat(36, 40, 14)                         # floating platform, stand 13 (+2)
r.fill(0, 6, 0, 7, '.')                    # Upper West door to Shaft
r.fill(0, 18, 0, 19, '.')                  # Lower West door to Enemy Pit
r.put(12, 1, '~'); r.put(24, 1, '~'); r.put(36, 1, '~')
r.put(4, 19, 'P')
# Chapter II: the Leviathan spawns from data/level.json
# No exit terminal: defeating the boss ends the chapter
r.write('room_06_arena.txt', [('name', 'R06 Arena'), ('room', 'R06'), ('seed', '606'), ('music', 'tense')])
