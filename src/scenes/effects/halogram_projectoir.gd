class_name HologramProjector
extends Node2D

## A spot Kira's hologram can appear at. Place one in every Inn room (not the restroom).

signal player_entered_room(projector: HologramProjector)

## Unique name used by story code and dialogue, e.g. &"front_desk", &"coren_room".
@export var projector_id: StringName = &""
## Area2D covering this projector's room. When the player walks in, Kira (in follow mode) comes here.
@export var room_area: Area2D
## Optional glow / light / beam sprite, shown only while Kira is at this projector.
@export var beam: CanvasItem

## Animation Kira plays at this projector. Must match a name in her SpriteFrames exactly.
@export var kira_animation: StringName = &"Standing"
## Mirror Kira horizontally at this projector.
@export var kira_flip_h: bool = false

@onready var spawn_point: Marker2D = $SpawnPoint


func _ready() -> void:
	add_to_group(&"hologram_projectors")
	if projector_id == &"":
		push_warning("HologramProjector at %s has no projector_id." % get_path())
	if room_area:
		room_area.body_entered.connect(_on_room_body_entered)
	set_active(false)

func get_spawn_position() -> Vector2:
	# No SpawnPoint child? Kira just appears on the projector itself.
	return spawn_point.global_position if spawn_point else global_position

func set_active(active: bool) -> void:
	if beam:
		beam.visible = active


func _on_room_body_entered(body: Node2D) -> void:
	print("Room ", projector_id, " entered by: ", body.name, " groups: ", body.get_groups())
	# CHECK: assumes the player node is in the "player" group.
	if body.is_in_group(&"player"):
		player_entered_room.emit(self)
