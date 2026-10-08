extends MenuPage
## System tab: Save, Load, Settings, Controls (placeholders) and Quit

signal quit_requested

func _build() -> void:
	var column := _new_column()
	for text in ["Save", "Load", "Settings", "Controls"]:
		var placeholder := Button.new()
		placeholder.text = text
		placeholder.disabled = true
		column.add_child(placeholder)

	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(quit_requested.emit)
	column.add_child(quit)
