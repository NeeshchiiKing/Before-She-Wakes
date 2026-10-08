class_name Player extends CharacterBody2D

const SPEED = 100.00
const ROLL_SPEED = 125
const SNEAK_SPEED = 20
const DIGGING_SPEED = 40.0
var _throw_cooldown : float = 0.0
var _spell_cooldown : float = 0.0

var is_digging : bool = false ## True while the menu is open during combat

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

@export var attack_cost : int = 0 ## Strength per swing. Bare hands are free; weapons will add their own cost
@export var roll_cost   : int = 1 ## Dexterity spent per dodge roll
@export var sneak_cost  : int = 1 ## Charisma spent to start sneaking


@export var character_name : String = "Coren"
@export var stats: Stats
@export var attributes : Attributes
@export var level_data : LevelData
@export var resource_points_per_level : int = 3
@export var orb_grid : OrbGrid
@export var tools  : AbilityBook
@export var spells : AbilityBook
@export var inventory : Inventory
@export var equipment : Equipment
@export var wallet : Wallet


#############################################################################################33

func _ready():
	
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_vitality.connect(die)
	level_data.leveled_up.connect(_on_leveled_up)
	equipment.changed.connect(_on_equipment_changed)
	_on_equipment_changed()


func _physics_process(_delta: float) -> void:
	_throw_cooldown = maxf(_throw_cooldown - _delta, 0.0)
	_spell_cooldown = maxf(_spell_cooldown - _delta, 0.0)
	var state = playback.get_current_node()
	match state:
		"MoveState": move_state(_delta)
		"AttackState": pass
		"DefendState": pass
		"RollState": roll_state(_delta)
		"SneakState": sneak_state(_delta)
	
func _unhandled_input(event: InputEvent) -> void:
	for i in 4:
		if event.is_action_pressed("quick_%d" % (i + 1)):
			use_quick_slot(i)

######Health################################

func take_hit(other_hitbox : Hitbox) -> void:
	stats.vitality -= other_hitbox.damage
	blink_animation.play("blink")
	
func die() -> void:
	hide()
	remove_from_group("player")
	process_mode = Node.PROCESS_MODE_DISABLED

######MoveState################################

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
		_try_attack()
		
	if Input.is_action_just_pressed("defend"):
		playback.travel("DefendState")
		
	if Input.is_action_just_pressed("roll"):
		_try_roll()
		
	if Input.is_action_just_pressed("throw"):
		throw()
		
	if Input.is_action_just_pressed("sneak"):
		_try_sneak()
		
	velocity = input_vector * (DIGGING_SPEED if is_digging else SPEED)
		
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
		_try_attack()
		
	if Input.is_action_just_pressed("defend"):
		playback.travel("DefendState")
		
	if Input.is_action_just_pressed("roll"):
		_try_roll()
		
	if Input.is_action_just_pressed("throw"):
		throw()
		
	velocity = input_vector * SNEAK_SPEED
	move_and_slide()

func _try_attack() -> void:
	if stats.try_spend(&"strength", attack_cost):
		playback.travel("AttackState")

func _try_roll() -> void:
	if stats.is_worst_status(&"dexterity"):
		return # Encumbered: dodge roll disabled
	if stats.try_spend(&"dexterity", roll_cost):
		playback.travel("RollState")

func _try_sneak() -> void:
	if stats.try_spend(&"charisma", sneak_cost):
		is_sneaking = true
		playback.travel("SneakState")
######Leveling################################

func gain_experience(amount: int) -> void:
	level_data.add_experience(amount)

func _on_leveled_up(new_level: int) -> void:
	attributes.add_points(1)
	stats.add_points(resource_points_per_level)
	print("Level %d! Attribute points: %d, Resource points: %d" % [
		new_level, attributes.unspent_points, stats.unspent_points])
		
		
## True if any enemy has the player in range
func is_in_combat() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("is_player_in_range") and enemy.is_player_in_range():
			return true
	return false
	
