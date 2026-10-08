extends MenuPage
## Inventory tab: quick slots, carried items (drag to a slot or Use), and unequipped gear (Equip).

func _build() -> void:
	var column := _new_scroll_column()
	var inventory := player.inventory
	if inventory == null:
		_add_label(column, "No Inventory set on the Player")
		return

	_add_quick_slots(column)
	_add_label(column, "")

	var items := inventory.get_items()
	_add_label(column, "%s  (%d / %d)" % [inventory.bag_name, items.size(), inventory.bag_capacity])
	if items.is_empty():
		_add_label(column, "No items")
	for item in items:
		var row := HBoxContainer.new()
		column.add_child(row)
		row.add_child(_make_icon(item.icon))
		var text := "%s x%d  (+%d %s, %d tier)" % [item.display_name, inventory.count_of(item), item.heal_amount, item.heals.capitalize(), item.tier_cost]
		var label := _add_drag_label(row, text, item)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var use := Button.new()
		use.text = "Use"
		use.disabled = player.stats.is_worst_status(item.heals)
		use.pressed.connect(_on_use_pressed.bind(item))
		row.add_child(use)

	_add_label(column, "")
	_add_label(column, "Gear")
	var gear := inventory.get_gear()
	if gear.is_empty():
		_add_label(column, "No spare gear")
	for piece in gear:
		var row := HBoxContainer.new()
		column.add_child(row)
		row.add_child(_make_icon(piece.icon))
		var text := "%s  (%s)  %s  %s" % [piece.display_name, piece.slot_type.capitalize(), piece.bonus_text(), piece.requirement_text()]
		var label := _add_label(row, text)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var equip := Button.new()
		equip.text = "Equip"
		equip.disabled = not piece.meets_requirement(player.attributes)
		equip.pressed.connect(_on_equip_pressed.bind(piece))
		row.add_child(equip)

func _on_use_pressed(item: ItemDefinition) -> void:
	player.use_item(item)
	refresh.call_deferred(player)

func _on_equip_pressed(piece: EquipmentDefinition) -> void:
	player.equip_from_inventory(piece)
	refresh.call_deferred(player)
