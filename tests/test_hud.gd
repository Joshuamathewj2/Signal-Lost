class_name TestHUD
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	if hud_scene == null:
		failures.append("HUD scene failed to load")
		return failures

	var hud: HUD = hud_scene.instantiate() as HUD
	if hud == null:
		failures.append("HUD failed to instantiate")
		return failures

	# 1. SafeArea & Root
	var root: Control = hud.get_node_or_null("Root") as Control
	if root == null:
		failures.append("Root missing from HUD")
	var safe_area: MarginContainer = hud.get_node_or_null("Root/SafeArea") as MarginContainer
	if safe_area == null:
		failures.append("SafeArea missing from HUD")

	# 2. FragmentCounter
	var frag_counter: FragmentCounter = hud.get_node_or_null("Root/SafeArea/TopLeft") as FragmentCounter
	if frag_counter == null:
		failures.append("FragmentCounter missing")
	else:
		frag_counter.set_count(3, false)
		if frag_counter.frag_count.text != "3":
			failures.append("FragmentCounter text expected '3', got '%s'" % frag_counter.frag_count.text)

	# 3. PipRow
	var pips: PipRow = hud.get_node_or_null("Root/SafeArea/BottomLeft/Pips") as PipRow
	if pips == null:
		failures.append("PipRow missing")
	else:
		pips.set_pips(2, 3)
		if pips.current_pips != 2:
			failures.append("PipRow expected current_pips 2, got %d" % pips.current_pips)

	# 4. AbilitySlots
	var primary_slot: AbilitySlot = hud.get_node_or_null("Root/SafeArea/BottomLeft/AbilityRow/PrimarySlot") as AbilitySlot
	if primary_slot == null or primary_slot.ability_name != "decoy":
		failures.append("PrimarySlot missing or wrong ability_name")

	var secondary_slot: AbilitySlot = hud.get_node_or_null("Root/SafeArea/BottomLeft/AbilityRow/SecondarySlot") as AbilitySlot
	if secondary_slot == null or not secondary_slot.is_locked:
		failures.append("SecondarySlot missing or not locked")

	# 5. LevelLabel & Progress
	var level_label: LevelLabel = hud.get_node_or_null("Root/SafeArea/BottomCentre") as LevelLabel
	if level_label == null:
		failures.append("LevelLabel missing")
	else:
		level_label.set_level_name("Test Chamber")
		if level_label.level_name_label.text != "Test Chamber":
			failures.append("LevelLabel title mismatch")
		level_label.set_progress(0.5, true)
		if not is_equal_approx(level_label.displayed_progress, 0.5):
			failures.append("LevelLabel progress mismatch")

	# 6. UiButton
	var btn := UiButton.new()
	if btn == null:
		failures.append("UiButton failed to instantiate")
	btn.free()

	hud.free()
	return failures
