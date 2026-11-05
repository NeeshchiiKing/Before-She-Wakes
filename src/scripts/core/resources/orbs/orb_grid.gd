class_name OrbGrid extends Resource
## FFX-style orb grid. Orbs fill stat nodes, Cores fill keystones, perk orbs fill perk sockets.
## You can only fill a node next to one that's already lit. A seal lets you through once one of its
## branch's two Attributes reaches seal_threshold. Orbs only boost Resource maxes, the 16 combat stats
## and crafting. Never Attributes. Placement is permanent.

const RESOURCE_KEYS : Dictionary = {"vit": "vitality", "int": "intelligence", "cha": "charisma", "str": "strength", "dex": "dexterity"}
const STAT_KEYS : Dictionary = {
	"def": &"defense", "poi": &"poise", "mag": &"magic_power", "mac": &"magic_precision",
	"mdf": &"magic_defense", "res": &"status_resistance", "eva": &"evasion", "app": &"status_application",
	"cri": &"crit_chance", "rng": &"range_precision", "atk": &"attack_power", "cdm": &"crit_damage",
	"mov": &"move_speed", "dod": &"dodge_recovery", "spd": &"attack_speed", "mel": &"melee_precision",
}
const CRAFT_KEY : String = "cft" ## Lowers crafting status-tier cost
const DIRECTIONS : Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

const BRANCH_NAMES : Dictionary = {"mig": "Might", "sur": "Survival", "arc": "Arcana", "tri": "Trickery", "con": "Conditioning"}
## The two Attributes that open each branch's seal
const BRANCH_SEALS : Dictionary = {
	"mig": [&"stamina", &"power"], "sur": [&"fortitude", &"endurance"], "arc": [&"wisdom", &"willpower"],
	"tri": [&"guile", &"agility"], "con": [&"perception", &"reflexes"],
}
## Which branch each bonus key belongs to. Only used for colours. cft has none.
const KEY_BRANCH : Dictionary = {
	"str": "mig", "atk": "mig", "cdm": "mig", "poi": "mig",
	"vit": "sur", "def": "sur", "mov": "sur",
	"int": "arc", "mag": "arc", "mac": "arc", "mdf": "arc", "res": "arc",
	"cha": "tri", "eva": "tri", "app": "tri", "spd": "tri", "mel": "tri",
	"dex": "con", "cri": "con", "rng": "con", "dod": "con",
}

enum Kind { CORE, STAT, KEYSTONE, SOCKET, SEAL }
enum SocketTier { INNER, OUTER, CAPSTONE, BRIDGE }

## Orbs the player is holding, not yet placed. Fill stat nodes.
@export var orbs : int = 0
## Cores the player is holding (boss rewards). Fill keystones.
@export var cores : int = 0
## Attribute level that opens a seal (either of the branch's two Attributes)
@export var seal_threshold : int = 5
## Perk orbs to start with, for testing. Found perks get added with gain_perk().
@export var starting_perks : Array[PerkDefinition] = []

