class_name QuickSlotButton extends Button
## A quick slot in the menu. Drop an item or spell on it; right-click to clear.

signal slot_changed

var index : int = 0
var inventory : Inventory = null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is ItemDefinition or data is AbilityDefinition

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	inventory.set_quick_slot(index, data)
	slot_changed.emit()

func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		inventory.clear_quick_slot(index)
		slot_changed.emit()