######QuickSlots,Items,Spells################################
	
func use_quick_slot(index: int) -> void:
	var thing := inventory.get_quick_slot(index)
	if thing is ItemDefinition:
		use_item(thing as ItemDefinition)
	elif thing is AbilityDefinition:
		cast_spell(thing as AbilityDefinition)

func use_item(item: ItemDefinition) -> void:
	if not inventory.use(item, stats):
		print("Can't use %s right now" % item.display_name)

func cast_spell(spell: AbilityDefinition) -> void:
	var tier := spells.tier_of(spell)
	if _spell_cooldown > 0.0:
		return
	if stats.intelligence < spell.cast_cost:
		print("Not enough Intelligence for %s" % spell.name_at(tier))
		return
	stats.intelligence -= spell.cast_cost
	_spell_cooldown = spell.cooldown

	if spell.projectile_scene == null:
		print("Cast %s" % spell.name_at(tier)) # FUTURE (spells): utility effects like Light
		return
	var hit_damage := spell.damage_at(tier) + CombatStats.total(attributes, orb_grid, equipment, &"magic_power")
	_launch(spell.projectile_scene, spell.projectile_speed, spell.projectile_range, hit_damage)

func describe_quick(thing: Resource) -> String:
	if thing is ItemDefinition:
		var item := thing as ItemDefinition
		return "%s x%d" % [item.short_name, inventory.count_of(item)]
	if thing is AbilityDefinition:
		var spell := thing as AbilityDefinition
		return spell.name_at(spells.tier_of(spell))
	return "empty"
	
## Picture for a quick slot, shared by the HUD and the menu
func quick_icon(thing: Resource) -> Texture2D:
	if thing is ItemDefinition:
		return (thing as ItemDefinition).icon
	if thing is AbilityDefinition:
		return (thing as AbilityDefinition).icon
	return null

func can_use_quick(thing: Resource) -> bool:
	if thing is ItemDefinition:
		var item := thing as ItemDefinition
		return inventory.count_of(item) > 0 and not stats.is_worst_status(item.heals)
	if thing is AbilityDefinition:
		return stats.intelligence >= (thing as AbilityDefinition).cast_cost
	return false

######Equipment&Throwing######################################

func _on_equipment_changed() -> void:
	if equipment.bag != null:
		inventory.apply_bag(equipment.bag)

## Equip from the bag. Whatever was in that slot goes back into the bag.
func equip_from_inventory(item: EquipmentDefinition) -> void:
	if not item.meets_requirement(attributes):
		return
	inventory.remove_gear(item)
	var old := equipment.equip(item)
	if old != null:
		inventory.add_gear(old)

## The bag can be swapped but never taken off
func unequip_to_inventory(slot: String) -> void:
	if slot == "bag":
		return
	var old := equipment.unequip(slot)
	if old != null:
		inventory.add_gear(old)

func throw() -> void:
	var weapon := equipment.throwing
	if weapon == null or weapon.projectile_scene == null or _throw_cooldown > 0.0:
		return
	if weapon.use_cost_resource != "none":
		var current : int = stats.get(weapon.use_cost_resource)
		if current < weapon.use_cost:
			return
		stats.set(weapon.use_cost_resource, current - weapon.use_cost)
	_throw_cooldown = weapon.cooldown

	var hit_damage := weapon.damage + CombatStats.total(attributes, orb_grid, equipment, &"attack_power")
	_launch(weapon.projectile_scene, weapon.throw_speed, weapon.throw_range, hit_damage)

## Spawns a projectile at chest height, flying the way the player faces
func _launch(scene: PackedScene, speed: float, max_range: float, hit_damage: int) -> void:
	var projectile := scene.instantiate() as Projectile
	projectile.setup(last_input_vector.normalized(), speed, max_range, hit_damage)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(0, -30) # chest height

######Camera&Animation#####################

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
