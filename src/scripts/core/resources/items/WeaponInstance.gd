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

func is_broken() -> bool:
	return durability <= 0