## One row per line, cells separated by spaces. Nodes link to the nodes directly above, below, left and right.
## "."        empty
## "@"        the core, where every path starts
## "key+N"    flat bonus, e.g. atk+2 or vit+10. "key%N" is a percent bonus.
## "key+N!"   keystone: same bonus, but needs a Core instead of an Orb
## "S:mig"    seal for a branch (mig sur arc tri con)
## "P1:mig"   inner perk socket, "P2:mig" outer (past the seal), "P3:mig" capstone
## "PW:mig:sur" bridge socket: takes Inner perks from either branch
@export_multiline var layout : String = """
.      .      .      .      .      .      .      .      .      .      P3:mig .      .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      .      cdm+4  atk%10! poi+4  .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      .      atk+4  .      poi+4  .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      P2:mig cdm+4  str+15 poi+4  P2:mig .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      .      .      S:mig  .      .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      .      atk+2  cft+1! poi+2  .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      .      cdm+2  .      poi+2  .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      .      P1:mig atk+2  str+10 poi+2  P1:mig .      .      .      .      .      .      .      .
.      .      .      P2:con .      .      .      P1:con .      .      str+5  .      .      P1:sur .      .      .      P2:sur .      .      .
.      dod+4  dod+4  dod+4  .      dod+2  dod+2  dod+2  .      .      str+5  .      .      def+2  def+2  def+2  .      def+4  def+4  def+4  .
P3:con cri%10! .      dex+15 S:con  cft+1! .      dex+10 dex+5  dex+5  @      vit+5  vit+5  vit+10 .      cft+1! S:sur  vit+15 .      def%10! P3:sur
.      rng+4  cri+4  rng+4  .      cri+2  rng+2  cri+2  .      .      cha+5  .      .      mov+2  mov+2  mov+2  .      mov+4  mov+4  mov+4  .
.      .      .      P2:con .      .      .      P1:con .      .      int+5  .      .      P1:sur .      .      .      P2:sur .      .      .
.      .      .      .      .      .      .      .      .      .      cha+5  .      .      .      .      .      .      .      .      .      .
.      .      .      .      .      .      .      cha+5  cha+5  cha+5  int+5  int+5  int+5  int+5  .      .      .      .      .      .      .
.      .      .      .      .      .      .      cha+5  .      .      .      .      .      int+5  .      .      .      .      .      .      .
.      .      .      .      .      P1:tri spd+2  cha+10 eva+2  P1:tri .      P1:arc mdf+2  int+10 mag+2  P1:arc .      .      .      .      .
.      .      .      .      .      .      mel+2  .      app+2  .      .      .      res+2  .      mac+2  .      .      .      .      .      .
.      .      .      .      .      .      spd+2  cft+1! eva+2  .      .      .      mdf+2  cft+1! mag+2  .      .      .      .      .      .
.      .      .      .      .      .      .      S:tri  .      .      .      .      .      S:arc  .      .      .      .      .      .      .
.      .      .      .      .      P2:tri mel+4  cha+15 app+4  P2:tri .      P2:arc res+4  int+15 mac+4  P2:arc .      .      .      .      .
.      .      .      .      .      .      spd+4  .      eva+4  .      .      .      mdf+4  .      mag+4  .      .      .      .      .      .
.      .      .      .      .      .      mel+4  eva%10! app+4  .      .      .      res+4  mag%10! mac+4  .      .      .      .      .      .
.      .      .      .      .      .      .      P3:tri .      .      .      .      .      P3:arc .      .      .      .      .      .      .
"""

class OrbNode:
	var cell : Vector2i
	var kind : int ## OrbGrid.Kind
	var key : String = ""
	var amount : int = 0
	var is_percent : bool = false
	var branch : String = "" ## For sockets and seals; stat nodes take it from KEY_BRANCH
	var branches : Array[String] = [] ## Bridge sockets only
	var socket_tier : int = 0 ## OrbGrid.SocketTier

## Live state during play. The save system will fill these later.
var nodes : Dictionary = {} ## Vector2i -> OrbNode
var active : Dictionary = {} ## Vector2i -> true. The core, filled nodes and filled sockets.
var installed : Dictionary = {} ## Vector2i -> PerkDefinition
var held_perks : Array[PerkDefinition] = [] ## Perk orbs found but not installed yet
var _width : int = 0
var _height : int = 0
var _is_set_up : bool = false

func _ensure_set_up() -> void:
	if _is_set_up:
		return
	_is_set_up = true
	held_perks = starting_perks.duplicate()
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
			if node.kind == Kind.CORE:
				active[node.cell] = true

func _parse(token: String, cell: Vector2i) -> OrbNode:
	if token == ".":
		return null
	var node := OrbNode.new()
	node.cell = cell
	if token == "@":
		node.kind = Kind.CORE
		return node
	if token.begins_with("S:") or token.begins_with("P"):
		return _parse_special(token, node)
	node.kind = Kind.STAT
	if token.ends_with("!"):
		node.kind = Kind.KEYSTONE
		token = token.trim_suffix("!")
	node.is_percent = token.contains("%")
	var parts := token.split("%" if node.is_percent else "+")
	if parts.size() != 2 or not is_known_key(parts[0]):
		push_warning("OrbGrid: can't read '%s' at %s" % [token, cell])
		return null
	node.key = parts[0]
	node.amount = parts[1].to_int()
	node.branch = KEY_BRANCH.get(node.key, "")
	return node

