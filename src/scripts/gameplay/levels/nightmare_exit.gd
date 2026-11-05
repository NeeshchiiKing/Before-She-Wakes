class_name NightmareExit extends LevelTransition
## Hospital door: Coren stops, Kira whispers his name, then the nightmare ends

@export var dialogue : DialogueResource
@export var dialogue_title : String = "start"

func _on_body_entered(body : Node2D) -> void:
	if _has_triggered or body is not Player:
		return
	_has_triggered = true
	body.in_dialogue = true # stop walking
	if dialogue:
		await Story.say(dialogue, dialogue_title)
	body.wakes_in_bed = true
	transition_requested.emit(destination_level_uid)
