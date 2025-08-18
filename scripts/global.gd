# Global.gd - Centralized Event Bus
extends Node

# Battle Flow Events
signal battle_state_changed(new_state: String)
signal all_enemy_turns_completed
signal battle_win
signal battle_lose

# Character Events
signal character_targeted(character: Character)
signal character_died(character: Character)
signal character_health_updated(character: Character, current_health: int, max_health: int)
signal character_block_updated(character: Character, block_amount: int)
signal character_attack_updated(character: Character, attack_amount: int)

# Enemy Specific Events
signal enemy_intent_selected(enemy: Enemy, action: EnemyAction)
signal enemy_action_executed(enemy: Enemy, action: EnemyAction)

# Slot Machine Events
signal slot_roll_completed(symbols: Array[SymbolData])
signal symbol_processing_started(symbol: SymbolData)
signal symbol_processing_completed(symbol: SymbolData)
signal symbol_effect_applied(symbol: SymbolData, target: Node)

# Player Action Events
signal attack_button_pressed
signal end_turn_button_pressed
signal spell_button_pressed(spell: Spell)

func _ready():
	# Set up the singleton to persist between scenes
	process_mode = Node.PROCESS_MODE_ALWAYS
