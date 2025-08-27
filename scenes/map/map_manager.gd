# map_manager.gd
# This script manages the map state, including player progression.
class_name MapManager
extends Node

# --- References ---
@onready var map_generator: MapGenerator = $MapGenerator
@onready var map_view: MapView = $MapView

# --- State ---
var map_data: Dictionary
var current_node_id: String = ""

func _ready():
	# Connect to the global signal that an event node has been selected by the player
	Global.event_node_selected.connect(_on_event_node_selected)
	start_new_map()
	
func start_new_map():
	"""
	Generates and displays a new map.
	"""
	map_data = map_generator.generate_map_data()
	map_view.display_map(map_data)
	# Initially, only the first row of nodes is available
	set_available_nodes_from_selection()

func _on_event_node_selected(node: EventNode):
	"""
	Handles the selection of an event node.
	"""
	# Mark all nodes as unavailable first to clear previous state
	for row in map_data.rows:
		for node_data in row:
			var n = map_view.get_node_by_id(node_data.id)
			if n:
				n.set_available(false)
	
	# Mark the selected node as completed
	node.set_completed(true)
	current_node_id = node.node_id
	
	# Determine which nodes are now available based on the new position
	set_available_nodes_from_selection(current_node_id)
	
	# Emit signal to the GameController to start the actual event
	Global.event_selected.emit(node.event_data)

func set_available_nodes_from_selection(selected_node_id: String = ""):
	"""
	Sets which nodes are available to the player based on the last node they selected.
	"""
	if selected_node_id.is_empty():
		# This is the start of the map. Make the first row available.
		if not map_data.rows.is_empty():
			for node_data in map_data.rows[0]:
				var node = map_view.get_node_by_id(node_data.id)
				if node:
					node.set_available(true)
	else:
		# Player has selected a node. Find all connected nodes in the next row.
		for connection in map_data.connections:
			if connection.from == selected_node_id:
				var next_node = map_view.get_node_by_id(connection.to)
				if next_node:
					next_node.set_available(true)
