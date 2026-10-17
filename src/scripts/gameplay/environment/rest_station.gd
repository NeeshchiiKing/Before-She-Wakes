class_name RestStation extends StaticBody2D
## Furniture that fully restores one Resource and resets its status (Bed, Chair, Bath, Toilet, Fire).

const ACTIONS : Dictionary = {
	"vitality": "Rest",
	"intelligence": "Meditate",
	"charisma": "Cleanse",
	"strength": "Discharge",
	"dexterity": "Sweat",
}

@export_enum("vitality", "intelligence", "charisma", "strength", "dexterity") var restores : String = "vitality"
@export var safe_only : bool = true ## Can't be used while enemies are nearby

@onready var interact_area : Area2D = $InteractArea
@onready var prompt : Label = $PromptLabel

var _player_in_range : Player = null

func _ready() -> void:
	prompt.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_use(_player_in_range)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = body as Player
		prompt.text = "E: %s" % ACTIONS[restores]
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.hide()

func _use(player: Player) -> void:
	if safe_only and player.is_in_combat():
		prompt.text = "Not with enemies nearby"
		return
	player.stats.fully_restore(StringName(restores))
	prompt.text = "%s: %s" % [restores.capitalize(), player.stats.status_name(StringName(restores))]
