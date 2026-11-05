class_name OrbGridView extends Control
## Draws the Orb Grid as a tree: lines between linked nodes, a shape for each kind of node.
## Mouse hover or the arrow keys pick a node; click or ui_accept presses it.
## Put it inside a ScrollContainer (directly, or inside a CenterContainer in one) so a big grid can scroll.

signal node_selected(cell: Vector2i)
signal node_pressed(cell: Vector2i)

const SPACING : float = 12.0 ## Pixels between node centres
const MARGIN : float = 8.0
const BRANCH_COLORS : Dictionary = {
	"mig": Color("e08a4f"), "sur": Color("7cc29a"), "arc": Color("9d96e8"),
	"tri": Color("e3809a"), "con": Color("5db8d0"), "": Color("c9c1a8"),
}
const LIT_COLOR : Color = Color(1.0, 0.85, 0.3)
const LINK_COLOR : Color = Color(0.25, 0.31, 0.28)
const SEAL_COLOR : Color = Color(0.89, 0.44, 0.36)
const EMPTY_FILL : Color = Color(0.06, 0.09, 0.08)
const CURSOR_COLOR : Color = Color.WHITE
const FADED : float = 0.35 ## How bright unreachable nodes are

var grid : OrbGrid
var attributes : Attributes
var selected : Vector2i = Vector2i.ZERO
var _lit : Dictionary = {}

func setup(new_grid: OrbGrid, new_attributes: Attributes, start_cell: Vector2i) -> void:
	grid = new_grid
	attributes = new_attributes
	selected = start_cell
	_lit = grid.lit_cells(attributes)
	custom_minimum_size = Vector2(grid.get_size()) * SPACING + Vector2(MARGIN, MARGIN) * 2.0
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(MARGIN, MARGIN) + (Vector2(cell) + Vector2(0.5, 0.5)) * SPACING

## The ScrollContainer this view sits in, if any
func _scroll_box() -> ScrollContainer:
	var parent := get_parent()
	while parent != null and not parent is ScrollContainer:
		parent = parent.get_parent()
	return parent as ScrollContainer

## Where a cell is inside the scrolled content (adds any offset from a CenterContainer)
func _content_point(cell: Vector2i) -> Vector2:
	var scroll := _scroll_box()
	var offset := Vector2.ZERO
	var node : Node = self
	while node != scroll and node is Control:
		offset += (node as Control).position
		node = node.get_parent()
	return offset + cell_center(cell)

## Scrolls the parent ScrollContainer so this cell sits in the middle
func center_on(cell: Vector2i) -> void:
	var scroll := _scroll_box()
	if scroll == null:
		return
	var point := _content_point(cell)
	scroll.scroll_horizontal = int(point.x - scroll.size.x * 0.5)
	scroll.scroll_vertical = int(point.y - scroll.size.y * 0.5)

# --- Drawing ---

func _draw() -> void:
	if grid == null:
		return
	# Links first, so nodes sit on top of them. Right and down only, so each link is drawn once.
	for cell in grid.nodes:
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var other : Vector2i = cell + direction
			if grid.nodes.has(other):
				_draw_link(cell, other)
	for cell in grid.nodes:
		_draw_node(grid.nodes[cell])
	if grid.nodes.has(selected):
		draw_arc(cell_center(selected), 6.5, 0.0, TAU, 16, CURSOR_COLOR, 1.0)

func _draw_link(a: Vector2i, b: Vector2i) -> void:
	var from := cell_center(a)
	var to := cell_center(b)
	if _is_closed_seal(a) or _is_closed_seal(b):
		draw_dashed_line(from, to, SEAL_COLOR.darkened(0.3), 1.0, 2.0)
	elif _lit.has(a) and _lit.has(b):
		draw_line(from, to, LIT_COLOR, 1.0)
	else:
		draw_line(from, to, LINK_COLOR, 1.0)

func _draw_node(node: OrbGrid.OrbNode) -> void:
	var center := cell_center(node.cell)
	var color : Color = BRANCH_COLORS.get(node.branch, BRANCH_COLORS[""])
	var is_lit := _lit.has(node.cell)
	var outline := color if is_lit or _is_reachable(node) else color.darkened(1.0 - FADED)
	match node.kind:
		OrbGrid.Kind.CORE:
			draw_circle(center, 5.0, LIT_COLOR)
		OrbGrid.Kind.STAT:
			_draw_orb(center, 3.5 if node.is_percent else 3.0, color, outline, is_lit)
		OrbGrid.Kind.KEYSTONE:
			_draw_orb(center, 4.5, color, outline, is_lit)
			draw_circle(center, 1.5, LIT_COLOR if is_lit else outline)
		OrbGrid.Kind.SOCKET:
			_draw_socket(node, center, color, outline, is_lit)
		OrbGrid.Kind.SEAL:
			_draw_seal(center, grid.is_seal_open(node, attributes))

