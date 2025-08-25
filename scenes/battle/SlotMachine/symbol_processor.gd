# SymbolProcessor.gd - Service class for applying symbol effects
class_name SymbolProcessor
extends Node

# main processing functions

func process_symbols_in_sequence(symbols: Array[SymbolData], delay_between: float = 0.1):
	"""Process an array of symbols with proper timing and effects"""
	
	# Separate instant and delayed effects
	var first_symbols = symbols.filter(func(s): return s.apply_time == SymbolData.APPLY_TIME.FIRST)
	var by_order_symbols = symbols.filter(func(s): return s.apply_time == SymbolData.APPLY_TIME.BY_ORDER)
	var last_symbols = symbols.filter(func(s): return s.apply_time == SymbolData.APPLY_TIME.LAST)
	
	for symbol in first_symbols:
		apply_symbol_effects(symbol)
	
	for symbol in by_order_symbols:
		apply_symbol_effects(symbol)
		
	for symbol in last_symbols:
		apply_symbol_effects(symbol)
	
	Global.symbol_sequence_completed.emit(symbols)

func apply_symbol_effects(symbol: SymbolData):
	
	# handle basic effects
	for i in range(symbol.basic_effect_stat_name.size()):
		
		var stat_name = symbol.basic_effect_stat_name[i]
		var stat_change_amount = symbol.basic_effect_stat_change_amount[i]
		var target_type = symbol.basic_effect_target_type[i]
		
		var targets = Global.get_targets_by_target_type(target_type) # Array[Character]
	
		for target in targets:
			target.modify_property_by_amount(stat_name, stat_change_amount)
			# for vfx
			Global.symbol_effect_applied.emit(symbol, target)

	
	# handle special effects
	for effect in symbol.special_effects:
		var target_type = symbol.special_effects[effect]
		
		var targets = Global.get_targets_by_target_type(target_type)
		
		for target in targets:
			apply_special_effect_to_target(effect, target)
			# for vfx
			Global.symbol_effect_applied.emit(symbol, target)

			
	# handle custom effects
	for effect in symbol.custom_effects:
		var target_type = symbol.custom_effects[effect]
		
		var targets = Global.get_targets_by_target_type(target_type)
		
		if targets.is_empty():
			apply_custom_effect(effect)
		else:
			for target in targets:
				apply_custom_effect_to_target(effect, target)
				# for vfx
				Global.symbol_effect_applied.emit(symbol, target)

#TODO:
func apply_special_effect_to_target(effect: SymbolData.SPECIAL_EFFECT, target: Character):
	"""Handle complex symbol effects by"""
	match effect:
		# TODO: maybe there's a better way?
		_:
			push_warning("Unknown special effect: ", effect)
#TODO:
func apply_custom_effect(effect: GDScript):
	pass
#TODO:
func apply_custom_effect_to_target(effect: GDScript, target: Character):
	pass

# Utility functions

func play_visual_effect(symbol: SymbolData):
	"""Play visual effect for symbol"""
	if symbol.visual_effect_scene:
		var effect = symbol.visual_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		# Position effect appropriately
		if effect.has_method("play"):
			effect.play()
