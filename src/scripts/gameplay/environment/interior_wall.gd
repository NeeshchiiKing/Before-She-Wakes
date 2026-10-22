@tool
class_name InteriorWall extends StaticBody2D
## Drop into any building. Set Length in the Inspector; Vertical flips it from left/right to up/down.
## Only the art is automatic. The CollisionShape2D is yours to draw on each wall.
@export_group("Fade")
@export_range(0.0, 1.0) var faded_alpha : float = 0.35 ## How see-through the wall gets
@export var fade_time : float = 0.2
@export var fade_margin : int = 8 ## Extra pixels around the picture where fading starts, so it fades just before you're behind it

@export var horizontal_texture : Texture2D: ## Wall seen from the front
	set(v): horizontal_texture = v; _update()
@export var vertical_texture : Texture2D: ## Wall seen from the side
	set(v): vertical_texture = v; _update()
@export var vertical : bool = false:
	set(v): vertical = v; _update()
@export var length : int = 64: ## Pixels along the wall
	set(v): length = maxi(v, 1); _update()
@export var thickness : int = 8: ## Pixels across the wall (the art's height for a horizontal wall)
	set(v): thickness = maxi(v, 1); _update()

var _tween : Tween

func _ready() -> void:
	_update()
	if Engine.is_editor_hint():
		return
	$FadeArea.body_entered.connect(_on_fade_entered)
	$FadeArea.body_exited.connect(_on_fade_exited)

func _update() -> void:
	if not is_node_ready():
		return
	var size := Vector2(thickness, length) if vertical else Vector2(length, thickness)
	var sprite : Sprite2D = $Sprite2D
	sprite.texture = vertical_texture if vertical else horizontal_texture
	sprite.centered = false
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.position = Vector2(0, -size.y) # picture grows upward from the node's origin
	
	# Fade area covers the whole picture plus a margin on the sides and top (not below, so standing in front doesn't fade it)
	var area_rect := Rect2(-fade_margin, -size.y - fade_margin, size.x + fade_margin * 2, size.y + fade_margin)
	var area_shape := RectangleShape2D.new()
	area_shape.size = area_rect.size
	$FadeArea/CollisionShape2D.shape = area_shape
	$FadeArea/CollisionShape2D.position = area_rect.position + area_rect.size / 2.0
	
func _on_fade_entered(body: Node2D) -> void:
	if body is Player:
		_fade_to(faded_alpha)

func _on_fade_exited(body: Node2D) -> void:
	if body is Player:
		_fade_to(1.0)

func _fade_to(alpha: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property($Sprite2D, "modulate:a", alpha, fade_time)
