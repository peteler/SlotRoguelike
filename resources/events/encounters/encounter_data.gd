# EncounterData.gd - Add map generation properties
@tool
class_name EncounterData
extends EventData

@export var encounter_name: String = "New Encounter"

## Enemy Configuration
@export var enemy_spawns: Array[EnemySpawn] = []

## Turn Order Configuration
@export_group("Turn Order")
@export var use_custom_turn_order: bool = false
@export var custom_turn_order: Array[int] = []  # Indices into enemy_spawns array

## Map Generation
@export var difficulty_level: int = 1  # How difficult this encounter is
