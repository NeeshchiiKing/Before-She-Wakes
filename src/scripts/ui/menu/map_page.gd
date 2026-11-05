extends MenuPage
## Map tab: the 12x12 world. Squares you haven't visited stay blank (fog of war).
## Hover or click a visited square to see its name plus the monsters (areas) or NPCs (towns) in it.

const CELL_SIZE : Vector2 = Vector2(14, 14)
const UNKNOWN_COLOR : Color = Color(0.6, 0.6, 0.6)
const KIND_COLORS : Dictionary = {
	RegionDefinition.Kind.AREA: Color(0.45, 0.75, 0.4),
	RegionDefinition.Kind.TOWN: Color(0.95, 0.8, 0.3),
	RegionDefinition.Kind.BOSS: Color(0.85, 0.3, 0.3),
}

var _info : Label = null

func _build() -> void:
	var grid_column := _new_column()
	grid_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var grid := GridContainer.new()
	grid.columns = WorldMap.GRID_SIZE
	grid.add_theme_constant_override(&"h_separation", 1)
	grid.add_theme_constant_override(&"v_separation", 1)
	grid_column.add_child(grid)

	var info_column := _new_scroll_column()
	_info = _add_label(info_column, "")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.custom_minimum_size.x = 120

	for y in WorldMap.GRID_SIZE:
		for x in WorldMap.GRID_SIZE:
			grid.add_child(_make_cell(Vector2i(x, y)))

	_show_square(WorldMap.current_pos)

func _make_cell(pos: Vector2i) -> Control:
	if not WorldMap.is_discovered(pos):
		var blank := Control.new()
		blank.custom_minimum_size = CELL_SIZE
		return blank

	var region := WorldMap.get_region(pos)
	var cell := Button.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.focus_mode = Control.FOCUS_NONE
	cell.self_modulate = KIND_COLORS.get(region.kind, UNKNOWN_COLOR) if region else UNKNOWN_COLOR
	if pos == WorldMap.current_pos:
		cell.text = "@"
	cell.mouse_entered.connect(_show_square.bind(pos))
	cell.pressed.connect(_show_square.bind(pos))
	return cell

func _show_square(pos: Vector2i) -> void:
	if _info == null:
		return
	if pos == WorldMap.NO_SQUARE or not WorldMap.is_discovered(pos):
		_info.text = "Hover a square to see what is there."
		return

	var region := WorldMap.get_region(pos)
	var label := RegionDefinition.grid_label(pos)
	if region == null:
		_info.text = "%s\nUnexplored detail" % label
		return

	var lines : PackedStringArray = ["%s  %s" % [label, region.region_name]]
	if region.kind == RegionDefinition.Kind.TOWN:
		lines.append("Town")
		lines.append("")
		lines.append("NPCs:")
		for npc in region.npcs:
			lines.append("  %s" % npc)
		if region.npcs.is_empty():
			lines.append("  None known")
	else:
		lines.append("Boss area" if region.kind == RegionDefinition.Kind.BOSS else "Area")
		lines.append("")
		lines.append("Monsters:")
		for enemy in region.enemies:
			lines.append("  %s" % enemy.display_name)
		if region.enemies.is_empty():
			lines.append("  None known")
	_info.text = "\n".join(lines)
