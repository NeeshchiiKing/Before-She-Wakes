class_name AbilityDefinition extends Resource
## One Tool or Spell. Each tier has its own name. Upgrading needs an Attribute level, checked by the NPC.

## Name per tier, e.g. ["Light", "Sunlight"]
@export var tier_names : Array[String] = ["New Ability"]
## What each tier does, same order as tier_names
@export var tier_descriptions : Array[String] = [""]
## Attribute an NPC checks before upgrading this
@export var upgrade_attribute : StringName = &"wisdom"
## Attribute level needed to upgrade INTO each tier. The first entry (base tier) is ignored.
@export var tier_requirements : Array[int] = [0]
## Intelligence spent per cast (spells only)
@export var icon : Texture2D ## Shown on quick slots


@export_group("Combat")
## Leave empty for utility spells (Light, Unlock...). Set it for attack spells.
@export var projectile_scene : PackedScene
## Base damage per tier, same order as tier_names
@export var tier_damage : Array[int] = [1]
@export var projectile_speed : float = 200.0
@export var projectile_range : float = 160.0
@export var cooldown : float = 0.8 ## Seconds between casts
@export var cast_cost : int = 0

func max_tier() -> int:
	return tier_names.size()

func name_at(tier: int) -> String:
	return tier_names[clampi(tier, 1, max_tier()) - 1]

func description_at(tier: int) -> String:
	if tier >= 1 and tier <= tier_descriptions.size():
		return tier_descriptions[tier - 1]
	return ""

func requirement_for(tier: int) -> int:
	if tier >= 1 and tier <= tier_requirements.size():
		return tier_requirements[tier - 1]
	return 0

func damage_at(tier: int) -> int:
	if tier >= 1 and tier <= tier_damage.size():
		return tier_damage[tier - 1]
	return 0
