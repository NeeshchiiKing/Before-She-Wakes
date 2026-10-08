class_name Wallet extends Resource
## The player's 3 currencies: Paper (old world), Gold (salvaged tech), Runes (magic)

const NAMES : Array[StringName] = [&"paper", &"gold", &"runes"]

@export var paper : int = 0
@export var gold  : int = 0
@export var runes : int = 0

func amount_of(currency: StringName) -> int:
	return get(currency)

## Pickups and quest rewards call this, e.g. player.wallet.add(&"gold", 5)
func add(currency: StringName, amount: int) -> void:
	if currency not in NAMES:
		push_warning("Wallet: unknown currency '%s'" % currency)
		return
	set(currency, amount_of(currency) + amount)
	emit_changed()

func can_afford(currency: StringName, amount: int) -> bool:
	return currency in NAMES and amount_of(currency) >= amount

## Shops and upgrade NPCs call this. Returns false if the player can't pay.
func spend(currency: StringName, amount: int) -> bool:
	if not can_afford(currency, amount):
		return false
	set(currency, amount_of(currency) - amount)
	emit_changed()
	return true
