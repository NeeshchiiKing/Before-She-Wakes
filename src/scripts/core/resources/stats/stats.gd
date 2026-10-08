class_name Stats extends Resource

signal no_vitality
signal no_intelligence
signal no_charisma
signal no_strength
signal no_dexterity

const MAX_RESOURCE_CAP : int = 100
const NAMES : Array[StringName] = [
	&"vitality", &"intelligence", &"charisma", &"strength", &"dexterity",
]

## Status tier names per Resource. Tier 0 = starting state (what facilities reset to), tier 4 = worst.
const STATUS_TIERS : Dictionary = {
	&"vitality": ["Healthy", "Stable", "Injured", "Critical", "Bleeding"],
	&"intelligence": ["Sober", "Focused", "Tired", "Inebriated", "Confused"],
	&"charisma": ["Radiant", "Fresh", "Presentable", "Dirty", "Repulsive"],
	&"strength": ["Starving", "Hungry", "Satisfied", "Full", "Enervated"],
	&"dexterity": ["Dehydrated", "Thirsty", "Refreshed", "Hydrated", "Encumbered"],
}
const WORST_TIER : int = 4

@export_range(0, WORST_TIER) var vitality_tier     : int = 0
@export_range(0, WORST_TIER) var intelligence_tier : int = 0
@export_range(0, WORST_TIER) var charisma_tier     : int = 0
@export_range(0, WORST_TIER) var strength_tier     : int = 0
@export_range(0, WORST_TIER) var dexterity_tier    : int = 0

@export var unspent_points : int = 0

@export var vitality: = 1 :
	set(value):
		vitality = value
		emit_changed()
		if vitality <= 0: no_vitality.emit()
@export var max_vitality: = 1 :
	set(value):
		max_vitality = value
		emit_changed()

@export var intelligence: = 1 :
	set(value):
		intelligence = value
		emit_changed()
		if intelligence <= 0: no_intelligence.emit()
@export var max_intelligence: = 1 :
	set(value):
		max_intelligence = value
		emit_changed()

@export var charisma: = 1 :
	set(value):
		charisma = value
		emit_changed()
		if charisma <= 0: no_charisma.emit()
@export var max_charisma: = 1 :
	set(value):
		max_charisma = value
		emit_changed()

@export var strength: = 1 :
	set(value):
		strength = value
		emit_changed()
		if strength <= 0: no_strength.emit()
@export var max_strength: = 1 :
	set(value):
		max_strength = value
		emit_changed()

@export var dexterity: = 1 :
	set(value):
		dexterity = value
		emit_changed()
		if dexterity <= 0: no_dexterity.emit()
@export var max_dexterity: = 1 :
	set(value):
		max_dexterity = value
		emit_changed()

func add_points(amount: int) -> void:
	unspent_points += amount
	emit_changed()

func can_raise(resource: StringName) -> bool:
	return unspent_points > 0 \
		and resource in NAMES \
		and get("max_" + resource) < MAX_RESOURCE_CAP

## Spends 1 point to raise a Resource's max by 1. The new point comes filled.
func raise(resource: StringName) -> bool:
	if not can_raise(resource):
		return false
	set("max_" + resource, get("max_" + resource) + 1)
	set(resource, get(resource) + 1)
	unspent_points -= 1
	emit_changed()
	return true


func status_tier(resource: StringName) -> int:
	return get(String(resource) + "_tier")

func status_name(resource: StringName) -> String:
	return STATUS_TIERS[resource][status_tier(resource)]

func is_worst_status(resource: StringName) -> bool:
	return status_tier(resource) >= WORST_TIER

## Used by healing items: each item says how many tiers it costs
func worsen_status(resource: StringName, tiers: int) -> void:
	set(String(resource) + "_tier", mini(status_tier(resource) + tiers, WORST_TIER))
	emit_changed()

## Used by town facilities (Rest, Meditate, Cleanse, Discharge, Sweat)
func reset_status(resource: StringName) -> void:
	set(String(resource) + "_tier", 0)
	emit_changed()

## Pays a Resource cost. Returns false (and spends nothing) if there isn't enough.
func try_spend(resource: StringName, amount: int) -> bool:
	if amount <= 0:
		return true
	var current : int = get(resource)
	if current < amount:
		return false
	set(resource, current - amount)
	return true
