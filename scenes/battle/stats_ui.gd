# StatsUI.gd
extends Control

@onready var block_label: Label = $HBoxContainer/BlockLabel
@onready var attack_label: Label = $HBoxContainer/AttackLabel
@onready var health_label: Label

var character: Character

func _ready():
	Global.character_block_updated.connect(_on_character_block_updated)
	Global.character_attack_updated.connect(_on_character_attack_updated)
	
	character = get_parent() as Character
	if character:
		_on_character_block_updated(character, character.block)
		_on_character_attack_updated(character, character.attack)

func _on_character_block_updated(updated_character: Character, block: int):
	print("Signal received for block update. Character: ", updated_character.name, ", Block: ", block)
	# Only update if this is our character
	if updated_character == character:
		print("  --> Match found! Updating UI for ", character.name)
		block_label.text = str(block)
		block_label.visible = block > 0
	else:
		print("  --> No match. This update is for a different character.")

func _on_character_attack_updated(updated_character: Character, attack: int):
	# Only update if this is our character
	if updated_character == character:
		attack_label.text = str(attack)
		attack_label.visible = attack > 0
