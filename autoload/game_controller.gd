# GameController.gd - Main game flow manager
# Add this as an autoload singleton in Project Settings
extends Node

## Scene paths 
const BATTLE_SCENE = "res://scenes/battle/battle_manager.tscn"
const MAP_SCENE = "res://scenes/map/map_manager.tscn"
const MAIN_MENU_SCENE = "res://scenes/main_menu.tscn"
const VICTORY_SCREEN_SCENE = "res://scenes/battle/victory_screen.tscn"
const DEFEAT_SCREEN_SCENE = "res://scenes/battle/defeat_screen.tscn"

## Class paths
var test_class: PlayerClassTemplate = load("res://resources/player/player_classes/test_player_class.tres")

## Player reference: DATA PERSISTS! SCENES GET DESTROYED, that's why playerdata and not playercharacter
var player_data: PlayerData

## Current game state
var current_event: EventData

# Map state persistence
var map_manager: MapManager

# ------------------------------------------

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
	"""Initialize new game and go to map"""
	# Create fresh player data from class
	if test_class:
		player_data = create_new_player_data_from_class_data(test_class)

	# Go to map
	change_scene_to(MAP_SCENE)
	
	# Wait for the map scene to load, then initialize the map
	await get_tree().process_frame
	var map_scene_node = get_tree().current_scene
	if map_scene_node:
		map_manager = map_scene_node.get_node("MapManager")
		if map_manager:
			map_manager.start_new_map()	

# --- Battle Management ---

func start_battle(encounter_data: EncounterData):
	"""Start a battle with the given encounter data"""
	current_event = encounter_data as EncounterData
	change_scene_to(BATTLE_SCENE)
	
	# have to wait for two frames so battle_manager's ready is called
	await get_tree().process_frame
	await get_tree().process_frame

	var all_battle_managers = get_tree().get_nodes_in_group("battle_manager")
	print("Nodes in 'battle_manager' group: ", all_battle_managers)
	
	setup_battle_manager()

func setup_battle_manager():
	"""Configure the battle manager with current encounter and player data"""
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	print("battle_manager: ", battle_manager)
	if battle_manager and current_event.event_type == EventData.EVENT_TYPE.ENCOUNTER:
		# Call the new initialize_battle method instead of the old setup
		if battle_manager.has_method("initialize_battle"):
			print("reached here")
			battle_manager.initialize_battle(current_event as EncounterData, player_data)
		else:
			push_error("BattleManager missing initialize_battle method")
	else:
		print("eventtype: ", current_event.event_type)
		push_error("setup_battle_manager failed - missing battle_manager or wrong event type")

# --- Signal Handlers ---

func _on_battle_win():
	"""Handle battle victory"""
	print("Game Controller: Battle Victory!")
	change_scene_to(VICTORY_SCREEN_SCENE)

func _on_battle_lose():
	"""Handle battle defeat"""
	print("Game Controller: Battle Defeat!")
	change_scene_to(DEFEAT_SCREEN_SCENE)

func _on_return_to_map():
	"""Return to map after victory"""
	print("Game Controller: Returning to map")
	change_scene_to(MAP_SCENE)
	
	# Wait for the map scene to load, then restore the correct available nodes
	await get_tree().process_frame
	var map_scene_node = get_tree().current_scene
	if map_scene_node:
		map_manager = map_scene_node.get_node("MapManager")
		if map_manager:
			# This ensures the map remembers where you were and shows the correct next paths
			map_manager.set_available_nodes_from_selection(map_manager.current_node_id)


func _on_game_over():
	"""Handle game over - reset and go to main menu"""
	print("Game Controller: Game Over")
	player_data = null  # Reset player data
	change_scene_to(MAIN_MENU_SCENE)

func _on_event_selected(event_data: EventData):
	current_event = event_data
	print("oneventselected, eventtype == encounter? ", event_data.event_type == EventData.EVENT_TYPE.ENCOUNTER)
	match event_data.event_type:
		EventData.EVENT_TYPE.ENCOUNTER:
			start_battle(event_data as EncounterData)
		# Add other event types here later
		_:
			push_warning("Event type not implemented: " + str(event_data.event_type))

# --- Helper Functions ---

func save_game():
	"""Save current game state (implement as needed)"""
	# TODO: Implement save system
	pass

func load_game():
	"""Load saved game state (implement as needed)"""
	# TODO: Implement save system
	pass

func create_new_player_data_from_class_data(class_template: PlayerClassTemplate) -> PlayerData:
	"""Create a new PlayerData with this class's starting values"""
	var new_player_data = PlayerData.new()
	
	# Copy class data to player data
	new_player_data.class_template = class_template
	new_player_data.max_health = class_template.max_health
	new_player_data.current_health = class_template.max_health
	
	# Set starting resources
	new_player_data.symbol_pool = class_template.symbol_pool.duplicate(true)
	new_player_data.current_mana = class_template.starting_mana
	new_player_data.max_mana = class_template.max_mana
	new_player_data.mana_per_turn = class_template.mana_per_turn
	new_player_data.gold = class_template.gold
	
	
	return new_player_data

func get_player_data_reference() -> PlayerData:
	"""Get reference to player data - adapt this to your game's architecture"""
	var player = get_tree().get_first_node_in_group("player_character") as PlayerCharacter
	if player and player.player_data:
		return player.player_data
	else: 
		push_error("failed: get_player_data_reference")
		return null
