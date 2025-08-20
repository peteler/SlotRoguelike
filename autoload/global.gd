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
signal player_mana_updated(current_mana: int) 

# Enemy Specific Events
signal enemy_intent_selected(enemy: Enemy, action: EnemyAction)
signal enemy_action_executed(enemy: Enemy, action: EnemyAction)

# Slot Machine Events
signal slot_roll_completed(symbols: Array[SymbolData])
signal symbol_processing_started(symbol: SymbolData)
signal symbol_processing_completed(symbol: SymbolData)
signal symbol_effect_applied(symbol: SymbolData, target: Node)
signal symbol_sequence_completed(symbols: Array[SymbolData])

# Symbol Pool Events
signal symbol_pool_updated  # When symbols are added/removed from pool

# Player Action Events
signal attack_button_pressed
signal end_turn_button_pressed
signal spell_button_pressed(spell: Spell)

# Game Controller events
signal return_to_map
signal game_over

# Map Events
signal event_node_selected(event_node: EventNode)
signal event_selected(event_data: EventData)

func _ready():
	# Set up the singleton to persist between scenes
	process_mode = Node.PROCESS_MODE_ALWAYS
