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


## UI Node References - now relative to self since BattleManager is root
@onready var slot_machine_container = $UI/SlotMachineContainer
@onready var attack_button = $UI/AttackButton
@onready var end_turn_button = $UI/EndTurnButton

## Scene references
@onready var characters_node = $Characters
@onready var enemies_container = $Characters/Enemies
@onready var spawn_points = $SpawnPoints
@onready var player_spawn = $PlayerSpawn

## Runtime created objects
var slot_machine: Node
var player_character: PlayerCharacter

## Scene resources
@export var player_character_scene: PackedScene = preload("res://scenes/characters/player_character.tscn")
@export var slot_machine_scene: PackedScene = preload("res://scenes/battle/SlotMachine/slot_machine.tscn")

## Encounter Management
@export var current_encounter: EncounterData
@export var enemy_scene: PackedScene = preload("res://scenes/characters/enemy.tscn")

# Turn order management
var turn_order: Array[Enemy] = []
var enemies: Array

# --------------------------------------------------

func _ready():
	# Add to group for GameController to find
	print("battle_manager.ready called")
	add_to_group("battle_manager")
	print("add_to_group called")
	# initialization is called from gamecontroller

# called once by GameController to initialize a battle encounter
func initialize_battle(encounter_data: EncounterData, player_data: PlayerData):
	"""Called by GameController to set up the battle with proper data"""
	if not encounter_data or not player_data:
		push_error("Missing encounter or player data for battle initialization!")
		return
	
	# Store references
	current_encounter = encounter_data
	
	# Initialize runtime objects with the provided data
	spawn_player_character(player_data)
	create_slot_machine(player_data)
	
	# Set up the encounter (enemies)
	setup_encounter(encounter_data)
	
	
	# Connect signals after everything is set up
	setup_signals()
	
	# Start the battle
	enter_state(State.PLAYER_ROLL)
# --------------------------------------------------

# --- init helpers ---
func setup_signals():
	"""Set up all signal connections"""
	Global.slot_roll_completed.connect(_on_slot_roll_completed)
	Global.attack_button_pressed.connect(_on_attack_button_pressed)
	Global.end_turn_button_pressed.connect(_on_end_turn_button_pressed)
	Global.character_targeted.connect(_on_character_targeted)
	Global.character_died.connect(_on_character_died)
	
	# Connect UI elements to emit global signals
	attack_button.pressed.connect(func(): Global.attack_button_pressed.emit())
	end_turn_button.pressed.connect(func(): Global.end_turn_button_pressed.emit())

func spawn_player_character(player_data: PlayerData):
	"""Create player character from provided player_data"""
	if not player_data:
		push_error("No player data available for battle!")
		return
	
	# Instantiate player character
	player_character = player_character_scene.instantiate()
	player_character.player_data = player_data
	
	# Position at spawn point
	if player_spawn:
		player_character.global_position = player_spawn.global_position
	
	# Add to scene
	characters_node.add_child(player_character)
	print("Player character spawned")

func create_slot_machine(player_data: PlayerData):
	"""Create slot machine based on provided player data"""
	if not player_data:
		push_error("No player data for slot machine!")
		return
	
	# Instantiate slot machine
	slot_machine = slot_machine_scene.instantiate()
	slot_machine_container.add_child(slot_machine)
	
	# Initialize with player data
	if slot_machine.has_method("init_from_player_data"):
		slot_machine.init_from_player_data(player_data)
	
	# Add to group for any other systems that need to find it
	slot_machine.add_to_group("slot_machine")
	print("Slot machine created and initialized")
# --------------------------------------------------

# --- Signal Handlers ---

func _on_character_targeted(character: Character):
	# Only process in targeting states
	if current_state != State.PLAYER_TARGETING:
		return
	
	# Only handle enemy targeting for now
	if not character is Enemy:
		return
		
	var enemy_node = character as Enemy
	
	# Handle based on current targeting mode
	match current_targeting_mode:
		
		TargetingMode.ATTACK:
			player_character.perform_basic_attack(enemy_node)
		TargetingMode.SPELL:
			pass
	
	# Clean up targeting state
	end_targeting()

func _on_character_died(character: Character):
	# Handle character death and check for battle end conditions
	if character is Enemy:
		var enemy = character as Enemy
		print("Enemy died: ", enemy.enemy_data.character_name)
		
		# Remove dead enemy from turn order
		if enemy in turn_order:
			turn_order.erase(enemy)
		
		# Check if all enemies are dead (battle win)
		if are_all_enemies_dead():
			enter_state(State.BATTLE_WIN)
			return
	
	elif character == player_character:
		print("Player character died!")
		enter_state(State.BATTLE_LOSE)
		return

func _on_slot_roll_completed(symbols: Array[SymbolData]):
	# This is called when the SlotMachine is done rolling.
	# Make sure we are in the correct state to accept a roll.
	if current_state != State.PLAYER_ROLL:
		push_error("roll completed signal received while not in player_roll state")
		return

	# The SlotMachine now handles all symbol processing via SymbolProcessor
	# We just need to wait for it to complete and move to the next state
	print("Roll received: ", symbols)
	
	# Move to player action state - symbol effects have already been applied
	enter_state(State.PLAYER_ACTION)

