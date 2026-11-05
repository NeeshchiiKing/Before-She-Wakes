class_name InnTutorial extends Node
## Opening tutorial: Coren must use every rest station in the Inn before he can leave.

@export var stations : Array[RestStation] = [] ## Bed, chair, bath, toilet, fire
@export var door_blocker : CollisionObject2D ## StaticBody2D across the Inn's doorway
@export var door_warning : StoryLineTrigger ## Kira's "not yet" line at the door
@export var kira_dialogue : DialogueResource

func _ready() -> void:
	if Story.is_set(&"inn_done"):
		_open_door()
		return
	for station in stations:
		station.used.connect(_on_station_used)

func _on_station_used(resource : String) -> void:
	if Story.is_set(&"inn_done"):
		return # tutorial's over, Kira stays quiet
	Story.set_flag(StringName("inn_used_" + resource))
	if _all_used():
		Story.set_flag(&"inn_done")
		_open_door()
		_stop_listening()
	if kira_dialogue:
		Story.say(kira_dialogue, "next")
		
## The tutorial is finished: stations no longer report to Kira
func _stop_listening() -> void:
	for station in stations:
		if station.used.is_connected(_on_station_used):
			station.used.disconnect(_on_station_used)


func _all_used() -> bool:
	for station in stations:
		if not Story.is_set(StringName("inn_used_" + station.restores)):
			return false
	return true

func _open_door() -> void:
	if door_blocker:
		door_blocker.queue_free()
	if door_warning:
		door_warning.queue_free()
