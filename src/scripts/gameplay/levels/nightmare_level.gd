class_name NightmareLevel extends BaseLevel

@onready var player_spawn_marker : PlayerSpawn = $Player/PlayerSpawn
@onready var player_camera       : Camera2D = $Player/PlayerCamera

@export var intro_dialogue : DialogueResource

func on_level_entered(player : Player) -> void:
	if intro_dialogue == null:
		return
	player.in_dialogue = true
	await Story.say(intro_dialogue, "intro")
	player.in_dialogue = false
	
func get_default_player_spawn() -> Vector2:
	return player_spawn_marker.global_position

func get_player_camera() -> Camera2D:
	return player_camera
