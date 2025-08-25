# PlayerClassData.gd - Static, unchanging player class definition
# A factory for creating a fresh "character sheet" [player_data] at the start of a run.
@tool
class_name PlayerClassData
extends CharacterData

## Starting Resources
@export_group("Starting Resources & Stats")
@export var symbol_pool: SymbolPool
@export var starting_mana: int = 3
@export var gold: int = 0

## Class-specific Mechanics
@export_group("Class Features")
@export var mana_per_turn: int = 1  # How much mana gained each turn
@export var max_mana: int = 10
@export var special_abilities: Array[Spell] = []  # Class-unique spells

## Progression
@export_group("Progression")
@export var class_symbol_types: Array[SymbolData] = []  # For encounter rewards

## UI placement
@export var attack_display_local_offset: Vector2 = Vector2(0, 25)
