extends CharacterBody2D

const SPEED = 60
const FRICTION = 200

# What the crow is doing with its memory of the player.
# The AnimationTree still decides Idle / Chase / Hit animations;
# this decides WHERE the crow goes while in "Chase".
enum Hunt { NONE, CHASE, TO_LAST_SEEN, CHECK_AHEAD, SEARCH, RETURN }

@export var experience_reward : int = 5
@export var loot : LootTable
@export var stats: Stats

@export_group("Senses")
@export var aggro_range := 200.00
@export var min_range := 8
@export var vision_angle := 180.0       # full width of the vision cone, in degrees
@export var hearing_range := 200.0       # hears a moving, non-sneaking player (through walls)

@export_group("Hunting")
@export var search_time := 4.0          # seconds it looks around at the last-seen spot
@export var overshoot := 64.0           # how far past the last-seen spot it checks (around corners)
@export var give_up_time := 4.0         # stops walking to a spot it can't reach
@export var look_around_speed := 4.0    # how fast it turns while searching (radians/sec)

@export_group("Whiskers")
@export var whisker_length := 40.0
@export var whisker_angle := 30.0       # degrees off the movement direction, each side

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var hurtbox: Hurtbox = $Hurtbox
# Optional: add a NavigationAgent2D child and the crow will path around walls.
# Without one it flies straight at its target.
@onready var nav: NavigationAgent2D = get_node_or_null("NavigationAgent2D")

var _is_dead : bool = false
var hunt := Hunt.NONE
var origin: Vector2
var target: Vector2
var last_seen_pos: Vector2
var last_seen_dir := Vector2.ZERO
var timer := 0.0
var facing := Vector2.RIGHT              # where the crow is looking (vision cone points this way)
var whisker_left: RayCast2D
var whisker_right: RayCast2D


func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_vitality.connect(die)
	add_to_group("enemies")
	origin = global_position
	# Top-down movement: slide along walls at any angle instead of sticking.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	# Whiskers are made in code so you don't need to add them to the scene.
	whisker_left = make_whisker()
	whisker_right = make_whisker()


func _physics_process(delta: float) -> void:
	var state = playback.get_current_node()
	match state:
		"Idle":
			update_hunt(delta)
			velocity = Vector2.ZERO
		"Chase":
			update_hunt(delta)
			move_hunt()
			move_with_wall_slide()
		"Hit":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()
	update_sprite_facing()


# ---------- Hunting brain ----------

func update_hunt(delta: float) -> void:
	# Hearing: turn toward the noise. If it still can't see him (wall in
	# the way), go check out where the noise came from.
	if can_hear_player():
		var player := get_player()
		facing = global_position.direction_to(player.global_position)
		if hunt != Hunt.CHASE and not can_see_player():
			investigate(player.global_position)

	# Seeing the player always wins, from any hunt state.
	if can_see_player():
		var player := get_player()
		last_seen_pos = player.global_position
		if player.velocity.length() > 1.0:
			last_seen_dir = player.velocity.normalized()
		hunt = Hunt.CHASE
		return

	timer -= delta
	match hunt:
		Hunt.CHASE:
			# Just lost sight: first fly to the exact spot he was last seen.
			# The crow had a clear line to that spot, so it can always get there,
			# even when he's ducked around a corner.
			set_target(last_seen_pos)
			hunt = Hunt.TO_LAST_SEEN
			timer = give_up_time
		Hunt.TO_LAST_SEEN:
			# Now at the corner: turn and check where he was heading.
			if reached_target() or timer <= 0.0:
				set_target(last_seen_pos + last_seen_dir * overshoot)
				hunt = Hunt.CHECK_AHEAD
				timer = give_up_time
		Hunt.CHECK_AHEAD:
			if reached_target() or timer <= 0.0:
				hunt = Hunt.SEARCH
				timer = search_time
		Hunt.SEARCH:
			# Slowly turn so the vision cone sweeps the area.
			facing = facing.rotated(look_around_speed * delta)
			if timer <= 0.0:
				set_target(origin)
				hunt = Hunt.RETURN
				timer = give_up_time * 3.0
		Hunt.RETURN:
			if reached_target() or timer <= 0.0:
				hunt = Hunt.NONE


# Go look at a spot (a noise, or where a hit came from).
func investigate(pos: Vector2) -> void:
	last_seen_pos = pos
	last_seen_dir = Vector2.ZERO
	set_target(pos)
	hunt = Hunt.TO_LAST_SEEN
	timer = give_up_time


