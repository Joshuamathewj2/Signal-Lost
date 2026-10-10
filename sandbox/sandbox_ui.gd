extends Node2D

@onready var hud: HUD = $HUD
@onready var info_label: Label = $CanvasLayer/InfoLabel

var mock_battery: Battery = null
var mock_charger: PulseCharger = null

var current_energy: float = 100.0
var max_energy: float = 100.0
var current_pips: int = 3
var test_frag_id: int = 1
var progress_step: float = 0.0

func _ready() -> void:
	mock_battery = Battery.new()
	mock_battery.max_energy = 100.0
	mock_battery.energy = 100.0
	add_child(mock_battery)

	mock_charger = PulseCharger.new()
	add_child(mock_charger)

	if hud != null and hud.battery_bar != null:
		hud.battery_bar.setup(mock_battery, mock_charger)

	if hud != null and hud.level_label != null:
		hud.level_label.set_level_name("Sandbox Level 1")
		hud.level_label.set_progress(0.25, true)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_ev: InputEventKey = event as InputEventKey
	if not key_ev.pressed or key_ev.echo:
		return

	match key_ev.keycode:
		KEY_1:
			# Drain energy
			current_energy = maxf(0.0, current_energy - 20.0)
			mock_battery.energy = current_energy
			mock_battery.energy_changed.emit(current_energy, max_energy)
		KEY_2:
			# Restore energy
			current_energy = minf(max_energy, current_energy + 20.0)
			mock_battery.energy = current_energy
			mock_battery.energy_changed.emit(current_energy, max_energy)
		KEY_3:
			# Mock charge & release
			mock_charger.charge_started.emit()
			mock_charger.charge_changed.emit(1, 0.5, 1)
			get_tree().create_timer(0.25).timeout.connect(func() -> void:
				current_energy = maxf(0.0, current_energy - 35.0)
				mock_battery.energy = current_energy
				mock_battery.energy_changed.emit(current_energy, max_energy)
				var prof: PulseProfile = GameConfig.pulse_for_tier(1)
				mock_charger.pulse_released.emit(prof, Vector2.ZERO)
			)
		KEY_4:
			# Add fragment
			GameState.collect_fragment(test_frag_id)
			test_frag_id += 1
		KEY_5:
			# Cycle decoy pips
			current_pips = (current_pips + 1) % 4
			if hud != null and hud.pip_row != null:
				hud.pip_row.set_pips(current_pips, 3)
		KEY_6:
			# Cycle progress
			progress_step = fmod(progress_step + 0.25, 1.25)
			if hud != null and hud.level_label != null:
				hud.level_label.set_progress(progress_step)
		KEY_F1:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		KEY_F2:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		KEY_F3:
			DisplayServer.window_set_size(Vector2i(2560, 1080))
