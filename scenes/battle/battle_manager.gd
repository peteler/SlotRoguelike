# BattleManager.gd
extends Node

## States
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

# Targeting mode enum
enum TargetingMode { NONE, ATTACK, SPELL }

# Variables to hold our current state and node references.
var current_state: State
var current_targeting_mode := TargetingMode.NONE
var current_spell: Spell


## UI Node References
@onready var slot_machine = $/root/Battle/UI/SlotMachine
@onready var roll_button = $/root/Battle/UI/SlotMachine/RollButton
@onready var attack_button = $/root/Battle/UI/AttackButton
@onready var end_turn_button = $/root/Battle/UI/EndTurnButton

## Encounter Management
@export var current_encounter: EncounterData
@export var enemy_scene: PackedScene = preload("res://scenes/characters/enemy.tscn")

# Turn order management
var turn_order: Array[Enemy] = []
var current_turn_index: int = 0

# Spawn points container
@onready var spawn_points: Node = $/root/Battle/SpawnPoints

## Characters
var player_character: PlayerCharacter # We'll assign this in _ready()
var enemies_container: Node # The parent node holding all enemy scenes
var enemies: Array # enemies_container.get_children()

# classes [structs]
class PlayerStatus:
	var has_attacked: bool = false
var player_status: PlayerStatus

