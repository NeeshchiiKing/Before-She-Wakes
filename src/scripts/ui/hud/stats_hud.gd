class_name StatsHud extends VBoxContainer
## Shows the player's 5 Resources (Vit, Int, Cha, Str, Dex) on the HUD

var _stats : Stats = null

func bind_stats(stats: Stats) -> void:
	if _stats != null and _stats.changed.is_connected(_refresh):
		_stats.changed.disconnect(_refresh)

	_stats = stats
	if _stats == null:
		return

	_stats.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in get_children():
		if child is ResourceBar:
			child.update_from(_stats)
