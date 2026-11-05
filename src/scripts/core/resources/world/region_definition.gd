class_name RegionDefinition extends Resource
## One 1280x1280 square of the 12x12 world. Make one .tres per square in src/data/regions/
## Grid labels: columns A-L (left to right), rows 1-12 (top to bottom). F8 = Pinetop.

enum Kind { AREA, TOWN, BOSS }

@export var grid_pos : Vector2i = Vector2i.ZERO ## Zero-based: column A=0 ... L=11, row 1=0 ... 12=11. F8 is (5, 7)
@export var region_name : String = "" ## What the map shows, e.g. "Forest" or "Pinetop"
@export var kind : Kind = Kind.AREA
@export_group("Contents shown on the map")
@export var enemies : Array[EnemyDefinition] = [] ## Listed for AREA and BOSS squares
@export var npcs : PackedStringArray = PackedStringArray() ## Listed for TOWN squares

## "F8" style label for a grid position
static func grid_label(pos: Vector2i) -> String:
	return "%s%d" % [char(65 + pos.x), pos.y + 1]

func label() -> String:
	return grid_label(grid_pos)
