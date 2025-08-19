# GameController.gd - Main game flow manager
# Add this as an autoload singleton in Project Settings
extends Node

## Scene paths [ NOT REAL ]
const BATTLE_SCENE = "res://scenes/Battle.tscn"
const MAP_SCENE = "res://scenes/Map.tscn"
const MAIN_MENU_SCENE = "res://scenes/MainMenu.tscn"
const VICTORY_SCREEN_SCENE = "res://scenes/VictoryScreen.tscn"
const DEFEAT_SCREEN_SCENE = "res://scenes/DefeatScreen.tscn"

## Player progression data
# var player_symbol_pool: Dictionary = {}/ custom resource?
var player_data: PlayerData  #TODO

## Current game state
var current_event: EventData

func _ready():
	# Set up singleton to persist between scenes
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect to global signals for game flow
	Global.battle_win.connect(_on_battle_win)
	Global.battle_lose.connect(_on_battle_lose)
	Global.return_to_map.connect(_on_return_to_map)
	Global.game_over.connect(_on_game_over)
	Global.event_selected.connect(_on_event_selected)

# --- Scene Management ---

func change_scene_to(scene_path: String):
	"""Safely change to a new scene"""
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Failed to load scene: " + scene_path)

func start_new_game():
	
	# Initialize player data
	
	# Go to map or first encounter
	change_scene_to(MAP_SCENE)

func start_battle(encounter_data: EncounterData):
	"""Start a battle with the given encounter data"""
	current_encounter = encounter_data
	change_scene_to(BATTLE_SCENE)
	
	# After scene loads, set up the battle manager
	await get_tree().process_frame
	setup_battle_manager()

func setup_battle_manager():
	"""Configure the battle manager with current encounter and player data"""
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var slot_machine = get_tree().get_first_node_in_group("slot_machine")
	
	if battle_manager and current_encounter:
		battle_manager.current_encounter = current_encounter
		battle_manager.setup_encounter(current_encounter)
	
	if slot_machine:
		slot_machine.player_symbol_pool = player_symbol_pool.duplicate()

# --- Signal Handlers ---

func _on_battle_win():
	"""Handle battle victory"""
	print("Game Controller: Battle Victory!")
	
	# Store rewards for display
	last_battle_rewards = rewards
	encounters_completed += 1
	
	# Add rewards to player's symbol pool
	add_rewards_to_player_pool(rewards)
	
	# The BattleManager will handle showing victory screen briefly
	# Then emit return_to_map signal

func _on_battle_lose():
	"""Handle battle defeat"""
	print("Game Controller: Battle Defeat!")
	
	# The BattleManager will handle showing defeat screen briefly
	# Then emit game_over signal

func _on_return_to_map():
	"""Return to map after victory"""
	print("Game Controller: Returning to map")
	change_scene_to(MAP_SCENE)

func _on_game_over():
	"""Handle game over"""
	print("Game Controller: Game Over")
	change_scene_to(MAIN_MENU_SCENE)

func _on_event_selected(event_data: EventData):
	# switch case for event types? shop/ battle encounter/ custom event?
	pass

# --- Helper Functions ---

func save_game():
	"""Save current game state (implement as needed)"""
	# TODO: Implement save system
	pass

func load_game():
	"""Load saved game state (implement as needed)"""
	# TODO: Implement save system
	pass
