class_name KiraHologram
extends Node2D

## Kira's hologram. She can only exist at a HologramProjector.
## FOLLOW: she jumps to whichever room the player walks into (if it has a projector).
## PINNED: she stays where story code puts her (e.g. sad in the corner).

enum Mode { FOLLOW, PINNED }

@export var start_projector_id: StringName = &"Counter"
@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "start"
## Pause after the player enters a room before Kira follows, so she doesn't feel instant.
@export var follow_delay: float = 0.6
## Length of each half of the flicker-out / flicker-in transition.
@export var transition_time: float = 0.35

var mode: Mode = Mode.FOLLOW
var current_projector: HologramProjector

var _projectors: Dictionary = {}  # StringName -> HologramProjector
var _moving := false
var _pending: HologramProjector
var _follow_target: HologramProjector
var _follow_timer: Timer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _mat: ShaderMaterial = sprite.material as ShaderMaterial


func _ready() -> void:
	_follow_timer = Timer.new()
	_follow_timer.one_shot = true
	_follow_timer.timeout.connect(_on_follow_timer_timeout)
	add_child(_follow_timer)

	# Wait one frame so every projector in the scene has registered itself.
	await get_tree().process_frame
	for p in get_tree().get_nodes_in_group(&"hologram_projectors"):
		var projector := p as HologramProjector
		_projectors[projector.projector_id] = projector
		projector.player_entered_room.connect(_on_player_entered_room)

	snap_to(start_projector_id)
	print("Kira found projectors: ", _projectors.keys())


# --- Public API (story code and dialogue) -----------------------------------

## Place Kira instantly, no transition. Use when loading or setting up a scene.
func snap_to(id: StringName) -> void:
	var target := _get_projector(id)
	if target:
		_place_at(target)


## Move Kira with the flicker transition. Does not change her mode.
func move_to(id: StringName) -> void:
	var target := _get_projector(id)
	if target == null or target == current_projector:
		return
	if _moving:
		_pending = target
		return

	_moving = true
	await _fade(0.0)
	_place_at(target)
	await _fade(1.0)
	_moving = false

	if _pending and _pending != current_projector:
		var next := _pending
		_pending = null
		move_to(next.projector_id)
	_pending = null


## Lock Kira at a projector for a story moment. Returns true so dialogue can call it in an `if`.
func pin_to(id: StringName) -> bool:
	mode = Mode.PINNED
	_follow_timer.stop()
	move_to(id)
	return true


## Let Kira follow the player between rooms again. Returns true for dialogue use.
func unpin() -> bool:
	mode = Mode.FOLLOW
	return true


## CHECK: rename to match whatever your interaction system calls on interactables.
func interact(_interactor: Node = null) -> void:
	if _moving or dialogue_resource == null:
		return
	# Passing self lets dialogue call pin_to()/unpin() via `if pin_to("faith_room")`.
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_title, [self])


# --- Internals --------------------------------------------------------------

func _get_projector(id: StringName) -> HologramProjector:
	var p: HologramProjector = _projectors.get(id)
	if p == null:
		push_warning("KiraHologram: no projector with id '%s'." % id)
	return p


func _place_at(target: HologramProjector) -> void:
	if current_projector:
		current_projector.set_active(false)
	current_projector = target
	global_position = target.get_spawn_position()
	target.set_active(true)
	_play_pose(target)

func _play_pose(target: HologramProjector) -> void:
	sprite.flip_h = target.kira_flip_h
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(target.kira_animation):
		sprite.play(target.kira_animation)
	else:
		push_warning("KiraHologram: no animation '%s' (projector '%s')." % [target.kira_animation, target.projector_id])
		
func _fade(to: float) -> void:
	if _mat == null:
		return
	if to > 0.0:
		_mat.set_shader_parameter("glitch_amount", 1.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(_mat, "shader_parameter/reveal", to, transition_time)
	tw.tween_property(_mat, "shader_parameter/glitch_amount", 1.0 if to == 0.0 else 0.0, transition_time)
	await tw.finished


func _on_player_entered_room(projector: HologramProjector) -> void:
	if mode != Mode.FOLLOW or projector == current_projector:
		return
	_follow_target = projector
	_follow_timer.start(follow_delay)


func _on_follow_timer_timeout() -> void:
	if mode == Mode.FOLLOW and _follow_target:
		move_to(_follow_target.projector_id)
