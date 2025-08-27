# map_view.gd
# This script handles the visual representation of the map, including drawing connections.
class_name MapView
extends Node2D

# --- Prefabs ---
@export var event_node_scene: PackedScene

# --- Properties ---
@export var row_spacing: float = 150.0
@export var node_spacing: float = 100.0
@export var line_color: Color = Color(0.8, 0.8, 0.8, 0.5)
@export var line_width: float = 5.0

# --- State ---
var node_references: Dictionary = {}
var _connections_to_draw: Array = []

func _draw():
	"""
	Godot's built-in draw function. This is called automatically after queue_redraw().
	It iterates through the connections and draws lines between the nodes.
	"""
	for connection in _connections_to_draw:
		var from_node = get_node_by_id(connection.from)
		var to_node = get_node_by_id(connection.to)
		
		# Ensure both nodes exist before trying to draw a line
		if from_node and to_node:
			draw_line(from_node.position, to_node.position, line_color, line_width)

func display_map(map_data: Dictionary):
	"""
	Instantiates nodes, positions them, and prepares connections for drawing.
	"""
	# Clear previous map visuals
	for child in get_children():
		child.queue_free()
	node_references.clear()
	
	# Create and position all the event nodes
	for row_index in range(map_data.rows.size()):
		var row_nodes = map_data.rows[row_index]
		var y_pos = row_index * row_spacing
		# Center the nodes horizontally
		var total_width = (row_nodes.size() - 1) * node_spacing
		var start_x = -total_width / 2.0
		
		for col_index in range(row_nodes.size()):
			var node_data = row_nodes[col_index]
			var x_pos = start_x + col_index * node_spacing
			
			var node_instance = event_node_scene.instantiate() as EventNode
			add_child(node_instance)
			# Pass the node's unique ID to its setup function
			node_instance.setup(node_data.id, node_data.event_data, Vector2(x_pos, y_pos))
			
			node_references[node_data.id] = node_instance
			
	# Store connections and trigger a redraw to display them
	_connections_to_draw = map_data.connections
	queue_redraw()


func get_node_by_id(node_id: String) -> EventNode:
	"""
	Returns a node instance by its ID.
	"""
	return node_references.get(node_id)
