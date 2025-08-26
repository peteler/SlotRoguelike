# Action.gd - Resource for individual enemy actions
@tool
class_name Action
extends Resource

enum ACTION_TYPE {
	ATTACK,            # deal damage
	BLOCK,             # give block
	HEAL,              # heal
	CUSTOM_ABILITY,    # script
	BUFF,
	DEBUFF_PLAYER
}

@export var action_name: String = ""
@export var action_type: ACTION_TYPE = ACTION_TYPE.ATTACK
@export var icon: Texture2D  # For intent display
@export var icon_scale_factor: float = 1

@export_group("Basic Action Multipliers")
# e.g: for ACTION_TYPE.ATTACK: total_damage = attack_level * multiplier 
@export var multiplier: int = 1

@export_group("Action targets")
@export var target_type: GlobalBattle.TARGET_TYPE = GlobalBattle.TARGET_TYPE.PLAYER_CHARACTER

@export_group("Action Requirements")
@export var min_health_percent: float = 0.0  # Only use when health >= this
@export var max_health_percent: float = 1.0  # Only use when health <= this
@export var cooldown_turns: int = 0  # Turns to wait before using again

@export_group("Custom Action script (optional)")
@export var custom_action_script: GDScript
