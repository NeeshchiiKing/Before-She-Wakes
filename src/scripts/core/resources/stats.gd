class_name Stats extends Resource

@export var vitality: = 1 :
	set(value):
		vitality = value
		if vitality <= 0: no_vitality.emit()
		
@export var max_vitality: = 1

signal no_vitality

@export var intelligence: = 1 :
	set(value):
		intelligence = value
		if intelligence <= 0: no_intelligence.emit()

@export var max_intelligence: = 1

signal no_intelligence

@export var charisma: = 1 :
	set(value):
		charisma = value
		if charisma <= 0: no_charisma.emit()
		
@export var max_charisma: = 1

signal no_charisma

@export var strength: = 1 :
	set(value):
		strength = value
		if strength <= 0: no_strength.emit()
		
@export var max_strength: = 1

signal no_strength

@export var dexterity: = 1 :
	set(value):
		dexterity = value
		if dexterity <= 0: no_dexterity.emit()
		
@export var max_dexterity: = 1

signal no_dexterity
