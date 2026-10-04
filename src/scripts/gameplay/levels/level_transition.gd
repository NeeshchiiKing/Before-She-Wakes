class_name LevelTransition extends Area2D

# const TEST_LEVEL_02 : String = "uid://kjasdhf"

signal transition_requested(scene_uid : String)

@export var destination_level_uid : String = ""

var _has_triggered : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body : Node2D) -> void:
	if _has_triggered:
		return
	
	if body is not Player:
		return
	
	_has_triggered = true
	
	transition_requested.emit(destination_level_uid)
	
