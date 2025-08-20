# main_menu.gd
extends Control

func _ready():
	$StartButton.pressed.connect(_on_start_button_pressed)
	$QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	GameController.start_new_game()

func _on_quit_button_pressed():
	get_tree().quit()