func _ready():
	# Get references to the characters
	player_character = get_tree().get_first_node_in_group("player_character")
	enemies_container = get_tree().get_first_node_in_group("enemies_container")
	
	# Load encounter if set
	if current_encounter:
		setup_encounter(current_encounter)
	else:
		push_warning("No encounter data set for BattleManager")
	
	# init structs
	player_status = PlayerStatus.new() 

	# Connect signals from UI elements to our manager's functions 
	# TODO: replace this with a function that loads ui
	slot_machine.roll_completed.connect(_on_slot_roll_completed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	
	# Start the battle
	enter_state(State.PLAYER_ROLL)

# --- Signal Handlers ---

# Revised enemy targeting handler
func _on_enemy_targeted(enemy_node: Area2D):
	# Only process in targeting states
	if current_state != State.PLAYER_TARGETING:
		return
	
	# Handle based on current targeting mode
	match current_targeting_mode:
		TargetingMode.ATTACK:
			handle_attack_targeting(enemy_node)
			# Disable attack for this turn
			player_status.has_attacked = true
		TargetingMode.SPELL:
			handle_spell_targeting(enemy_node)
	
	# Clean up targeting state
	end_targeting()

#TODO:
func _on_enemy_died(enemy_node: Area2D):
	pass

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

# Attack button handler
func _on_attack_button_pressed():
	if current_state == State.PLAYER_ACTION:
		start_attack_targeting()

# Spell button handler (connect all spell buttons to this)
func _on_spell_button_pressed(spell: Spell):
	pass

func _on_end_turn_button_pressed():
	if current_state != State.PLAYER_ACTION:
		return
	
	# The player ends their turn, so we move to the enemy's turn.
	enter_state(State.ENEMY_TURN)
# --------------------------------------------------

# --- state management functions ---
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
			init_player_start_of_turn()
			init_enemy_start_of_turn()
			

		State.PLAYER_ACTION:
			# The player has rolled, now they can act.
			# Disable roll, enable actions.
			roll_button.disabled = true
			attack_button.disabled = (player_character.attack <= 0) or player_status.has_attacked
			end_turn_button.disabled = false
			# spell_panel.show() # for later

		State.PLAYER_TARGETING:
			# Player needs to select a target, so disable other actions.
			attack_button.disabled = true
			end_turn_button.disabled = true
			# TODO: Add a visual indicator for targeting mode (e.g., change cursor)
			
		State.ENEMY_TURN:
			# Disable all player controls
			attack_button.disabled = true
			end_turn_button.disabled = true
			
			# Execute enemy turns using turn order
			await execute_enemy_turns()
			
			# Return to player turn
			enter_state(State.PLAYER_ROLL)

# End targeting mode
func end_targeting():
	# TODO:  Remove highlights
	
	# Reset targeting
	current_targeting_mode = TargetingMode.NONE
	current_spell = null
	
	# Return to action state
	enter_state(State.PLAYER_ACTION)

# Start attack targeting
func start_attack_targeting():
	current_targeting_mode = TargetingMode.ATTACK
	enter_state(State.PLAYER_TARGETING)
	
	# TODO: Highlight enemies

# Start spell targeting
func start_spell_targeting(spell: Spell):
	current_targeting_mode = TargetingMode.SPELL
	current_spell = spell
	enter_state(State.PLAYER_TARGETING)
	
	# TODO: Highlight valid targets

func init_player_start_of_turn():
	player_status.has_attacked = false
	player_character.attack = 0
	player_character.block = 0

# TODO: setup enemy intent system
func init_enemy_start_of_turn():
	pass
# --------------------------------------------------

# --- combat helper functions ---

func handle_attack_targeting(target):
	# Apply damage
	var damage = max(0, player_character.attack - target.block)
	target.take_damage_consider_block(damage)
	
	# TODO: Visual feedback

func handle_spell_targeting(target):
	if current_spell:
		current_spell.execute(target)
		# Deduct mana cost would go here
# --------------------------------------------------

# --- symbol interaction functions ---

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
# --------------------------------------------------

# --- Encounter Management ---

func setup_encounter(encounter_data: EncounterData):
	"""Set up the battle from encounter data"""
	current_encounter = encounter_data
	
	# Clear any existing enemies
	clear_enemies()
	
	# Spawn enemies from encounter data
	spawn_enemies_from_encounter()
	
	# Setup turn order
	setup_turn_order()
	
	# Update enemies array
	enemies = enemies_container.get_children()
	
	# Connect signals
	connect_enemy_signals()

func spawn_enemies_from_encounter():
	"""Spawn all enemies defined in the encounter"""
	if not current_encounter:
		push_error("No encounter data available")
		return
	
	for enemy_spawn in current_encounter.enemy_spawns:
		var enemy_instance = create_enemy_from_spawn(enemy_spawn)
		if enemy_instance:
			enemies_container.add_child(enemy_instance)

func create_enemy_from_spawn(enemy_spawn: EnemySpawn) -> Enemy:
	"""Create an enemy instance from spawn configuration"""
	if not enemy_scene or not enemy_spawn.enemy_data:
		push_error("Missing enemy scene or enemy data")
		return null
	
	# Create enemy instance
	var enemy_instance = enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		push_error("Failed to instantiate enemy scene")
		return null
	
	# Set basic data
	enemy_instance.enemy_data = enemy_spawn.enemy_data
	
	# Apply position
	var spawn_position = get_spawn_position(enemy_spawn)
	enemy_instance.global_position = spawn_position
	
	# Apply modifiers
	apply_spawn_modifiers(enemy_instance, enemy_spawn)
	
	return enemy_instance

func get_spawn_position(enemy_spawn: EnemySpawn) -> Vector2:
	"""Get the world position for an enemy spawn"""
	var base_position = Vector2.ZERO
	
	# Try to find spawn point by name
	if not enemy_spawn.spawn_point_name.is_empty() and spawn_points:
		var spawn_point = spawn_points.get_node_or_null(enemy_spawn.spawn_point_name)
		if spawn_point and spawn_point is Marker2D:
			base_position = spawn_point.global_position
		else:
			push_warning("Spawn point '" + enemy_spawn.spawn_point_name + "' not found")
			base_position = get_default_spawn_position()
	else:
		base_position = get_default_spawn_position()
	
	# Apply additional offset
	return base_position + enemy_spawn.spawn_offset

func get_default_spawn_position() -> Vector2:
	"""Fallback position when no spawn point is specified"""
	return Vector2(600, 300)  # Adjust to your game's layout

func apply_spawn_modifiers(enemy: Enemy, spawn_config: EnemySpawn):
	"""Apply spawn-specific modifiers to an enemy"""
	# Apply health modifier
	if spawn_config.health_multiplier != 1.0:
		enemy.max_health = int(enemy.max_health * spawn_config.health_multiplier)
		enemy.current_health = enemy.max_health
	
	# Apply attack modifier (modify the enemy data's base attack)
	if spawn_config.attack_multiplier != 1.0 and enemy.enemy_data:
		enemy.enemy_data.base_attack = int(enemy.enemy_data.base_attack * spawn_config.attack_multiplier)
	
	# Add extra actions
	if not spawn_config.give_extra_actions.is_empty():
		enemy.enemy_data.possible_actions.append_array(spawn_config.give_extra_actions)

# --- Turn Order System ---

func setup_turn_order():
	"""Establish the turn order for this encounter"""
	var spawned_enemies = enemies_container.get_children()
	
	if current_encounter.use_custom_turn_order:
		setup_custom_turn_order(spawned_enemies)
	else:
		setup_priority_based_turn_order(spawned_enemies)

func setup_custom_turn_order(spawned_enemies: Array):
	"""Use the explicitly defined turn order"""
	turn_order.clear()
	
	for turn_index in current_encounter.custom_turn_order:
		if turn_index >= 0 and turn_index < spawned_enemies.size():
			turn_order.append(spawned_enemies[turn_index])
		else:
			push_warning("Invalid turn order index: " + str(turn_index))

func setup_priority_based_turn_order(spawned_enemies: Array):
	"""Use turn_priority values to determine order"""
	turn_order.clear()
	
	# Create array of enemies with their spawn configs for priority sorting
	var enemies_with_priority = []
	
	for i in range(spawned_enemies.size()):
		if i < current_encounter.enemy_spawns.size():
			var spawn_config = current_encounter.enemy_spawns[i]
			enemies_with_priority.append({
				"enemy": spawned_enemies[i],
				"priority": spawn_config.turn_priority
			})
		else:
			# Fallback for enemies without spawn config
			enemies_with_priority.append({
				"enemy": spawned_enemies[i],
				"priority": 0
			})
	
	# Sort by priority (lower priority goes first)
	enemies_with_priority.sort_custom(func(a, b): return a.priority < b.priority)
	
	# Extract sorted enemies
	for entry in enemies_with_priority:
		turn_order.append(entry.enemy)

func get_next_enemy_in_turn_order() -> Enemy:
	"""Get the next enemy that should take a turn"""
	if turn_order.is_empty():
		return null
	
	# Find next alive enemy in turn order
	var attempts = 0
	while attempts < turn_order.size():
		var enemy = turn_order[current_turn_index]
		current_turn_index = (current_turn_index + 1) % turn_order.size()
		
		if enemy.is_alive():
			return enemy
		
		attempts += 1
	
	# No alive enemies found
	return null

# --- Updated Enemy Turn Handling ---

func execute_enemy_turns():
	"""Execute enemy turns according to turn order"""
	if turn_order.is_empty():
		# Fallback to old behavior
		for enemy in enemies:
			if enemy.is_alive():
				await enemy.start_turn()
		return
	
	# Use turn order system
	var enemies_that_acted = 0
	var max_turns = turn_order.size()  # Prevent infinite loops
	
	while enemies_that_acted < max_turns:
		var current_enemy = get_next_enemy_in_turn_order()
		
		if not current_enemy:
			break  # No more alive enemies
		
		await current_enemy.start_turn()
		enemies_that_acted += 1

# --- Utility Functions ---

func clear_enemies():
	"""Clear all enemies from the battle"""
	for enemy in enemies_container.get_children():
		enemy.queue_free()

func connect_enemy_signals():
	"""Connect signals for all enemies"""
	for enemy in enemies_container.get_children():
		enemy.targeted.connect(_on_enemy_targeted)
		enemy.died.connect(_on_enemy_died)

func load_encounter(encounter_resource: EncounterData):
	"""Load a new encounter (useful for transitioning between battles)"""
	setup_encounter(encounter_resource)
