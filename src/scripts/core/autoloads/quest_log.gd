extends Node
## The player's quest list. Flags in GameState are the truth; this keeps the lists the menu shows.
## (No class_name: the autoload name QuestLog is how you reach it.)

signal changed

var active : Array[QuestDefinition] = []
var completed : Array[QuestDefinition] = []

func is_started(quest: QuestDefinition) -> bool:
	return GameState.has_flag(quest.started_flag())

func is_complete(quest: QuestDefinition) -> bool:
	return GameState.has_flag(quest.complete_flag())

func start(quest: QuestDefinition) -> void:
	if quest == null or is_started(quest):
		return
	GameState.set_flag(quest.started_flag())
	active.append(quest)
	changed.emit()

func complete(quest: QuestDefinition) -> void:
	if quest == null or is_complete(quest):
		return
	GameState.set_flag(quest.complete_flag())
	active.erase(quest)
	completed.append(quest)
	changed.emit()
