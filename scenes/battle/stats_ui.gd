# StatsUI.gd
extends Control

@onready var block_label = $HBoxContainer/BlockLabel
@onready var attack_label = $HBoxContainer/AttackLabel

func set_block(block_val: int):
	block_label.text = str(block_val)
	
func set_attack(attack_val: int):
	attack_label.text = str(attack_val)