func _draw_orb(center: Vector2, radius: float, color: Color, outline: Color, is_lit: bool) -> void:
	draw_circle(center, radius, color if is_lit else EMPTY_FILL)
	draw_circle(center, radius, LIT_COLOR if is_lit else outline, false, 1.0)

func _draw_socket(node: OrbGrid.OrbNode, center: Vector2, color: Color, outline: Color, is_lit: bool) -> void:
	var rect := Rect2(center - Vector2(4, 4), Vector2(8, 8))
	draw_rect(rect, color.darkened(0.5) if is_lit else EMPTY_FILL)
	var perk : PerkDefinition = grid.installed.get(node.cell)
	if perk != null and perk.icon != null:
		draw_texture_rect(perk.icon, rect, false)
	if node.socket_tier == OrbGrid.SocketTier.BRIDGE and not is_lit:
		_draw_dashed_rect(rect, outline)
	else:
		draw_rect(rect, LIT_COLOR if is_lit else outline, false, 1.0)

func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 1.0, 2.0)

func _draw_seal(center: Vector2, is_open: bool) -> void:
	var points := PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0), center + Vector2(0, 4), center + Vector2(-4, 0)])
	var color := LIT_COLOR if is_open else SEAL_COLOR
	draw_colored_polygon(points, EMPTY_FILL)
	points.append(points[0])
	draw_polyline(points, color, 1.0)
	if not is_open:
		draw_line(center + Vector2(-1.5, -1.5), center + Vector2(1.5, 1.5), color, 1.0)
		draw_line(center + Vector2(1.5, -1.5), center + Vector2(-1.5, 1.5), color, 1.0)

## Same rule as OrbGrid.is_reachable, but uses the lit set worked out once in setup()
func _is_reachable(node: OrbGrid.OrbNode) -> bool:
	if node.kind == OrbGrid.Kind.SEAL or node.kind == OrbGrid.Kind.CORE:
		return false
	for direction in OrbGrid.DIRECTIONS:
		if _lit.has(node.cell + direction):
			return true
	return false

func _is_closed_seal(cell: Vector2i) -> bool:
	var node : OrbGrid.OrbNode = grid.nodes[cell]
	return node.kind == OrbGrid.Kind.SEAL and not grid.is_seal_open(node, attributes)

# --- Input ---

func _gui_input(event: InputEvent) -> void:
	if grid == null:
		return
	if event is InputEventMouseMotion:
		var cell : Variant = _cell_at(event.position)
		if cell != null and cell != selected:
			_select(cell)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell : Variant = _cell_at(event.position)
		if cell != null:
			grab_focus()
			_select(cell)
			node_pressed.emit(cell)
			accept_event()
	elif event.is_action_pressed("ui_accept"):
		node_pressed.emit(selected)
		accept_event()
	else:
		for action in [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]:
			if event.is_action_pressed(action, true):
				_move_cursor(_action_direction(action))
				accept_event()
				return

## The node under a point, or null
func _cell_at(point: Vector2) -> Variant:
	var cell := Vector2i(((point - Vector2(MARGIN, MARGIN)) / SPACING).floor())
	if grid.nodes.has(cell):
		return cell
	return null

func _select(cell: Vector2i) -> void:
	selected = cell
	queue_redraw()
	node_selected.emit(cell)

func _action_direction(action: StringName) -> Vector2i:
	match action:
		&"ui_left":
			return Vector2i.LEFT
		&"ui_right":
			return Vector2i.RIGHT
		&"ui_up":
			return Vector2i.UP
	return Vector2i.DOWN

## Jumps to the closest node in that direction, preferring ones straight ahead over ones off to the side
func _move_cursor(direction: Vector2i) -> void:
	var best : Variant = null
	var best_score := INF
	for cell in grid.nodes:
		var delta : Vector2i = cell - selected
		var ahead := delta.x * direction.x + delta.y * direction.y
		if ahead <= 0:
			continue
		var side := absi(delta.x * direction.y) + absi(delta.y * direction.x)
		var score := ahead + side * 2.0
		if score < best_score:
			best_score = score
			best = cell
	if best != null:
		_select(best)
		_keep_visible(best)

func _keep_visible(cell: Vector2i) -> void:
	var scroll := _scroll_box()
	if scroll == null:
		return
	var point := _content_point(cell)
	var view := Rect2(Vector2(scroll.scroll_horizontal, scroll.scroll_vertical), scroll.size).grow(-SPACING * 2.0)
	if not view.has_point(point):
		center_on(cell)
