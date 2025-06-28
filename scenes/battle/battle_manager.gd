# BattleManager.gd
extends Node

# Define the possible states for our battle flow.
enum State {
	BATTLE_START,
	PLAYER_ROLL,    # Waiting for the player to roll the slot machine.
	PLAYER_ACTION,  # Player has rolled and can now act (attack, cast spells).
	PLAYER_TARGETING, # Player has selected an action and must choose a target.
	ENEMY_TURN,     # The AI is taking its turn.
	BATTLE_WIN,
	BATTLE_LOSE
}

# Variables to hold our current state and node references.
var current_state: State
var player: PlayerCharacter # We'll assign this in _ready()
var enemies_container: Node # The parent node holding all enemy scenes
var enemies: Array # enemies_container.get_children()

# UI Node References
@onready var slot_machine = $/root/Battle/UI/SlotMachine
@onready  var roll_button = $/root/Battle/UI/SlotMachine/RollButton
@onready var attack_button = $/root/Battle/UI/AttackButton
@onready var end_turn_button = $/root/Battle/UI/EndTurnButton
# @onready var spell_panel = get_node("/root/Battle/UI/SpellPanel") # For later


# To store what action the player wants to perform when targeting.
var pending_action = null


func _ready():
	# Get references to the characters
	player = get_node("/root/Battle/Characters/Player")
	enemies_container = get_node("/root/Battle/Characters/Enemies")
	enemies = enemies_container.get_children()

	# Connect signals from UI elements to our manager's functions.
	slot_machine.roll_completed.connect(_on_slot_roll_completed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	
	# Connect to the targeted signal for each enemy
	for enemy in enemies_container.get_children():
		enemy.enemy_targeted.connect(_on_enemy_targeted)
		
	# Start the battle
	enter_state(State.PLAYER_ROLL)

# --- Signal Handlers ---

func _on_enemy_targeted(enemy_node):
	pass
	
	## Only do something if we are actually waiting for a target.
	#if current_state != State.PLAYER_TARGETING:
		#return
#
	#print("Player targeted ", enemy_node.name)
#
	## Execute the action that was waiting for a target.
	#if pending_action == "basic_attack":
		## Calculate damage (Player's attack - Enemy's block)
		## For this, your enemy and player need stats. Let's assume they have them.
		#var damage = turn_attack - enemy_node.get("block", 0) # Assuming enemy has a 'block' var
		#if damage > 0:
			#enemy_node.take_damage(damage) # Assuming enemy has a take_damage function
#
	## For spells, you'd have more logic here:
	## elif pending_action is a spell object:
	##     pending_action.execute(enemy_node)
#
	## Clear the pending action
	#pending_action = null
#
	## After attacking, the player's turn is over.
	## (Or you could return to PLAYER_ACTION if you want them to do more things)
	#enter_state(State.ENEMY_TURN)
	

func _on_slot_roll_completed(symbols: Array):
	# This is called when the SlotMachine is done rolling.
	# Make sure we are in the correct state to accept a roll.
	if current_state != State.PLAYER_ROLL:
		return

	# Step 1: Apply the results from the roll to our turn stats.
	print("Roll received: ", symbols)
	# Process instant effects first (like global modifiers)
	for symbol in symbols:
		if symbol.is_instant_effect:
			_process_symbol_immediately(symbol)
	
	# Process remaining symbols in order
	for symbol in symbols:
		if !symbol.is_instant_effect:
			await _process_symbol_with_delay(symbol, 0.3)
	
	enter_state(State.PLAYER_ACTION)
		
		
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
			return [player]

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
			var all_chars = [player]
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

	if symbol.mana_effect != 0 and target.has_method("modify_mana"):
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


func _on_attack_button_pressed():
	if current_state != State.PLAYER_ACTION:
		return
	
	# The player wants to attack, so we enter targeting mode.
	pending_action = "basic_attack"
	enter_state(State.PLAYER_TARGETING)

func _on_end_turn_button_pressed():
	if current_state != State.PLAYER_ACTION:
		return
	
	# The player ends their turn, so we move to the enemy's turn.
	enter_state(State.ENEMY_TURN)

func enter_state(new_state: State):
	current_state = new_state
	print("Entering state: ", State.keys()[new_state]) # For debugging

	match new_state:
		State.PLAYER_ROLL:
			# Enable the roll button, disable actions.
			roll_button.disabled = false
			attack_button.disabled = true
			end_turn_button.disabled = true
			# spell_panel.hide() # for later

			# Reset turn stats from the previous turn
			
			# TODO: Update UI to show these stats are 0

		State.PLAYER_ACTION:
			# The player has rolled, now they can act.
			# Disable roll, enable actions.
			roll_button.disabled = true
			attack_button.disabled = false
			end_turn_button.disabled = false
			# spell_panel.show() # for later

		State.PLAYER_TARGETING:
			# Player needs to select a target, so disable other actions.
			attack_button.disabled = true
			end_turn_button.disabled = true
			# TODO: Add a visual indicator for targeting mode (e.g., change cursor)
			
		State.ENEMY_TURN:
			# Disable all player controls.
			attack_button.disabled = true
			end_turn_button.disabled = true
			# We'll implement the enemy's logic here later.
			# For now, we'll just go back to the player's turn.
			await get_tree().create_timer(1.0).timeout # Simulate enemy thinking
			print("Enemy turn ends.")
			enter_state(State.PLAYER_ROLL)
