extends CharacterBody2D

const SPEED = 60
const FRICTION = 200

@export var aggro_range: = 200
@export var min_range: = 8

@export var stats: Stats
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var hurtbox: Hurtbox = $Hurtbox

#@export var player: Player
#not = to but : of type Player This gives access to the Player but only works if both are added to the world scene
#we did this for the grass effect but not doing it for the player

func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_vitality.connect(queue_free)
	
func _physics_process(_delta: float) -> void:
	var state = playback.get_current_node()
	match state:
		"Idle": 
			print("idle") 
			pass 
		"Chase": 
			print("chasing player")
			var player = get_player()
			if player is Player:
				velocity = global_position.direction_to(player.global_position) * SPEED
				sprite_2d.scale.x = sign(velocity.x)
				# so sign either shows 1 or -1 so if velocity is -50 then its -1 etc
			else:
				velocity = Vector2.ZERO
			move_and_slide()
		"Hit":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * _delta)
			move_and_slide()
			
func take_hit(other_hitbox: Hitbox) -> void:
	stats.vitality -= other_hitbox.damage
	velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount
	playback.start("Hit")
	print("changed hit state")	
#using groups this gives us access to the player, use nodes_in_the_group to get a list of nodes
func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

# bool true or false
func is_player_in_range() -> bool:
	var result = false #result is false by default
	var player: = get_player()
	if player is Player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < aggro_range and distance_to_player > min_range: 
			result = true 
	return result
	
func can_see_player() -> bool:
	if not is_player_in_range(): return false
	var player = get_player()
	ray_cast_2d.target_position = player.global_position - global_position #gp is the bats position
	var has_los_to_player: = not ray_cast_2d.is_colliding()
	return has_los_to_player
	#los = Line Of Sight
	
