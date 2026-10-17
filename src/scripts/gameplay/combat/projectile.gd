class_name Projectile extends Hitbox
## A thrown object. Flies straight, hurts the first enemy it hits, stops at walls or max range.
## If it carries gear (e.g. the rock), it lands as a WorldPickup the player must go retrieve.

@export var pickup_scene : PackedScene ## Your WorldPickup scene, dropped when this lands
const FALL_TIME : float = 0.25 ## Seconds a throw spends dropping to the ground at the end of its range
var drop_gear : EquipmentDefinition = null ## Set by the thrower. null = vanishes on landing
var height : float = 0.0 ## How far above the ground it flies. Set by the thrower
var _direction : Vector2 = Vector2.RIGHT
var _speed : float = 180.0
var _range_left : float = 120.0
var _landed : bool = false

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
	if _landed:
		return
	if not hit_targets.is_empty():
		_land(global_position, -_direction * 16.0, true) # hit an enemy: bounces back
		return
	var step := _speed * delta
	global_position += _direction * step
	_range_left -= step
	if _range_left <= _speed * FALL_TIME:
		_land(global_position, _direction * _range_left, false) # losing steam: drops while still moving

func _on_body_entered(_body: Node2D) -> void:
	_land(global_position - _direction * 6.0, -_direction * 16.0, true) # hit a wall: bounces back

func _land(spot: Vector2, slide: Vector2, bounced: bool) -> void:
	if _landed:
		return
	_landed = true
	if drop_gear != null and pickup_scene != null:
		var pickup := pickup_scene.instantiate()
		pickup.set("gear", drop_gear)
		get_parent().add_child.call_deferred(pickup)
		pickup.set_deferred("global_position", spot + Vector2(0, height)) # onto the ground line
		pickup.call_deferred("fall_from", height, slide, bounced, FALL_TIME)
	queue_free()
