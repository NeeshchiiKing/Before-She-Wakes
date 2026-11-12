class_name DrawAboveArea
extends Area2D

## While the player stands inside this area, he is drawn ABOVE the building.
## Put one over a building's front stairs / porch. When he leaves it (through the door),
## his normal draw order comes back and the building's own fade takes over.

## Must be higher than the Z Index of the building's Top node.
@export var player_z_inside: int = 10

var _saved_z: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_saved_z = body.z_index
		body.z_index = player_z_inside


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		body.z_index = _saved_z
