class_name QuestNPC extends NPC
## An NPC with a fetch quest. Assign the quest .tres and a .dialogue file.

@export var quest : QuestDefinition

func quest_started() -> bool:
	return QuestLog.is_started(quest)

func quest_complete() -> bool:
	return QuestLog.is_complete(quest)

func start_quest() -> void:
	QuestLog.start(quest)

func items_held() -> int:
	var player := get_tree().get_first_node_in_group("player")
	return player.inventory.count_of(quest.item) if player else 0

func has_items() -> bool:
	return items_held() >= quest.item_count

## Takes the item, pays the rewards, marks the quest complete. False if the player can't turn it in.
func turn_in() -> bool:
	if quest_complete() or not has_items():
		return false
	var player := get_tree().get_first_node_in_group("player")
	player.inventory.remove(quest.item, quest.item_count)
	player.gain_experience(quest.reward_xp)
	if quest.reward_currency != null:
		player.wallet.add(StringName(quest.reward_currency.id), quest.reward_currency_amount)
	QuestLog.complete(quest)
	return true

func reward_text() -> String:
	return quest.reward_text()