func _parse_special(token: String, node: OrbNode) -> OrbNode:
	var parts := token.split(":")
	for i in range(1, parts.size()):
		if parts[i] not in BRANCH_NAMES:
			push_warning("OrbGrid: unknown branch in '%s' at %s" % [token, node.cell])
			return null
	match parts[0]:
		"S":
			node.kind = Kind.SEAL
		"P1":
			node.kind = Kind.SOCKET
			node.socket_tier = SocketTier.INNER
		"P2":
			node.kind = Kind.SOCKET
			node.socket_tier = SocketTier.OUTER
		"P3":
			node.kind = Kind.SOCKET
			node.socket_tier = SocketTier.CAPSTONE
		"PW":
			node.kind = Kind.SOCKET
			node.socket_tier = SocketTier.BRIDGE
		_:
			push_warning("OrbGrid: can't read '%s' at %s" % [token, node.cell])
			return null
	var needed := 3 if node.socket_tier == SocketTier.BRIDGE and node.kind == Kind.SOCKET else 2
	if parts.size() != needed:
		push_warning("OrbGrid: '%s' at %s needs %d parts" % [token, node.cell, needed])
		return null
	node.branch = parts[1]
	for i in range(1, parts.size()):
		node.branches.append(parts[i])
	return node

func is_known_key(key: String) -> bool:
	return key in RESOURCE_KEYS or key in STAT_KEYS or key == CRAFT_KEY

func get_size() -> Vector2i:
	_ensure_set_up()
	return Vector2i(_width, _height)

func node_at(cell: Vector2i) -> OrbNode:
	_ensure_set_up()
	return nodes.get(cell)

func core_cell() -> Vector2i:
	_ensure_set_up()
	for cell in nodes:
		if nodes[cell].kind == Kind.CORE:
			return cell
	return Vector2i.ZERO

func is_active(cell: Vector2i) -> bool:
	_ensure_set_up()
	return active.has(cell)

func is_seal_open(node: OrbNode, attributes: Attributes) -> bool:
	if attributes == null or node.kind != Kind.SEAL:
		return false
	for attribute in BRANCH_SEALS[node.branch]:
		if attributes.get(attribute) >= seal_threshold:
			return true
	return false

## Every node the player has reached: the core, filled nodes, and open seals connected to them
func lit_cells(attributes: Attributes) -> Dictionary:
	_ensure_set_up()
	var core := core_cell()
	var lit : Dictionary = {core: true}
	var queue : Array[Vector2i] = [core]
	while not queue.is_empty():
		var cell : Vector2i = queue.pop_front()
		for direction in DIRECTIONS:
			var next := cell + direction
			if lit.has(next) or not nodes.has(next):
				continue
			if active.has(next) or is_seal_open(nodes[next], attributes):
				lit[next] = true
				queue.append(next)
	return lit

## True if this node is empty and sits next to a lit node, so something can go in it now
func is_reachable(cell: Vector2i, attributes: Attributes) -> bool:
	_ensure_set_up()
	var node : OrbNode = nodes.get(cell)
	if node == null or active.has(cell) or node.kind == Kind.SEAL or node.kind == Kind.CORE:
		return false
	var lit := lit_cells(attributes)
	for direction in DIRECTIONS:
		if lit.has(cell + direction):
			return true
	return false

func can_activate(cell: Vector2i, attributes: Attributes) -> bool:
	var node := node_at(cell)
	if node == null or not is_reachable(cell, attributes):
		return false
	if node.kind == Kind.STAT:
		return orbs > 0
	if node.kind == Kind.KEYSTONE:
		return cores > 0
	return false

## Places an Orb or Core. Permanent. Resource nodes raise the max right away (the new space comes filled).
func activate(cell: Vector2i, stats: Stats, attributes: Attributes) -> bool:
	if not can_activate(cell, attributes):
		return false
	var node : OrbNode = nodes[cell]
	if node.kind == Kind.KEYSTONE:
		cores -= 1
	else:
		orbs -= 1
	active[cell] = true
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

# --- Perks ---

