class_name Bee extends Node2D
## A bee that circles its hive. When the hive is angry, it dives at the player every few seconds.

enum State { ORBIT, ATTACK, RETURN }
var _awake : bool = false

var hive : Beehive

@export var wake_grace : float = 1.0 ## Can't be hurt for this long after leaving the hive

@export var wander_radius : float = 40.0 ## How far from the hive a bee will roam
@export var wander_speed : float = 40.0 ## Lazy buzzing speed (dives still use dive_speed)

@export var orbit_speed : float = 2.0 ## How fast it circles (radians per second)
@export var dive_speed : float = 150.0
@export var attack_interval : float = 2.5 ## Seconds between dives
@export var attack_jitter : float = 1.0 ## Random extra wait so the bees don't all dive together

var _wander_target : Vector2 = Vector2.ZERO


var _state : State = State.ORBIT
var _attack_timer : float = 0.0
var _target : Vector2 = Vector2.ZERO
var _is_dead : bool = false

@onready var hitbox : Hitbox = $Hitbox
@onready var hurtbox : Hurtbox = $Hurtbox

func _ready() -> void:
	visible = false
	hitbox.set_deferred("monitorable", false)
	hive = _find_hive()
	if hive == null:
		push_warning("Bee has no Beehive above it: %s" % get_path())
	_attack_timer = _next_wait()
	hurtbox.hurt.connect(_on_hurt.call_deferred)
	_set_hurtable(false) # hidden in the hive: can't be hit
	
func _physics_process(delta: float) -> void:
	if _is_dead or not _awake:
		return

	match _state:
		State.ORBIT:
			position = position.move_toward(_wander_target, wander_speed * delta)
			if position.distance_to(_wander_target) < 1.0:
				_pick_wander_target()
			if hive and hive.is_player_in_range():
				_attack_timer -= delta
				if _attack_timer <= 0.0:
					_start_attack()
		State.ATTACK:
			global_position = global_position.move_toward(_target, dive_speed * delta)
			if global_position.distance_to(_target) < 2.0:
				_end_attack()
		State.RETURN:
			position = position.move_toward(_wander_target, dive_speed * delta)
			if position.distance_to(_wander_target) < 2.0:
				_state = State.ORBIT
				
func wake() -> void:
	if _awake or _is_dead:
		return
	_awake = true
	_pick_wander_target()
	visible = true
	_attack_timer = _next_wait()
	# Fade in instead of popping into view
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	get_tree().create_timer(wake_grace).timeout.connect(_set_hurtable.bind(true))
	
func _pick_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * wander_radius
	# Squashed like the old orbit so it reads right from top-down
	_wander_target = Vector2(cos(angle), sin(angle) * 0.5) * dist
	
func _set_hurtable(on: bool) -> void:
	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring", on)
		hurtbox.set_deferred("monitorable", on)
		
func _find_hive() -> Beehive:
	var node := get_parent()
	while node:
		if node is Beehive:
			return node
		node = node.get_parent()
	return null
	
func _start_attack() -> void:
	if hive == null:
		return
	var player := hive.get_player()
	if player == null:
		return
	_target = player.global_position + Vector2(0, -12) # aim at the body, not the feet
	_state = State.ATTACK
	hitbox.set_deferred("monitorable", true) # only stings while diving

func _end_attack() -> void:
	_state = State.RETURN
	hitbox.set_deferred("monitorable", false)
	_attack_timer = _next_wait()

func _next_wait() -> float:
	return attack_interval + randf() * attack_jitter

func _on_hurt(_other_hitbox: Hitbox) -> void:
	die() # one swat and it's gone

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	hitbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
