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
enum RARITY {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}
enum EDITION {
	# like foil, polychrome, etc.. some additional random modifier
}
@export var symbol_name: String = "Basic Symbol"
@export var description: String = ""
@export var texture: Texture2D
@export var target_type: TARGET_TYPE = TARGET_TYPE.SELF
@export var rarity: RARITY = RARITY.COMMON
@export var edition: EDITION

## Stat modifications (can be positive or negative)
@export var health_effect: int = 0
@export var mana_effect: int = 0
@export var attack_effect: int = 0
@export var block_effect: int = 0

# Special effect configuration
@export var special_effect_id: String = ""  # References SymbolProcessor logic
@export var effect_parameters: Dictionary = {}  # Configurable parameters
@export var effect_script: GDScript

# Visual and audio
@export var visual_effect_scene: PackedScene
@export var sound_effect: AudioStream
@export var animation_duration: float = 0.3

# Gameplay flags
@export var is_instant: bool = false  # Applied immediately vs on target
@export var is_consumable: bool = false  # Removed after use
@export var triggers_on_draw: bool = false  # Special symbols that activate when drawn
