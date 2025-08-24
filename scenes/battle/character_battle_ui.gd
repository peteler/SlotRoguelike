# CharacterBattleUI.gd
class_name CharacterBattleUI
extends Control

@onready var block_label: Label = $BlockDisplay/BlockLabel
@onready var health_label: Label = $HealthBar/HealthLabel

var character: Character

func _ready():
	Global.character_block_updated.connect(_on_character_block_updated)
	Global.character_health_updated.connect(_on_character_health_updated)

func _on_character_block_updated(updated_character: Character, block: int):
	# Only update if this is our character
	if updated_character == character:
		block_label.text = str(block)
		block_label.visible = block > 0

func _on_character_health_updated(updated_character: Character, health: int, max_health: int):
	print("Signal received for health update. Character: ", updated_character.name, ", health: ", health)
	if updated_character == character:
		health_label.text = str(health)

# TODO: buff/debuff diplay
