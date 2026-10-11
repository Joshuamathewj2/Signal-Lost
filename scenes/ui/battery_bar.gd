class_name BatteryBar
extends Control

var current_energy: float = 100.0
var max_energy: float = 100.0
var displayed_energy: float = 100.0
var drain_flash_energy: float = 100.0
var drain_flash_alpha: float = 0.0

var is_charging: bool = false
var affordable_tier: int = -1
var selected_tier: int = -1
var blink_time: float = 0.0

var drain_tween: Tween
var flash_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(180, 10)

func setup(battery: Battery, charger: PulseCharger) -> void:
	if battery != null:
		current_energy = battery.energy
		max_energy = battery.max_energy
		displayed_energy = current_energy
		if not battery.energy_changed.is_connected(_on_energy_changed):
			battery.energy_changed.connect(_on_energy_changed)

	if charger != null:
		if not charger.charge_started.is_connected(_on_charge_started):
			charger.charge_started.connect(_on_charge_started)
		if not charger.charge_changed.is_connected(_on_charge_changed):
			charger.charge_changed.connect(_on_charge_changed)
		if not charger.pulse_released.is_connected(_on_pulse_released):
			charger.pulse_released.connect(_on_pulse_released)
		if not charger.pulse_failed.is_connected(_on_pulse_failed):
			charger.pulse_failed.connect(_on_pulse_failed)

func _on_energy_changed(val: float, max_val: float) -> void:
	current_energy = val
	max_energy = max_val
	queue_redraw()

func _on_charge_started() -> void:
	is_charging = true
	queue_redraw()

func _on_charge_changed(tier: int, _c: float, affordable: int) -> void:
	selected_tier = tier
	affordable_tier = affordable
	queue_redraw()

func _on_pulse_released(_profile: PulseProfile, _origin: Vector2) -> void:
	is_charging = false
	drain_flash_energy = displayed_energy
	drain_flash_alpha = 1.0

	if drain_tween != null and drain_tween.is_valid():
		drain_tween.kill()
	drain_tween = create_tween()
	drain_tween.tween_property(self, "displayed_energy", current_energy, 0.12)

	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_property(self, "drain_flash_alpha", 0.0, 0.30)
	queue_redraw()

func _on_pulse_failed() -> void:
	is_charging = false
	queue_redraw()

func _process(delta: float) -> void:
	blink_time += delta
	if not is_charging and (flash_tween == null or not flash_tween.is_valid()):
		displayed_energy = current_energy
	queue_redraw()

func _draw() -> void:
	var white_c: Color = Palette.color(&"white")
	var red_c: Color = Palette.color(&"danger")

	var outline_color: Color = white_c
	if current_energy <= 0.001:
		outline_color = red_c if sin(blink_time * 2.0 * TAU) > 0.0 else white_c
	elif is_charging and affordable_tier == -1:
		outline_color = red_c if sin(blink_time * 6.0 * TAU) > 0.0 else white_c

	draw_rect(Rect2(0, 0, 180, 10), outline_color, false, 1.0)

	var inner_w: float = 176.0
	var fill_w: float = clampf(displayed_energy / max_energy, 0.0, 1.0) * inner_w
	if fill_w > 0.0:
		draw_rect(Rect2(2, 2, fill_w, 6), red_c, true)

	if drain_flash_alpha > 0.01:
		var old_w: float = clampf(drain_flash_energy / max_energy, 0.0, 1.0) * inner_w
		if old_w > fill_w:
			draw_rect(Rect2(2 + fill_w, 2, old_w - fill_w, 6), Color(1, 1, 1, drain_flash_alpha * 0.8), true)

	if is_charging:
		if affordable_tier != -1:
			var prof: PulseProfile = GameConfig.pulse_for_tier(affordable_tier)
			if prof != null:
				var cost_w: float = (prof.energy_cost / max_energy) * inner_w
				var ghost_x: float = maxf(2.0, 2.0 + fill_w - cost_w)
				var ghost_w: float = minf(cost_w, fill_w)
				draw_rect(Rect2(ghost_x, 2, ghost_w, 6), Color(1, 1, 1, 0.35), true)
		else:
			# Hatched lines for unaffordable pending cost
			var hatch_spacing: float = 6.0
			for x in range(int(2), int(2 + fill_w), int(hatch_spacing)):
				draw_line(Vector2(x, 8), Vector2(x + 4, 2), Color(1, 1, 1, 0.6), 1.0)
