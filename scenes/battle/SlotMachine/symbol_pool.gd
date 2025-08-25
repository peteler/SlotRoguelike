# SymbolPool.gd - Dynamic symbol pool resource
@tool
class_name SymbolPool
extends Resource

# Changed from Array to Dictionary to track quantities
@export var available_symbols: Dictionary[SymbolData, int] = {}  # {SymbolData: quantity}

# Track symbols for current roll (temporary state)
var _current_roll_pool: Array[SymbolData] = []

func add_symbol(symbol: SymbolData, quantity: int = 1):
	"""Add symbols to the pool"""
	if symbol in available_symbols:
		available_symbols[symbol] = available_symbols[symbol] + quantity
	else:
		available_symbols[symbol] = quantity
	
	Global.symbol_pool_updated.emit()

func remove_symbol(symbol: SymbolData, quantity: int = 1) -> bool:
	"""Remove symbols from pool, returns true if successful"""
	if symbol in available_symbols and available_symbols[symbol] >= quantity:
		available_symbols[symbol] -= quantity
		if available_symbols[symbol] <= 0:
			available_symbols.erase(symbol)
		Global.symbol_pool_updated.emit()
		return true
	return false

func get_available_symbol_count(symbol: SymbolData) -> int:
	"""Get how many of a specific symbol are available"""
	return available_symbols.get(symbol, 0)

func get_total_symbol_count() -> int:
	"""Get total number of all symbols in pool"""
	var total = 0
	for count in available_symbols.values():
		total += count
	return total

func prepare_for_roll():
	"""Set up temporary pool for a single roll"""
	_current_roll_pool.clear()
	
	# Add all available symbols to the temporary pool
	for symbol_data in available_symbols:
		var quantity = available_symbols[symbol_data]
		for i in range(quantity):
			_current_roll_pool.append(symbol_data)
	
	# Shuffle for randomness
	_current_roll_pool.shuffle()

func draw_symbol_for_roll() -> SymbolData:
	"""Draw one symbol from the current roll pool"""
	if _current_roll_pool.is_empty():
		return null
	return _current_roll_pool.pop_back()

func is_roll_pool_empty() -> bool:
	"""Check if current roll pool is empty"""
	return _current_roll_pool.is_empty()

func get_all_available_symbols() -> Array[SymbolData]:
	"""Get list of all unique symbols available"""
	return available_symbols.keys()
