extends MenuPage
## Tools or Spells tab. Owned abilities are always usable; upgrades happen at NPCs.

@export var book_property : StringName = &"tools" ## "tools" or "spells" on the Player
@export var empty_message : String = "Nothing found yet"
@export var allow_quick_slots : bool = false ## Turn on for the Spells tab only

func _build() -> void:
	var column := _new_scroll_column()
	if allow_quick_slots:
		_add_quick_slots(column)
		_add_label(column, "")

	var book : AbilityBook = player.get(book_property)
	if book == null or book.get_owned().is_empty():
		_add_label(column, empty_message)
		return

	for ability in book.get_owned():
		var tier := book.tier_of(ability)
		var title := "%s  (Tier %d / %d)" % [ability.name_at(tier), tier, ability.max_tier()]

		var row := HBoxContainer.new()
		column.add_child(row)
		row.add_child(_make_icon(ability.icon))
		if allow_quick_slots:
			_add_drag_label(row, title, ability)
		else:
			_add_label(row, title)

		_add_label(column, "    " + ability.description_at(tier))
		_add_label(column, "    " + _upgrade_text(book, ability, tier))
	
func _upgrade_text(book: AbilityBook, ability: AbilityDefinition, tier: int) -> String:
	if tier >= ability.max_tier():
		return "Fully upgraded"
	var next := tier + 1
	if book.can_upgrade(ability, player.attributes):
		return "Ready: an NPC can upgrade this to %s" % ability.name_at(next)
	var attribute := String(ability.upgrade_attribute).capitalize()
	return "Next: %s needs %s %d" % [ability.name_at(next), attribute, ability.requirement_for(next)]
