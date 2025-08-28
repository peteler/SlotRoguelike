# IntentComponent.gd - Component for managing character intents
# connecting between character level component and available actions
class_name IntentComponent
extends Node


@export var owner_character: BattleNPC
var current_intent: Action
var current_action_val: int = 0
var current_targets = []

# Reference to the character's level component
var level_component: LevelComponent

# References to the character's possible actions & weights
var possible_actions: Array[Action] = []
var action_weights: Array[int] = []  # Relative weights for action selection
#var ai_type reference for owner_character's ai

# Trackers for character's action selection
var action_cooldowns: Dictionary = {}  # Track cooldowns for each action
var turns_since_last_special: int = 0

func initialize(template: BattleNPCTemplate):
	level_component = owner_character.get_node_or_null("LevelComponent")
	possible_actions = owner_character.get_possible_actions()
	for action in possible_actions:
		action_cooldowns[action] = 0
	action_weights = owner_character.get_possible_action_weights()

func select_intent():
	"""Choose what action to take in upcoming turn"""
	var available_actions = get_available_actions()
	
	#TODO: Select action based on AI type
	current_intent = select_weighted_action(available_actions)
	
	if not current_intent:
		push_error("current_intent is null for ", self)
		return
	
	# update action's value and targets to current intent 
	current_action_val = calculate_current_intent_action_value()
	current_targets = get_current_intent_targets()
	
	# signals for ui change
	Global.intent_changed.emit(owner_character, current_intent, current_action_val, current_targets)

func clear_intent():
	"""Clear the current intent"""
	current_intent = null
	current_action_val = 0
	current_targets = []
	
	# signals for ui change
	Global.intent_changed.emit(owner_character, current_intent, current_action_val, current_targets)

func calculate_current_intent_action_value() -> int:
	"""Calculate the action value based on character stats and action multiplier"""
	if not current_intent or not level_component:
		return 0
	
	match current_intent.action_type:
		Action.ACTION_TYPE.ATTACK:
			return current_intent.multiplier * level_component.get_level("attack")
		Action.ACTION_TYPE.BLOCK:
			return current_intent.multiplier * level_component.get_level("block")
		Action.ACTION_TYPE.HEAL:
			return current_intent.multiplier * level_component.get_level("heal")
		Action.ACTION_TYPE.BUFF:
			return current_intent.multiplier * level_component.get_level("buff")
		_:
			return current_intent.multiplier

func get_current_intent_targets():
	if current_intent and current_intent.target_type:
		return GlobalBattle.get_targets_by_target_type(current_intent.target_type, owner_character)
	push_error("no current intent / no current_intent.target_type")

func get_available_actions() -> Array[Action]:
	"""Get actions that can be used this turn"""
	if not possible_actions or possible_actions.is_empty():
		push_error("no possible_actions for: ", owner_character)
		return []
	
	var available: Array[Action] = []
	
	for action in possible_actions:
		# Check cooldown
		if action_cooldowns.get(action, 0) > 0:
			continue
		
		#TODO: implement character_stats component? or just implement .get_curr_health_ratio()
		#var health_percent = character_stats.get("current_health") / character_stats.get("max_health")
		#
		## Check health requirements
		#if health_percent < action.min_health_percent:
			#continue
		#if health_percent > action.max_health_percent:
			#continue
		
		available.append(action)
	
	return available

func select_weighted_action(actions: Array[Action]) -> Action:
	"""Select action based on configured weights"""
	if actions.is_empty():
		push_error("No available actions for enemy: ", self)
	
	if action_weights.is_empty():
		return actions[randi() % actions.size()]
	
	# Simple weighted selection
	var total_weight = 0
	for i in range(min(actions.size(), action_weights.size())):
		total_weight += action_weights[i]
	
	var rand_value = randi() % total_weight
	var current_weight = 0
	
	for i in range(min(actions.size(), action_weights.size())):
		current_weight += action_weights[i]
		if rand_value < current_weight:
			return actions[i]
	
	return actions[0]

func get_current_intent_data() -> Dictionary:
	"""Get current intent data for UI display"""
	return {
		"intent": current_intent,
		"action_val": current_action_val,
		"targets": current_targets
	}

# --- action execution functions ---
func execute_current_intent():
	"""Execute the selected action"""
	if not current_intent:
		push_error("No intent selected for enemy turn!")
		return
	
	print(owner_character , " uses " + current_intent.action_name)
	
	# Add visual delay for better game feel
	await get_tree().create_timer(0.3).timeout
	
	match current_intent.action_type:
		Action.ACTION_TYPE.ATTACK:
			for target in current_targets:
				await attack_target(target)
		Action.ACTION_TYPE.BLOCK:
			for target in current_targets:
				await give_block_to_target(target)
		Action.ACTION_TYPE.HEAL:
			for target in current_targets:
				await heal_target(target)
	# Set cooldown
	if current_intent.cooldown_turns > 0:
		action_cooldowns[current_intent] = current_intent.cooldown_turns

func attack_target(target: Character):
	"""Deal damage to target"""
	if target and current_action_val > 0:
		target.take_damage(current_action_val)

func give_block_to_target(target: Character):
	"""Gain block"""
	target.current_block += current_action_val

func heal_target(target: Character):
	"""Execute custom special ability"""
	if target and current_action_val > 0:
		target.current_health += current_action_val

func update_current_intent():
	"""Recalculate action value & targets** (called when character stats change)"""
	if current_intent:
		current_action_val = calculate_current_intent_action_value()
		
		# signal for ui
		Global.intent_changed.emit(owner_character, current_intent, current_action_val, current_targets)

func update_cooldowns():
	"""Update action cooldowns at start of turn"""
	for action in action_cooldowns:
		if action_cooldowns[action] > 0:
			action_cooldowns[action] -= 1
	
	turns_since_last_special += 1
