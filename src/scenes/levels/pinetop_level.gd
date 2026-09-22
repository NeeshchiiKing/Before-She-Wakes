class_name PinetopLevel extends BaseLevel 

@onready var player_spawn_marker : PlayerSpawn = $Entities/PlayerSpawn
@onready var player_camera       : Camera2D = $Entities/PlayerCamera
@onready var level_transition: LevelTransition = $Transitions/LevelTransition


func _ready() -> void:
	level_transition.transition_requested.connect(_on_level_transition_requested)
	
# Provides a player spawn location
func get_default_player_spawn() -> Vector2:
	return player_spawn_marker.global_position

# Provides the camera used in the level
func get_player_camera() -> Camera2D:
	return player_camera


func _on_level_transition_requested(scene_uid: String) -> void:
	signal_level_transition.emit(scene_uid)
