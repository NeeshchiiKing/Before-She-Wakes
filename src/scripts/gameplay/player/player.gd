class_name Player extends CharacterBody2D

const SPEED = 100.00
const ROLL_SPEED = 125
const SNEAK_SPEED = 20

var input_vector: = Vector2.ZERO
var last_input_vector = Vector2.LEFT
var is_sneaking: bool = false

var camera_look_direction : Vector2 = Vector2.ZERO
@onready var player_sprite_2d : Sprite2D = $PlayerSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var blink_animation: AnimationPlayer = $BlinkAnimation

@export var stats: Stats

#############################################################################################33

func _ready():
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_vitality.connect(die)

func _physics_process(_delta: float) -> void:
	
	var state = playback.get_current_node()
	match state:
		"MoveState": move_state(_delta)
		"AttackState": pass
		"DefendState": pass
		"RollState": roll_state(_delta)
		"SneakState": sneak_state(_delta)
		
func take_hit(other_hitbox : Hitbox) -> void:
	stats.vitality -= other_hitbox.damage
	blink_animation.play("blink")

func die() -> void:
	hide()
	remove_from_group("player")
	process_mode = Node.PROCESS_MODE_DISABLED

func move_state(_delta: float) -> void:
	# Vector is a combination of a x Value and y Value
	input_vector = Input.get_vector("move_left","move_right", "move_up", "move_down")

	#!= Means not Equal
	if input_vector!= Vector2.ZERO:
		hitbox.knockback_direction = input_vector.normalized()
		#this remembers the last input we did "move left, right, up, down
		last_input_vector = input_vector
		#directional_vector made to pass the animation tree flipping +1 and -1
		var direction_vector: = Vector2(input_vector.x, -input_vector.y)
		update_blend_positions(direction_vector)
		
	if Input.is_action_just_pressed("attack"):
		playback.travel("AttackState")
		
	if Input.is_action_just_pressed("defend"):
		playback.travel("DefendState")
		
	if Input.is_action_just_pressed("roll"):
		playback.travel("RollState")
	
	if Input.is_action_just_pressed("sneak"):
		playback.travel("SneakState")
		
	velocity = input_vector * SPEED
	move_and_slide()
	



func roll_state(_delta: float) -> void:
		velocity = last_input_vector.normalized() * ROLL_SPEED
		move_and_slide()

func sneak_state(_delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		var direction_vector := Vector2(input_vector.x, -input_vector.y)
		update_blend_positions(direction_vector)

	if Input.is_action_just_pressed("sneak"):
		is_sneaking = false
		playback.travel("MoveState")

	if Input.is_action_just_pressed("attack"):
		playback.travel("AttackState")
		
	if Input.is_action_just_pressed("defend"):
		playback.travel("DefendState")
		
	if Input.is_action_just_pressed("roll"):
		playback.travel("RollState")

	velocity = input_vector * SNEAK_SPEED
	move_and_slide()

func get_camera_look_direction() -> Vector2:
	return last_input_vector.normalized()
	
##This Function is Called in the Physics Process. All animations are in one area!
func update_blend_positions(direction_vector: Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/StandState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/AttackState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/DefendState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/RollState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/SneakState/SneakState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/SneakState/StandState/blend_position", direction_vector)
