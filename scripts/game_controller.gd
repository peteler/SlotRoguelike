# GameController.gd - Main game flow manager
# Add this as an autoload singleton in Project Settings
extends Node

## Scene paths [ NOT REAL ]
const BATTLE_SCENE = "res://scenes/battle/battle.tscn"
const MAP_SCENE = "res://scenes/map.tscn"
const MAIN_MENU_SCENE = "res://scenes/main_menu.tscn"
const VICTORY_SCREEN_SCENE = "res://scenes/victory_screen.tscn"
const DEFEAT_SCREEN_SCENE = "res://scenes/defeat_screen.tscn"

## Player reference: DATA PERSISTS! SCENES GET DESTROYED, that's why playerdata and not playercharacter
var player_data: PlayerData

## Current game state
var current_event: EventData

# ------------------------------------------

func _ready():
	# Set up singleton to persist between scenes
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get references
	player_data = get_player_data_reference()
	
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
	
	# TODO: Initialize player data? needed or done by ready() function of player_character? does he need to be a child or what?
	
	# Go to map or first encounter
	change_scene_to(MAP_SCENE)


# --- Battle Management ---

func start_battle(encounter_data: EncounterData):
	"""Start a battle with the given encounter data"""
	current_event = encounter_data as EncounterData
	change_scene_to(BATTLE_SCENE)
	
	# After scene loads, set up the battle manager
	await get_tree().process_frame
	setup_battle_manager()

func setup_battle_manager():
	"""Configure the battle manager with current encounter and player data"""
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var slot_machine = get_tree().get_first_node_in_group("slot_machine")
	
	if battle_manager and current_event.event_type == EventData.EVENT_TYPE.ENCOUNTER:
		battle_manager.setup_encounter(current_event)
	else:
		push_error("setup_battle_manager failed")
		
	if slot_machine and player_data:
		slot_machine.init_from_player_data(player_data)
	else:
		push_error("slot_machine init failed")



# --- Signal Handlers ---

func _on_battle_win():
	"""Handle battle victory"""
	print("Game Controller: Battle Victory!")
	
	# TODO:
	# switch to a rewards scene? 
	# then wait for a signal to return to map, that signal will

func _on_battle_lose():
	"""Handle battle defeat"""
	print("Game Controller: Battle Defeat!")
	
	# The BattleManager will handle showing defeat screen briefly
	# Then emit game_over signal

func _on_return_to_map():
	"""Return to map after victory"""
	print("Game Controller: Returning to map")
	change_scene_to(MAP_SCENE)
	
	# TODO: how to know where to return to? i need the map manager to remember all map related data
	

func _on_game_over():
	"""Handle game over"""
	print("Game Controller: Game Over")
	change_scene_to(MAIN_MENU_SCENE)

func _on_event_selected(event_data: EventData):
	# TODO:
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

func get_player_data_reference() -> PlayerData:
	"""Get reference to player data - adapt this to your game's architecture"""
	var player = get_tree().get_first_node_in_group("player_character") as PlayerCharacter
	if player and player.player_data:
		return player.player_data
	else: 
		push_error("failed: get_player_data_reference")
		return null
