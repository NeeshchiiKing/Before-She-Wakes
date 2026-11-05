class_name RestStation extends StaticBody2D
## Furniture that fully restores one Resource and resets its status (Bed, Chair, Bath, Toilet, Fire).

signal used(resource : String)

const ACTIONS : Dictionary = {
	"vitality": "Rest",
	"intelligence": "Meditate",
	"charisma": "Cleanse",
	"strength": "Discharge",
	"dexterity": "Sweat",
}

@export_group("Use Animation")
@export var enter_animations : Array[StringName] = [] ## One-shot, in order, getting on (e.g. laying_down)
@export var use_animation    : StringName = &"" ## Optional loop while on it (e.g. sleeping). Empty = hold the last enter frame
@export var exit_animations  : Array[StringName] = [] ## One-shot, in order, getting off (e.g. laying_up)
@export var use_time    : float = 1.0 ## Seconds he stays down after the Resource is restored
@export var use_spot    : Marker2D ## Where the player lies/sits
@export var exit_spot   : Marker2D ## Where the player stands afterward
@export var exit_facing : Vector2 = Vector2.DOWN

var _in_use : bool = false

@export_enum("vitality", "intelligence", "charisma", "strength", "dexterity") var restores : String = "vitality"
@export var safe_only : bool = true ## Can't be used while enemies are nearby

@onready var interact_area : Area2D = $InteractArea
@onready var prompt : Label = $PromptLabel

var _player_in_range : Player = null

func _ready() -> void:
	if use_spot == null:
		use_spot = get_node_or_null("UseSpot") as Marker2D
	if exit_spot == null:
		exit_spot = get_node_or_null("ExitSpot") as Marker2D
	if _is_animated() and (use_spot == null or exit_spot == null):
		push_warning("%s: missing UseSpot or ExitSpot marker" % name)
	prompt.hide()
	# ...rest of _ready stays the same
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_use(_player_in_range)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body as Player
		prompt.text = "E: %s" % ACTIONS[restores]
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.hide()

func _use(player: Player) -> void:
	if _in_use:
		return
	if safe_only and player.is_in_combat():
		prompt.text = "Not with enemies nearby"
		return
	if not _is_animated():
		player.stats.fully_restore(StringName(restores))
		prompt.text = "%s: %s" % [restores.capitalize(), player.stats.status_name(StringName(restores))]
		used.emit(restores)
		return
	_use_animated(player)

func _is_animated() -> bool:
	return not enter_animations.is_empty() or use_animation != &"" or not exit_animations.is_empty()

func _use_animated(player: Player) -> void:
	await start_asleep(player)
	player.stats.fully_restore(StringName(restores)) # instant refill
	await get_tree().create_timer(use_time).timeout
	await wake_up(player)
	used.emit(restores)

func start_asleep(player: Player) -> void:
	_in_use = true
	prompt.hide()
	player.in_dialogue = true # freeze controls
	if use_spot:
		player.global_position = use_spot.global_position
	for anim in enter_animations:
		await player.play_scene_animation(anim)
	if use_animation != &"":
		player.play_scene_animation(use_animation)
		
		
## Plays the get-up animations and gives control back
func wake_up(player: Player) -> void:
	for anim in exit_animations:
		await player.play_scene_animation(anim)
	if exit_spot:
		player.global_position = exit_spot.global_position
	player.end_scene_animation(exit_facing)
	player.in_dialogue = false
	_in_use = false
	if _player_in_range:
		prompt.text = "E: %s" % ACTIONS[restores]
		prompt.show()
	print("exit_spot: ", exit_spot, "  player now at: ", player.global_position)
