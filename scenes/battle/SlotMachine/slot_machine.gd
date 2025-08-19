# SlotMachine.gd
class_name SlotMachine
extends Control

# Assign your Slot.tscn scene in the Inspector.
# References to player data instead of hardcoded symbols
var player_data: PlayerData
var symbol_processor: SymbolProcessor

@export var slot_scene: PackedScene
@onready var slot_container: HBoxContainer = $SlotContainer
@onready var roll_button: Button = $RollButton


func _ready():
	# Get references to needed components
	player_data = get_player_data_reference()
	
	# Create and add symbol processor as child
	symbol_processor = SymbolProcessor.new()
	add_child(symbol_processor)
	
	roll_button.pressed.connect(_on_roll_button_pressed)
	
	# Setup slots based on player data
	if player_data:
		setup_slots(player_data.slot_count)
	else:
		push_error("No player data found for slot machine!")

func get_player_data_reference() -> PlayerData:
	"""Get reference to player data - adapt this to your game's architecture"""
	var player = get_tree().get_first_node_in_group("player_character") as PlayerCharacter
	if player and player.player_data:
		return player.player_data
	return null

# Call this function whenever the number of slots needs to change.
func setup_slots(amount: int):
	# Clear any old slots first.
	for child in slot_container.get_children():
		child.queue_free()
	
	# Instance the new slots.
	for i in range(amount):
		var slot_instance = slot_scene.instantiate()
		slot_container.add_child(slot_instance)
		
	# update RollButton position
	roll_button.position = Vector2(amount * 115 + 25, 25)

# This is the main function that runs the turn.
func _on_roll_button_pressed():
	if not player_data or not symbol_processor:
		push_error("Missing required components for slot roll!")
		return
	
	# Disable the button to prevent clicking again while rolling.
	roll_button.disabled = true

	# 1. Prepare the symbol pool for this roll
	var symbol_pool = player_data.get_symbol_pool()
	symbol_pool.prepare_for_roll()

	# 2. Prepare to collect the results.
	var symbols_rolled: Array[SymbolData] = []

	# 3. Roll the slots sequentially.
	var slots = slot_container.get_children()
	for slot in slots:
		# Draw a symbol from our finite pool.
		var drawn_symbol: SymbolData = symbol_pool.draw_symbol_for_roll()

		if drawn_symbol:
			# Update the slot's visual.
			slot.set_symbol(drawn_symbol)
			symbols_rolled.append(drawn_symbol)
		else:
			#TODO: implement discard pile for symbols like Slay The Spire
			slot.set_symbol(null) # Show a blank slot.
			print("Warning: Symbol pool is empty!")
		
		# Wait for a short duration to create the left-to-right effect.
		await get_tree().create_timer(0.05).timeout

	# 4. Process the symbols using the SymbolProcessor
	await symbol_processor.process_symbols_in_sequence(symbols_rolled, 0.1)
	
	# 5. Emit completion signal for BattleManager
	Global.slot_roll_completed.emit(symbols_rolled)
	print("Roll complete! Symbols_rolled: ", symbols_rolled)

# should this be moved to playerdata?
func update_slot_count(new_count: int):
	"""Update the number of slots and refresh display"""
	if player_data:
		player_data.slot_count = new_count
		setup_slots(new_count)
