# SymbolData.gd
@tool
class_name SymbolData
extends Resource

enum TARGET_TYPE {
	SELF,           # Applies to the player
	SINGLE_ENEMY,   # Applies to one enemy
	ALL_ENEMIES,    # Applies to all enemies
	RANDOM_ENEMY,   # Applies to a random enemy
	ALL_CHARACTERS, # Applies to everyone
	NONE            # No target (global effects)
}

## The visual representation of the symbol
@export var texture: Texture2D

## The name or ID of the symbol
@export var symbol_name: String = "Symbol"

## Who should receive this symbol effect?
@export var target_type: TARGET_TYPE = TARGET_TYPE.SELF

## Should this symbol be processed immediately when rolled?
@export var is_instant_effect: bool = false

## Stat modifications (can be positive or negative)
@export var health_effect: int = 0
@export var mana_effect: int = 0
@export var attack_effect: int = 0
@export var block_effect: int = 0

## Special effect script (optional)
@export var effect_script: GDScript

## Visual effect to play when processed
@export var visual_effect: PackedScene

# Helper function to get target type as string
func get_target_string() -> String:
	match target_type:
		TARGET_TYPE.SELF: return "Self"
		TARGET_TYPE.SINGLE_ENEMY: return "Single Enemy"
		TARGET_TYPE.ALL_ENEMIES: return "All Enemies"
		TARGET_TYPE.RANDOM_ENEMY: return "Random Enemy"
		TARGET_TYPE.ALL_CHARACTERS: return "All Characters"
		TARGET_TYPE.NONE: return "None"
	return "Unknown"
