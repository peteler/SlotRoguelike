# EnemyTemplate.gd - A resource for defining enemy-specific data
@tool
class_name EnemyTemplate
extends BattleNPCTemplate

## Reward drops
@export_group("Rewards")
@export var symbol_rewards: Array[SymbolData] = []  # Symbols player can gain
@export var reward_count: int = 1  # How many symbols to give
