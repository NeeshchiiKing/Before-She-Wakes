@abstract
class_name BaseLevel extends Node2D
# Abstract class for levels

signal signal_level_transition(scene_uid: String)

@export_group("Lighting")
@export var player_light_on     : bool = false ## Light around Coren (dark levels)
@export var player_light_pulses : bool = false ## Nightmare-style dimming pulses

@export_group("Story")
@export var story_lockout : bool = false ## Slow walk only: no attacks, rolls, sneak, items, menu or HUD

@export var grid_pos : Vector2i = Vector2i(-1, -1)

@export var spawn_facing : Vector2 = Vector2.DOWN ## Direction the player faces when this level loads

@export_enum("None", "Arm", "Leg") var player_bleed_spot : String = "None" ## Where Coren bleeds from

#This sets up Ysort for player
@onready var ysort_container: Node2D = $LevelObjects 


func _ready() -> void:
	for transition in find_children("*", "LevelTransition", true, false):
		transition.transition_requested.connect(_on_transition_requested)
	WorldMap.visit(grid_pos)

## Called by MainGame once the level has faded in. Override for intro lines/scenes.
func on_level_entered(_player : Player) -> void:
	pass
	
## Called by MainGame right after the level loads, while the screen is still black.
## Use it to set up poses/positions the player shouldn't see happen.
func on_level_loaded(_player : Player) -> void:
	pass
	
	
	
func _on_transition_requested(scene_uid: String) -> void:
	signal_level_transition.emit(scene_uid)

func get_ysort_container() -> Node2D:
	return ysort_container
	
# Provides a player spawn location
@abstract func get_default_player_spawn() -> Vector2
#never return a Vector2.ZERO for the player this has to stay abstract for that reason 

# Provides the camera used in the level
@abstract func get_player_camera() -> Camera2D
