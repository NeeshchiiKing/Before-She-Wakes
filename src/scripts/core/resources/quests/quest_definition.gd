class_name QuestDefinition extends Resource
## One fetch quest. Make a .tres of this per quest, e.g. src/data/quests/minerva_mushroom.tres

@export var id : String = "minerva_mushroom" ## Unique. Save flags are built from it. Set once, don't change.
@export var title : String = "Minerva's Mushroom"
@export var giver : String = "Minerva"
@export_multiline var description : String = "Minerva the witch wants a mushroom."
@export_group("Objective")
@export var item : ItemDefinition ## drag in minervas_mushroom.tres
@export var item_count : int = 1
@export_group("Rewards")
@export var reward_xp : int = 25
@export var reward_currency : CurrencyDefinition ## drag in runes.tres
@export var reward_currency_amount : int = 1

func started_flag() -> String:
	return "quest_%s_started" % id

func complete_flag() -> String:
	return "quest_%s_complete" % id

func reward_text() -> String:
	var text := "%d XP" % reward_xp
	if reward_currency != null:
		text += ", %d %s" % [reward_currency_amount, reward_currency.display_name]
	return text
