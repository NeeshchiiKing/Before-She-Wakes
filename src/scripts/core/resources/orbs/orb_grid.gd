class_name OrbGrid extends Resource
## FFX-style orb grid. Each node has a fixed bonus; an orb activates a node next to one already active.
## Orbs only boost Resource maxes, the 16 combat stats, and crafting. Never Attributes. Placement is permanent.

const RESOURCE_KEYS : Dictionary = {"vit": "vitality", "int": "intelligence", "cha": "charisma", "str": "strength", "dex": "dexterity"}
const STAT_KEYS : Dictionary = {
	"def": &"defense", "poi": &"poise", "mag": &"magic_power", "mac": &"magic_precision",
	"mdf": &"magic_defense", "res": &"status_resistance", "eva": &"evasion", "app": &"status_application",
	"cri": &"crit_chance", "rng": &"range_precision", "atk": &"attack_power", "cdm": &"crit_damage",
	"mov": &"move_speed", "dod": &"dodge_recovery", "spd": &"attack_speed", "mel": &"melee_precision",
}
const CRAFT_KEY : String = "cft" ## Lowers crafting status-tier cost
const DIRECTIONS : Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

## Orbs the player is holding, not yet placed
@export var orbs : int = 0

## One row per line, cells separated by spaces. "." empty, "@" core, "key+N" flat, "key%N" percent.
@export_multiline var layout : String = """
mdf+1 .     mag+1 int+2 mac+1 .     res+1
cri+1 .     .     mag%5 .     .     app+1
rng+1 .     cft+1 int+2 .     .     eva+1
def+1 vit+2 poi+1 @     dex+2 spd+1 mov+1
dod+1 .     .     str+2 cha+2 .     eva%5
.     .     .     atk+1 .     .     .
.     cdm+1 atk%5 mel+1 .     .     .
"""

class OrbNode:
	var cell : Vector2i
	var key : String
	var amount : int
	var is_percent : bool
	var is_start : bool

## Live state during play. The save system will fill `active` later.
var nodes : Dictionary = {} ## Vector2i -> OrbNode
var active : Dictionary = {} ## Vector2i -> true
var _width : int = 0
var _height : int = 0
var _is_set_up : bool = false

func _ensure_set_up() -> void:
	if _is_set_up:
		return
	_is_set_up = true
	var lines := layout.strip_edges().split("\n")
	_height = lines.size()
	for y in lines.size():
		var tokens := lines[y].split(" ", false)
		_width = maxi(_width, tokens.size())
		for x in tokens.size():
			var node := _parse(tokens[x], Vector2i(x, y))
			if node == null:
				continue
			nodes[node.cell] = node
			if node.is_start:
				active[node.cell] = true

func _parse(token: String, cell: Vector2i) -> OrbNode:
	if token == ".":
		return null
	var node := OrbNode.new()
	node.cell = cell
	if token == "@":
		node.is_start = true
		return node
	node.is_percent = token.contains("%")
	var parts := token.split("%" if node.is_percent else "+")
	if parts.size() != 2 or not is_known_key(parts[0]):
		push_warning("OrbGrid: can't read '%s' at %s" % [token, cell])
		return null
	node.key = parts[0]
	node.amount = parts[1].to_int()
	return node

func is_known_key(key: String) -> bool:
	return key in RESOURCE_KEYS or key in STAT_KEYS or key == CRAFT_KEY

func get_size() -> Vector2i:
	_ensure_set_up()
	return Vector2i(_width, _height)

func node_at(cell: Vector2i) -> OrbNode:
	_ensure_set_up()
	return nodes.get(cell)

func is_active(cell: Vector2i) -> bool:
	_ensure_set_up()
	return active.has(cell)

func can_activate(cell: Vector2i) -> bool:
	_ensure_set_up()
	if orbs <= 0 or not nodes.has(cell) or active.has(cell):
		return false
	for direction in DIRECTIONS:
		if active.has(cell + direction):
			return true
	return false

## Places an orb. Permanent. Resource nodes raise the max right away (the new space comes filled).
func activate(cell: Vector2i, stats: Stats) -> bool:
	if not can_activate(cell):
		return false
	orbs -= 1
	active[cell] = true
	var node : OrbNode = nodes[cell]
	if node.key in RESOURCE_KEYS:
		_apply_resource(node, stats)
	emit_changed()
	return true

func _apply_resource(node: OrbNode, stats: Stats) -> void:
	var resource : String = RESOURCE_KEYS[node.key]
	var current_max : int = stats.get("max_" + resource)
	var amount := node.amount
	if node.is_percent:
		amount = ceili(current_max * node.amount / 100.0)
	stats.set("max_" + resource, current_max + amount)
	stats.set(resource, stats.get(resource) + amount)

## Sum of active flat bonuses for a key, e.g. flat_bonus("def")
func flat_bonus(key: String) -> int:
	return _sum(key, false)

## Sum of active percent bonuses for a key, e.g. percent_bonus("atk") -> 5 means +5%
func percent_bonus(key: String) -> int:
	return _sum(key, true)

## How many status tiers crafting costs are reduced by
func crafting_discount() -> int:
	return flat_bonus(CRAFT_KEY)

func _sum(key: String, want_percent: bool) -> int:
	_ensure_set_up()
	var total := 0
	for cell in active:
		var node : OrbNode = nodes[cell]
		if node.key == key and node.is_percent == want_percent:
			total += node.amount
	return total

func describe(node: OrbNode) -> String:
	if node.is_start:
		return "Core: where every path begins"
	var amount_text := ("+%d%%" if node.is_percent else "+%d") % node.amount
	if node.key in RESOURCE_KEYS:
		return "%s Max %s" % [amount_text, String(RESOURCE_KEYS[node.key]).capitalize()]
	if node.key == CRAFT_KEY:
		return "Crafting costs %d fewer status tier" % node.amount
	return "%s %s" % [amount_text, String(STAT_KEYS[node.key]).capitalize()]
