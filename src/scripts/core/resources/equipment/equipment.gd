class_name Equipment extends Resource
## What the player has equipped. One slot each, except two Accessory slots.

const SLOT_ORDER : Array[String] = ["helmet", "back", "armor", "pants", "gloves", "shoes", "main_hand", "off_hand", "throwing", "arrows", "bag", "accessory_1", "accessory_2"]

@export var helmet      : EquipmentDefinition
@export var back        : EquipmentDefinition
@export var armor       : EquipmentDefinition
@export var pants       : EquipmentDefinition
@export var gloves      : EquipmentDefinition
@export var shoes       : EquipmentDefinition
@export var main_hand   : EquipmentDefinition
@export var off_hand    : EquipmentDefinition
@export var throwing    : EquipmentDefinition
@export var arrows      : EquipmentDefinition
@export var bag         : EquipmentDefinition
@export var accessory_1 : EquipmentDefinition
@export var accessory_2 : EquipmentDefinition

func get_item(slot: String) -> EquipmentDefinition:
	return get(slot)

## Which slot a piece of gear goes in. Accessories fill the first empty one.
func slot_for(item: EquipmentDefinition) -> String:
	if item.slot_type != "accessory":
		return item.slot_type
	if accessory_1 != null and accessory_2 == null:
		return "accessory_2"
	return "accessory_1"

## Puts gear in its slot. Returns whatever was there before (or null).
func equip(item: EquipmentDefinition) -> EquipmentDefinition:
	var slot := slot_for(item)
	var old := get_item(slot)
	set(slot, item)
	emit_changed()
	return old

func unequip(slot: String) -> EquipmentDefinition:
	var old := get_item(slot)
	set(slot, null)
	emit_changed()
	return old

## Total of one combat stat across everything equipped
func total_bonus(stat: StringName) -> int:
	var total := 0
	for slot in SLOT_ORDER:
		var item := get_item(slot)
		if item != null:
			total += item.bonus(stat)
	return total
