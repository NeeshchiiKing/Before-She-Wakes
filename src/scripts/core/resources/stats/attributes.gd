class_name Attributes extends Resource
## The 10 static Attributes, raised with points earned on level-up

const MAX_ATTRIBUTE_LEVEL : int = 10
const NAMES : Array[StringName] = [&"fortitude", &"stamina", &"wisdom", &"willpower", &"guile", &"perception", &"power", &"endurance", &"reflexes", &"agility"]

@export_range(0, MAX_ATTRIBUTE_LEVEL) var fortitude  : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var stamina    : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var wisdom     : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var willpower  : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var guile      : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var perception : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var power      : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var endurance  : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var reflexes   : int = 0
@export_range(0, MAX_ATTRIBUTE_LEVEL) var agility    : int = 0

@export var unspent_points : int = 0

func add_points(amount: int) -> void:
	unspent_points += amount
	emit_changed()

func can_raise(attribute: StringName) -> bool:
	if unspent_points <= 0 or attribute not in NAMES:
		return false
	return get(attribute) < MAX_ATTRIBUTE_LEVEL

## Spends 1 point on an attribute. Returns false if it couldn't.
func raise(attribute: StringName) -> bool:
	if not can_raise(attribute):
		return false
	set(attribute, get(attribute) + 1)
	unspent_points -= 1
	emit_changed()
	return true
