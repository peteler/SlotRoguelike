# PlayerData.gd - Dynamic player save data that persists between different scene roots
@tool
class_name PlayerData
extends Resource

## Core Identity
@export var class_data: PlayerClassData  # Reference to the class this character is
var character_name = class_data.character_name if class_data else null

## Core Stats (these change during a run)
@export var max_health: int = 30
@export var current_health: int = 30
@export var base_attack: int = 5
@export var base_block: int = 0

## Current Resources (these change during gameplay)
@export_group("Current Resources")
@export var symbol_pool: SymbolPool # Dynamic symbol pool
@export var slot_count: int = 5  # Number of slots player currently has
@export var current_mana: int = 3
@export var max_mana: int = 10
@export var mana_per_turn: int = 1 # mana restored per turn
@export var gold: int = 0


## Collections (grow during gameplay)
@export_group("Collections")
#@export var spells: Array[Spell] = []
#@export var equipment: Array[Equipment] = []  
#@export var consumables: Array[Consumable] = []  
#@export var artifacts: Array[Artifact] = []  

## Progression Tracking
# TODO: move map progression data to another script?
@export_group("Progress")
@export var current_path: Array[String] = []  # Track which encounters were chosen
@export var special_events_visited: Array[String] = [] # no duplicate events during runs

##TODO: MAYBE THESE ARE GOOD WHEN SYMBOL EFFECTS ARE ACTUALLY ADDED, SOLVE SYMBOL SYSTEM FIRST !
# Helper functions for resource management
func get_total_health() -> int:
	"""Get current max health including temporary bonuses"""
	return max_health

func get_total_attack() -> int:
	"""Get current base attack including temporary bonuses"""
	return base_attack

func get_total_block() -> int:
	"""Get current base block including temporary bonuses"""
	return base_block

# Symbol pool management functions
func add_symbol_to_pool(symbol: SymbolData, amount: int = 1):
	"""Add symbols to the player's pool"""
	symbol_pool.add_symbol(symbol, amount)

func remove_symbol_from_pool(symbol: SymbolData, amount: int = 1) -> bool:
	"""Remove symbols from pool, returns true if successful"""
	return symbol_pool.remove_symbol(symbol, amount)

func get_symbol_pool() -> SymbolPool:
	"""Get the player's symbol pool"""
	return symbol_pool

func can_afford(cost: int) -> bool:
	"""Check if player can afford something"""
	return gold >= cost

func gain_gold(amount: int):
	"""Gain gold"""
	gold += amount

func heal_to_full():
	"""Restore health to maximum"""
	current_health = get_total_health()

# Save/Load helpers
func get_save_data():
	pass

func load_save_data(data: Dictionary):
	pass
