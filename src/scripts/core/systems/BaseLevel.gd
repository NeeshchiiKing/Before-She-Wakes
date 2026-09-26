@abstract
class_name BaseLevel extends Node2D
# Abstract class for levels

signal signal_level_transition(scene_uid: String)

#This sets up Ysort for player
@onready var ysort_container: Node2D = $LevelObjects 


func _ready() -> void:
	for transition in find_children("*", "LevelTransition", true, false):
		transition.transition_requested.connect(_on_transition_requested)

func _on_transition_requested(scene_uid: String) -> void:
	signal_level_transition.emit(scene_uid)

func get_ysort_container() -> Node2D:
	return ysort_container
	
# Provides a player spawn location
@abstract func get_default_player_spawn() -> Vector2
#never return a Vector2.ZERO for the player this has to stay abstract for that reason 

# Provides the camera used in the level
@abstract func get_player_camera() -> Camera2D
