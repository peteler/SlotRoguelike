# SlotMachine.gd
class_name SlotMachine
extends Control

# Assign your Slot.tscn scene in the Inspector.
@export var slot_scene: PackedScene
# Assign the player's starting symbols and their quantities here.
# This can be modified by game progression.
@export var player_symbol_pool: Dictionary = {
 preload("res://custom_resources/symbols/sword.tres"): 5,
 preload("res://custom_resources/symbols/shield.tres"): 5,
 preload("res://custom_resources/symbols/heart.tres"): 1,
 preload("res://custom_resources/symbols/mana_potion.tres"): 2
}

@onready var slot_container: HBoxContainer = $SlotContainer
@onready var roll_button: Button = $RollButton

# The number of slots the player currently has.
var number_of_slots: int = 5 # You will update this from player stats.

var _symbol_pool = SymbolPool.new()

func _ready():
	roll_button.pressed.connect(_on_roll_button_pressed)
	# Initial setup of the slots.
	setup_slots(number_of_slots)

# Call this function whenever the number of slots needs to change.
func setup_slots(amount: int):
	# separates slots so they don't stack
	#slot_container.separation = 115 # this is an error somehow ..
	# Clear any old slots first.
	for child in slot_container.get_children():
		child.queue_free()
	
	# Instance the new slots.
	number_of_slots = amount
	for i in range(number_of_slots):
		var slot_instance = slot_scene.instantiate()
		slot_container.add_child(slot_instance)
		
	# update RollButton position
	roll_button.position = Vector2(amount * 115 + 25, 25)

# This is the main function that runs the turn.
func _on_roll_button_pressed():
	# Disable the button to prevent clicking again while rolling.
	roll_button.disabled = true

	# 1. Initialize the pool of symbols for this roll.
	_symbol_pool.initialize(player_symbol_pool)

	# 2. Prepare to collect the results.
	var symbols_rolled = []

	# 3. Roll the slots sequentially.
	var slots = slot_container.get_children()
	for slot in slots:
		# Draw a symbol from our finite pool.
		var drawn_symbol: SymbolData = _symbol_pool.draw_symbol()

		if drawn_symbol:
			# Update the slot's visual.
			slot.set_symbol(drawn_symbol)

			# add to rolled_symbols
			symbols_rolled.append(drawn_symbol)
		else:
			# Handle the case where you run out of symbols (if possible).
			slot.set_symbol(null) # Show a blank slot.
			print("Warning: Symbol pool is empty!")
		
		# Wait for a short duration to create the left-to-right effect.
		await get_tree().create_timer(0.05).timeout

	# 4. Emit the signal with the final, aggregated results.
	Global.slot_roll_completed.emit(symbols_rolled)
	print("Roll complete! Symbols_rolled: ", symbols_rolled)
