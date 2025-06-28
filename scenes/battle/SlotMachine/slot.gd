# Slot.gd
extends Control

@onready var texture_rect: TextureRect = $PanelContainer/TextureRect

# This function is called by the SlotMachine to update this slot's visual.
func set_symbol(symbol_data: SymbolData):
	if symbol_data and symbol_data.texture:
		texture_rect.texture = symbol_data.texture
	else:
		# Set a default or blank texture if something goes wrong.
		texture_rect.texture = preload("res://icon.svg") 

# Optional: Add a function for a spinning animation.
func play_spin_animation():
	# Your animation logic here (e.g., using a Tween or AnimationPlayer)
	pass
