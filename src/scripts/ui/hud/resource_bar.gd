class_name ResourceBar extends HBoxContainer
## One HUD row: short name, bar, and current/max for a single Resource

@export var stat_name  : StringName = &"vitality" ## Must match the variable name in stats.gd
@export var short_name : String = "Vit"
@export var fill_color : Color = Color.RED

@onready var name_label  : Label = $NameLabel
@onready var bar         : ProgressBar = $Bar
@onready var value_label : Label = $ValueLabel

func _ready() -> void:
	name_label.text = short_name

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override(&"fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.6)
	bar.add_theme_stylebox_override(&"background", background)

func update_from(stats: Stats) -> void:
	var current : int = stats.get(stat_name)
	var maximum : int = stats.get("max_" + stat_name)
	bar.max_value = maximum # set max before value so it doesn't clamp wrong
	bar.value = current
	value_label.text = "%d/%d %s" % [current, maximum, stats.status_name(stat_name)]
