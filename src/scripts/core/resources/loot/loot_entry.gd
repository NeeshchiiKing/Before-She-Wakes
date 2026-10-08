class_name LootEntry extends Resource
## One possible drop: which item, how likely, and how many.

@export var item : ItemDefinition
@export_range(0.0, 1.0, 0.05) var chance : float = 1.0 ## 1.0 = always, 0.5 = half the time
@export var min_amount : int = 1
@export var max_amount : int = 1
