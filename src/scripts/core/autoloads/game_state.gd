extends Node

#holds the flags for questlog and worldmap  used ofr visited map squares 
var flags: Dictionary = {}


func set_flag(id: String, value: bool = true) -> void:
	flags[id] = value


func has_flag(id: String) -> bool:
	return flags.get(id, false)
