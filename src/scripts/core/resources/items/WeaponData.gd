class_name WeaponData
extends Resource

enum Category { SHARP, BLUNT, RANGED, MAGIC, THROWN }
enum Accuracy { MELEE, RANGE, MAGIC }          # picks which precision stat applies
enum Element { NONE, FIRE, FROST, SHOCK, TOXIC }
enum ResourceType { VITALITY, INTELLIGENCE, CHARISMA, STRENGTH, DEXTERITY }
enum Attribute { FORTITUDE, STAMINA, WISDOM, WILLPOWER, GUILE,
		PERCEPTION, POWER, ENDURANCE, REFLEXES, AGILITY }

@export_group("Identity")
@export var base_name: String = "Sword"        # the prefix/suffix generator wraps this
@export var category: Category = Category.SHARP
@export var element: Element = Element.NONE    # fixed element (legendaries); drops can override
@export var texture: Texture2D
@export var grip_offset: Vector2
@export var hitbox_shape: Shape2D

@export_group("Stats")
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0          # feeds the TimeScale node
@export var poise_damage: float = 10.0         # how hard it staggers enemies
@export_range(1, 4) var tier_scale: int = 1
@export var crit_modifier: float = 1.5

@export_group("System")
@export var use_cost_resource: ResourceType = ResourceType.STRENGTH
@export var use_cost_amount: float = 5.0
@export var accuracy_type: Accuracy = Accuracy.MELEE
@export var max_durability: int = 100
@export var durability_per_swing: int = 1      # 2 for heavy weapons
@export var weight: float = 3.0
@export var two_handed: bool = false
@export var required_attribute: Attribute = Attribute.POWER
@export var required_points: int = 1

@export_group("Feel")
@export var combo: Array[AttackStep] = []
