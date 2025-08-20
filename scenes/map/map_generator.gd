## THIS IS THE CHANGE - Start ##
# MapGenerator.gd - Procedural map generation
class_name MapGenerator
extends Node

## Configuration
@export var map_width: int = 1000
@export var map_height: int = 600
@export var horizontal_spacing: int = 150
@export var vertical_spacing: int = 120
@export var rows: int = 5  # Number of vertical layers

## Event distribution weights
@export var encounter_weight: float = 0.7
@export var shop_weight: float = 0.2
@export var special_weight: float = 0.1

## Available events
@export var encounter_events: Array[EncounterData]
@export var shop_events: Array[EventData]  # You'll create these later
@export var special_events: Array[EventData]  # You'll create these later

func generate_map(difficulty: int = 1) -> Array:
	"""Generate a procedural map with branching paths"""
	var map_nodes = []
	
	# Create rows of events
	for row in range(rows):
		var row_nodes = generate_row(row, difficulty)
		map_nodes.append(row_nodes)
	
	# Connect nodes between rows
	connect_nodes(map_nodes)
	
	# Set starting node as available
	if map_nodes.size() > 0 and map_nodes[0].size() > 0:
		map_nodes[0][0].set_available(true)
		map_nodes[0][0].set_current(true)
	
	return map_nodes

func generate_row(row: int, difficulty: int) -> Array:
	"""Generate a single row of events"""
	var row_nodes = []
	var node_count = calculate_row_node_count(row)
	
	for i in range(node_count):
		var event_type = choose_event_type(row, difficulty)
		var event_data = get_event_data(event_type, row, difficulty)
		var position = calculate_node_position(row, i, node_count)
		
		var node = preload("res://scenes/map/event_node.tscn").instantiate()
		node.setup(event_data, position)
		node.set_available(false)  # Nodes start unavailable
		
		row_nodes.append(node)
	
	return row_nodes

func calculate_row_node_count(row: int) -> int:
	"""Calculate how many nodes should be in this row"""
	# Middle rows have more nodes, creating branching paths
	if row == 0:  # First row
		return 1
	elif row == rows - 1:  # Last row (boss)
		return 1
	elif row < rows / 2:  # First half - expanding
		return 1 + row
	else:  # Second half - contracting toward boss
		return rows - row

func choose_event_type(row: int, difficulty: int) -> EventData.EVENT_TYPE:
	"""Choose an event type based on row and difficulty"""
	# Early rows have more encounters, later rows have more variety
	var weights = {
		EventData.EVENT_TYPE.ENCOUNTER: encounter_weight,
		# Add other types as you implement them
	}
	
	# Adjust weights based on row
	if row > rows / 2:
		weights[EventData.EVENT_TYPE.ENCOUNTER] *= 0.8
		# Increase chance for special events in later rows
	
	# Choose based on weights
	var total = 0.0
	for weight in weights.values():
		total += weight
	
	var random_value = randf() * total
	var current = 0.0
	
	for event_type in weights.keys():
		current += weights[event_type]
		if random_value <= current:
			return event_type
	
	return EventData.EVENT_TYPE.ENCOUNTER  # Fallback

func get_event_data(event_type: EventData.EVENT_TYPE, row: int, difficulty: int) -> EventData:
	"""Get a specific event data based on type and row"""
	match event_type:
		EventData.EVENT_TYPE.ENCOUNTER:
			return get_encounter_data(row, difficulty)
		# Add other event types as you implement them
		_:
			return encounter_events[0]  # Fallback

func get_encounter_data(row: int, difficulty: int) -> EncounterData:
	"""Get an appropriate encounter for this row and difficulty"""
	# Filter encounters by difficulty
	var available_encounters = encounter_events.filter(
		func(e): return e.difficulty <= difficulty + row
	)
	
	if available_encounters.is_empty():
		return encounter_events[0]
	
	return available_encounters[randi() % available_encounters.size()]

func calculate_node_position(row: int, index: int, total_in_row: int) -> Vector2:
	"""Calculate position for a node in the map"""
	var x = (index + 1) * (map_width / (total_in_row + 1))
	var y = (row + 1) * vertical_spacing
	return Vector2(x, y)

func connect_nodes(map_nodes: Array):
	"""Connect nodes between rows with appropriate branching"""
	for row in range(map_nodes.size() - 1):
		var current_row = map_nodes[row]
		var next_row = map_nodes[row + 1]
		
		# Connect each node to 1-3 nodes in the next row
		for i in range(current_row.size()):
			var node = current_row[i]
			var connections = calculate_connections(i, current_row.size(), next_row.size())
			
			for connection_index in connections:
				if connection_index >= 0 and connection_index < next_row.size():
					node.add_connection(next_row[connection_index])

func calculate_connections(current_index: int, current_count: int, next_count: int) -> Array:
	"""Calculate which nodes in the next row this node should connect to"""
	var connections = []
	
	# Simple connection logic - can be enhanced for more interesting maps
	if next_count == 1:
		connections.append(0)  # Single connection
	else:
		# Connect to nearby nodes
		var ratio = float(current_index) / (current_count - 1) if current_count > 1 else 0.5
		var target_index = int(ratio * (next_count - 1))
		
		connections.append(target_index)
		
		# Sometimes add an additional connection for branching
		if randf() < 0.3 and next_count > 1:
			var alternate = target_index + (1 if target_index == 0 else -1)
			alternate = clamp(alternate, 0, next_count - 1)
			if alternate != target_index:
				connections.append(alternate)
	
	return connections
## THIS IS THE CHANGE - End ##
