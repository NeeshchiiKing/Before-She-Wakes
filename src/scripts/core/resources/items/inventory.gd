class_name Inventory extends Resource
## Carried items, the equipped bag, and the quick slots (the bag sets how many).

@export var bag_name : String = "Small Bag"
@export var bag_capacity : int = 8 ## Different item types the bag holds
@export var quick_slot_count : int = 2 ## Set by the equipped bag
## What the player starts with. List an item twice to start with 2 of it.
@export var starting_items : Array[ItemDefinition] = []
## Unequipped gear the player starts with
@export var starting_gear : Array[EquipmentDefinition] = []


## Live state during play. The save system fills these later.
var counts : Dictionary = {} ## ItemDefinition -> int
var gear : Array[EquipmentDefinition] = []
var quick_slots : Array[Resource] = [] ## ItemDefinition or AbilityDefinition, null = empty
var _is_set_up : bool = false

func _ensure_set_up() -> void:
	if _is_set_up:
		return
	_is_set_up = true
	for item in starting_items:
		if item != null:
			counts[item] = counts.get(item, 0) + 1
	for item in starting_gear:
		if item != null:
			gear.append(item)
	quick_slots.resize(quick_slot_count)

func get_items() -> Array[ItemDefinition]:
	_ensure_set_up()
	var result : Array[ItemDefinition] = []
	for item in counts:
		result.append(item)
	return result

func count_of(item: ItemDefinition) -> int:
	_ensure_set_up()
	return counts.get(item, 0)

func add(item: ItemDefinition, amount: int = 1) -> void:
	_ensure_set_up()
	counts[item] = count_of(item) + amount
	emit_changed()

func remove(item: ItemDefinition, amount: int = 1) -> bool:
	if count_of(item) < amount:
		return false
	counts[item] = count_of(item) - amount
	if counts[item] <= 0:
		counts.erase(item)
	emit_changed()
	return true

## Heals, then worsens the status tier. Blocked once that Resource is at its worst tier.
func use(item: ItemDefinition, stats: Stats) -> bool:
	if count_of(item) <= 0 or stats.is_worst_status(item.heals):
		return false
	var maximum : int = stats.get("max_" + item.heals)
	stats.set(item.heals, mini(stats.get(item.heals) + item.heal_amount, maximum))
	stats.worsen_status(item.heals, item.tier_cost)
	remove(item)
	return true

func get_quick_slot(index: int) -> Resource:
	_ensure_set_up()
	if index < 0 or index >= quick_slots.size():
		return null
	return quick_slots[index]

## Puts an item or spell in a slot. Anything can only sit in one slot at a time.
func set_quick_slot(index: int, thing: Resource) -> void:
	_ensure_set_up()
	if index < 0 or index >= quick_slots.size():
		return
	for i in quick_slots.size():
		if quick_slots[i] == thing:
			quick_slots[i] = null
	quick_slots[index] = thing
	emit_changed()

func clear_quick_slot(index: int) -> void:
	set_quick_slot(index, null)

## Equipping a different bag calls this
func set_quick_slot_count(count: int) -> void:
	_ensure_set_up()
	quick_slot_count = count
	quick_slots.resize(count)
	emit_changed()
	
func get_gear() -> Array[EquipmentDefinition]:
	_ensure_set_up()
	return gear

func add_gear(item: EquipmentDefinition) -> void:
	_ensure_set_up()
	gear.append(item)
	emit_changed()

func remove_gear(item: EquipmentDefinition) -> void:
	_ensure_set_up()
	gear.erase(item)
	emit_changed()

## The equipped bag decides name, capacity and quick slot count
func apply_bag(bag: EquipmentDefinition) -> void:
	if bag.bag_quick_slots <= 0:
		push_warning("Bag '%s' has 0 Bag Quick Slots. Set it in the bag's .tres (Bag group)." % bag.display_name)
	bag_name = bag.display_name
	bag_capacity = bag.bag_capacity
	set_quick_slot_count(bag.bag_quick_slots)

## True if the bag has room. Items you already carry always stack; a new kind needs a free space.
func can_add(item: ItemDefinition) -> bool:
	_ensure_set_up()
	return counts.has(item) or counts.size() < bag_capacity
