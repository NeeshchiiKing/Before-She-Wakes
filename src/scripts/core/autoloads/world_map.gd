extends Node
## The 12x12 world map. Loads every RegionDefinition and remembers which squares you've visited.
## Visited flags live in GameState (like quests), so saving the flags saves the fog of war.

signal changed

const REGION_DIR : String = "res://src/data/regions/"
const GRID_SIZE : int = 12
const NO_SQUARE : Vector2i = Vector2i(-1, -1)

var current_pos : Vector2i = NO_SQUARE

var _regions : Dictionary = {} # Vector2i -> RegionDefinition

func _ready() -> void:
	_load_regions()

func _load_regions() -> void:
	for file in ResourceLoader.list_directory(REGION_DIR):
		if not file.ends_with(".tres"):
			continue
		var region := ResourceLoader.load(REGION_DIR + file) as RegionDefinition
		if region == null:
			push_warning("WorldMap: %s is not a RegionDefinition" % file)
			continue
		if _regions.has(region.grid_pos):
			push_warning("WorldMap: two regions share square %s" % region.label())
		_regions[region.grid_pos] = region

## Called by BaseLevel when a square loads
func visit(pos: Vector2i) -> void:
	if pos == NO_SQUARE:
		return
	current_pos = pos
	GameState.set_flag(_visited_flag(pos))
	changed.emit()

func is_discovered(pos: Vector2i) -> bool:
	return GameState.has_flag(_visited_flag(pos))

## Null when that square has no .tres yet
func get_region(pos: Vector2i) -> RegionDefinition:
	return _regions.get(pos) as RegionDefinition

func _visited_flag(pos: Vector2i) -> String:
	return "visited_%s" % RegionDefinition.grid_label(pos)
