extends MenuPage
## Attributes tab: spend Attribute points, see the 16 combat stats they raise

func _build() -> void:
	var attrs := player.attributes

	var left := _new_column()
	_add_label(left, "Attribute points: %d" % attrs.unspent_points)
	for attribute in Attributes.NAMES:
		var level : int = attrs.get(attribute)
		var text := "%s  %d / %d" % [attribute.capitalize(), level, Attributes.MAX_ATTRIBUTE_LEVEL]
		_add_raise_row(left, text, attrs.can_raise(attribute), attrs.raise.bind(attribute))

	_add_label(left, "")
	_add_label(left, "Status Effects: None")
	_add_label(left, "Resistances: Coming soon")

	var right := _new_column()
	_add_label(right, "Combat Stats")
	for stat in CombatStats.SOURCES:
		var from_attr := CombatStats.from_attributes(attrs, stat)
		var from_gear := CombatStats.from_gear(player.equipment, stat)
		var from_grid := CombatStats.from_grid(player.orb_grid, stat)
		var total := CombatStats.total(attrs, player.orb_grid, player.equipment, stat)
		var source_short := String(CombatStats.SOURCES[stat]).capitalize().left(3)
		var text := "%s  %d  (%s +%d, Gear +%d, Grid +%d)" % [String(stat).capitalize(), total, source_short, from_attr, from_gear, from_grid]
		_add_label(right, text)
