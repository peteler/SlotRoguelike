# Map.gd - Simple map scene controller for MVP
extends Control

## References
@onready var node_container = $NodeContainer

## Simple event data for MVP - later replace with procedural generation
var test_encounters: Array[EncounterData] = []

func _ready():
	# Connect signals
	Global.event_node_selected.connect(_on_event_node_selected)
	
	# Create simple test encounters
	create_test_encounters()
	
	# Generate simple map for MVP
	generate_simple_map()

func create_test_encounters():
	"""Create some basic encounters for testing"""
	# You'll need to create these encounter resources in the editor
	# For now, create them programmatically
	var encounter1 = preload("res://resources/events/encounters/test_encounter.tres")
	var encounter2 = preload("res://resources/events/encounters/test_encounter.tres")
	var encounter3 = preload("res://resources/events/encounters/test_encounter.tres")
	
	test_encounters = [encounter1, encounter2, encounter3]

func generate_simple_map():
	"""Generate a simple horizontal row of events for MVP"""
	# Clear existing nodes
	for child in node_container.get_children():
		child.queue_free()
	
	# Create event nodes in a simple horizontal line
	for i in range(test_encounters.size()):
		var event_node = create_event_node(test_encounters[i], Vector2(i * 200 + 100, 300))
		node_container.add_child(event_node)

func create_event_node(event_data: EventData, pos: Vector2) -> EventNode:
	"""Create an event node at the specified position"""
	var event_node = preload("res://scenes/map/event_node.tscn").instantiate()
	event_node.setup(event_data, pos)
	return event_node

# only checks if it's a legal event node to select
# if it is, it emits a signal for game controller to start the event
func _on_event_node_selected(node: EventNode):
	if not node.is_available or node.is_completed:
		return
	
	# Just emit to GameController - don't call directly
	Global.event_selected.emit(node.event_data)
	
	# Mark as completed (or let GameController handle this)
	node.set_completed(true)
