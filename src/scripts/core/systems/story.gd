extends Node
## Remembers what has happened in the story. Dialogue can read it: if Story.is_set("inn_done")
## The flags themselves live in GameState (the one place quests, the map and story all share),
## so saving GameState.flags saves everything. Story is just the friendly front door for
## story code and .dialogue files.

signal flag_set(flag : StringName)

## Sets a story flag. Returns true so dialogue can use it without a `do` line:
##   if Story.set_flag("met_chant_trembling")
func set_flag(flag : StringName) -> bool:
	var key := String(flag) # GameState uses String keys; keep them matching
	if GameState.has_flag(key):
		return true
	GameState.set_flag(key)
	flag_set.emit(flag)
	return true

func is_set(flag : StringName) -> bool:
	return GameState.has_flag(String(flag))

## Shows a dialogue and waits for it to finish, then makes sure the balloon is gone
## (a leftover balloon keeps swallowing input).
func say(dialogue : DialogueResource, title : String = "start") -> void:
	var balloon := DialogueManager.show_dialogue_balloon(dialogue, title)
	await DialogueManager.dialogue_ended
	if is_instance_valid(balloon):
		balloon.queue_free()
