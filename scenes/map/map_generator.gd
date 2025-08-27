# map_generator.gd
# This script contains the logic for generating the map layout.
class_name MapGenerator
extends Node

# --- Configuration ---
@export var num_rows: int = 10
@export var nodes_per_row_min: int = 2
@export var nodes_per_row_max: int = 4
@export var extra_connection_probability: float = 0.3 # Chance for extra paths

# --- Event Data ---
## for now it's exported, later on will be set by gamecontroller 
@export var event_data_resources: Array[EventData]

# --- Generation Logic ---
func generate_map_data() -> Dictionary:
	"""
	Generates the entire map structure with nodes and connections.
	"""
	var map_data = {
		"rows": [],
		"connections": []
	}
	
	# Create nodes for each row
	for i in range(num_rows):
		var row_nodes = create_row_nodes(i)
		map_data.rows.append(row_nodes)
		
	# Create connections between rows
	for i in range(num_rows - 1):
		# Ensure the map is fully connected and playable
		var connections = create_guaranteed_connections(map_data.rows[i], map_data.rows[i+1])
		map_data.connections.append_array(connections)
		
	return map_data

func create_row_nodes(row_index: int) -> Array:
	"""
	Creates the nodes for a single row.
	"""
	var row_nodes = []
	var num_nodes = randi_range(nodes_per_row_min, nodes_per_row_max)
	
	for i in range(num_nodes):
		var event_data = select_random_event_data(row_index)
		# Generate a unique ID for each node based on its position
		var node_id = "node_%d_%d" % [row_index, i]
		var node = {
			"id": node_id,
			"row": row_index,
			"col": i,
			"event_data": event_data
		}
		row_nodes.append(node)
		
	return row_nodes

func select_random_event_data(row_index: int) -> EventData:
	"""
	Selects a random event data resource suitable for the given row.
	"""
	var valid_events = []
	for event in event_data_resources:
		if row_index >= event.min_row and row_index <= event.max_row:
			valid_events.append(event)
			
	if not valid_events.is_empty():
		return valid_events.pick_random()
	else:
		# Fallback in case no events are valid for the row
		push_warning("No valid event data found for row " + str(row_index) + ". Using a random one.")
		return event_data_resources.pick_random()

func create_guaranteed_connections(from_row: Array, to_row: Array) -> Array:
	"""
	Creates connections between two rows, ensuring every node is part of a path.
	This prevents dead ends and orphaned nodes.
	"""
	var connections = []
	var to_nodes_connected = {} # Using a dictionary to track connected 'to' nodes
	
	# 0. Ensure every to_node starts as not_connected
	for node in to_row: 
		to_nodes_connected[node.id] = false

	# 1. Ensure every 'from_node' has at least one connection going forward.
	for from_node in from_row:
		var target_node = to_row.pick_random()
		connections.append({"from": from_node.id, "to": target_node.id})
		to_nodes_connected[target_node.id] = true

	# 2. Ensure every 'to_node' has at least one connection coming from behind.
	for to_node_id in to_nodes_connected:
		if not to_nodes_connected[to_node_id]:
			var source_node = from_row.pick_random()
			connections.append({"from": source_node.id, "to": to_node_id})

	# 3. Add some extra random connections for more branching paths.
	for from_node in from_row:
		for to_node in to_row:
			if randf() < extra_connection_probability:
				# Check if connection already exists to avoid duplicates
				var existing = connections.filter(func(c): return c.from == from_node.id and c.to == to_node.id)
				if existing.is_empty():
					connections.append({"from": from_node.id, "to": to_node.id})

	return connections
