class_name FlickerLight extends PointLight2D
## A light that gently wobbles. Used on the player's DarkLight and on fires.

@export var flicker_amount : float = 0.06 ## How much brightness wobbles (0 = steady)
@export var flicker_speed  : float = 4.0
@export var pulse_enabled  : bool = false ## Occasional heavy dim, like Coren nearly blacking out
@export var pulse_interval : Vector2 = Vector2(4.0, 8.0) ## Random seconds between pulses
@export var pulse_strength : float = 0.6 ## How much light is lost at the bottom of a pulse

var _base_energy : float
var _base_scale  : float
var _noise := FastNoiseLite.new()
var _time : float = 0.0
var _pulse_timer : float = 0.0
var _pulse : float = 0.0 ## 0 = normal, 1 = fully dimmed (tweened)

func _ready() -> void:
	_base_energy = energy
	_base_scale = texture_scale
	_noise.seed = randi()
	_reset_pulse_timer()

func _process(delta: float) -> void:
	_time += delta
	var wobble := _noise.get_noise_1d(_time * flicker_speed * 10.0) * flicker_amount

	if pulse_enabled:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_do_pulse()
			_reset_pulse_timer()

	energy = _base_energy * (1.0 + wobble) * (1.0 - _pulse * pulse_strength)
	texture_scale = _base_scale * (1.0 - _pulse * pulse_strength * 0.3)

func _do_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_pulse", 1.0, 0.15) # quick dim
	tween.tween_property(self, "_pulse", 0.0, 0.8)  # slow recovery

func _reset_pulse_timer() -> void:
	_pulse_timer = randf_range(pulse_interval.x, pulse_interval.y)
