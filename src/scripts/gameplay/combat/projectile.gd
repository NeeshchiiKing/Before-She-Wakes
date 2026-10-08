class_name Projectile extends Hitbox
## A thrown object. Flies straight, hurts the first enemy it hits, stops at walls or max range.

var _direction : Vector2 = Vector2.RIGHT
var _speed : float = 180.0
var _range_left : float = 120.0

func setup(direction: Vector2, speed: float, max_range: float, hit_damage: int) -> void:
	rotation = direction.angle()
	_direction = direction
	_speed = speed
	_range_left = max_range
	damage = hit_damage
	knockback_direction = direction
	stores_hit_targets = true # lets us know when a Hurtbox took the hit

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not hit_targets.is_empty():
		queue_free()
		return
	var step := _speed * delta
	global_position += _direction * step
	_range_left -= step
	if _range_left <= 0.0:
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free() # hit a wall
