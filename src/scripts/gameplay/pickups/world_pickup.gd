@tool
class_name WorldPickup extends Area2D
## Something lying in the world: an item, a currency, OR a piece of gear (like a thrown rock).
## Press E nearby to pick it up (or walk over it if requires_press is off).

@export var item : ItemDefinition:
	set(value):
		item = value
		_update_sprite()
@export var currency : CurrencyDefinition: ## Use only one of item / currency / gear
	set(value):
		currency = value
		_update_sprite()
@export var gear : EquipmentDefinition:
	set(value):
		gear = value
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
		get_viewport().set_input_as_handled() # one press = one pickup, even if things overlap
		_try_pick_up(_player_in_range)


func _update_sprite() -> void:
	if not is_node_ready():
		return
	var texture : Texture2D = null
	if item != null:
		texture = item.world_sprite if item.world_sprite != null else item.icon
	elif currency != null:
		texture = currency.world_sprite if currency.world_sprite != null else currency.icon
	elif gear != null:
		texture = gear.icon
	sprite.texture = texture


func _display_name() -> String:
	if item != null:
		return item.display_name
	if gear != null:
		return gear.display_name
	return currency.display_name


func _on_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	if item == null and currency == null and gear == null:
		return
	var player := body as Player
	if requires_press:
		_player_in_range = player
		if gear != null:
			prompt.text = "E: %s" % _display_name()
		else:
			prompt.text = "E: %s x%d" % [_display_name(), amount]
		prompt.show()
	else:
		_try_pick_up(player)


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.hide()


func _try_pick_up(player: Player) -> void:
	if currency != null:
		player.wallet.add(StringName(currency.id), amount) # money never fills the bag
		queue_free()
		return
	if gear != null:
		player.pick_up_gear(gear)
		queue_free()
		return
	if not player.inventory.can_add(item):
		prompt.text = "Bag is full"
		prompt.show()
		return
	player.inventory.add(item, amount)
	queue_free()


## Thrown things fall from where they stopped down to where they rest on the ground
## Thrown things arc down to the ground, slide a little, and bounce once
## Thrown things come down to the ground. Bounced = knocked back off something; otherwise it
## keeps the throw's momentum while it drops.
func fall_from(height: float, slide: Vector2, bounced: bool, fall_time: float = 0.25) -> void:
	var ground_y := sprite.position.y
	sprite.position.y = ground_y - height # start up where the throw was
	var start := position
	var arc := create_tween()

	if bounced:
		# Knocked back: slide away slowing down, pop up, fall
		create_tween().tween_property(self, "position", start + slide, 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		arc.tween_property(sprite, "position:y", ground_y - height - 8.0, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		arc.tween_property(sprite, "position:y", ground_y, 0.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		# Still flying: same speed forward while gravity pulls it down, then a short roll
		var move := create_tween()
		move.tween_property(self, "position", start + slide, fall_time) # linear = keeps the throw's speed
		move.tween_property(self, "position", start + slide + slide.normalized() * 6.0, 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		arc.tween_property(sprite, "position:y", ground_y, fall_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Both end with one small bounce
	arc.tween_property(sprite, "position:y", ground_y - 3.0, 0.06) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(sprite, "position:y", ground_y, 0.06) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
