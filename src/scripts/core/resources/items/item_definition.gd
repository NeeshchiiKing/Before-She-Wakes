class_name ItemDefinition extends Resource
## A consumable item. Heals one Resource, then pushes that Resource's status tier worse.

## What the player sees. Change freely: "Crow Feather", "Phoenix Feather"...
@export var display_name : String = "New Item"
## Shorter text for quick slots (about 10 letters). Change freely.
@export var short_name : String = "Item"
@export var icon : Texture2D
@export var world_sprite : Texture2D ## Small picture when lying in the world (12x12). Empty = uses the icon
@export_enum("base", "processed", "crafted") var kind : String = "base"
## What crafting treats this as. Every feather variant stays "feathers". Set once, don't change.
@export_enum("none", "resin", "fiber", "organ", "scale", "insects", "bone", "creature_parts", "herb", "mushroom", "sweetener", "caffeine", "alcohol", "nut", "fossil", "flower", "spice", "fat", "hide", "feathers", "ash", "condiments", "meat", "fish", "shellfish", "eggs", "grain", "breads", "prepped", "seed", "water", "fruit", "vegetable", "dairy", "salt", "aquatic_plants", "fuel", "wood") var base_type : String = "none"
@export_enum("vitality", "intelligence", "charisma", "strength", "dexterity") var heals : String = "vitality"
@export var heal_amount : int = 1
@export_range(0, 3) var tier_cost : int = 1 ## Base alone 1, processed + base 2, with boost slot 3
