# EnemySpawn.gd - Individual enemy spawn configuration
@tool
class_name EnemySpawn
extends Resource

@export var enemy_data: EnemyData
@export var spawn_point_name: String = ""  # Name of Marker2D node to spawn at
@export var spawn_offset: Vector2 = Vector2.ZERO  # Additional offset from spawn point

## Per-enemy modifiers
@export_group("Modifiers")
@export var health_multiplier: float = 1.0
@export var attack_multiplier: float = 1.0
@export var give_extra_actions: Array[EnemyAction] = []  # Add special abilities for this fight

## Turn order weight (higher = goes later in turn)
@export var turn_priority: int = 0
