extends MenuPage
## Quests tab: active quests with progress, then completed ones.

func _build() -> void:
	var column := _new_scroll_column()
	_add_label(column, "Active Quests")
	if QuestLog.active.is_empty():
		_add_label(column, "No active quests")
	for quest in QuestLog.active:
		_add_quest(column, quest, false)

	_add_label(column, "")
	_add_label(column, "Completed")
	if QuestLog.completed.is_empty():
		_add_label(column, "None yet")
	for quest in QuestLog.completed:
		_add_quest(column, quest, true)

func _add_quest(column: Control, quest: QuestDefinition, done: bool) -> void:
	var title := quest.title
	if quest.giver != "":
		title += "  (%s)" % quest.giver
	if done:
		title += "  - Done"
	_add_label(column, title)

	var description := _add_label(column, quest.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 200
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if not done and quest.item != null:
		var held := mini(player.inventory.count_of(quest.item), quest.item_count)
		_add_label(column, "  %s  %d / %d" % [quest.item.display_name, held, quest.item_count])
	_add_label(column, "  Reward: %s" % quest.reward_text())
	_add_label(column, "")