func fits(node: OrbNode, perk: PerkDefinition) -> bool:
	if node == null or node.kind != Kind.SOCKET or perk == null:
		return false
	match node.socket_tier:
		SocketTier.BRIDGE:
			return perk.tier == PerkDefinition.Tier.INNER and perk.branch in node.branches
		SocketTier.INNER:
			return perk.branch == node.branch and perk.tier == PerkDefinition.Tier.INNER
		SocketTier.OUTER:
			return perk.branch == node.branch and perk.tier != PerkDefinition.Tier.CAPSTONE
		SocketTier.CAPSTONE:
			return perk.branch == node.branch and perk.tier == PerkDefinition.Tier.CAPSTONE
	return false

## Held perk orbs that could go in this socket
func perks_that_fit(cell: Vector2i) -> Array[PerkDefinition]:
	_ensure_set_up()
	var result : Array[PerkDefinition] = []
	for perk in held_perks:
		if fits(nodes.get(cell), perk):
			result.append(perk)
	return result

func can_install(cell: Vector2i, perk: PerkDefinition, attributes: Attributes) -> bool:
	_ensure_set_up()
	return perk in held_perks and fits(nodes.get(cell), perk) and is_reachable(cell, attributes)

## Puts a held perk orb into a socket. Permanent. A filled socket also lights the path through it.
func install_perk(cell: Vector2i, perk: PerkDefinition, attributes: Attributes) -> bool:
	if not can_install(cell, perk, attributes):
		return false
	held_perks.erase(perk)
	installed[cell] = perk
	active[cell] = true
	emit_changed()
	return true

## Finding a Blueprint or Tome, learning from a Teacher, or finishing a Deed calls this
func gain_perk(perk: PerkDefinition) -> void:
	_ensure_set_up()
	if perk == null or perk in held_perks or perk in installed.values():
		return
	held_perks.append(perk)
	emit_changed()

## Gameplay asks this, e.g. if player.orb_grid.has_perk(&"battering_ram"):
func has_perk(id: StringName) -> bool:
	_ensure_set_up()
	for perk in installed.values():
		if perk.id == id:
			return true
	return false

func gain_orbs(amount: int) -> void:
	orbs += amount
	emit_changed()

func gain_cores(amount: int) -> void:
	cores += amount
	emit_changed()

# --- Bonuses ---

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

# --- Text for the menu ---

func title(node: OrbNode) -> String:
	match node.kind:
		Kind.CORE:
			return "Core"
		Kind.SEAL:
			return "%s Seal" % BRANCH_NAMES[node.branch]
		Kind.SOCKET:
			if installed.has(node.cell):
				return installed[node.cell].display_name
			match node.socket_tier:
				SocketTier.BRIDGE:
					return "%s / %s Bridge Socket" % [BRANCH_NAMES[node.branches[0]], BRANCH_NAMES[node.branches[1]]]
				SocketTier.OUTER:
					return "%s Deep Socket" % BRANCH_NAMES[node.branch]
				SocketTier.CAPSTONE:
					return "%s Capstone Socket" % BRANCH_NAMES[node.branch]
			return "%s Socket" % BRANCH_NAMES[node.branch]
		Kind.KEYSTONE:
			return "Keystone"
	return "Orb Node"

func describe(node: OrbNode) -> String:
	match node.kind:
		Kind.CORE:
			return "Where every path begins"
		Kind.SEAL:
			var names := PackedStringArray()
			for attribute in BRANCH_SEALS[node.branch]:
				names.append(String(attribute).capitalize())
			return "Opens with %s at %d or more" % [" or ".join(names), seal_threshold]
		Kind.SOCKET:
			if installed.has(node.cell):
				return installed[node.cell].description
			match node.socket_tier:
				SocketTier.BRIDGE:
					return "Takes an Inner perk from either branch"
				SocketTier.OUTER:
					return "Takes an Inner or Outer %s perk" % BRANCH_NAMES[node.branch]
				SocketTier.CAPSTONE:
					return "Takes a Capstone %s perk" % BRANCH_NAMES[node.branch]
			return "Takes an Inner %s perk" % BRANCH_NAMES[node.branch]
	var amount_text := ("+%d%%" if node.is_percent else "+%d") % node.amount
	if node.key in RESOURCE_KEYS:
		return "%s Max %s" % [amount_text, String(RESOURCE_KEYS[node.key]).capitalize()]
	if node.key == CRAFT_KEY:
		return "Crafting costs %d fewer status tier" % node.amount
	return "%s %s" % [amount_text, String(STAT_KEYS[node.key]).capitalize()]
