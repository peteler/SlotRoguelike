# CombatManager.gd
extends Node


# Signals
signal symbol_processing_started(symbol: SymbolData)
signal symbol_processing_completed(symbol: SymbolData)
signal symbol_effect_applied(symbol: SymbolData, target: Node)

# References
var player_character: PlayerCharacter
var enemies: Array = []

func _ready():
	# Connect to slot machine
	SlotMachine.symbols_rolled.connect(_on_symbols_rolled)
	
	# Find combatants
	player_character = get_tree().get_first_node_in_group("player_character")
	enemies = get_tree().get_nodes_in_group("enemies")

# Main symbol processing function
func _on_symbols_rolled(symbols: Array[SymbolData]):
	# Process instant effects first (like global modifiers)
	for symbol in symbols:
		if symbol.is_instant_effect:
			_process_symbol_immediately(symbol)
	
	# Process remaining symbols in order
	for symbol in symbols:
		if !symbol.is_instant_effect:
			await _process_symbol_with_delay(symbol, 0.3)

# Process a symbol with visual delay
func _process_symbol_with_delay(symbol: SymbolData, delay: float):
	emit_signal("symbol_processing_started", symbol)
	
	# Get targets based on symbol type
	var targets = _get_targets_for_symbol(symbol)
	
	# Apply effect to each target
	for target in targets:
		_apply_symbol_to_target(symbol, target)
		await get_tree().create_timer(delay / targets.size()).timeout
	
	emit_signal("symbol_processing_completed", symbol)

# Process instant effects immediately
func _process_symbol_immediately(symbol: SymbolData):
	var targets = _get_targets_for_symbol(symbol)
	for target in targets:
		_apply_symbol_to_target(symbol, target)

# Determine targets for a symbol
func _get_targets_for_symbol(symbol: SymbolData) -> Array:
	match symbol.target_type:
		SymbolData.TARGET_TYPE.SELF:
			return [player_character]
		
		SymbolData.TARGET_TYPE.SINGLE_ENEMY:
			# Get first alive enemy (or use player-selected target)
			var alive_enemies = enemies.filter(func(e): return e.is_alive())
			if alive_enemies.size() > 0:
				return [alive_enemies[0]]
			return []
		
		SymbolData.TARGET_TYPE.ALL_ENEMIES:
			return enemies.filter(func(e): return e.is_alive())
		
		SymbolData.TARGET_TYPE.RANDOM_ENEMY:
			var alive_enemies = enemies.filter(func(e): return e.is_alive())
			if alive_enemies.size() > 0:
				return [alive_enemies[randi() % alive_enemies.size()]]
			return []
		
		SymbolData.TARGET_TYPE.ALL_CHARACTERS:
			var all_chars = [player_character]
			all_chars.append_array(enemies)
			return all_chars.filter(func(c): return c.is_alive())
		
		SymbolData.TARGET_TYPE.NONE:
			return []  # Global effects handled separately
	
	return []

# Apply symbol effect to a target
func _apply_symbol_to_target(symbol: SymbolData, target: Node):
	# Play visual effect
	if symbol.visual_effect:
		var effect = symbol.visual_effect.instantiate()
		target.add_child(effect)
		effect.global_position = target.global_position
		effect.emitting = true
	
	# Apply stat changes
	if symbol.health_effect != 0:
		target.modify_health(symbol.health_effect)
	
	if symbol.mana_effect != 0 && target.has_method("modify_mana"):
		target.modify_mana(symbol.mana_effect)
	
	if symbol.attack_effect != 0:
		target.modify_attack(symbol.attack_effect)
	
	if symbol.block_effect != 0:
		target.modify_block(symbol.block_effect)
	
	# Execute custom effect script
	if symbol.effect_script:
		var effect_instance = symbol.effect_script.new()
		if effect_instance.has_method("apply_effect"):
			effect_instance.apply_effect(symbol, target)
	
	emit_signal("symbol_effect_applied", symbol, target)
