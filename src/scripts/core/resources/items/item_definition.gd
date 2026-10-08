class_name ItemDefinition extends Resource
## A consumable item. Heals one Resource, then pushes that Resource's status tier worse.

@export var display_name : String = "New Item"
@export var icon : Texture2D ## Shown in the menu next to the name
@export var short_name : String = "Item" ## Short enough for a quick slot
@export_enum("vitality", "intelligence", "charisma", "strength", "dexterity") var heals : String = "vitality"
@export var heal_amount : int = 1
@export_range(0, 3) var tier_cost : int = 1 ## Status tiers this costs (raw+raw 1, raw+Processed 2, Processed+Processed 3)
