class_name FillStation extends StaticBody2D
## Fills empty containers in the player's bag (a well turns Empty Bottles into Bottles of Water).
## Reuse it for streams, springs, a beer tap...: just change the two items.

signal filled(amount : int)

@export var empty_item : ItemDefinition ## e.g. empty_bottle.tres
@export var filled_item : ItemDefinition ## e.g. bottle_of_water.tres
@export var action_name : String = "Fill Bottles"
## On: one press fills every empty (a well). Off: one bottle per press, so the player
## chooses how many to fill here (Minerva's cauldron).
@export var fill_all : bool = true

@export_group("First Time")
## Set the first time the player fills anything here. Empty = no tutorial line.
@export var first_use_flag : StringName = &"learned_bottle_filling"
@export var first_use_dialogue : DialogueResource
@export var first_use_title : String = "first_fill"

@onready var interact_area : Area2D = $InteractArea
@onready var prompt : Label = $PromptLabel

var _player_in_range : Player = null
var _busy : bool = false

func _ready() -> void:
	prompt.hide()
	if empty_item == null or filled_item == null:
		push_warning("%s: set Empty Item and Filled Item in the Inspector" % name)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range == null or _busy:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_fill(_player_in_range)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body as Player
		_update_prompt()
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.hide()

## "E: Fill Bottles (3)" so the player sees how many empties they carry
func _update_prompt() -> void:
	var empties := _player_in_range.inventory.count_of(empty_item)
	if empties > 0:
		prompt.text = "E: %s (%d)" % [action_name, empties]
	else:
		prompt.text = "E: %s" % action_name

func _fill(player: Player) -> void:
	var inventory := player.inventory
	var empties := inventory.count_of(empty_item)
	if empties <= 0:
		prompt.text = "No empty %s" % empty_item.short_name.to_lower()
		return
	var amount := empties if fill_all else 1
	# A new kind of item needs bag space, unless this fill empties the last bottle (frees its space)
	if amount < empties and not inventory.can_add(filled_item):
		prompt.text = "Bag is full"
		return
	inventory.remove(empty_item, amount)
	inventory.add(filled_item, amount)
	prompt.text = "Filled %d" % amount
	filled.emit(amount)
	await _teach_once(player)
	if _player_in_range == player and not fill_all and inventory.count_of(empty_item) > 0:
		_update_prompt() # show how many empties are left for the next press

func _teach_once(player: Player) -> void:
	if first_use_flag == &"" or Story.is_set(first_use_flag):
		return
	Story.set_flag(first_use_flag)
	if first_use_dialogue == null:
		return
	_busy = true
	player.in_dialogue = true
	await Story.say(first_use_dialogue, first_use_title)
	player.in_dialogue = false
	_busy = false
