#LevelComponent.gd
class_name LevelComponent
extends Node

var attack: int = 0
var block: int = 0
var heal: int = 0
var buff: int = 0

func initialize(template: BattleNPCTemplate):
	attack = template.attack_level
	block = template.block_level
	heal = template.heal_level
	buff = template.buff_level

func get_level(stat_name: String):
		return get(stat_name) if stat_name in self else 0
