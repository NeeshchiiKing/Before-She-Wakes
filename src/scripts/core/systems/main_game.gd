class_name MainGame extends Node
#Responsible for setting up the World Layers and Coordinating high-level systems

#MainGame Application Root Loads when game runs
#Systems GameManagers, Quest Tracker, Inventory, Crafting Systems, Dialogue Manager, Save load, Audio Manager
#World Contains the World
#HUD heads Health bars, minimap, quest trracker, ability cooldowns
#Pause to pause the game which allowes to pause the game as you transition etc
#Transisition handles visual effects mostly
#Debug is currectly used so you can quit set fps, level name, noclip toggle, spawn enemy buttons

@onready var world: Node2D = $World

#Future (Main Menu): Loading test level for prototype
const PINETOP_LEVEL    : String = "uid://c7ta2yrs1skiv" 
const PLAYER_SCENE_UID : String = "uid://dnjkaew63j15w"
const NIGHTMARE_LEVEL    : String = "uid://bjiexlgyuwi54" 

@onready var fade_rect : ColorRect = $TransitionLayer/TransitionRoot/Fade

const FADE_OUT_TIME : float = 0.8
const FADE_IN_TIME  : float = 0.6

@export_group("Debug")
@export var debug_skip_intro : bool = false ## Editor only: start in Pinetop with the Inn tutorial already done

var _transitioning : bool = false


var player : Player = null

var _current_level : BaseLevel = null

# Game World Root Nodes
@onready var level_root  : Node2D = $World/LevelRoot
@onready var entity_root : Node2D = $World/EntityRoot
@onready var effect_root : Node2D = $World/EffectRoot

# UI Root Nodes (Future)
@onready var hud_root       : Control = $HudLayer/HudRoot 
@onready var pause_root     : Control = $PauseLayer/PauseRoot
@onready var transition_root: Control = $TransitionLayer/TransitionRoot

@onready var stats_hud : StatsHud = $HudLayer/HudRoot/StatsHud

@onready var pause_menu : PauseMenu = $PauseLayer/PauseRoot/PauseMenu

@onready var quick_bar_hud : QuickBarHud = $HudLayer/HudRoot/QuickBarHud
func _ready() -> void:
	_init_player()
	if player:
		stats_hud.bind_stats(player.stats)
		quick_bar_hud.bind_player(player)
	hud_root.visible = false     # each level turns it on in _apply_level_rules
	fade_rect.modulate.a = 1.0   # start on black, fade into the first level
	# The fade covers the whole screen, so it must never catch mouse clicks
	transition_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if debug_skip_intro and OS.is_debug_build():
		_debug_finish_intro()
		load_level(PINETOP_LEVEL)
	else:
		load_level(NIGHTMARE_LEVEL)
	pause_menu.quit_requested.connect(quit_game)
	

## Pretends the opening already happened (nightmare + Inn tutorial)
func _debug_finish_intro() -> void:
	for resource in ["vitality", "intelligence", "charisma", "strength", "dexterity"]:
		Story.set_flag(StringName("inn_used_" + resource))
	Story.set_flag(&"inn_done")
	
		
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event.is_action_pressed(&"debug_quit"):
		print_orphan_nodes()
		quit_game()

func quit_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
	
	
## Loads a level scene that must extend BaseLevel
## Loads a level scene that must extend BaseLevel (fades out, loads, fades in)
func load_level(level_scene : String) -> void:
	# Make sure this is called during idle time
	_transition_to.call_deferred(level_scene)

func _transition_to(level_scene : String) -> void:
	if _transitioning:
		return
	_transitioning = true
	if player:
		player.in_dialogue = true # freeze during the fade
	await _fade(1.0, FADE_OUT_TIME)
	await _perform_level_load(level_scene)
	await _fade(0.0, FADE_IN_TIME)
	if player:
		player.in_dialogue = false
	_transitioning = false
	_current_level.on_level_entered(player)

