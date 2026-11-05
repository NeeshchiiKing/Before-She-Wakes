extends Node
## Remembers what has happened in the story. Dialogue can read it: if Story.is_set("inn_done")
## FUTURE (save/load): save and load _flags

signal flag_set(flag : StringName)

var _flags : Dictionary = {}

func set_flag(flag : StringName) -> void:
	if _flags.has(flag):
		return
	_flags[flag] = true
	flag_set.emit(flag)

func is_set(flag : StringName) -> bool:
	return _flags.has(flag)

## Shows a dialogue and waits for it to finish, then makes sure the balloon is gone
## (a leftover balloon keeps swallowing input).
func say(dialogue : DialogueResource, title : String = "start") -> void:
	var balloon := DialogueManager.show_dialogue_balloon(dialogue, title)
	await DialogueManager.dialogue_ended
	if is_instance_valid(balloon):
		balloon.queue_free()
		
		
		
