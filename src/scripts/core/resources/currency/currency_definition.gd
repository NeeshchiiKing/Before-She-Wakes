class_name CurrencyDefinition extends Resource
## One of the 3 currencies: its wallet id, display name and icon.

@export_enum("paper", "gold", "runes") var id : String = "paper"
@export var display_name : String = "Paper"
@export var icon : Texture2D
@export var world_sprite : Texture2D ## Small picture when lying in the world (12x12). Empty = uses the icon
