# PlayerClassData.gd - Static, unchanging player class definition
# A factory for creating a fresh "character sheet" [player_data] at the start of a run.
@tool
class_name PlayerClassData
extends CharacterData

## Starting Resources
@export_group("Starting Resources & Stats")
@export var symbol_pool: SymbolPool
@export var mana: int = 3
@export var gold: int = 0

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
	var new_player_data = PlayerData.new()
	
	# Copy class data to player data
	new_player_data.class_data = self
	new_player_data.max_health = max_health
	new_player_data.current_health = max_health
	new_player_data.base_attack = base_attack
	new_player_data.base_block = base_block
	
	# Set starting resources
	new_player_data.symbol_pool = symbol_pool.duplicate(true)
	new_player_data.current_mana = mana
	new_player_data.max_mana = max_mana
	new_player_data.mana_per_turn = mana_per_turn
	new_player_data.gold = gold
	
	
	return new_player_data
