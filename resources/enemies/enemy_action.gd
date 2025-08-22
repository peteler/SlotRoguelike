# EnemyAction.gd - Resource for individual enemy actions
@tool
class_name EnemyAction
extends Resource

enum ActionType {
	ATTACK,          # Deal damage to player
	DEFEND,          # Gain block
	HEAL,            # Restore health
	SPECIAL_ABILITY, # Custom effect
	BUFF_SELF,       # Temporary stat boost
	DEBUFF_PLAYER    # Weaken player
}

@export var action_name: String = "Attack"
@export var action_type: ActionType = ActionType.ATTACK
@export var icon: Texture2D  # For intent display

## Action Values
@export var attack_amount: int = 0
@export var block_amount: int = 0
@export var heal_amount: int = 0
@export var effect_duration: int = 1  # For buffs/debuffs

## Action Requirements
@export var min_health_percent: float = 0.0  # Only use when health >= this
@export var max_health_percent: float = 1.0  # Only use when health <= this
@export var cooldown_turns: int = 0  # Turns to wait before using again

## Custom effect script (optional)
@export var custom_effect_script: GDScript

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
