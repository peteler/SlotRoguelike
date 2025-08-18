# StatsUI.gd
extends Control

@onready var block_label: Label = $BlockDisplay/BlockLabel
@onready var attack_label: Label = $AttackDisplay/AttackLabel
@onready var health_label: Label = $HealthBar/HealthLabel

var character: Character

func _ready():
	Global.character_block_updated.connect(_on_character_block_updated)
	Global.character_attack_updated.connect(_on_character_attack_updated)
	
	character = get_parent() as Character
	if character:
		_on_character_block_updated(character, character.block)
		_on_character_attack_updated(character, character.attack)

func _on_character_block_updated(updated_character: Character, block: int):
	# Only update if this is our character
	if updated_character == character:
		block_label.text = str(block)
		block_label.visible = block > 0

func _on_character_attack_updated(updated_character: Character, attack: int):
	# Only update if this is our character
	if updated_character == character:
		attack_label.text = str(attack)
		attack_label.visible = attack > 0
		
func _on_character_health_changed(updated_character: Character, health: int, max_health: int):
	print("Signal received for health update. Character: ", updated_character.name, ", health: ", health)
	if updated_character == character:
		health_label.text = str(health)
