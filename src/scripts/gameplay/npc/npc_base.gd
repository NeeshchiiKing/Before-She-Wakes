class_name NPC
extends StaticBody2D

@export var npc_name: String = "NPC"
@export var dialogue: DialogueResource
@export var dialogue_start: String = "start"

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Label = $Prompt

var player_in_range := false
var is_talking := false
var _balloon: Node = null

func _ready() -> void:
	prompt.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_talking and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		talk()

func talk() -> void:
	if dialogue == null:
		push_warning("%s has no dialogue assigned" % npc_name)
		return
	is_talking = true
	prompt.visible = false
	_balloon = DialogueManager.show_dialogue_balloon(dialogue, dialogue_start, [self])
func _on_dialogue_ended(_resource: DialogueResource) -> void:
	print("DIALOGUE ended")
	if not is_talking:
		return
	# Safety net: make sure the balloon is gone so it can't keep swallowing input
	if is_instance_valid(_balloon):
		_balloon.queue_free()
	_balloon = null
	# Wait a frame so the key press that closed the dialogue doesn't reopen it
	await get_tree().create_timer(0.3).timeout
	is_talking = false
	prompt.visible = player_in_range


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt.visible = not is_talking


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt.visible = false
