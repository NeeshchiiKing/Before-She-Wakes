class_name MenuPage extends HBoxContainer
## Base for menu tabs. Each page clears and rebuilds itself when the menu opens.

var player : Player = null

func refresh(new_player: Player) -> void:
	player = new_player
	for child in get_children():
		remove_child(child) # remove first so old and new rows never overlap for a frame
		child.queue_free()
	if player:
		_build()

## Each page overrides this to add its contents
func _build() -> void:
	pass

func _new_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(column)
	return column
	
## A column that scrolls instead of stretching the menu
func _new_scroll_column() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column

func _add_label(column: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	column.add_child(label)
	return label

## A row with text and a + button. Pressing it calls on_raise, then rebuilds the page.
func _add_raise_row(column: Control, text: String, can_raise: bool, on_raise: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var button := Button.new()
	button.text = "+"
	button.disabled = not can_raise
	button.pressed.connect(_on_raise_pressed.bind(on_raise))
	row.add_child(button)
	column.add_child(row)

func _on_raise_pressed(on_raise: Callable) -> void:
	on_raise.call()
	refresh.call_deferred(player) # deferred: don't delete the button mid-click


func _add_drag_label(column: Control, text: String, payload: Resource) -> DragLabel:
	var label := DragLabel.new()
	label.text = text
	label.payload = payload
	column.add_child(label)
	return label

## The quick slot row, shown on the Spells and Inventory tabs
func _add_quick_slots(column: Control) -> void:
	var inventory := player.inventory
	_add_label(column, "Quick Slots (drag here, right-click to clear)")
	var row := HBoxContainer.new()
	column.add_child(row)
	for i in inventory.quick_slot_count:
		var slot := QuickSlotButton.new()
		slot.index = i
		slot.inventory = inventory
		slot.custom_minimum_size = Vector2(80, 16)
		slot.text = "%d: %s" % [i + 1, player.describe_quick(inventory.get_quick_slot(i))]
		slot.icon = player.quick_icon(inventory.get_quick_slot(i))
		slot.add_theme_constant_override(&"icon_max_width", 12)
		slot.slot_changed.connect(_on_slot_changed)
		row.add_child(slot)

func _on_slot_changed() -> void:
	refresh.call_deferred(player)

const ICON_SIZE : Vector2 = Vector2(16, 16)

## A small picture for a menu row. A null texture leaves an empty space so names stay lined up.
func _make_icon(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon
