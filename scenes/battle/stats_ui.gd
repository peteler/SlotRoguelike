# StatsUI.gd
extends Control

@onready var block_label: Label = $HBoxContainer/BlockLabel
@onready var attack_label: Label = $HBoxContainer/AttackLabel

func _ready():
	var character = get_parent() as Character
	if character:
		character.block_updated.connect(_on_block_updated)
		character.attack_updated.connect(_on_attack_updated)
		_on_block_updated(character.block)
		_on_attack_updated(character.attack)

func _on_block_updated(block: int):
	block_label.text = str(block)
	block_label.visible = block > 0

func _on_attack_updated(attack: int):
	attack_label.text = str(attack)
	attack_label.visible = attack > 0
