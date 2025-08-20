# VictoryScreen.gd
extends Control

func _ready():
	$MapButton.pressed.connect(_on_map_button_pressed)

func _on_map_button_pressed():
	Global.return_to_map.emit()
