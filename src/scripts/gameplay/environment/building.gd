class_name Building extends Node2D
## A walk-in building. The top layer (roof + outer walls) fades out while the player is inside.
## On start, it fixes Y-sort so the player goes behind the building from the north and in front from the south.

@export var fade_nodes : Array[CanvasItem] = [] ## What fades. Leave empty to fade the "Top" child.
@export_range(0.0, 1.0) var inside_alpha : float = 0.0 ## 0 = fully see-through, 0.3 = ghostly walls
@export var fade_time : float = 0.3 ## Seconds to fade in or out
## Moves the sort line up from the bottom of the Top art, for art with ground or shadow below the wall
@export var front_sort_offset : float = 0.0

@onready var interior : Area2D = $InteriorArea

var _tween : Tween

func _ready() -> void:
	if has_node("Top"):
		_sort_from_bottom($Top, front_sort_offset)
	if has_node("Floor"):
		_sort_from_top($Floor)

	if fade_nodes.is_empty() and has_node("Top"):
		fade_nodes.append($Top)
	interior.body_entered.connect(_on_body_entered)
	interior.body_exited.connect(_on_body_exited)

## Moves a sprite's origin to its bottom edge without moving the picture.
## Y-sort then treats the whole building as standing on its front wall.
func _sort_from_bottom(sprite: Sprite2D, lift: float) -> void:
	var bottom := sprite.get_rect().end.y - lift
	sprite.position.y += bottom * sprite.scale.y
	sprite.offset.y -= bottom

## Moves a sprite's origin to its top edge, so it sorts behind everything inside the building
func _sort_from_top(sprite: Sprite2D) -> void:
	var top := sprite.get_rect().position.y
	sprite.position.y += top * sprite.scale.y
	sprite.offset.y -= top

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_fade_to(inside_alpha)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_fade_to(1.0)

func _fade_to(alpha: float) -> void:
	if _tween != null:
		_tween.kill() # walking in and right back out reverses smoothly instead of fighting
	_tween = create_tween().set_parallel(true)
	for node in fade_nodes:
		_tween.tween_property(node, "modulate:a", alpha, fade_time)
