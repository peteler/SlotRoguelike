# event_node.gd
# Modified to store its own ID.
class_name EventNode
extends Button

## Event data this node represents
var event_data: EventData
var node_id: String # Unique identifier for this node

## State tracking
var is_available: bool = false # Start as unavailable by default
var is_completed: bool = false

func _ready():
	# Connect pressed signal
	pressed.connect(_on_pressed)
	
	# Set initial appearance
	update_appearance()

func setup(id: String, event_data_ref: EventData, pos: Vector2):
	"""Initialize the event node with data and position"""
	node_id = id
	event_data = event_data_ref
	position = pos
	
	# Set button text based on event
	if event_data:
		match event_data.event_type:
			EventData.EVENT_TYPE.ENCOUNTER:
				text = "Battle"
			EventData.EVENT_TYPE.SHOP:
				text = "Shop"
			EventData.EVENT_TYPE.REST:
				text = "Rest"
			_:
				text = "Unknown"
				push_warning("Unhandled event type: " + str(event_data.event_type))
	
	update_appearance()

func update_appearance():
	"""Update visual appearance based on state"""
	if is_completed:
		modulate = Color(0.3, 0.8, 0.3)  # Green for completed
		disabled = true
	elif is_available:
		modulate = Color.WHITE  # Normal color
		disabled = false
	else:
		modulate = Color(0.5, 0.5, 0.5)  # Gray for unavailable
		disabled = true

func set_available(available: bool):
	"""Set whether this node is available for selection"""
	is_available = available
	update_appearance()

func set_completed(completed: bool):
	"""Mark this event as completed"""
	is_completed = completed
	is_available = false # A completed node can no longer be available
	update_appearance()

func _on_pressed():
	"""Handle node click"""
	if is_available and not is_completed:
		# Emit a reference to itself so the manager knows which node was clicked
		Global.event_node_selected.emit(self)
