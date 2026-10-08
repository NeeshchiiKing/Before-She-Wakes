extends MenuPage
## Orb Grid tab: place orbs on nodes next to active ones. Placement is permanent.

const CELL_SIZE : Vector2 = Vector2(34, 16)
const ACTIVE_COLOR : Color = Color(1.0, 0.85, 0.3)

var _hover_label : Label = null

func _build() -> void:
	var grid : OrbGrid = player.orb_grid
	var left := _new_column()
	if grid == null:
		_add_label(left, "No Orb Grid set on the Player")
		return

	var grid_size := grid.get_size()
	var cells := GridContainer.new()
	cells.columns = grid_size.x
	cells.add_theme_constant_override(&"h_separation", 2)
	cells.add_theme_constant_override(&"v_separation", 2)
	left.add_child(cells)
	for y in grid_size.y:
		for x in grid_size.x:
			cells.add_child(_make_cell(grid, Vector2i(x, y)))

	var info := _new_column()
	_add_label(info, "Orbs: %d" % grid.orbs)
	_add_label(info, "Active nodes: %d / %d" % [grid.active.size(), grid.nodes.size()])
	_add_label(info, "")
	_add_label(info, "Gold = active")
	_add_label(info, "Bright = can place an orb")
	_add_label(info, "Gray = not reachable yet")
	_add_label(info, "")
	_hover_label = _add_label(info, "Hover a node to see its bonus")

func _make_cell(grid: OrbGrid, cell: Vector2i) -> Control:
	var node := grid.node_at(cell)
	if node == null:
		var spacer := Control.new()
		spacer.custom_minimum_size = CELL_SIZE
		return spacer

	var button := Button.new()
	button.custom_minimum_size = CELL_SIZE
	button.text = "core" if node.is_start else node.key + ("%" if node.is_percent else "+") + str(node.amount)
	button.mouse_entered.connect(_show_info.bind(grid.describe(node)))

	if grid.is_active(cell):
		button.modulate = ACTIVE_COLOR
	elif grid.can_activate(cell):
		button.pressed.connect(_on_cell_pressed.bind(cell))
	else:
		button.disabled = true
	return button

func _show_info(text: String) -> void:
	if _hover_label:
		_hover_label.text = text

func _on_cell_pressed(cell: Vector2i) -> void:
	player.orb_grid.activate(cell, player.stats)
	refresh.call_deferred(player)
