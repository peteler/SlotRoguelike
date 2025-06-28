# Enemy.gd
extends Area2D # Make sure this is your root node!

signal enemy_targeted(enemy)
# This signal is built-in to Area2D. Connect it to this function in the Inspector.
# (Node Tab -> Signals -> input_event)

func _ready():
	pass
	# call setup to basic stats


func _on_input_event(viewport, event, shape_idx):
	print("Enemy ", name, " detected an input event: ", event.get_class())
	# Check if the input was a left mouse click that was just pressed.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Emit a signal with a reference to ourselves (this enemy instance).
		emit_signal("enemy_targeted", self)
		print("signal emitted")
