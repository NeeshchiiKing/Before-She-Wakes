class_name PauseMenu extends Control
## Game menu. Pauses when it's safe; stays live (digging in your bag) when enemies are near.

signal quit_requested

const LIVE_TINT : Color = Color(1, 1, 1, 0.8)

@onready var tabs        : TabContainer = $Panel/Tabs
@onready var system_page : MenuPage = $Panel/Tabs/System

var _player : Player = null

func _ready() -> void:
	hide()
	system_page.quit_requested.connect(quit_requested.emit)
	tabs.tab_changed.connect(_on_tab_changed)

func open(player: Player, is_live: bool = false) -> void:
	_player = player
	modulate = LIVE_TINT if is_live else Color.WHITE
	for page in tabs.get_children():
		if page is MenuPage:
			page.refresh(player)
	if not player.stats.changed.is_connected(_refresh_current_tab):
		player.stats.changed.connect(_refresh_current_tab)
	if not player.inventory.changed.is_connected(_refresh_current_tab):
		player.inventory.changed.connect(_refresh_current_tab)
	if not player.equipment.changed.is_connected(_refresh_current_tab):
		player.equipment.changed.connect(_refresh_current_tab)
	if is_live:
		tabs.current_tab = $Panel/Tabs/Inventory.get_index()
	show()

func close() -> void:
	hide()

## Switching tabs always shows fresh data (e.g. a slot set on Spells shows up on Inventory)
func _on_tab_changed(_tab: int) -> void:
	_refresh_current_tab()

## Keeps the open tab current: data changes, taking hits in a live menu, or switching tabs
func _refresh_current_tab() -> void:
	if not visible or _player == null:
		return
	var page = tabs.get_current_tab_control()
	if page is MenuPage:
		page.refresh.call_deferred(_player)
