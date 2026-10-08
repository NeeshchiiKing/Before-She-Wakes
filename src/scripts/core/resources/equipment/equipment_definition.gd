class_name EquipmentDefinition extends Resource
## One piece of gear. Gated by an Attribute level. Bags and throwing weapons use their extra groups.

@export var display_name : String = "New Gear"
@export var icon : Texture2D ## Shown in the menu next to the name
@export_enum("helmet", "back", "armor", "pants", "gloves", "shoes", "main_hand", "off_hand", "throwing", "arrows", "bag", "accessory") var slot_type : String = "armor"

@export_group("Requirement")
@export_enum("none", "fortitude", "stamina", "wisdom", "willpower", "guile", "perception", "power", "endurance", "reflexes", "agility") var required_attribute : String = "none"
@export_range(0, 10) var required_level : int = 0

@export_group("Stats")
## Combat stat -> bonus, e.g. "defense": 1. Keys match the 16 combat stats (snake_case).
@export var stat_bonuses : Dictionary[String, int] = {}

@export_group("Bag")
@export var bag_capacity : int = 0
@export var bag_quick_slots : int = 0

@export_group("Throwing")
@export var projectile_scene : PackedScene
@export var damage : int = 1
@export var throw_speed : float = 180.0
@export var throw_range : float = 120.0
@export var cooldown : float = 0.6 ## Seconds between throws
@export_enum("none", "vitality", "intelligence", "charisma", "strength", "dexterity") var use_cost_resource : String = "none"
@export var use_cost : int = 0

func meets_requirement(attributes: Attributes) -> bool:
	if required_attribute == "none":
		return true
	return attributes.get(required_attribute) >= required_level

func requirement_text() -> String:
	if required_attribute == "none":
		return "No requirement"
	return "Needs %s %d" % [required_attribute.capitalize(), required_level]

func bonus(stat: StringName) -> int:
	return stat_bonuses.get(String(stat), 0)

func bonus_text() -> String:
	var parts : Array[String] = []
	for stat in stat_bonuses:
		parts.append("%s +%d" % [stat.capitalize(), stat_bonuses[stat]])
	return ", ".join(parts)
