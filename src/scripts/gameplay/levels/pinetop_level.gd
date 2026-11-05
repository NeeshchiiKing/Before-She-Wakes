class_name PinetopLevel extends BaseLevel 

@onready var player_spawn_marker : PlayerSpawn = $Player/PlayerSpawn
@onready var player_camera       : Camera2D = $Player/PlayerCamera

@export var inn_bed : RestStation ## The bed Coren wakes up in after the nightmare
@export var kira_dialogue : DialogueResource

func on_level_loaded(player : Player) -> void:
	if player.wakes_in_bed and inn_bed:
		player.stats.drain_all()
		await inn_bed.start_asleep(player) # lies down while the screen is still black


func on_level_entered(player : Player) -> void:
	if not (player.wakes_in_bed and inn_bed):
		return
	player.wakes_in_bed = false
	player.in_dialogue = true
	await get_tree().create_timer(1.5).timeout
	if kira_dialogue:
		await Story.say(kira_dialogue, "wake_call") # wakes him up
	await inn_bed.wake_up(player)
	if kira_dialogue:
		Story.say(kira_dialogue, "wake")
func _init() -> void:
	grid_pos = Vector2i(5, 7) # F8
	
# Provides a player spawn location
func get_default_player_spawn() -> Vector2:
	return player_spawn_marker.global_position

# Provides the camera used in the level
func get_player_camera() -> Camera2D:
	return player_camera
