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

# --- Scrolling/Dragging State ---
var _is_dragging: bool = false
var _drag_last_pos: Vector2

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

func _input(event: InputEvent):
	"""Handles mouse input for dragging the map."""
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_is_dragging = true
			_drag_last_pos = get_global_mouse_position()
		else:
			_is_dragging = false
	
	if event is InputEventMouseMotion and _is_dragging:
		var mouse_pos = get_global_mouse_position()
		var delta = mouse_pos - _drag_last_pos
		# Move the entire MapView node
		self.global_position += delta
		_drag_last_pos = mouse_pos

func initial_focus():
	"""Positions the map view so the first row is visible at the bottom of the screen."""
	# We want to position the MapView node such that the first row (at local y=0)
	# appears near the bottom of the screen.
	var viewport_size = get_viewport_rect().size
	
	# Place the first row 100 pixels up from the bottom edge.
	var target_y_on_screen = viewport_size.y - 100
	
	# The first row's nodes are at local y=0. The node's global position is the
	# MapView's global position + the node's local position. So, to make the node's
	# global y equal to our target, we set the MapView's global y to that target.
	self.position.y = target_y_on_screen
	
	# Center the map horizontally. Since rows are centered on local x=0, we just need
	# to set the MapView's x position to the middle of the screen.
	self.position.x = viewport_size.x / 2.0

func display_map(map_data: Dictionary):
	"""
	Instantiates nodes, positions them, and prepares connections for drawing.
	"""
	# Clear previous map visuals
	for child in get_children():
		child.queue_free()
	node_references.clear()
	
	# Create and position all the event nodes.
	# The positioning is now relative to the MapView's own origin (0,0), not the viewport.
	# This allows the entire MapView node to be moved/scrolled.
	for row_index in range(map_data.rows.size()):
		var row_nodes = map_data.rows[row_index]
		
		# Calculate y_pos for bottom-up layout (row 0 at y=0, higher rows move up into negative space).
		var y_pos = -(row_index * row_spacing)
		
		# Center the nodes of the current row horizontally around the MapView's origin (x=0).
		var total_row_width = (row_nodes.size() - 1) * node_spacing
		var start_x = -total_row_width / 2.0
		
		for col_index in range(row_nodes.size()):
			var node_data = row_nodes[col_index]
			var x_pos = start_x + col_index * node_spacing
			
			var node_instance = event_node_scene.instantiate() as EventNode
			add_child(node_instance)
			# Pass the node's unique ID to its setup function
			node_instance.setup(node_data.id, node_data.event_data, Vector2(x_pos, y_pos))
			print("instantiated node: ", node_data, "id: ",  node_data.id,"event_data: ", node_data.event_data)
			
			node_references[node_data.id] = node_instance
			
	# Store connections and trigger a redraw to display them
	_connections_to_draw = map_data.connections
	queue_redraw()

func get_node_by_id(node_id: String) -> EventNode:
	"""
	Returns a node instance by its ID.
	"""
	return node_references.get(node_id)
