class_name Hurtbox extends Area2D

signal hurt(hitbox: Hitbox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area_2D: Area2D) -> void:
	if area_2D is not Hitbox: return
	hurt.emit(area_2D)
