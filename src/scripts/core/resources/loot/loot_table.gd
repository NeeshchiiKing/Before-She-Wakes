class_name LootTable extends Resource
## What an enemy can drop. Each entry rolls on its own, so one kill can drop several things.

@export var pickup_scene : PackedScene ## world_pickup.tscn
@export var entries : Array[LootEntry] = []

## Rolls every entry and spawns pickups around a spot
func drop(at: Vector2, parent: Node2D) -> void:
	if pickup_scene == null:
		push_warning("LootTable has no Pickup Scene set")
		return
	for entry in entries:
		if entry == null or entry.item == null:
			continue
		if randf() > entry.chance:
			continue
		var pickup := pickup_scene.instantiate() as WorldPickup
		pickup.item = entry.item
		pickup.amount = randi_range(entry.min_amount, entry.max_amount)
		var scatter := Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
		pickup.position = parent.to_local(at + scatter)
		parent.add_child.call_deferred(pickup)
