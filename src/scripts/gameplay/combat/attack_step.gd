class_name AttackStep
extends Resource

@export var anim: StringName = &"slash"   # slash, overhead, short_stab, long_thrust, blunt_swing, bow_draw, aim_shoot, cast, throw, unarmed
@export var damage_multiplier: float = 1.0
@export var poise_damage_multiplier: float = 1.0
@export var combo_window: float = 0.35    # seconds to press attack again for the next step
