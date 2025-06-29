# EncounterData.gd - Main resource for battle encounters
@tool
class_name EncounterData
extends Resource

@export var encounter_name: String = "New Encounter"

## Enemy Configuration
@export var enemy_spawns: Array[EnemySpawn] = []

## Turn Order Configuration
@export_group("Turn Order")
@export var use_custom_turn_order: bool = false
@export var custom_turn_order: Array[int] = []  # Indices into enemy_spawns array

## Future expansion (commented for now)
# @export_group("Presentation")
# @export var background_texture: Texture2D
# @export var battle_music: AudioStream
# @export var ambient_sound: AudioStream
