class_name CombatStats extends RefCounted
## The 16 hidden combat stats. Calculated from Attributes + gear + orb grid, never stored.

## Each stat -> the Attribute that raises it. Order here is the display order.
const SOURCES : Dictionary = {
	&"defense": &"fortitude",
	&"poise": &"stamina",
	&"magic_power": &"wisdom",
	&"magic_precision": &"wisdom",
	&"magic_defense": &"willpower",
	&"status_resistance": &"willpower",
	&"evasion": &"guile",
	&"status_application": &"guile",
	&"crit_chance": &"perception",
	&"range_precision": &"perception",
	&"attack_power": &"power",
	&"crit_damage": &"power",
	&"move_speed": &"endurance",
	&"dodge_recovery": &"reflexes",
	&"attack_speed": &"agility",
	&"melee_precision": &"agility",
}

## Placeholder: each Attribute point adds 1. Real per-stat formulas come later.
const PER_POINT : int = 1

static func from_attributes(attributes: Attributes, stat: StringName) -> int:
	return attributes.get(SOURCES[stat]) * PER_POINT

static func from_gear(equipment: Equipment, stat: StringName) -> int:
	if equipment == null:
		return 0
	return equipment.total_bonus(stat)

static func from_grid(grid: OrbGrid, stat: StringName) -> int:
	if grid == null:
		return 0
	var key = OrbGrid.STAT_KEYS.find_key(stat)
	if key == null:
		return 0
	return grid.flat_bonus(key)

static func grid_percent(grid: OrbGrid, stat: StringName) -> int:
	if grid == null:
		return 0
	var key = OrbGrid.STAT_KEYS.find_key(stat)
	if key == null:
		return 0
	return grid.percent_bonus(key)

static func total(attributes: Attributes, grid: OrbGrid, equipment: Equipment, stat: StringName) -> int:
	var flat := from_attributes(attributes, stat) + from_gear(equipment, stat) + from_grid(grid, stat)
	return roundi(flat * (1.0 + grid_percent(grid, stat) / 100.0))
