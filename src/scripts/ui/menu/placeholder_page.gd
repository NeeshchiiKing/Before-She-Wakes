extends MenuPage
## Simple "coming soon" tab

@export var message : String = "Coming soon"

func _build() -> void:
	_add_label(_new_column(), message)
