class_name StoryLineTrigger extends Area2D
## Says a line when the player walks in. Use for "wrong way" spots, hints, etc.

@export var dialogue : DialogueResource
@export var dialogue_title : String = "wrong_way"
@export var once : bool = false
@export var cooldown : float = 3.0 ## Seconds before it can talk again

var _can_talk : bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body : Node2D) -> void:
	if not _can_talk or body is not Player or dialogue == null or body.in_dialogue:
		return
	_can_talk = false
	body.in_dialogue = true
	await Story.say(dialogue, dialogue_title)
	body.in_dialogue = false
	if once:
		return
	await get_tree().create_timer(cooldown).timeout
	_can_talk = true
