class_name AbilityBook extends Resource
## Tools or Spells the player owns, and each one's tier. Owned = usable, no equipping.

## What the player starts the game with (all at tier 1). Set these in the Inspector.
@export var starting_abilities : Array[AbilityDefinition] = []

## Live state during play: ability -> tier. Built from starting_abilities; the save system fills it later.
var owned : Dictionary = {}
var _is_set_up : bool = false

func _ensure_set_up() -> void:
	if _is_set_up:
		return
	_is_set_up = true
	for ability in starting_abilities:
		if ability != null:
			owned[ability] = 1

func get_owned() -> Array[AbilityDefinition]:
	_ensure_set_up()
	var result : Array[AbilityDefinition] = []
	for ability in owned:
		result.append(ability)
	return result

func has(ability: AbilityDefinition) -> bool:
	_ensure_set_up()
	return owned.has(ability)

func tier_of(ability: AbilityDefinition) -> int:
	_ensure_set_up()
	return owned.get(ability, 0)

## Finding a scroll or tool calls this
func learn(ability: AbilityDefinition) -> void:
	_ensure_set_up()
	if not has(ability):
		owned[ability] = 1
		emit_changed()

## Obstacles call this, e.g. a Degree 2 fallen tree needs Burn at tier 2 or higher
func can_solve(ability: AbilityDefinition, required_tier: int) -> bool:
	return tier_of(ability) >= required_tier

func can_upgrade(ability: AbilityDefinition, attributes: Attributes) -> bool:
	var next := tier_of(ability) + 1
	if not has(ability) or next > ability.max_tier():
		return false
	return attributes.get(ability.upgrade_attribute) >= ability.requirement_for(next)

## Upgrade NPCs (Wizard, Blacksmith...) call this after taking payment
func upgrade(ability: AbilityDefinition, attributes: Attributes) -> bool:
	if not can_upgrade(ability, attributes):
		return false
	owned[ability] = tier_of(ability) + 1
	emit_changed()
	return true
