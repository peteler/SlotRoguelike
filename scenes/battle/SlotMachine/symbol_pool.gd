class_name SymbolPool

# This array holds all symbols for the upcoming roll.
var _symbols_in_pool: Array[SymbolData] = []

# Call this to set up the pool before a roll.
# 'symbols' should be a dictionary like {SymbolData: quantity}
func initialize(symbols: Dictionary):
	_symbols_in_pool.clear()
	for symbol_data in symbols:
		var quantity = symbols[symbol_data]
		for i in range(quantity):
			_symbols_in_pool.append(symbol_data)
	
	# Shuffle the pool to randomize the draw order.
	_symbols_in_pool.shuffle()

# Draw one symbol from the pool. Returns null if the pool is empty.
func draw_symbol() -> SymbolData:
	if _symbols_in_pool.is_empty():
		return null
	# pop_back() is an efficient way to get and remove the last element.
	return _symbols_in_pool.pop_back()

func is_empty() -> bool:
	return _symbols_in_pool.is_empty()
