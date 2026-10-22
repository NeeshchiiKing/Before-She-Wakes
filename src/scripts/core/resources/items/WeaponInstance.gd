class_name WeaponInstance
extends Resource

@export var data: WeaponData
@export var prefix: String = ""
@export var suffix: String = ""
@export var element: WeaponData.Element = WeaponData.Element.NONE
@export var durability: int = 0
@export var rolled_stats: Dictionary = {}      # e.g. {"atk_power": 4, "crit_chance": 2}


func spend_durability() -> void:
	durability = maxi(durability - data.durability_per_swing, 0)
	emit_changed()   # the player listens to this to refresh the sprite

func current_texture() -> Texture2D:
	if is_broken() and data.texture_broken != null:
		return data.texture_broken
	var fraction := float(durability) / float(data.max_durability)
	if fraction <= data.damaged_threshold and data.texture_damaged != null:
		return data.texture_damaged
	return data.texture
func is_broken() -> bool:
	return durability <= 0
