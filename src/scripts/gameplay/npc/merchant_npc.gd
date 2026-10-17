class_name MerchantNPC extends NPC

@export var stock: Array[ShopEntry] = []


func get_price(index: int) -> int:
	return stock[index].price


func is_sold_out(index: int) -> bool:
	var flag := stock[index].sold_out_flag
	return flag != "" and GameState.has_flag(flag)


func can_afford(index: int) -> bool:
	var wallet := _get_wallet()
	if wallet == null:
		return false
	var entry := stock[index]
	return wallet.can_afford(StringName(entry.currency.id), entry.price)


func buy(index: int) -> bool:
	var inventory := _get_inventory()
	var wallet := _get_wallet()
	if inventory == null or wallet == null or is_sold_out(index) or not can_afford(index):
		return false
	var entry := stock[index]
	var currency := StringName(entry.currency.id)

	if entry.item is EquipmentDefinition:
		wallet.spend(currency, entry.price)
		inventory.add_gear(entry.item)
	elif entry.item is ItemDefinition:
		if not inventory.can_add(entry.item):
			return false
		wallet.spend(currency, entry.price)
		inventory.add(entry.item)
	else:
		push_error("%s: stock item %d is not an item or gear" % [npc_name, index])
		return false

	if entry.sold_out_flag != "":
		GameState.set_flag(entry.sold_out_flag)
	return true


func _get_player() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Merchant can't find the player")
	return player


func _get_inventory() -> Inventory:
	var player := _get_player()
	if player == null or not "inventory" in player:
		push_error("Merchant can't find player.inventory")
		return null
	return player.inventory


func _get_wallet() -> Wallet:
	var player := _get_player()
	if player == null or not "wallet" in player:
		push_error("Merchant can't find player.wallet")
		return null
	return player.wallet

## "Pouch - 10 Paper", shown as a shop option in dialogue
func get_listing(index: int) -> String:
	var entry := stock[index]
	return "%s - %d %s" % [entry.item.display_name, entry.price, entry.currency.display_name]


func get_currency_name(index: int) -> String:
	return stock[index].currency.display_name
