# SymbolProcessor.gd - Service class for applying symbol effects
class_name SymbolProcessor
extends Node

# main processing functions

func process_symbols_in_sequence(symbols: Array[SymbolData], delay_between: float = 0.1):
	"""Process an array of symbols with proper timing and effects"""
	
	# Separate instant and delayed effects
	var instant_symbols = symbols.filter(func(s): return s.is_instant)
	var delayed_symbols = symbols.filter(func(s): return not s.is_instant)
	
	# Process instant effects immediately
	for symbol in instant_symbols:
		process_symbol_immediately(symbol)
	
	# Process delayed effects with timing
	for symbol in delayed_symbols:
		await process_symbol_with_delay(symbol, delay_between)
	
	Global.symbol_sequence_completed.emit(symbols)

func process_symbol_immediately(symbol: SymbolData):
	"""Apply symbol effects without delay or signals"""
	var targets = get_targets_for_symbol(symbol)
	
	for target in targets:
		apply_symbol_to_target(symbol, target)

func process_symbol_with_delay(symbol: SymbolData, delay: float):
	"""Apply symbol effect with visual feedback and timing"""
	Global.symbol_processing_started.emit(symbol)
	
	# Play visual effect
	if symbol.visual_effect_scene:
		play_visual_effect(symbol)
	
	# Get targets and apply effects
	var targets = get_targets_for_symbol(symbol)
	
	for target in targets:
		apply_symbol_to_target(symbol, target)
		# Small delay between multiple targets
		if targets.size() > 1:
			await get_tree().create_timer(delay / targets.size()).timeout
	
	# Wait for animation to complete
	await get_tree().create_timer(symbol.animation_duration).timeout
	
	Global.symbol_processing_completed.emit(symbol)

func apply_symbol_to_target(symbol: SymbolData, target: Character):
	"""Apply a symbol's effects to a specific target"""
	
	# Apply basic stat effects
	if symbol.health_effect != 0:
		if symbol.health_effect > 0:
			target.heal(symbol.health_effect)
		else:
			target.take_basic_attack_damage(abs(symbol.health_effect))
	
	if symbol.attack_effect != 0:
		target.modify_attack(symbol.attack_effect)
	
	if symbol.block_effect != 0:
		target.modify_block(symbol.block_effect)
	
	if symbol.mana_effect != 0 and target.has_method("modify_mana"):
		target.modify_mana(symbol.mana_effect)
	
	# Apply special effects
	if not symbol.special_effect_id.is_empty():
		apply_special_effect(symbol, target)
	
	# Emit signal for any listeners
	Global.symbol_effect_applied.emit(symbol, target)

func apply_special_effect(symbol: SymbolData, target: Character):
	"""Handle complex symbol effects by ID"""
	match symbol.special_effect_id:
		"double_next_attack":
			apply_double_next_attack(target, symbol.effect_parameters)
		"heal_all_allies":
			apply_heal_all_allies(symbol.effect_parameters)
		"random_enemy_damage":
			apply_random_enemy_damage(symbol.effect_parameters)
		"steal_enemy_block":
			apply_steal_enemy_block(target, symbol.effect_parameters)
		"conditional_bonus":
			apply_conditional_bonus(target, symbol.effect_parameters)
		_:
			push_warning("Unknown special effect ID: " + symbol.special_effect_id)

# Special effect implementations
# TODO: add a custom script option, and filter these
func apply_double_next_attack(target: Character, params: Dictionary):
	"""Double the effect of the next attack symbol"""
	# This would require a temporary buff system
	print("Applied double next attack to ", target.name)

func apply_heal_all_allies(params: Dictionary):
	"""Heal all allied characters"""
	var heal_amount = params.get("heal_amount", 5)
	var player = get_tree().get_first_node_in_group("player_character")
	if player:
		player.heal(heal_amount)

func apply_random_enemy_damage(params: Dictionary):
	"""Deal damage to a random enemy"""
	var damage = params.get("damage", 3)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var alive_enemies = enemies.filter(func(e): return e.is_alive())
	
	if not alive_enemies.is_empty():
		var target = alive_enemies[randi() % alive_enemies.size()]
		target.take_basic_attack_damage(damage)

func apply_steal_enemy_block(target: Character, params: Dictionary):
	"""Steal block from enemies and give to target"""
	var steal_amount = params.get("steal_amount", 2)
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.is_alive() and enemy.block > 0:
			var stolen = min(enemy.block, steal_amount)
			enemy.modify_block(-stolen)
			target.modify_block(stolen)
			break

func apply_conditional_bonus(target: Character, params: Dictionary):
	"""Apply bonus effects based on conditions"""
	var condition = params.get("condition", "")
	var bonus_attack = params.get("bonus_attack", 0)
	
	match condition:
		"low_health":
			if float(target.current_health) / target.max_health < 0.3:
				target.modify_attack(bonus_attack)
		"high_block":
			if target.block >= 5:
				target.heal(params.get("bonus_heal", 3))

# Utility functions
func get_targets_for_symbol(symbol: SymbolData) -> Array[Character]:
	"""Determine targets for a symbol based on its target type"""
	match symbol.target_type:
		SymbolData.TARGET_TYPE.SELF:
			var player = get_tree().get_first_node_in_group("player_character")
			return [player] if player else []
		
		SymbolData.TARGET_TYPE.SINGLE_ENEMY:
			var enemies = get_tree().get_nodes_in_group("enemies")
			var alive_enemies = enemies.filter(func(e): return e.is_alive())
			return [alive_enemies[0]] if not alive_enemies.is_empty() else []
		
		SymbolData.TARGET_TYPE.ALL_ENEMIES:
			var enemies = get_tree().get_nodes_in_group("enemies")
			return enemies.filter(func(e): return e.is_alive())
		
		SymbolData.TARGET_TYPE.RANDOM_ENEMY:
			var enemies = get_tree().get_nodes_in_group("enemies")
			var alive_enemies = enemies.filter(func(e): return e.is_alive())
			if alive_enemies.is_empty():
				return []
			return [alive_enemies[randi() % alive_enemies.size()]]
		
		SymbolData.TARGET_TYPE.ALL_CHARACTERS:
			var all_chars: Array[Character] = []
			var player = get_tree().get_first_node_in_group("player_character")
			if player:
				all_chars.append(player)
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			all_chars.append_array(enemies.filter(func(e): return e.is_alive()))
			return all_chars
		
		SymbolData.TARGET_TYPE.NONE:
		# Global effects that don't target specific characters
			return []
		
		_:
			return []

func play_visual_effect(symbol: SymbolData):
	"""Play visual effect for symbol"""
	if symbol.visual_effect_scene:
		var effect = symbol.visual_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		# Position effect appropriately
		if effect.has_method("play"):
			effect.play()