func _fade(to_alpha : float, time : float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", to_alpha, time)
	await tween.finished
	
func _detach_entity_root_from_level() -> void:
	if entity_root.get_parent() != world:
		entity_root.get_parent().remove_child(entity_root)
		world.add_child(entity_root)
		
func _perform_level_load(level_scene_uid : String) -> void:
	if is_instance_valid(_current_level):
		_detach_entity_root_from_level()
		_current_level.queue_free()
		_current_level = null
		# Wait to allow the queued deletion to process so it is out of the scene tree
		await get_tree().process_frame
	for child in entity_root.get_children():
		if child != player:
			child.queue_free()

	var new_level_packed : PackedScene = (
			ResourceLoader.load(level_scene_uid, "PackedScene") as PackedScene
	)

	if new_level_packed == null:
		push_error("Could not load level as a packed scene: " + level_scene_uid)
		return

	var new_level : Node = new_level_packed.instantiate()

	if not new_level:
		push_error("Could not instantiate new level " + level_scene_uid)
		return

	if new_level is not BaseLevel:
		new_level.free()  # Level must be freed to avoid unreferenced orphan nodes
		push_error("Loaded level is not of type BaseLevel " + level_scene_uid)
		return
	# FUTURE (main menu): Should have a fall back scene

	_current_level = new_level as BaseLevel

	level_root.add_child(_current_level) #this adds that level node to the Main game LevelRoot 
	# Level is stored as _current_level : BaseLevel

	_current_level.signal_level_transition.connect(load_level)

	_attach_entity_root_to_level()  
	_place_player_at_level_spawn()
	_setup_level_camera()
	_apply_level_lighting()
	_apply_level_rules()
	await _current_level.on_level_loaded(player)
	
## Turns the player's light on/off to match the level
func _apply_level_lighting() -> void:
	if player == null or _current_level == null:
		return
	player.set_dark_light(_current_level.player_light_on, _current_level.player_light_pulses)
	
## Story lockout: slow walk, no actions, no menu, HUD hidden
func _apply_level_rules() -> void:
	if player == null or _current_level == null:
		return
	player.set_story_locked(_current_level.story_lockout)
	hud_root.visible = not _current_level.story_lockout
	
	player.set_bleeding(_current_level.player_bleed_spot)
	player.face(_current_level.spawn_facing)
	
	
## Instantiates the player and adds it to the entity layer
func _init_player() -> void:
	var player_scene : PackedScene = ResourceLoader.load(PLAYER_SCENE_UID) as PackedScene
	if player_scene == null:
		push_error("Could not load player scene: " + PLAYER_SCENE_UID)
		return

	var player_instance : Node = player_scene.instantiate()
	if not player_instance:
		push_error("Could not instantiate player scene " + PLAYER_SCENE_UID)
		return

	if player_instance is not Player:
		player_instance.free()
		push_error("Loaded player scene is not of type Player " + PLAYER_SCENE_UID)
		return

	player = player_instance as Player
	entity_root.add_child(player)

## Moves the entity_root (player, NPCs, enemies) into the newly loaded level's
##  Y-sort container so everything inside it draws correctly relative to that
##  level's trees, bushes, buildings, etc.
func _attach_entity_root_to_level() -> void:
	if _current_level == null:
		push_error("Cannot attach entity_root to level because level is null")
		return

	var ysort_container : Node2D = _current_level.get_ysort_container()
	if ysort_container == null:
		push_error("Current level has no Y-sort container to attach entity_root to")
		return

	if entity_root.get_parent() != null:
		entity_root.get_parent().remove_child(entity_root)

	ysort_container.add_child(entity_root)
	
## Finds the default spawn location in currently loaded level, and places
##  the Player at that position.
func _place_player_at_level_spawn() -> void:
	if player == null:
		push_error("Cannot place player in level because it is null")
		return
	if _current_level == null:
		push_error("Cannot place player into level because level is null")
		return

	player.global_position = _current_level.get_default_player_spawn()

## Attaches player to the current camera as the target
func _setup_level_camera() -> void:
	if player == null or _current_level == null:
		return

	var level_camera : Camera2D = _current_level.get_player_camera()
	if level_camera == null:
		return

	# FUTURE (camera): Temporary hookup
	# NOTE: target variable was added as part of the custom camera script used for the prototype
	level_camera.set_player_target(player)


func _unhandled_input(event: InputEvent) -> void:
	if player and player.story_locked:
		return

	if event.is_action_pressed(&"menu"):
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if player == null:
		return
	if pause_menu.visible:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	var in_combat := player.is_in_combat()
	get_tree().paused = not in_combat # safe = paused, combat = live
	player.is_digging = in_combat
	pause_menu.open(player, in_combat)

func _close_menu() -> void:
	pause_menu.close()
	get_tree().paused = false
	player.is_digging = false

func _init_systems() -> void:
	pass # FUTURE (systems): Will be called to set
