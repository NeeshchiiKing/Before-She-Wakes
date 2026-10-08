@tool
class_name WorldPickup extends Area2D
## An item lying in the world. Shows the item's icon. Press E nearby to pick it up (or walk over it if requires_press is off).

@export var item : ItemDefinition:
	set(value):
		item = value
		_update_sprite()
@export var amount : int = 1
@export var requires_press : bool = true ## Off = picked up just by walking over it

@onready var sprite : Sprite2D = $Sprite2D
@onready var prompt : Label = $PromptLabel

var _player_in_range : Player = null

func _ready() -> void:
	_update_sprite()
	if Engine.is_editor_hint():
		return # only show the icon in the editor, don't run pickup logic
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or _player_in_range == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled() # one press = one pickup, even if items overlap
		_try_pick_up(_player_in_range)

func _update_sprite() -> void:
	if not is_node_ready():
		return
	sprite.texture = item.icon if item != null else null

func _on_body_entered(body: Node2D) -> void:
	if body is not Player or item == null:
		return
	var player := body as Player
	if requires_press:
		_player_in_range = player
		prompt.text = "E: %s x%d" % [item.display_name, amount]
		prompt.show()
	else:
		_try_pick_up(player)

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.hide()

func _try_pick_up(player: Player) -> void:
	if not player.inventory.can_add(item):
		prompt.text = "Bag is full"
		prompt.show()
		return
	player.inventory.add(item, amount)
	queue_free()
