# PlayerClassData.gd - Static class definitions
@tool
class_name PlayerClassData
extends CharacterData

## Class Identity
@export var class_id: String = "class id"
@export var class_description: String = "class description"
@export var class_icon: Texture2D

## Starting Resources
@export_group("Starting Resources")
@export var starting_symbol_pool: Dictionary = {
	# Example: preload("res://symbols/sword.tres"): 5
}
@export var starting_mana: int = 3
@export var starting_gold: int = 0

## Class-specific Mechanics
@export_group("Class Features")
@export var mana_per_turn: int = 1  # How much mana gained each turn
@export var max_mana: int = 10
@export var special_abilities: Array[Spell] = []  # Class-unique spells

## Progression
@export_group("Progression")
@export var class_symbol_types: Array[SymbolData] = []  # For encounter rewards

# Helper function to create starting PlayerData for this class
func create_starting_player_data() -> PlayerData:
	"""Create a new PlayerData with this class's starting values"""
	var player_data = PlayerData.new()
	
	# Copy class data to player data
	player_data.class_data = self
	player_data.character_name = class_id
	player_data.sprite = sprite
	player_data.max_health = max_health
	player_data.current_health = max_health
	player_data.base_attack = base_attack
	player_data.base_block = base_block
	
	# Set starting resources
	player_data.current_symbol_pool = starting_symbol_pool.duplicate(true)
	player_data.current_mana = starting_mana
	player_data.max_mana = max_mana
	player_data.mana_per_turn = mana_per_turn
	player_data.gold = starting_gold
	
	# Copy arrays
	player_data.spells = special_abilities.duplicate()
	
	return player_data
