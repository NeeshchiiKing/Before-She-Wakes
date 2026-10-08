class_name EnemyHealthBar extends ProgressBar
## Drop-in health bar for any enemy whose root node has `@export var stats: Stats`.
## Must be a direct child of the enemy's root node.

@export var fill_color     : Color = Color.RED
@export var hide_when_full : bool = true

var _stats : Stats = null

func _ready() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_style()
	hide()

	var host : Node = get_parent()
	# Wait for the enemy's own _ready() so we get its duplicated stats, not the shared original
	if not host.is_node_ready():
		await host.ready

	var host_stats = host.get("stats")
	if host_stats is Stats:
		_bind(host_stats)
	else:
		push_warning("EnemyHealthBar: parent '%s' has no Stats in a 'stats' variable" % host.name)

func _bind(stats: Stats) -> void:
	_stats = stats
	_stats.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	max_value = _stats.max_vitality # set max before value so it doesn't clamp wrong
	value = _stats.vitality
	visible = not (hide_when_full and _stats.vitality >= _stats.max_vitality)

func _apply_style() -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	add_theme_stylebox_override(&"fill", fill)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.7)
	add_theme_stylebox_override(&"background", background)
