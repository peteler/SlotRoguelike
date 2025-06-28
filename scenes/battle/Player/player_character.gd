class_name PlayerCharacter
extends Character

@onready var stats_ui = get_node("StatsUI")

# In your Player.gd or some other manager script.
func _ready():
	# Find the SlotMachine scene and connect to its signal.
	var slot_machine = get_tree().get_first_node_in_group("SlotMachine")
	slot_machine.roll_completed.connect(_on_slot_roll_completed)

# This function will be executed when the signal is emitted.
func _on_slot_roll_completed(results: Dictionary):
	print("Player script received roll results!")
	# Now, use the results to set the player's stats for the turn.
	
	stats_ui.set_attack(results["attack"])
	stats_ui.set_block(results["block"])
	
	# Now the player can proceed with their turn (e.g., enable spell buttons).