func move_hunt() -> void:
	var goal: Vector2
	match hunt:
		Hunt.CHASE:
			var player := get_player()
			if player == null:
				velocity = Vector2.ZERO
				return
			goal = player.global_position
			if nav:
				nav.target_position = goal
		Hunt.TO_LAST_SEEN, Hunt.CHECK_AHEAD, Hunt.RETURN:
			goal = target
		_:
			velocity = Vector2.ZERO
			return

	var final_goal := goal
	if nav:
		if nav.is_navigation_finished():
			velocity = Vector2.ZERO
			return
		goal = nav.get_next_path_position()

	velocity = global_position.direction_to(goal) * SPEED

	# Whiskers only when not right on top of the goal, so they don't
	# keep it from reaching a spot next to a wall.
	if global_position.distance_to(final_goal) > whisker_length * 2.0:
		velocity = steer_with_whiskers(velocity)

	if velocity != Vector2.ZERO:
		facing = velocity.normalized()
	if hunt == Hunt.CHASE:
		facing = global_position.direction_to(final_goal)


# Moves like move_and_slide(), but if a wall (or a wall corner) blocks
# most of the movement, the crow steers along the wall instead of
# pushing into it, so it slips around corners.
func move_with_wall_slide() -> void:
	var desired := velocity
	move_and_slide()
	if desired == Vector2.ZERO or get_slide_collision_count() == 0:
		return
	if get_real_velocity().length() < desired.length() * 0.3:
		var normal := get_slide_collision(0).get_normal()
		var tangent := Vector2(-normal.y, normal.x)
		if tangent.dot(desired) < 0.0:
			tangent = -tangent
		velocity = tangent * desired.length()
		move_and_slide()


func set_target(pos: Vector2) -> void:
	target = pos
	if nav:
		nav.target_position = pos


func reached_target() -> bool:
	if nav:
		return nav.is_navigation_finished()
	return global_position.distance_to(target) < 4.0


# Used by the AnimationTree transitions (Idle <-> Chase).
func is_hunting() -> bool:
	return hunt != Hunt.NONE


func update_sprite_facing() -> void:
	if absf(facing.x) > 0.1:
		sprite_2d.scale.x = sign(facing.x)


# ---------- Whiskers ----------

func make_whisker() -> RayCast2D:
	var ray := RayCast2D.new()
	ray.enabled = false  # only updated on demand
	ray.collision_mask = ray_cast_2d.collision_mask  # same walls the sight ray sees
	add_child(ray)
	return ray


# Turns the velocity away from whichever side has a wall closer.
func steer_with_whiskers(vel: Vector2) -> Vector2:
	var dir := vel.normalized()
	var angle := deg_to_rad(whisker_angle)
	var left_push := whisker_push(whisker_left, dir.rotated(-angle))
	var right_push := whisker_push(whisker_right, dir.rotated(angle))
	return vel.rotated((left_push - right_push) * angle)


# 0 = nothing ahead, 1 = wall right in its face.
func whisker_push(ray: RayCast2D, dir: Vector2) -> float:
	ray.target_position = dir * whisker_length
	ray.force_raycast_update()
	if not ray.is_colliding():
		return 0.0
	var dist := global_position.distance_to(ray.get_collision_point())
	return 1.0 - dist / whisker_length


# ---------- Senses ----------

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")


func is_player_in_range() -> bool:
	var player := get_player()
	if player == null:
		return false
	var distance_to_player = global_position.distance_to(player.global_position)
	return distance_to_player < aggro_range and distance_to_player > min_range


func can_see_player() -> bool:
	if not is_player_in_range():
		return false
	var player := get_player()
	var to_player := player.global_position - global_position
	# Vision cone: can't see what's behind it.
	if absf(facing.angle_to(to_player)) > deg_to_rad(vision_angle) / 2.0:
		return false
	ray_cast_2d.target_position = to_player
	ray_cast_2d.force_raycast_update()  # check this frame, not last frame
	return not ray_cast_2d.is_colliding()


func can_hear_player() -> bool:
	var player := get_player()
	if player == null:
		return false
	if global_position.distance_to(player.global_position) > hearing_range:
		return false
	# The player decides what counts as noise (see is_making_noise() in the Player script).
	return player.is_making_noise()


# ---------- Combat ----------

func take_hit(other_hitbox: Hitbox) -> void:
	stats.vitality -= other_hitbox.damage
	velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount
	# Getting hit (like a sneak attack from behind) makes it turn and look.
	var player := get_player()
	if player and hunt != Hunt.CHASE:
		facing = global_position.direction_to(player.global_position)
		investigate(player.global_position)
	playback.start("Hit")


func die() -> void:
	if _is_dead:
		return
	_is_dead = true

	var player : Player = get_player()
	if player:
		player.gain_experience(experience_reward)
	if loot != null:
		loot.drop(global_position, get_parent())
	queue_free()
