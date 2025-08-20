extends Control

func _ready():
	$MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

func _on_main_menu_button_pressed():
	Global.game_over.emit()
