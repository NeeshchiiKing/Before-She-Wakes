class_name DragLabel extends Label
## A label you can drag onto a quick slot. Carries an item or spell.

var payload : Resource = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG

func _get_drag_data(_at_position: Vector2) -> Variant:
	if payload == null:
		return null
	var preview := Label.new()
	preview.text = text.strip_edges()
	preview.add_theme_font_size_override(&"font_size", 8)
	set_drag_preview(preview)
	return payload
