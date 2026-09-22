@tool extends Sprite2D

const NULL_SPRITE : Texture2D = preload("uid://dyolk4wxcqmjf")

var _previous_texture : Texture2D = null

@onready var preview_refresh_timer : Timer = $PreviewRefreshTimer

func _ready()-> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
		
	preview_refresh_timer.timeout.connect(_on_refresh_timeout)
	preview_refresh_timer.start(0.25)
	_on_refresh_timeout()
	
func _on_refresh_timeout() -> void:
	var spawner : Spawner = get_parent() as Spawner
	if spawner == null:
		return
			
	# Check for a new texture being added and if so add it make sure not to add the same one over and over
	var definition : EnemyDefinition = spawner.enemy_definition
	
	var new_texture : Texture2D =\
	definition.preview_texture if (definition and definition.preview_texture) else NULL_SPRITE
	
	
	if new_texture == _previous_texture:
		return
		
	_previous_texture = new_texture
	texture = new_texture
	
	
	