func _on_attack_button_pressed():
	if current_state == State.PLAYER_ACTION:
		start_attack_targeting()

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
	
	# Emit state change to global bus
	Global.battle_state_changed.emit(State.keys()[new_state])

	match new_state:
		State.PLAYER_ROLL:
			# Enable the roll button, disable actions.
			if slot_machine:
				slot_machine.enable_roll()
			attack_button.disabled = true
			end_turn_button.disabled = true
			# spell_panel.hide() # for later

			# init start of player's turn for player & enemies
			player_character.init_start_of_turn()
			for enemy in enemies_container.get_children():
				if enemy is Enemy and enemy.is_alive():
					enemy.call_on_start_of_player_turn()


		State.PLAYER_ACTION:
			# The player has rolled, now they can act.
			# Disable roll, enable actions.
			if slot_machine:
				slot_machine.disable_roll()
			attack_button.disabled = (player_character.attack <= 0) or (not player_character.can_attack)
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
			
		State.BATTLE_WIN:
			# Disable all player controls
			disable_battle_ui()
			
			# Handle victory
			handle_battle_win()
			
		State.BATTLE_LOSE:
			# Disable all player controls
			disable_battle_ui()
			# Handle defeat
			handle_battle_lose()

func end_targeting():
	# TODO:  Remove highlights
	
	# Reset targeting
	current_targeting_mode = TargetingMode.NONE
	current_spell = null
	
	# Return to action state
	enter_state(State.PLAYER_ACTION)

func start_attack_targeting():
	current_targeting_mode = TargetingMode.ATTACK
	enter_state(State.PLAYER_TARGETING)
	
	# TODO: Highlight enemies

# TODO: spell system
func start_spell_targeting(spell: Spell):
	current_targeting_mode = TargetingMode.SPELL
	current_spell = spell
	enter_state(State.PLAYER_TARGETING)
	
	# TODO: Highlight valid targets
# --------------------------------------------------

# --- Encounter Setup Management ---

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

func spawn_enemies_from_encounter():
	"""Spawn all enemies defined in the encounter"""
	if not current_encounter:
		push_error("No encounter data available")
		return
	
	for enemy_spawn in current_encounter.enemy_spawns:
		var enemy_instance = create_enemy_from_spawn(enemy_spawn)
		if enemy_instance:
			enemies_container.add_child(enemy_instance)
			print("added ", enemy_instance, " as child")

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
	
	#TODO: check if needed... Apply modifiers
	# apply_spawn_modifiers(enemy_instance, enemy_spawn)
	
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
# --------------------------------------------------

# --- Enemy Turn Order System ---

func setup_turn_order():
	"""Establish the turn order for this encounter"""
	var spawned_enemies = enemies_container.get_children()
	
	if current_encounter.use_custom_turn_order:
		setup_custom_turn_order(spawned_enemies)
	else:
		setup_basic_turn_order(spawned_enemies)

func setup_custom_turn_order(spawned_enemies: Array):
	"""Use the explicitly defined turn order"""
	turn_order.clear()
	
	for turn_index in current_encounter.custom_turn_order:
		if turn_index >= 0 and turn_index < spawned_enemies.size():
			turn_order.append(spawned_enemies[turn_index])
		else:
			push_warning("Invalid turn order index: " + str(turn_index))

func setup_basic_turn_order(spawned_enemies: Array):
	"""Use turn_priority values to determine order"""
	turn_order.clear()

	for enemy in spawned_enemies:
		turn_order.append(enemy)

func execute_enemy_turns():
	"""
	Called once when entering enemy turn state
	Executes enemy turns according to turn order
	"""

	for enemy in turn_order:
		print("inside execute_enemy_turns loop")
		if enemy.is_alive():
			print("inside execute_enemy_turns loop, enemy is alive")
			await enemy.start_turn()
	
	Global.all_enemy_turns_completed.emit()
# --------------------------------------------------

# --- Battle End Condition Functions ---

func are_all_enemies_dead() -> bool:
	"""Check if all enemies in the encounter are defeated"""
	for enemy in enemies_container.get_children():
		if enemy is Enemy and enemy.is_alive():
			return false
	return true

func disable_battle_ui():
	"""Disable all battle UI elements when battle ends"""
	if slot_machine and slot_machine.has_method("disable_roll"):
		slot_machine.disable_roll()
	attack_button.disabled = true
	end_turn_button.disabled = true

func handle_battle_win():
	print("Battle win")
	# Emit victory signal with rewards
	Global.battle_win.emit()

func handle_battle_lose():
	print("Battle lose")
	# Emit defeat signal
	Global.battle_lose.emit()
# --------------------------------------------------

# --- Utility Functions ---
func clear_enemies():
	"""Clear all enemies from the battle"""
	for enemy in enemies_container.get_children():
		enemy.queue_free()

# --------------------------------------------------
