extends MenuPage
## Orb Grid tab: the drawn tree on the left, the picked node on the right.
## Click (or press accept on) a bright node to fill it with an Orb or Core.
## Pick a perk socket to see the perk orbs that fit it. Placement is permanent.

const INFO_WIDTH : float = 150.0

## Kept across refreshes so the cursor and scroll stay where the player left them
var _selected : Vector2i = Vector2i(-1, -1)
var _scroll : Vector2i = Vector2i.ZERO
var _has_scroll : bool = false

var _view : OrbGridView = null
var _scroll_box : ScrollContainer = null
var _info : VBoxContainer = null

func _build() -> void:
	var grid : OrbGrid = player.orb_grid
	if grid == null:
		_add_label(_new_column(), "No Orb Grid set on the Player")
		return
	if grid.node_at(_selected) == null:
		_selected = grid.core_cell()

	_scroll_box = ScrollContainer.new()
	_scroll_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll_box)

	# Centres the tree when the tab is bigger than the grid
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_box.add_child(center)

	_view = OrbGridView.new()
	center.add_child(_view)
	_view.setup(grid, player.attributes, _selected)
	_view.node_selected.connect(_on_node_selected)
	_view.node_pressed.connect(_on_node_pressed)

	_info = VBoxContainer.new()
	_info.custom_minimum_size.x = INFO_WIDTH
	add_child(_info)
	_fill_info()
	_restore_scroll()

## Waits one frame so the ScrollContainer knows its size before scrolling
func _restore_scroll() -> void:
	await get_tree().process_frame
	# The menu refreshes every tab when it opens; only scroll the one the player can see
	if not is_instance_valid(_view) or not _view.is_visible_in_tree():
		return
	if _has_scroll:
		_scroll_box.scroll_horizontal = _scroll.x
		_scroll_box.scroll_vertical = _scroll.y
	else:
		_view.center_on(_selected)
		_has_scroll = true
	_view.grab_focus()

func _remember_scroll() -> void:
	if is_instance_valid(_scroll_box):
		_scroll = Vector2i(_scroll_box.scroll_horizontal, _scroll_box.scroll_vertical)

# --- Info column ---

func _fill_info() -> void:
	for child in _info.get_children():
		_info.remove_child(child)
		child.queue_free()
	var grid : OrbGrid = player.orb_grid
	_add_label(_info, "Orbs %d   Cores %d   Perk orbs %d" % [grid.orbs, grid.cores, grid.held_perks.size()])
	_add_label(_info, "")

	var node := grid.node_at(_selected)
	if node == null:
		return
	_add_label(_info, grid.title(node))
	_add_wrapped(grid.describe(node))
	_add_label(_info, _state_text(grid, node))

	if node.kind == OrbGrid.Kind.SOCKET:
		_add_perk_choices(grid, node)
	elif grid.can_activate(_selected, player.attributes):
		var button := Button.new()
		button.text = "Place Core" if node.kind == OrbGrid.Kind.KEYSTONE else "Place Orb"
		button.pressed.connect(_on_node_pressed.bind(_selected))
		_info.add_child(button)

	_add_label(_info, "")
	_add_wrapped("Arrows or mouse to pick. Click or accept to fill.")

func _state_text(grid: OrbGrid, node: OrbGrid.OrbNode) -> String:
	match node.kind:
		OrbGrid.Kind.CORE:
			return "Active"
		OrbGrid.Kind.SEAL:
			return "Open" if grid.is_seal_open(node, player.attributes) else "Sealed"
	if grid.is_active(node.cell):
		return "Filled"
	if not grid.is_reachable(node.cell, player.attributes):
		return "Not reachable yet"
	if node.kind == OrbGrid.Kind.SOCKET:
		return "Ready for a perk orb"
	if node.kind == OrbGrid.Kind.KEYSTONE:
		return "Needs a Core" if grid.cores <= 0 else "Can place a Core"
	return "Needs an Orb" if grid.orbs <= 0 else "Can place an Orb"

func _add_perk_choices(grid: OrbGrid, node: OrbGrid.OrbNode) -> void:
	var perk : PerkDefinition = grid.installed.get(node.cell)
	if perk != null:
		if perk.source_detail != "":
			_add_wrapped("From: " + perk.source_detail)
		return
	if not grid.is_reachable(node.cell, player.attributes):
		return
	var choices := grid.perks_that_fit(node.cell)
	if choices.is_empty():
		_add_wrapped("No perk orb you hold fits here")
		return
	for choice in choices:
		var button := Button.new()
		button.text = "Install " + choice.display_name
		button.icon = choice.icon
		button.add_theme_constant_override(&"icon_max_width", 12)
		button.tooltip_text = choice.description
		button.pressed.connect(_on_install_pressed.bind(choice))
		_info.add_child(button)

func _add_wrapped(text: String) -> Label:
	var label := _add_label(_info, text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = INFO_WIDTH
	return label

# --- Actions ---

func _on_node_selected(cell: Vector2i) -> void:
	_selected = cell
	_fill_info()

func _on_node_pressed(cell: Vector2i) -> void:
	_selected = cell
	var grid : OrbGrid = player.orb_grid
	var node := grid.node_at(cell)
	if node != null and node.kind != OrbGrid.Kind.SOCKET and grid.can_activate(cell, player.attributes):
		grid.activate(cell, player.stats, player.attributes)
		_remember_scroll()
		refresh.call_deferred(player) # deferred: don't delete the view mid-click
		return
	_fill_info.call_deferred()

func _on_install_pressed(perk: PerkDefinition) -> void:
	if player.orb_grid.install_perk(_selected, perk, player.attributes):
		_remember_scroll()
		refresh.call_deferred(player)
