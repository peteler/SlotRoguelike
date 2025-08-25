# EnemyData.gd - A resource for defining enemy-specific data
@tool
class_name EnemyData
extends CharacterData

## stat levels, affect actions of same type
@export var attack_level: int = 5
@export var block_level: int = 2
@export var heal_level: int = 0
@export var buff_level: int = 0

## AI Behavior Configuration
@export_group("AI Behavior")
@export var ai_type: String = "aggressive"  # aggressive, defensive, random, custom
@export var attack_frequency: float = 0.8  # Chance to attack vs other actions
@export var special_ability_cooldown: int = 3  # Turns between special abilities

## Intent System (what the enemy plans to do)
@export_group("Enemy Actions")
@export var possible_actions: Array[EnemyAction] = []
@export var action_weights: Array[int] = []  # Relative weights for action selection

## Enemy Intent UI placement
@export_group("Intent UI Placement")
@export var intent_ui_offset: Vector2 = Vector2(0, -100)  # Relative to sprite center
@export var intent_ui_anchor: String = "top_center"  # Where to anchor the UI

## Reward drops
@export_group("Rewards")
@export var symbol_rewards: Array[SymbolData] = []  # Symbols player can gain
@export var reward_count: int = 1  # How many symbols to give
