# EnemyData.gd - A resource for defining enemy-specific data
@tool
class_name EnemyData
extends CharacterData

## base enemy stats (used only by enemy for intent system)
@export var base_attack: int = 5
@export var base_block: int = 2

## AI Behavior Configuration
@export_group("AI Behavior")
@export var ai_type: String = "aggressive"  # aggressive, defensive, random, custom
@export var attack_frequency: float = 0.8  # Chance to attack vs other actions
@export var special_ability_cooldown: int = 3  # Turns between special abilities

## Intent System (what the enemy plans to do)
@export_group("Enemy Actions")
@export var possible_actions: Array[EnemyAction] = []
@export var action_weights: Array[int] = []  # Relative weights for action selection

## Reward drops
@export_group("Rewards")
@export var symbol_rewards: Array[SymbolData] = []  # Symbols player can gain
@export var reward_count: int = 1  # How many symbols to give
