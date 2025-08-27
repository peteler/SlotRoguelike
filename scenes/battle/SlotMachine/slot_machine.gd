# SlotMachine.gd
class_name SlotMachine
extends Control

var symbol_processor: SymbolProcessor
var symbol_pool: SymbolPool

@export var slot_scene: PackedScene
@onready var slot_container: HBoxContainer = $SlotContainer
@onready var roll_button: Button = $RollButton


func _ready():
	
	add_to_group("slot_machine")
	
	# Create and add symbol processor as child
	symbol_processor = SymbolProcessor.new()
	add_child(symbol_processor)
	
	roll_button.pressed.connect(_on_roll_button_pressed)
	Global.battle_state_changed.connect(_on_battle_state_changed)

func _on_battle_state_changed(state_name: String):
	match state_name:
		"PLAYER_ROLL":
			on_enter_player_roll()
		_:
			return

func on_enter_player_roll():
	enable_roll()

func enable_roll():
	roll_button.disabled = false

func disable_roll():
	roll_button.disabled = true

# called once from game_controller when setting up battle_manager
func init_from_player_data(player_data: PlayerData):
	
	symbol_pool = player_data.get_symbol_pool()
	
	var slot_count = player_data.slot_count
	# Clear any old slots first.
	for child in slot_container.get_children():
		child.queue_free()
	
	# Instance the new slots.
	for i in range(slot_count):
		var slot_instance = slot_scene.instantiate()
		slot_container.add_child(slot_instance)
		
	# update RollButton position
	roll_button.position = Vector2(slot_count * 115 + 25, 25)

# This is the main function that runs the turn.
func _on_roll_button_pressed():
	if not symbol_pool or not symbol_processor:
		push_error("Missing required components for slot roll!")
		return
	
	# Disable the button to prevent clicking again while rolling.
	roll_button.disabled = true

	# 1. Prepare the symbol pool for this roll
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
	await symbol_processor.process_symbols_in_sequence(symbols_rolled)
	
	# 5. Emit completion signal for BattleManager
	Global.slot_roll_completed.emit()
	print("Roll complete! Symbols_rolled: ", symbols_rolled)
