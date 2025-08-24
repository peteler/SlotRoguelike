# EnemyAction.gd - Resource for individual enemy actions
@tool
class_name EnemyAction
extends Resource

enum ACTION_TYPE {
	ATTACK,          # Deal damage to player
	DEFEND,          # Gain block
	HEAL,            # Restore health
	SPECIAL_ABILITY, # Custom effect
	BUFF_SELF,       # Temporary stat boost
	DEBUFF_PLAYER    # Weaken player
}

enum TARGET_TYPE {
	SELF,
	PLAYER_CHARACTER,
	ALL ENEMIES,
}

@export var action_name: String = "Attack"
@export var action_type: ActionType = ActionType.ATTACK
@export var icon: Texture2D  # For intent display

@export_group("Basic Action Multipliers")
@export var attack_multiplier: int = 1
@export var block_multiplier: int = 1
@export var heal_multiplier: int = 1
@export var effect_duration: int = 1  # For buffs/debuffs

@export_group("Action Requirements")
@export var min_health_percent: float = 0.0  # Only use when health >= this
@export var max_health_percent: float = 1.0  # Only use when health <= this
@export var cooldown_turns: int = 0  # Turns to wait before using again

@export_group("Custom Action script (optional)")
@export var custom_action_script: GDScript

# Get a description of what this action will do
func get_intent_description() -> String:
	match action_type:
		ActionType.ATTACK:
			return "Attack for " + str(attack_amount) + " damage"
		ActionType.DEFEND:
			return "Gain " + str(block_amount) + " block"
		ActionType.HEAL:
			return "Heal " + str(heal_amount) + " health"
		ActionType.SPECIAL_ABILITY:
			return action_name
		_:
			return action_name
