class_name Beehive extends Node2D
## A hive full of bees. Hit it and the bees attack every few seconds until the hive falls,
## breaks open and leaves its loot (honey) on the ground.
const BEE_SCENE := preload("res://src/scenes/enemies/bees.tscn") 

@onready var sprite : Sprite2D = $Sprite2D

var _sprite_home : Vector2
var _shake_tween : Tween

@export var stats : Stats
@export var bee_count : int = 4
@export var loot : LootTable
@export var experience_reward : int = 5
@export var aggro_range : float = 300.0 ## Bees stop attacking if the player gets this far away
@export var fall_distance : float = 40.0 ## How far the hive drops before breaking open

@onready var hurtbox : Hurtbox = $Hurtbox
@onready var bees : Node2D = $Bees


var is_angry : bool = false
var _is_dead : bool = false
	
func _ready() -> void:

	stats = stats.duplicate() # every hive gets its own health
	add_to_group("enemies")
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_vitality.connect(die)
	for i in bee_count:
		var bee := BEE_SCENE.instantiate()
		bees.add_child(bee)
	_sprite_home = sprite.position
	
func take_hit(other_hitbox: Hitbox) -> void:
	if _is_dead:
		return
	_wake_bees()
	_shake()
	is_angry = true
	stats.vitality -= other_hitbox.damage
	
func _wake_bees() -> void:
	if not is_instance_valid(bees):
		return
	bees.visible = true
	for bee in bees.get_children():
		if bee is Bee:
			bee.wake()
			
func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player

## Bees use this to decide when to attack. It also makes the live menu treat an angry hive as combat.
func is_player_in_range() -> bool:
	var player := get_player()
	if not is_angry or player == null:
		return false
	return global_position.distance_to(player.global_position) < aggro_range

## Quick side-to-side shake plus a white flash so the player knows the hit landed.
func _shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
	sprite.position = _sprite_home
	sprite.modulate = Color(1.8, 1.8, 1.8) # flash bright
	_shake_tween = create_tween()
	_shake_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	var hits := 5
	for i in hits:
		var strength := 3.0 * (1.0 - float(i) / hits) # each wobble a little smaller
		var side := 1.0 if i % 2 == 0 else -1.0
		_shake_tween.chain().tween_property(sprite, "position", _sprite_home + Vector2(strength * side, 0), 0.04)
	_shake_tween.chain().tween_property(sprite, "position", _sprite_home, 0.04)

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	is_angry = false
	hurtbox.set_deferred("monitoring", false)
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	if is_instance_valid(bees):
		for bee in bees.get_children():
			if bee is Bee:
				bee.die()

	var player := get_player()
	if player != null:
		player.gain_experience(experience_reward)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + fall_distance, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self, "rotation", 0.4, 0.6) # tips over as it falls
	tween.tween_callback(_break_open)

func _break_open() -> void:
	if loot != null:
		loot.drop(global_position, get_parent())
	queue_free()
