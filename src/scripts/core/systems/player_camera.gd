extends Camera2D

const LERP_WEIGHT : float = 2.0
const CAMERA_LOOK_AHEAD_VAL : Vector2 = Vector2(0.0, -8.0)
const CAMERA_LOOK_AMOUNT    : float =  64.0

var target : Node2D = null
var _player_target : Node2D = null   # remembers the player so we can return to them

func _physics_process(delta : float) -> void:
	_follow_camera_target(delta)

func _follow_camera_target(delta : float) -> void:
	if not target:
		return

	var target_camera_offset : Vector2 = CAMERA_LOOK_AHEAD_VAL
	var target_global_pos    : Vector2 = target.global_position + target_camera_offset

	if target.has_method("get_camera_look_direction"):
		target_global_pos += target.get_camera_look_direction() * CAMERA_LOOK_AMOUNT

	var camera_pos_out : Vector2
	camera_pos_out.x = lerpf(global_position.x, target_global_pos.x, LERP_WEIGHT * delta)
	camera_pos_out.y = lerpf(global_position.y, target_global_pos.y, LERP_WEIGHT * delta)

	global_position = camera_pos_out


## Sets the player as the default follow target. Snaps immediately so there's
## no swooping-in effect when a new level loads.
func set_player_target(player_node : Node2D) -> void:
	_player_target = player_node
	target = player_node
	if target:
		global_position = target.global_position + CAMERA_LOOK_AHEAD_VAL


## Temporarily redirects the camera to focus on something else (boss intro,
## cutscene point, etc). Call return_to_player() when done.
func focus_on(new_target : Node2D) -> void:
	target = new_target


# somewhere the camera reference is accessible, e.g. via main_game or a signal
#level_camera.focus_on(boss_node)
#await get_tree().create_timer(2.0).timeout   # hold on the boss for a beat
#level_camera.return_to_player()

## Returns camera focus back to the player.
func return_to_player() -> void:
	target = _player_target
