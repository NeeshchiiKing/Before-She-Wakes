extends MenuPage
## Character tab: name, level, Resources (spend points here), currency, equipment

func _build() -> void:
	var info := _new_column()
	_add_label(info, player.character_name)

	var levels := player.level_data
	_add_label(info, "Level %d   XP %d / %d" % [levels.level, levels.experience, levels.experience_to_next_level()])
	_add_label(info, "Resource points: %d" % player.stats.unspent_points)

	for resource in Stats.NAMES:
		var current : int = player.stats.get(resource)
		var maximum : int = player.stats.get("max_" + resource)
		var text := "%s  %d / %d  %s" % [resource.capitalize(), current, maximum, player.stats.status_name(resource)]
		_add_raise_row(info, text, player.stats.can_raise(resource), player.stats.raise.bind(resource))

	_add_label(info, "")
	_add_label(info, "Currency")
	for currency in Wallet.NAMES:
		_add_label(info, "%s: %d" % [String(currency).capitalize(), player.wallet.amount_of(currency)])

	var gear := _new_scroll_column()
	_add_label(gear, "Equipment")
	for slot in Equipment.SLOT_ORDER:
		var item := player.equipment.get_item(slot)
		var row := HBoxContainer.new()
		gear.add_child(row)
		var texture : Texture2D = null
		if item != null:
			texture = item.icon
		row.add_child(_make_icon(texture))

		var label := Label.new()
		label.text = "%s: %s" % [slot.capitalize(), item.display_name if item != null else "(empty)"]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		if item != null and slot != "bag":
			var button := Button.new()
			button.text = "Off"
			button.pressed.connect(_on_unequip_pressed.bind(slot))
			row.add_child(button)

func _on_unequip_pressed(slot: String) -> void:
	player.unequip_to_inventory(slot)
	refresh.call_deferred(player)
