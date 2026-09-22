extends Node2D

#const GRASS_EFFECT = preload("res://scenes/effects/grass_effect.tscn")
#hold control to get an onready var also this GRASS_EFFECT IS HARD CODED IF WE MOVE THE TSCN WE ARE SCREWED

@export var GRASS_EFFECT: PackedScene
#grasseffect now is a type which ":" means is type 

@onready var hurtbox: Hurtbox = $Hurtbox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#hurt is the area_entered
	hurtbox.hurt.connect(_on_hurt)

func _on_hurt(_other_hitbox: Hitbox) -> void:
	var grass_effect_instance = GRASS_EFFECT.instantiate()
	get_tree().current_scene.add_child(grass_effect_instance)
	#need instance to be at global position where it is destroyed
	grass_effect_instance.global_position = global_position
	queue_free()
	
	#dynamic instance means to run something while the game is running
