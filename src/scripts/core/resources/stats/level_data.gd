class_name LevelData extends Resource
## Tracks level and experience. Emits leveled_up once per level gained.

signal leveled_up(new_level: int)

const MAX_LEVEL : int = 99

## XP needed for the next level = base_experience * level ^ curve_exponent
@export var base_experience : int = 100
@export var curve_exponent  : float = 1.5

@export_range(1, MAX_LEVEL) var level : int = 1
@export var experience : int = 0 ## Progress toward the next level, not lifetime total

func experience_to_next_level() -> int:
	return int(base_experience * pow(level, curve_exponent))

func add_experience(amount: int) -> void:
	if level >= MAX_LEVEL:
		return

	experience += amount
	# while, not if: one big XP reward can cross several levels at once
	while level < MAX_LEVEL and experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		leveled_up.emit(level)

	if level >= MAX_LEVEL:
		experience = 0
	emit_changed()
