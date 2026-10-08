class_name QuickBarHud extends HBoxContainer
## HUD quick slots (keys 1-4). Drag spells or items onto them from the open menu; right-click to clear.

const SLOT_SIZE : Vector2 = Vector2(64, 14)

var _player : Player = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # accept drops even while the game is paused

func bind_player(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_queue_refresh)
	player.stats.changed.connect(_queue_refresh)
	player.spells.changed.connect(_queue_refresh)
	_refresh()

## Deferred so a slot is never deleted in the middle of its own drop
func _queue_refresh() -> void:
	_refresh.call_deferred()

func _refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.6)

	var inventory := _player.inventory
	for i in inventory.quick_slot_count:
		var thing := inventory.get_quick_slot(i)
		var slot := QuickSlotButton.new()
		slot.index = i
		slot.inventory = inventory
		slot.focus_mode = Control.FOCUS_NONE # so keys 1-4 never "press" the button
		slot.text = "%d %s" % [i + 1, _player.describe_quick(thing)]
		slot.icon = _player.quick_icon(thing)
		slot.add_theme_constant_override(&"icon_max_width", 12)	
		slot.custom_minimum_size = SLOT_SIZE
		slot.add_theme_font_size_override(&"font_size", 8)
		for style in [&"normal", &"hover", &"pressed", &"disabled"]:
			slot.add_theme_stylebox_override(style, background)
		slot.modulate = Color.WHITE if _player.can_use_quick(thing) else Color(1, 1, 1, 0.4)
		add_child(slot)
